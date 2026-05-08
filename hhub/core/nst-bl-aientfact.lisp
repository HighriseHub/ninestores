;; -*- mode: common-lisp; coding: utf-8 -*-
;; nst-bl-aientfact.lisp
;; Business layer for DOD_PROCURE_ENTITY_FACT — EAV versioned fact store.
;;
;; IMMUTABILITY CONTRACT:
;;   doUpdate  = expire current fact (SET VALID_TO = NOW()) + insert new row.
;;   doDelete  = expire current fact (SET VALID_TO = NOW()). No physical delete.
;;   doCreate  = INSERT only. Never UPDATE an existing row.
;;
;; LEGAL / AUDIT NOTE:
;;   This table is the evidentiary record for AI decisions.
;;   Physical deletion of rows may breach EU AI Act Article 13 (transparency)
;;   and data retention obligations. Soft-expiry via VALID_TO is mandatory.
;;
;; MULTI-TENANT NOTE:
;;   TENANT_ID has no FK declared in MySQL schema. Enforce in every query.
;;   Do not rely on the DB engine to prevent cross-tenant reads.
(in-package :nstores)
(clsql:file-enable-sql-reader-syntax)

;;; ─── Internal helpers ────────────────────────────────────────────────────────

(defun %current-timestamp ()
  "Returns current wall-time for VALID_FROM / VALID_TO stamping."
  (clsql:get-time))

(defun %tenant-id-from-company (company)
  (slot-value company 'row-id))

;;; ─── Source-type and Confidence validation ───────────────────────────────────
;; Called before every write. Fail loud — silent coercion hides agent errors.

(defun validate-aientfact-source-type (source-type)
  "Signal an error if source-type is not in the governed vocabulary."
  (unless (member source-type *aientfact-source-types* :test #'string=)
    (error 'hhub-business-function-error
           :errstring
           (format nil "Invalid SOURCE_TYPE '~A'. Allowed: ~{~A~^, ~}"
                   source-type *aientfact-source-types*))))

(defun validate-aientfact-confidence (confidence)
  "Confidence must be between 0.4 and 1.0 inclusive."
  (unless (and (>= confidence 0.4) (<= confidence 1.0))
    (error 'hhub-business-function-error
           :errstring
           (format nil "CONFIDENCE ~A out of range [0.4, 1.0]." confidence))))

;;; ─── Query Functions ─────────────────────────────────────────────────────────

(defun select-current-fact (entity-id fact-key tenant-id)
  "Fetch the single live fact (VALID_TO IS NULL) for entity + key + tenant."
  (car (clsql:select 'dod-procure-entity-fact
                     :where [and [= [:entity-id]  entity-id]
                                 [= [:fact-key]   fact-key]
                                 [= [:tenant-id]  tenant-id]
                                 [null [:valid-to]]]
                     :caching nil :flatp t)))

(defun select-all-current-facts (entity-id tenant-id)
  "Fetch all live facts for an entity (VALID_TO IS NULL)."
  (clsql:select 'dod-procure-entity-fact
                :where [and [= [:entity-id] entity-id]
                            [= [:tenant-id] tenant-id]
                            [null [:valid-to]]]
                :order-by '(([fact-key] :asc))
                :caching nil :flatp t))

(defun select-fact-history (entity-id fact-key tenant-id)
  "Fetch full version history for a specific fact key (including expired rows)."
  (clsql:select 'dod-procure-entity-fact
                :where [and [= [:entity-id] entity-id]
                            [= [:fact-key]  fact-key]
                            [= [:tenant-id] tenant-id]]
                :order-by '(([valid-from] :desc))
                :caching nil :flatp t))

(defun select-facts-by-key-prefix (entity-id fact-key-prefix tenant-id)
  "Fetch current facts whose key starts with a namespace prefix."
  (clsql:select 'dod-procure-entity-fact
                :where [and [= [:entity-id]  entity-id]
                            [= [:tenant-id]  tenant-id]
                            [like [:fact-key] (format nil "~A%" fact-key-prefix)]
                            [null [:valid-to]]]
                :caching nil :flatp t))

(defun select-facts-by-source-type (entity-id source-type tenant-id)
  "Fetch current facts for an entity filtered by who asserted them."
  (clsql:select 'dod-procure-entity-fact
                :where [and [= [:entity-id]   entity-id]
                            [= [:source-type] source-type]
                            [= [:tenant-id]   tenant-id]
                            [null [:valid-to]]]
                :caching nil :flatp t))

;;; ─── Copy Functions ──────────────────────────────────────────────────────────

(defun copyAIEntityFact-domaintodb (source destination)
  "Sync domain AIEntityFact → dod-procure-entity-fact DB object."
  (let ((company (slot-value source 'company)))
    (with-slots (entity-id fact-key fact-val fact-type
                 source-type confidence valid-from valid-to
                 asserted-by tenant-id) destination
      (setf entity-id   (slot-value source 'entityid))
      (setf fact-key    (slot-value source 'factkey))
      (setf fact-val    (slot-value source 'factval))
      (setf fact-type   (slot-value source 'facttype))
      (setf source-type (slot-value source 'sourcetype))
      (setf confidence  (slot-value source 'confidence))
      (setf valid-from  (or (slot-value source 'validfrom) (%current-timestamp)))
      (setf valid-to    (slot-value source 'validto))
      (setf asserted-by (slot-value source 'assertedby))
      (setf tenant-id   (%tenant-id-from-company company))
      destination)))

(defun copyAIEntityFact-dbtodomain (source destination)
  "Sync dod-procure-entity-fact DB object → domain AIEntityFact."
  (with-slots (rowid entityid factkey factval facttype
               sourcetype confidence validfrom validto assertedby created) destination
    (setf rowid      (slot-value source 'row-id))
    (setf entityid   (slot-value source 'entity-id))
    (setf factkey    (slot-value source 'fact-key))
    (setf factval    (slot-value source 'fact-val))
    (setf facttype   (slot-value source 'fact-type))
    (setf sourcetype (slot-value source 'source-type))
    (setf confidence (slot-value source 'confidence))
    (setf validfrom  (slot-value source 'valid-from))
    (setf validto    (slot-value source 'valid-to))
    (setf assertedby (slot-value source 'asserted-by))
    (setf created    (slot-value source 'created))
    destination))

(defun createAIEntityFactObject (entityid factkey factval facttype
                                  sourcetype confidence assertedby company)
  "Construct a new AIEntityFact domain object."
  (make-instance 'AIEntityFact
                 :entityid   entityid
                 :factkey    factkey
                 :factval    factval
                 :facttype   facttype
                 :sourcetype sourcetype
                 :confidence confidence
                 :assertedby assertedby
                 :validfrom  (%current-timestamp)
                 :company    company))

;;; ─── DBAdapterService Methods ────────────────────────────────────────────────

(defmethod init ((dbas AIEntityFactDBService) (bo AIEntityFact))
  :description "Init DB object. VALID_TO starts as NIL (fact is live)."
  (let ((dbobj (make-instance 'dod-procure-entity-fact)))
    (setf (dbobject dbas) dbobj)
    (setcompany dbas (slot-value bo 'company))
    (call-next-method)))

(defmethod Copy-BusinessObject-To-DBObject ((dbas AIEntityFactDBService))
  :description "Sync domain → DB object for INSERT."
  (let ((dbobj    (slot-value dbas 'dbobject))
        (domainobj (slot-value dbas 'businessobject)))
    (setf (slot-value dbas 'dbobject)
          (copyAIEntityFact-domaintodb domainobj dbobj))))

;;; ─── Internal: expire a live db row ─────────────────────────────────────────

(defun %expire-fact-row (dbobj company)
  "Set VALID_TO = NOW() on an existing DB row and persist it."
  (let ((dbas (make-instance 'AIEntityFactDBService)))
    (setf (slot-value dbobj 'valid-to) (%current-timestamp))
    (setf (slot-value dbas 'dbobject) dbobj)
    (setcompany dbas company)
    (db-save dbas)))

;;; ─── BusinessService CRUD Methods ────────────────────────────────────────────

(defmethod doCreate ((service AIEntityFactService)
                     (rm AIEntityFactRequestModel))
  :description "Write a new fact row. Validates governed fields before insert."
  (validate-aientfact-source-type (sourcetype rm))
  (validate-aientfact-confidence  (confidence rm))
  (let* ((dbas   (make-instance 'AIEntityFactDBService))
         (domain (createAIEntityFactObject
                   (entityid rm) (factkey rm) (factval rm)
                   (facttype rm) (sourcetype rm) (confidence rm)
                   (assertedby rm) (company rm))))
    (init dbas domain)
    (copy-businessobject-to-dbobject dbas)
    (db-save dbas)
    domain))

(defmethod doRead ((service AIEntityFactService)
                   (rm AIEntityFactRequestModel))
  :description "Read the current live fact by entity-id + fact-key."
  (let* ((comp      (company rm))
         (tenant-id (%tenant-id-from-company comp))
         (knowledge (with-db-call
                      (select-current-fact (entityid rm) (factkey rm) tenant-id)))
         (domain    (make-instance 'AIEntityFact :company comp)))
    (setf (bo-knowledge service) knowledge)
    (when (eq (bo-knowledge-truth knowledge) :T)
      (copyAIEntityFact-dbtodomain (bo-knowledge-payload knowledge) domain))
    domain))

(defmethod doReadAll ((service AIEntityFactService)
                      (rm AIEntityFactRequestModel))
  :description "Read all current live facts for an entity."
  (let* ((comp      (company rm))
         (tenant-id (%tenant-id-from-company comp))
         (rows      (select-all-current-facts (entityid rm) tenant-id)))
    (mapcar (lambda (row)
              (let ((d (make-instance 'AIEntityFact :company comp)))
                (copyAIEntityFact-dbtodomain row d))) rows)))

(defmethod doReadAll ((service AIEntityFactService)
                      (rm AIEntityFactSearchRequestModel))
  :description "Search current facts by namespace prefix or full history."
  (let* ((comp      (company rm))
         (tenant-id (%tenant-id-from-company comp))
         (rows (if (include-history rm)
                   (select-fact-history (entityid rm) (factkey rm) tenant-id)
                   (select-facts-by-key-prefix
                     (entityid rm) (factkey-prefix rm) tenant-id))))
    (mapcar (lambda (row)
              (let ((d (make-instance 'AIEntityFact :company comp)))
                (copyAIEntityFact-dbtodomain row d))) rows)))

(defmethod doUpdate ((service AIEntityFactService)
                     (rm AIEntityFactRequestModel))
  :description "Expire current fact + insert new row. Maintains full history."
  (validate-aientfact-source-type (sourcetype rm))
  (validate-aientfact-confidence  (confidence rm))
  (let* ((comp      (company rm))
         (tenant-id (%tenant-id-from-company comp))
         (live-row  (select-current-fact (entityid rm) (factkey rm) tenant-id)))
    ;; Step 1: expire old row
    (when live-row
      (%expire-fact-row live-row comp))
    ;; Step 2: insert new row (reuse doCreate logic)
    (doCreate service rm)))

(defmethod doDelete ((service AIEntityFactService)
                     (rm AIEntityFactRequestModel))
  :description "Soft-expire a live fact. Physical delete is prohibited."
  ;; LEGAL: See file header. Physical deletes are not permitted.
  (let* ((comp      (company rm))
         (tenant-id (%tenant-id-from-company comp))
         (live-row  (select-current-fact (entityid rm) (factkey rm) tenant-id)))
    (when live-row
      (%expire-fact-row live-row comp)
      t)))

;;; ─── Adapter Methods ─────────────────────────────────────────────────────────

(defmethod ProcessCreateRequest ((adapter AIEntityFactAdapter)
                                 (rm AIEntityFactRequestModel))
  (setf (slot-value adapter 'businessservice) (find-class 'AIEntityFactService))
  (call-next-method))

(defmethod ProcessReadRequest ((adapter AIEntityFactAdapter)
                               (rm AIEntityFactRequestModel))
  (setf (slot-value adapter 'businessservice) (find-class 'AIEntityFactService))
  (call-next-method))

(defmethod ProcessReadAllRequest ((adapter AIEntityFactAdapter)
                                  (rm AIEntityFactRequestModel))
  (setf (slot-value adapter 'businessservice) (find-class 'AIEntityFactService))
  (call-next-method))

(defmethod ProcessReadAllRequest ((adapter AIEntityFactAdapter)
                                  (rm AIEntityFactSearchRequestModel))
  (setf (slot-value adapter 'businessservice) (find-class 'AIEntityFactService))
  (call-next-method))

(defmethod ProcessUpdateRequest ((adapter AIEntityFactAdapter)
                                 (rm AIEntityFactRequestModel))
  (setf (slot-value adapter 'businessservice) (find-class 'AIEntityFactService))
  (call-next-method))

(defmethod ProcessDeleteRequest ((adapter AIEntityFactAdapter)
                                 (rm AIEntityFactRequestModel))
  (setf (slot-value adapter 'businessservice) (find-class 'AIEntityFactService))
  (call-next-method))

;;; ─── Response / ViewModel ────────────────────────────────────────────────────

(defmethod ProcessResponse ((adapter AIEntityFactAdapter) (bo AIEntityFact))
  (let ((rm (make-instance 'AIEntityFactResponseModel)))
    (createresponsemodel adapter bo rm)))

(defmethod CreateResponseModel ((adapter AIEntityFactAdapter)
                                (source AIEntityFact)
                                (dest AIEntityFactResponseModel))
  (with-slots (rowid entityid factkey factval facttype sourcetype
               confidence validfrom validto assertedby created company) dest
    (setf rowid      (slot-value source 'rowid))
    (setf entityid   (slot-value source 'entityid))
    (setf factkey    (slot-value source 'factkey))
    (setf factval    (slot-value source 'factval))
    (setf facttype   (slot-value source 'facttype))
    (setf sourcetype (slot-value source 'sourcetype))
    (setf confidence (slot-value source 'confidence))
    (setf validfrom  (slot-value source 'validfrom))
    (setf validto    (slot-value source 'validto))
    (setf assertedby (slot-value source 'assertedby))
    (setf created    (slot-value source 'created))
    (setf company    (slot-value source 'company))
    dest))

(defmethod ProcessResponseList ((adapter AIEntityFactAdapter) fact-list)
  (mapcar (lambda (bo)
            (let ((rm (make-instance 'AIEntityFactResponseModel)))
              (createresponsemodel adapter bo rm))) fact-list))

(defmethod CreateViewModel ((presenter AIEntityFactPresenter)
                            (rm AIEntityFactResponseModel))
  (let ((vm (make-instance 'AIEntityFactViewModel)))
    (dolist (slot '(rowid entityid factkey factval facttype sourcetype
                    confidence validfrom validto assertedby created company))
      (setf (slot-value vm slot) (slot-value rm slot)))
    vm))

(defmethod CreateAllViewModel ((presenter AIEntityFactPresenter) rm-list)
  (mapcar (lambda (rm) (createviewmodel presenter rm)) rm-list))
