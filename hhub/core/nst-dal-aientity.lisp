
;; nst-dal-aientity.lisp
;; DAL layer for DOD_PROCURE_ENTITY — AI procurement anchor/identity table.
;; Composite PK: (ENTITY_ID, TENANT_ID). No soft-delete; entities are canonical.
(in-package :nstores)

;;; ─── Request / Response / View Models ───────────────────────────────────────

(defclass AIEntityRequestModel (RequestModel)
  ((entityid
    :initarg :entityid
    :accessor entityid)
   (entitytype
    :initarg :entitytype
    :accessor entitytype)
   (company
    :initarg :company
    :accessor company)))

(defclass AIEntitySearchRequestModel (AIEntityRequestModel)
  ((entitytype-filter
    :initarg :entitytype-filter
    :accessor entitytype-filter
    :initform nil)))

(defclass AIEntityResponseModel (ResponseModel)
  ((entityid   :initarg :entityid   :accessor entityid)
   (entitytype :initarg :entitytype :accessor entitytype)
   (created    :initarg :created    :accessor created)
   (company    :initarg :company    :accessor company)))

(defclass AIEntityViewModel (ViewModel)
  ((entityid   :initarg :entityid   :accessor entityid)
   (entitytype :initarg :entitytype :accessor entitytype)
   (created    :initarg :created    :accessor created)
   (company    :initarg :company    :accessor company)))

;;; ─── Domain / Business Object ────────────────────────────────────────────────

(defclass AIEntity (BusinessObject)
  ((entityid
    :initarg :entityid
    :accessor entityid)
   (entitytype
    :initarg :entitytype
    :accessor entitytype)
   (created
    :initarg :created
    :accessor created)
   (company
    :initarg :company
    :accessor company)))

;;; ─── CLSQL View Class (DB Mapping) ──────────────────────────────────────────
;; NOTE: Composite PK (entity-id, tenant-id). CLSQL marks only one :db-kind :key;
;; the WHERE clause in fetch queries must always include both columns.

(clsql:def-view-class dod-procure-entity ()
  ((entity-id
    :db-kind :key
    :db-constraints :not-null
    :type (string 100)
    :initarg :entity-id
    :accessor entity-id)
   (entity-type
    :type (string 50)
    :initarg :entity-type
    :accessor entity-type)
   (tenant-id
    :type integer
    :initarg :tenant-id
    :accessor tenant-id)
   (created
    :type (string 30)
    :initarg :created
    :accessor created)
   (deleted-state
    :type (string 1)
    :initarg :deleted-state
    :accessor deleted-state)
   (COMPANY
    :accessor get-company
    :db-kind :join
    :db-info (:join-class dod-company
              :home-key tenant-id
              :foreign-key row-id
              :set nil)))
  (:base-table dod_procure_entity))

;;; ─── Adapter / Service / Presenter / View Classes ───────────────────────────

(defclass AIEntityAdapter   (AdapterService)  ())
(defclass AIEntityDBService (DBAdapterService) ())
(defclass AIEntityPresenter (PresenterService) ())
(defclass AIEntityService   (BusinessService)  ())
(defclass AIEntityHTMLView  (HTMLView)         ())
(defclass AIEntityJSONView  (JSONView)         ())
