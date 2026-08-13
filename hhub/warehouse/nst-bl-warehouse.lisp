;;; nst-dal-warehouse.lisp — Domain class
(in-package :nstores)
(clsql:file-enable-sql-reader-syntax)

(defparameter *whs-sort-whitelist*
  '((:w-name . :w-name) (:w-city . :w-city) (:w-state . :w-state)
    (:warehouse-type . :warehouse-type) (:created . :created))
  "The ONLY columns enumerate may sort by. sort-by is caller-
   controllable (eventually from HTTP params) — this whitelist is
   what stands between that and arbitrary ORDER BY construction.
   Extend deliberately, one line at a time; never accept a raw
   column name from outside this list.")

(defun kw->enum-string (kw)
  "Converts a Lisp keyword like :third-party to the MySQL enum string
   THIRD_PARTY. Hyphen→underscore — MySQL ENUM values throughout
   DOD_WAREHOUSE (WAREHOUSE_TYPE, REGISTRATION_TYPE, WAREHOUSE_PURPOSE,
   VALUATION_METHOD, GSTIN_STATUS) use underscores; Lisp keywords
   idiomatically use hyphens. A bare (string kw) call would silently
   write the wrong string for any multi-word value."
  (substitute #\_ #\- (string kw)))

;;; ?exists — checked by GSTIN, the [LEGAL] uniqueness this entity needs.
(defmethod ?exists ((entity-class (eql 'nst-whs)) (gstin string) (ctx domain-ctx))
  (with-db-call                                   ; existing macro
    (select-warehouse-by-gstin gstin)))

;;; make :before — GSTIN uniqueness, Section 6's [LEGAL] example,
;;; now checking the CORRECTLY named initarg and the CORRECTLY cased
;;; Belnap value.
(defmethod make :before ((entity-class (eql 'nst-whs)) (ctx domain-ctx)
                          &rest initargs)
  (let ((gstin (getf initargs :warehouse-gstin)))   ; was :wgstin
    (when gstin
      (let ((check (?exists 'nst-whs gstin ctx)))
        (unless (eq (bo-knowledge-truth check) :F)   ; was :f — real bug, fixed
          (error "GSTIN ~A: uniqueness check returned ~A, not confirmed-
                  available (:F). Refusing to create. [LEGAL: Section 122
                  CGST Act — duplicate GSTIN registration]"
                 gstin (bo-knowledge-truth check)))))))
;;; Devil's advocate: DOD_WAREHOUSE.WAREHOUSE_GSTIN already carries a
;;; DB-level UNIQUE constraint (confirmed in the original schema — "UNI"
;;; key). This :before check is defense-in-depth, not the sole guard —
;;; it turns a raw SQL constraint-violation into a clean, LEGAL-cited
;;; domain error BEFORE the INSERT is attempted. It does NOT close the
;;; TOCTOU gap (two concurrent creates with the same GSTIN could both
;;; pass this check before either commits) — the DB constraint is what
;;; actually prevents the duplicate in that race; this exists for the
;;; common case's clean error message, not as the only safety net.

;;; make primary method — REVISED against real doCreate.
(defmethod make ((entity-class (eql 'nst-whs)) (ctx domain-ctx) &rest initargs)
  (let* ((entity (apply #'make-instance 'nst-whs :tenant-id (domain-ctx-tenant ctx) initargs))
         (dbobj  (make-instance 'dod-warehouse)))
    
    (setf (warehouse-uuid entity)  (generate-warehouse-uuid))
    (setf (warehouse-code entity)  (generate-warehouse-short-code))
    (copywarehouse-domaintodb entity dbobj)
    ;;(populate-dbobj-from-entity dbobj entity (tenant ctx))

    (let ((knowledge (with-nst-db-create (:source "nst-whs/make")
                        (clsql:update-records-from-instance dbobj)
                        dbobj)))
      (case (bo-knowledge-truth knowledge)
        (:T (bind-generated-row-id entity (bo-knowledge-payload knowledge))
            entity)
        (:F (error "GSTIN ~A rejected at DB write — Section 122 CGST Act \
                     (uniqueness race lost after :before check passed)"
                    (warehouse-gstin entity)))
        (:U (error 'hhub-database-error :errstring "Warehouse create failed — see log"))
        (:C (error "Unreachable: no :pre-flight form supplied to with-nst-db-create \
                     in this call — a :C here means the macro contract changed \
                     without this method being updated"))
        (otherwise (error "Unrecognized bo-knowledge-truth ~A from with-nst-db-create"
                           (bo-knowledge-truth knowledge)))))))


;;; fetch — returns a real nst-whs OR a Belnap-inspectable sentinel,
;;; never a bare CL nil (Section 6's fetch contract). Unchanged from
;;; the original draft — doCreate gave no new evidence about fetch,
;;; so nothing here was revised.
(defmethod fetch ((entity-class (eql 'nst-whs)) (id string) (ctx domain-ctx))
  (let ((tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id))
	(bk (with-db-call (select-warehouse-by-id (parse-integer id) (slot-value (domain-ctx-tenant ctx) 'row-id)))))
    (if bk
        (let ((entity (make-instance 'nst-whs :tenant-id tenant-id))
	      (dbobj (bo-knowledge-payload bk)))
          (copywarehouse-dbtodomain dbobj entity)   ; ⚠ still unverified —
          entity)                                    ; same honest-unknown
        (make-instance 'nst-entity-nil :tenant-id tenant-id))))

(defmethod delete! ((entity-class (eql 'nst-whs)) (row-id string) (ctx domain-ctx))
  (let* ((tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id))
	 (dbobj (select-warehouse-by-id (parse-integer row-id) tenant-id)))
    (cond
      ((null dbobj)
       (make-instance 'nst-entity-nil :tenant-id tenant-id
                       :reason (format nil "Warehouse row-id ~A not found" row-id)))
      ((string= (deleted-state dbobj) "Y")
       (make-instance 'nst-entity-nil :tenant-id tenant-id
                       :reason (format nil "Warehouse row-id ~A already deleted" row-id)))
      (t
       (let ((knowledge (with-nst-db-delete (:source "nst-whs/delete!")
                           (setf (deleted-state dbobj) "Y")
                           (clsql:update-record-from-slot dbobj 'deleted-state)
                           dbobj)))
         (case (bo-knowledge-truth knowledge)
           (:T t)
           (:U (error 'hhub-database-error
                       :errstring (format nil "Warehouse delete failed, row-id ~A" row-id)))
           (otherwise (error "Unrecognized bo-knowledge-truth ~A" (bo-knowledge-truth knowledge)))))))))



(defun validate-sort-args (sort-by sort-dir)
  (let ((col (cdr (assoc sort-by *whs-sort-whitelist*))))
    (unless col
      (error "enumerate: sort-by ~A not in whitelist ~A" sort-by *whs-sort-whitelist*))
    (unless (member sort-dir '(:asc :desc))
      (error "enumerate: sort-dir must be :asc or :desc, got ~A" sort-dir))
    (values col sort-dir)))

(defun escape-like-wildcards (str)
  "Escapes MySQL LIKE metachars so name-like input is treated literally."
  (when str
    (let ((result str))
      ;; Escape backslash first (must be first)
      (setf result (cl-ppcre:regex-replace-all "\\\\" result "\\\\\\\\"))
      ;; Escape percent sign
      (setf result (cl-ppcre:regex-replace-all "%" result "\\\\%"))
      ;; Escape underscore
      (setf result (cl-ppcre:regex-replace-all "_" result "\\\\_"))
      result)))


(defun build-warehouse-filter-clauses (tenant-id &key warehouse-type state-code city
                                                    is-primary-location name-like)
  "गण: Anusthup. Assembles WHERE clauses for warehouse queries.
   DELETED_STATE = 'N' is fixed, not a keyword."
  (let ((clauses (list [= [:tenant-id] tenant-id]
                        [= [:deleted-state] "N"])))
    (when warehouse-type
      (push [= [:warehouse-type] (kw->enum-string warehouse-type)] clauses))
    (when state-code (push [= [:state-code] state-code] clauses))
    (when city (push [= [:w-city] city] clauses))
    (when (not (null is-primary-location))
      (push [= [:is-primary-location] (if is-primary-location 1 0)] clauses))
    (when (and name-like (plusp (length (string-trim " " name-like))))
      (push [like [:w-name] (format nil "%~A%" (escape-like-wildcards name-like))] clauses))
    clauses))

(defun select-warehouses-by-filter (tenant-id &key warehouse-type state-code city
                                                 is-primary-location name-like
                                                 (sort-by :w-name) (sort-dir :asc))
  (multiple-value-bind (sort-col sort-dir) (validate-sort-args sort-by sort-dir)
    (clsql:select 'dod-warehouse
                  :where (apply #'clsql:sql-and
                                (build-warehouse-filter-clauses
                                 tenant-id :warehouse-type warehouse-type
                                           :state-code state-code :city city
                                           :is-primary-location is-primary-location
                                           :name-like name-like))
                  :order-by (list (list sort-col sort-dir))
                  :caching *dod-database-caching* :flatp t)))



(defmethod enumerate ((entity-class (eql 'nst-whs)) (ctx domain-ctx)
                       &key warehouse-type state-code city is-primary-location name-like
                            (sort-by :w-name) (sort-dir :asc))
  (let* ((tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id))
         (knowledge (with-nst-db-read-all
                        (:source "nst-whs/enumerate"
                         :pk-extractor (lambda (d) (slot-value d 'row-id)))
                      (select-warehouses-by-filter tenant-id
                                                   :warehouse-type warehouse-type :state-code state-code
                                                   :city city :is-primary-location is-primary-location
                                                   :name-like name-like
                                                   :sort-by sort-by :sort-dir sort-dir))))
    (case (bo-knowledge-truth knowledge)
      (:T (mapcar (lambda (dbobj)
                    (let ((entity (make-instance 'nst-whs :tenant-id tenant-id)))
                      (copywarehouse-dbtodomain dbobj entity)
                      entity))
                  (bo-knowledge-payload knowledge)))
      (:F '())
      (:U (error 'hhub-database-error :errstring "Warehouse enumerate failed — see log"))
      (:C (error "PK duplication in enumerate results, tenant ~A — data integrity issue, investigate DOD_WAREHOUSE directly"
                 tenant-id))
      (otherwise (error "Unrecognized bo-knowledge-truth ~A" (bo-knowledge-truth knowledge))))))


;;; ═══════════════════════════════════════════════════════════════════════
;;; domain->response — nst-whs → WarehouseResponseModel
;;; ═══════════════════════════════════════════════════════════════════════
;;;
;;; The reverse ferry (Section 4 of nst-bl-adhara.lisp). entity is the
;;; ONLY dispatching argument that may be an nst-domain-entity. Returns
;;; an WarehouseResponseModel (boundary tree) — never the entity itself.
;;; The entity does not cross into Ring 4 (UI/HTTP) directly.
;;;
;;; EVERY slot declared on nst-whs is copied — all fields present in
;;; the domain class cross to the outbound response shape. The current
;;; implementation copies the full set; a narrower allowlist can be
;;; introduced later by editing ONLY this method, not the class.

(defmethod domain->response ((entity nst-whs) (ctx domain-ctx))
  (let ((destination (make-instance 'WarehouseResponseModel)))
    ;; ROW
    (setf (row-id destination)                (row-id entity))
    ;; UNIQUE IDENTIFIERS
    (setf (warehouse-uuid destination)        (warehouse-uuid entity))
    (setf (warehouse-code destination)        (warehouse-code entity))
    ;; BASIC INFO
    (setf (wname destination)                 (wname entity))
    (setf (waddr1 destination)                (waddr1 entity))
    (setf (waddr2 destination)                (waddr2 entity))
    (setf (wpin destination)                  (wpin entity))
    (setf (wcity destination)                 (wcity entity))
    (setf (wstate destination)                (wstate entity))
    (setf (wcountry destination)              (wcountry entity))
    (setf (wmanager destination)              (wmanager entity))
    (setf (wphone destination)                (wphone entity))
    (setf (waltphone destination)             (waltphone entity))
    (setf (wemail destination)                (wemail entity))
    ;; AUDIT FIELDS
    (setf (activeflag destination)            (activeflag entity))
    ;; OWNERSHIP MODEL
    (setf (ownership-type destination)        (ownership-type entity))
    (setf (owner-entity-type destination)     (owner-entity-type entity))
    (setf (owner-entity-id destination)       (owner-entity-id entity))
    (setf (vendor destination)                (vendor entity))
    (setf (operator-entity-type destination)  (operator-entity-type entity))
    (setf (operator-entity-id destination)    (operator-entity-id entity))
    (setf (legal-entity-type destination)     (legal-entity-type entity))
    ;; GST COMPLIANCE
    (setf (warehouse-gstin destination)       (warehouse-gstin entity))
    (setf (gstin-status destination)          (gstin-status entity))
    (setf (legal-name destination)            (legal-name entity))
    (setf (is-primary-location destination)   (is-primary-location entity))
    (setf (state-code destination)            (state-code entity))
    (setf (registration-type destination)     (registration-type entity))
    (setf (pan-number destination)            (pan-number entity))
    ;; WAREHOUSE CLASSIFICATION
    (setf (warehouse-type destination)        (warehouse-type entity))
    (setf (warehouse-purpose destination)     (warehouse-purpose entity))
    ;; LOGISTICS
    (setf (default-transporter-id destination)   (default-transporter-id entity))
    (setf (default-transporter-name destination) (default-transporter-name entity))
    (setf (eway-bill-enabled destination)        (eway-bill-enabled entity))
    ;; LOCATION
    (setf (latitude destination)              (latitude entity))
    (setf (longitude destination)             (longitude entity))
    ;; INVENTORY MANAGEMENT
    (setf (valuation-method destination)      (valuation-method entity))
    (setf (hsn-wise-stock destination)        (hsn-wise-stock entity))
    ;; TENANT
    (setf (company destination)               (company entity))
    destination))

;;; domain->response-list — convenience for collections (e.g. enumerate
;;; results). Thin mapcar over the single-entity method; the entity
;;; instances still never cross the boundary directly.
(defmethod domain->response-list ((entities list) (ctx domain-ctx))
  "Carries each nst-whs through domain->response, returning a list of
   WarehouseResponseModel objects. BELNAP NOTE: mapping the list is a
   pure structural transform — it does NOT inspect each element's
   Belnap truth. Filter/route on sentinels BEFORE calling this."
  (mapcar (lambda (dom) (domain->response dom ctx)) entities))

;;; processresponselist-warehouse — listed-view entry point. Thin
;;; wrapper over domain->response-list; kept for call-site clarity and
;;; as the single named seam between enumerate's DOMAIN list and the
;;; outbound boundary list.


;;; ═══════════════════════════════════════════════════════════════════════
;;; render-json — WarehouseResponseModel
;;; ═══════════════════════════════════════════════════════════════════════
;;;
;;; Multiple dispatch on the response argument: a single
;;; WarehouseResponseModel, or a LIST of them. Both cardinalities are
;;; resolved by CLOS — one method per (generic × cardinality), no if/else
;;; over types.
;;;
;;; SECURITY CONTRACT: each method is an explicit field allowlist. A slot
;;; added to WarehouseResponseModel does NOT auto-leak; it must be added
;;; here per-format.
;;;
;;; NOTE: render-html for WarehouseResponseModel lives in
;;; nst-ui-warehouse.lisp, not here — it reuses display-as-table +
;;; display-warehouse-row (cl-who, HTML-escaping). No render-html method
;;; is defined in this DAL-level file.

(defmethod render-json ((r WarehouseResponseModel) (ctx domain-ctx))
  "Single warehouse → JSON alist (caller or a list method applies
   json:encode-json-to-string). Match all fields from RenderJSON."
  (list 
   (cons "rowId" (row-id r))
   (cons "warehouseUuid" (warehouse-uuid r))
   (cons "warehouseCode" (warehouse-code r))
   (cons "name" (wname r))
   (cons "address1" (waddr1 r))
   (cons "address2" (waddr2 r))
   (cons "pin" (wpin r))
   (cons "city" (wcity r))
   (cons "state" (wstate r))
   (cons "country" (wcountry r))
   (cons "manager" (wmanager r))
   (cons "phone" (wphone r))
   (cons "altPhone" (waltphone r))
   (cons "email" (wemail r))
   (cons "activeFlag" (activeflag r))
   ;; Ownership fields
   (cons "ownershipType" (ownership-type r))
   (cons "ownerEntityType" (owner-entity-type r))
   (cons "ownerEntityId" (owner-entity-id r))
   (cons "operatorEntityType" (operator-entity-type r))
   (cons "operatorEntityId" (operator-entity-id r))
   (cons "legalEntityType" (legal-entity-type r))
   ;; GST and Advanced Fields
   (cons "warehouseGstin" (warehouse-gstin r))
   (cons "gstinStatus" (gstin-status r))
   (cons "legalName" (legal-name r))
   (cons "isPrimaryLocation" (is-primary-location r))
   (cons "stateCode" (state-code r))
   (cons "registrationType" (registration-type r))
   (cons "warehouseType" (warehouse-type r))
   (cons "warehousePurpose" (warehouse-purpose r))
   (cons "defaultTransporterId" (default-transporter-id r))
   (cons "defaultTransporterName" (default-transporter-name r))
   (cons "ewayBillEnabled" (eway-bill-enabled r))
   (cons "latitude" (latitude r))
   (cons "longitude" (longitude r))
   (cons "valuationMethod" (valuation-method r))
   (cons "hsnWiseStock" (hsn-wise-stock r))
   (cons "panNumber" (pan-number r))))

(defmethod render-json ((responses list) (ctx domain-ctx))
  "Many warehouses → a JSON array text. Empty list → [] (bracketed — is
   what a caller listed with zero rows should see, distinct from 404)."
  (json:encode-json-to-string
   (mapcar (lambda (r) (render-json r ctx)) responses)))

(defun processresponselist-warehouse (warehouselist &optional (ctx (make-domain-ctx)))
  "DEPRECATED-PREFERENCE: prefer domain->response-list directly.
   Load-bearing only for code that predates the generic method."
  (domain->response-list warehouselist ctx))




