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

;;; ?exists — the identity the DB actually enforces.
;;;
;;; DOD_WAREHOUSE's unique key is uk_gstin_name_tenant
;;; (WAREHOUSE_GSTIN, W_NAME, TENANT_ID) — NOT GSTIN alone, and NOT including
;;; DELETED_STATE (see installation/upgrades/nst-dbu-warehouse.lisp). Everything
;;; below follows those two facts:
;;;   * the pre-check must match the tuple, or it predicts the wrong thing;
;;;   * a softly-deleted row keeps holding its identity forever, so "was
;;;     deleted" and "may be re-created" are different questions.
(defmethod ?exists ((entity-class (eql 'nst-whs)) (gstin string) (ctx domain-ctx)
                    &key wname)
  "Is the warehouse identity (GSTIN, WNAME, TENANT) already taken?
   Belnap answer, because the honest one is not yes/no:
     :F  free — nothing holds the identity
     :T  a LIVE warehouse holds it (a fact of existence)
     :C  a SOFT-DELETED row holds it: two of our own rules disagree — the row
         is present in DOD_WAREHOUSE and occupies uk_gstin_name_tenant, while
         नियम-2 makes DELETED_STATE='Y' rows invisible to every verb, so no
         warehouse is there. Callers must escalate (human/409), never read this
         as free: the INSERT would fail on the unique key.
     :U  the DB could not be consulted — must NOT be treated as :F.
   Without WNAME the identity cannot be formed (W_NAME is part of the key), so
   this falls back to the historical GSTIN-only, live-rows-only check."
  (let ((tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id)))
    (if (null wname)
        (with-db-call (select-warehouse-by-gstin gstin)
                      "nst-whs/?exists (gstin only, no name supplied)")
        (let ((knowledge (with-db-call
                             (select-warehouse-by-identity gstin wname tenant-id
                                                           :include-deleted t)
                           "nst-whs/?exists (gstin, name, tenant)")))
          (cond
            ;; Free, unknown, or the (impossible under a unique key) multi-row
            ;; :C — all pass through as the DB reported them.
            ((not (eq (bo-knowledge-truth knowledge) :T)) knowledge)
            ((string= (deleted-state (bo-knowledge-payload knowledge)) "Y")
             ;; Identity held by a row the domain considers gone. Merge the two
             ;; facts under the knowledge order: :T (it is there) ⊔ :F (no
             ;; warehouse there) = :C, provenance showing WHICH rules collided.
             (bo-merge knowledge
                       (make-bo-knowledge
                        :truth :F
                        :payload nil
                        :provenance "नियम-2: DELETED_STATE='Y' rows are invisible to every verb")))
            (t knowledge))))))

;;; make :before — refuse BEFORE the INSERT is attempted, on the identity the
;;; unique key really enforces. Only :F (confirmed free) may create: :U is not
;;; "probably free", and :C is a question for a human.
(defmethod make :before ((entity-class (eql 'nst-whs)) (ctx domain-ctx)
                          &rest initargs)
  (let ((gstin (getf initargs :warehouse-gstin)))   ; was :wgstin
    (when gstin
      (let* ((wname (getf initargs :wname))
             (check (?exists 'nst-whs gstin ctx :wname wname))
             (truth (bo-knowledge-truth check)))
        (case truth
          (:F nil)                     ; confirmed free — proceed
          (:T (error "GSTIN ~A + name ~S: a LIVE warehouse already holds this identity (uk_gstin_name_tenant). Refusing to create. [LEGAL: Section 122 CGST Act — duplicate GSTIN registration]"
                     gstin wname))
          (:C (error "GSTIN ~A + name ~S: the identity is held by a SOFT-DELETED warehouse — the row is still in DOD_WAREHOUSE (uk_gstin_name_tenant includes no DELETED_STATE) while नियम-2 makes it invisible to every verb. Human decision needed: undelete it, or create under a different name. Refusing to create."
                     gstin wname))
          (otherwise
           (error "GSTIN ~A: uniqueness check returned ~A, not confirmed-available (:F). Refusing to create. [LEGAL: Section 122 CGST Act — duplicate GSTIN registration]"
                  gstin truth)))))))
;;; Devil's advocate, CORRECTED against the real DDL
;;; (installation/upgrades/nst-dbu-warehouse.lisp): WAREHOUSE_GSTIN does NOT
;;; carry a single-column UNIQUE key. The DB enforces
;;; uk_gstin_name_tenant (WAREHOUSE_GSTIN, W_NAME, TENANT_ID) — so a duplicate
;;; GSTIN is only blocked when the name AND tenant also match, while a
;;; soft-deleted row keeps its slot because DELETED_STATE is not part of the
;;; key. The :before check above deliberately mirrors that tuple; it is
;;; defense-in-depth for the clean, LEGAL-cited error, and it does NOT close the
;;; TOCTOU gap (two concurrent creates of the same tuple could both pass before
;;; either commits) — the unique key is what actually prevents that race.

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

(defmethod !update ((entity-class (eql 'nst-whs)) (row-id string) (ctx domain-ctx)
                     &rest update-args)
  (let* ((tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id))
	(dbobj (select-warehouse-by-id (parse-integer row-id) tenant-id)))
    (if (null dbobj)
        (make-instance 'nst-entity-nil :tenant-id tenant-id
                        :reason (format nil "Warehouse row-id ~A not found" row-id))
	;;else 
	(let ((entity (make-instance 'nst-whs :tenant-id tenant-id)))
	  (copyWarehouse-dbtodomain dbobj entity) ;; hydrate current state
          (apply #'reinitialize-instance entity update-args)  ;; CLOS partial-update —
	  ;; only supplied initargs change
	  (copyWarehouse-domaintodb entity dbobj)
          (let ((knowledge (with-nst-db-update (:source "nst-whs/!update")
                             (clsql:update-records-from-instance dbobj)
                              dbobj)))
            (case (bo-knowledge-truth knowledge)
              (:T entity)
              (:U (error 'hhub-database-error
                          :errstring (format nil "Warehouse update failed, row-id ~A" row-id)))
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
    destination))

;;; domain->response-list — convenience for collections (e.g. enumerate
;;; results). Thin mapcar over the single-entity method; the entity
;;; instances still never cross the boundary directly.
(defun domain->response-list (entities ctx)
  "Carries each nst-whs through domain->response, returning a list of
   WarehouseResponseModel objects. Plain function, not a generic —
   the per-element dispatch already happens correctly inside
   domain->response itself; wrapping mapcar in a defmethod on 'list'
   would just be false ceremony, the same mistake caught in render-html
   two turns ago. BELNAP NOTE: mapping the list is a pure structural
   transform — it does NOT inspect each element's Belnap truth.
   Filter/route on sentinels BEFORE calling this."
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
   json:encode-json-to-string). Match all fields from RenderJSON.

   ID CONVENTION: every identifier crosses as a JSON string via
   response-id-string (see dod-ui-utl.lisp). rowId already arrives from the DB
   as a string, but ownerEntityId/operatorEntityId come from integer columns and
   operatorEntityId is NIL when unset — without normalisation one response mixed
   \"47\", 0 and null for the same kind of value. warehouseUuid / warehouseCode /
   defaultTransporterId are strings by construction and are passed through
   unchanged."
  (list 
   (cons "rowId" (response-id-string (row-id r)))
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
   (cons "ownerEntityId" (response-id-string (owner-entity-id r)))
   (cons "operatorEntityType" (operator-entity-type r))
   (cons "operatorEntityId" (response-id-string (operator-entity-id r)))
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


;;; ===========================================================================
;;; RELOCATED LEGACY HELPERS (moved from dod-bl-wrh.lisp)
;;; The nst-* verbs above call several of these directly (select-warehouse-by-id,
;;; select-warehouse-by-gstin, generate-warehouse-uuid/-short-code,
;;; copyWarehouse-domaintodb/-dbtodomain). They live here now that dod-bl-wrh.lisp
;;; is retired.
;;; ===========================================================================

(defparameter *valid-gst-state-codes*
  '("01" "02" "03" "04" "05" "06" "07" "08" "09" "10" "11" "12" "13"
    "14" "15" "16" "17" "18" "19" "20" "21" "22" "23" "24" "26" "27"
    "28" "29" "30" "31" "32" "33" "34" "35" "36" "37" "38")
  "GST jurisdiction state codes. Verify against the current GSTN
   master list before relying on this in production — codes are
   occasionally added (new UTs) or reclassified.")

(defun valid-indian-state-code-p (code)
  (and (stringp code) (member code *valid-gst-state-codes* :test #'string=)))


;;; ---------------------------------------------------------------------------
;;; QUERY FUNCTIONS
;;; ---------------------------------------------------------------------------

(defun select-warehouse-by-id (id tenant-id)
  "Select warehouse by row-id"
  (car (clsql:select 'dod-warehouse :where 
                     [and 
		      [= [:tenant-id] tenant-id]
		      [= [:row-id] id]
                      [= [:deleted-state] "N"]]
                     :caching *dod-database-caching* :flatp t)))

(defun select-warehouse-by-name (wname tenant-id)
  "Select warehouse by name"
  (car (clsql:select 'dod-warehouse :where
                     [and 
                      [= [:w-name] wname]
                      [= [:tenant-id] tenant-id]
                      [= [:deleted-state] "N"]]
                     :caching *dod-database-caching* :flatp t)))

(defun select-warehouse-by-code (warehouse-code tenant-id)
  "Select warehouse by business code"
  (car (clsql:select 'dod-warehouse 
                     :where [and
                             [= [:warehouse-code] warehouse-code]
                             [= [:tenant-id] tenant-id]
                             [= [:deleted-state] "N"]]
                     :flatp t)))

(defun select-warehouse-by-uuid (warehouse-uuid tenant-id)
  "Select warehouse by UUID"
  (car (clsql:select 'dod-warehouse 
                     :where [and
                             [= [:warehouse-uuid] warehouse-uuid]
                             [= [:tenant-id] tenant-id]
                             [= [:deleted-state] "N"]]
                     :flatp t)))

(defun select-warehouse-by-gstin (gstin)
  "Select warehouse by GSTIN (live rows only).
   NOTE: this is NOT the uniqueness the database enforces — see
   select-warehouse-by-identity — and it deliberately has no TENANT filter, so
   it must never back a read the API serves."
  (car (clsql:select 'dod-warehouse :where
                     [and 
                      [= [:warehouse-gstin] gstin]
                      [= [:deleted-state] "N"]]
                     :caching *dod-database-caching* :flatp t)))

(defun select-warehouse-by-identity (gstin wname tenant-id &key include-deleted)
  "Select by the tuple DOD_WAREHOUSE actually makes unique:
   (WAREHOUSE_GSTIN, W_NAME, TENANT_ID) — uk_gstin_name_tenant in
   installation/upgrades/nst-dbu-warehouse.lisp.

   INCLUDE-DELETED decides which question is being asked:
     NIL — 'is there a warehouse here?' (live rows, what every verb may see)
     T   — 'is this identity taken?' (what the unique key enforces, because
           DELETED_STATE is NOT part of the key, so a soft-deleted row keeps
           the identity reserved forever).

   Returns at most one row: the unique key guarantees the tuple appears once,
   deleted or not."
  (car (clsql:select 'dod-warehouse
                     :where (if include-deleted
                                [and [= [:warehouse-gstin] gstin]
                                     [= [:w-name] wname]
                                     [= [:tenant-id] tenant-id]]
                                [and [= [:warehouse-gstin] gstin]
                                     [= [:w-name] wname]
                                     [= [:tenant-id] tenant-id]
                                     [= [:deleted-state] "N"]])
                     :caching *dod-database-caching* :flatp t)))

(defun select-matching-warehouses (wname-like tenant-id)
  "Select warehouses matching partial name"
  (clsql:select 'dod-warehouse :where
                [and 
                 [like [:w-name] (format nil "%~a%" wname-like)]
                 [= [:tenant-id] tenant-id]
                 [= [:deleted-state] "N"]]
                :limit 200
                :caching *dod-database-caching* :flatp t))

(defun select-warehouses-by-city (city tenant-id)
  "Select warehouses by city"
  (clsql:select 'dod-warehouse :where
                [and 
                 [= [:w-city] city]
                 [= [:tenant-id] tenant-id]
                 [= [:deleted-state] "N"]]
                :limit 200
                :caching *dod-database-caching* :flatp t))

(defun select-warehouses-by-state-code (state-code tenant-id)
  "Select warehouses by state code"
  (clsql:select 'dod-warehouse :where
                [and 
                 [= [:state-code] state-code]
                 [= [:tenant-id] tenant-id]
                 [= [:deleted-state] "N"]]
                :caching *dod-database-caching* :flatp t))

(defun select-primary-warehouse (tenant-id)
  "Select primary warehouse location"
  (car (clsql:select 'dod-warehouse :where
                     [and
                      [= [:tenant-id] tenant-id]
                      [= [:is-primary-location] 1]
                      [= [:deleted-state] "N"]]
                     :caching *dod-database-caching* :flatp t)))

(defun select-all-warehouses (tenant-id)
  "Select all warehouses for a tenant"
  (clsql:select 'dod-warehouse :where
                [and
                 [= [:tenant-id] tenant-id]
                 [= [:deleted-state] "N"]]
                :limit 200
                :caching *dod-database-caching* :flatp t))

(defun select-vendor-warehouses (vendor-id tenant-id)
  "Select all warehouses owned by a vendor"
  (clsql:select 'dod-warehouse :where
                [and
                 [= [:tenant-id] tenant-id]
                 [= [:owner-entity-id] vendor-id]
                 [= [:owner-entity-type] "SELLER"]
                 [= [:deleted-state] "N"]]
                :limit 200
                :caching *dod-database-caching* :flatp t))

(defun select-warehouses-by-ownership (ownership-type owner-entity-type owner-entity-id tenant-id)
  "Select warehouses by ownership criteria"
  (clsql:select 'dod-warehouse :where
                [and
                 [= [:ownership-type] ownership-type]
                 [= [:owner-entity-type] owner-entity-type]
                 [= [:owner-entity-id] owner-entity-id]
                 [= [:tenant-id] tenant-id]
                 [= [:deleted-state] "N"]]
                :caching *dod-database-caching* :flatp t))

(defun get-active-warehouses (tenant-id)
  "Get all active warehouses for a tenant"
  (clsql:select 'dod-warehouse :where
                [and
                 [= [:tenant-id] tenant-id]
                 [= [:active-flag] "Y"]
                 [= [:deleted-state] "N"]]
                :caching *dod-database-caching* :flatp t))

;;; ---------------------------------------------------------------------------
;;; CODE GENERATION FUNCTIONS
;;; ---------------------------------------------------------------------------

(defun generate-warehouse-uuid ()
  "Generate UUID for warehouse"
  (format nil "~A" (uuid:make-v4-uuid)))

(defun generate-warehouse-short-code ()
  "Generate short alphanumeric code: WH-XXXXXXXX"
  (let* ((uuid (uuid:make-v4-uuid))
         (uuid-str (format nil "~A" uuid))
         (short-id (subseq uuid-str 0 8)))
    (format nil "WH-~A" (string-upcase short-id))))

;;; ---------------------------------------------------------------------------
;;; DOMAIN <-> DB COPY HELPERS
;;; ---------------------------------------------------------------------------

(defun copyWarehouse-domaintodb (source destination)
  "Copy warehouse domain object to database object with ownership fields"
  (let ((company (slot-value source 'company)))
    (with-slots (w-name w-addr1 w-addr2 w-pin w-city w-state w-country 
                 w-manager w-phone w-alt-phone w-email active-flag deleted-state
                 ownership-type owner-entity-type owner-entity-id
                 operator-entity-type operator-entity-id legal-entity-type
                 warehouse-gstin gstin-status legal-name is-primary-location
                 state-code registration-type warehouse-type warehouse-purpose
                 default-transporter-id default-transporter-name eway-bill-enabled
                 latitude longitude valuation-method hsn-wise-stock pan-number 
                 warehouse-uuid warehouse-code tenant-id) destination

 
      ;; Basic fields
      (setf w-name (slot-value source 'wname))
      (setf w-addr1 (slot-value source 'waddr1))
      (setf w-addr2 (slot-value source 'waddr2))
      (setf w-pin (slot-value source 'wpin))
      (setf w-city (slot-value source 'wcity))
      (setf w-state (slot-value source 'wstate))
      (setf w-country (slot-value source 'wcountry))
      (setf w-manager (slot-value source 'wmanager))
      (setf w-phone (slot-value source 'wphone))
      (setf w-alt-phone (slot-value source 'waltphone))
      (setf w-email (slot-value source 'wemail))
      (setf active-flag (slot-value source 'activeflag))
      (setf deleted-state "N")
      
      ;; Ownership fields
      (setf ownership-type (slot-value source 'ownership-type))
      (setf owner-entity-type (slot-value source 'owner-entity-type))
      (setf owner-entity-id (slot-value source 'owner-entity-id))
      (setf operator-entity-type (slot-value source 'operator-entity-type))
      (setf operator-entity-id (slot-value source 'operator-entity-id))
      (setf legal-entity-type (slot-value source 'legal-entity-type))
      
      ;; GST and Advanced Fields
      (setf warehouse-gstin (slot-value source 'warehouse-gstin))
      (setf gstin-status (slot-value source 'gstin-status))
      (setf legal-name (slot-value source 'legal-name))
      (setf is-primary-location (slot-value source 'is-primary-location))
      (setf state-code (slot-value source 'state-code))
      (setf registration-type (slot-value source 'registration-type))
      (setf warehouse-type (slot-value source 'warehouse-type))
      (setf warehouse-purpose (slot-value source 'warehouse-purpose))
      (setf default-transporter-id (slot-value source 'default-transporter-id))
      (setf default-transporter-name (slot-value source 'default-transporter-name))
      (setf eway-bill-enabled (slot-value source 'eway-bill-enabled))
      (setf latitude (slot-value source 'latitude))
      (setf longitude (slot-value source 'longitude))
      (setf valuation-method (slot-value source 'valuation-method))
      (setf hsn-wise-stock (slot-value source 'hsn-wise-stock))
      (setf pan-number (slot-value source 'pan-number))
      (setf warehouse-uuid (slot-value source 'warehouse-uuid))
      (setf warehouse-code (slot-value source 'warehouse-code))
      (setf tenant-id (slot-value company 'row-id))
      destination)))

(defun copyWarehouse-dbtodomain (source destination)
  "Copy database object to warehouse domain object with ownership fields"
  (with-slots (row-id wname waddr1 waddr2 wpin wcity wstate wcountry 
               wmanager wphone waltphone wemail activeflag
               ownership-type owner-entity-type owner-entity-id
               operator-entity-type operator-entity-id legal-entity-type
               warehouse-gstin gstin-status legal-name is-primary-location
               state-code registration-type warehouse-type warehouse-purpose
               default-transporter-id default-transporter-name eway-bill-enabled
               latitude longitude valuation-method hsn-wise-stock pan-number 
               warehouse-uuid warehouse-code) destination
    ;; Basic fields
    (setf row-id (slot-value source 'row-id))
    (setf wname (slot-value source 'w-name))
    (setf waddr1 (slot-value source 'w-addr1))
    (setf waddr2 (slot-value source 'w-addr2))
    (setf wpin (slot-value source 'w-pin))
    (setf wcity (slot-value source 'w-city))
    (setf wstate (slot-value source 'w-state))
    (setf wcountry (slot-value source 'w-country))
    (setf wmanager (slot-value source 'w-manager))
    (setf wphone (slot-value source 'w-phone))
    (setf waltphone (slot-value source 'w-alt-phone))
    (setf wemail (slot-value source 'w-email))
    (setf activeflag (slot-value source 'active-flag))
    
    ;; Ownership fields
    (setf ownership-type (slot-value source 'ownership-type))
    (setf owner-entity-type (slot-value source 'owner-entity-type))
    (setf owner-entity-id (slot-value source 'owner-entity-id))
    (setf operator-entity-type (slot-value source 'operator-entity-type))
    (setf operator-entity-id (slot-value source 'operator-entity-id))
    (setf legal-entity-type (slot-value source 'legal-entity-type))
    
    ;; GST and Advanced Fields
    (setf warehouse-gstin (slot-value source 'warehouse-gstin))
    (setf gstin-status (slot-value source 'gstin-status))
    (setf legal-name (slot-value source 'legal-name))
    (setf is-primary-location (slot-value source 'is-primary-location))
    (setf state-code (slot-value source 'state-code))
    (setf registration-type (slot-value source 'registration-type))
    (setf warehouse-type (slot-value source 'warehouse-type))
    (setf warehouse-purpose (slot-value source 'warehouse-purpose))
    (setf default-transporter-id (slot-value source 'default-transporter-id))
    (setf default-transporter-name (slot-value source 'default-transporter-name))
    (setf eway-bill-enabled (slot-value source 'eway-bill-enabled))
    (setf latitude (slot-value source 'latitude))
    (setf longitude (slot-value source 'longitude))
    (setf valuation-method (slot-value source 'valuation-method))
    (setf hsn-wise-stock (slot-value source 'hsn-wise-stock))
    (setf pan-number (slot-value source 'pan-number))
    (setf warehouse-uuid (slot-value source 'warehouse-uuid))
    (setf warehouse-code (slot-value source 'warehouse-code))
    destination))




