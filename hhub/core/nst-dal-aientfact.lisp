;;; nst-dal-aientfact.lisp
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.

;; -*- mode: common-lisp; coding: utf-8 -*-
;; nst-dal-aientfact.lisp
;; DAL layer for DOD_PROCURE_ENTITY_FACT — EAV versioned fact store.
;; DESIGN CONTRACT:
;;   - Every fact is immutable once written. "Update" = expire old + insert new.
;;   - VALID_TO IS NULL means the fact is the current live version.
;;   - SOURCE_TYPE must be one of: HUMAN_ENTERED | AI_EXTRACTED |
;;     AI_INFERRED | API_SYNC | OBSERVATION
;;   - FACT_KEY follows: {org}.{source}.{entity-type}.{category}.{attribute}
;;   - CONFIDENCE range: 0.4 (weak) to 1.0 (certain)
(in-package :nstores)

;;; ─── Constants: governed vocabularies ───────────────────────────────────────
;; Changing these affects downstream AI agents. Treat as a schema migration.

(defparameter *aientfact-source-types*
  '("HUMAN_ENTERED" "AI_EXTRACTED" "AI_INFERRED" "API_SYNC" "OBSERVATION")
  "Allowed SOURCE_TYPE values for DOD_PROCURE_ENTITY_FACT.")

(defparameter *aientfact-fact-types*
  '("string" "number" "boolean" "json" "date")
  "Allowed FACT_TYPE values.")

;;; ─── Request / Response / View Models ───────────────────────────────────────

(defclass AIEntityFactRequestModel (RequestModel)
  ((entityid
    :initarg :entityid    :accessor entityid)
   (factkey
    :initarg :factkey     :accessor factkey)
   (factval
    :initarg :factval     :accessor factval)
   (facttype
    :initarg :facttype    :accessor facttype
    :initform "string")
   (sourcetype
    :initarg :sourcetype  :accessor sourcetype)
   (confidence
    :initarg :confidence  :accessor confidence
    :initform 1.0)
   (validfrom
    :initarg :validfrom   :accessor validfrom
    :initform nil)
   (validto
    :initarg :validto     :accessor validto
    :initform nil)
   (assertedby
    :initarg :assertedby  :accessor assertedby
    :initform nil)
   (company
    :initarg :company     :accessor company)))

(defclass AIEntityFactSearchRequestModel (AIEntityFactRequestModel)
  ;; Search by entity-id (all current facts) or by fact-key prefix
  ((factkey-prefix
    :initarg :factkey-prefix :accessor factkey-prefix
    :initform nil)
   (include-history
    :initarg :include-history :accessor include-history
    :initform nil
    :documentation "When T, returns all versions including expired rows.")))

(defclass AIEntityFactResponseModel (ResponseModel)
  ((rowid      :initarg :rowid      :accessor rowid)
   (entityid   :initarg :entityid   :accessor entityid)
   (factkey    :initarg :factkey    :accessor factkey)
   (factval    :initarg :factval    :accessor factval)
   (facttype   :initarg :facttype   :accessor facttype)
   (sourcetype :initarg :sourcetype :accessor sourcetype)
   (confidence :initarg :confidence :accessor confidence)
   (validfrom  :initarg :validfrom  :accessor validfrom)
   (validto    :initarg :validto    :accessor validto)
   (assertedby :initarg :assertedby :accessor assertedby)
   (created    :initarg :created    :accessor created)
   (company    :initarg :company    :accessor company)))

(defclass AIEntityFactViewModel (ViewModel)
  ((rowid      :initarg :rowid      :accessor rowid)
   (entityid   :initarg :entityid   :accessor entityid)
   (factkey    :initarg :factkey    :accessor factkey)
   (factval    :initarg :factval    :accessor factval)
   (facttype   :initarg :facttype   :accessor facttype)
   (sourcetype :initarg :sourcetype :accessor sourcetype)
   (confidence :initarg :confidence :accessor confidence)
   (validfrom  :initarg :validfrom  :accessor validfrom)
   (validto    :initarg :validto    :accessor validto)
   (assertedby :initarg :assertedby :accessor assertedby)
   (created    :initarg :created    :accessor created)
   (company    :initarg :company    :accessor company)))

;;; ─── Domain / Business Object ────────────────────────────────────────────────

(defclass AIEntityFact (BusinessObject)
  ((rowid
    :initarg :rowid      :accessor rowid)
   (entityid
    :initarg :entityid   :accessor entityid)
   (factkey
    :initarg :factkey    :accessor factkey)
   (factval
    :initarg :factval    :accessor factval)
   (facttype
    :initarg :facttype   :accessor facttype
    :initform "string")
   (sourcetype
    :initarg :sourcetype :accessor sourcetype)
   (confidence
    :initarg :confidence :accessor confidence
    :initform 1.0)
   (validfrom
    :initarg :validfrom  :accessor validfrom)
   (validto
    :initarg :validto    :accessor validto
    :initform nil)
   (assertedby
    :initarg :assertedby :accessor assertedby
    :initform nil)
   (created
    :initarg :created    :accessor created)
   (company
    :initarg :company    :accessor company)))

;;; ─── CLSQL View Class ────────────────────────────────────────────────────────
;; NOTE: VALID_TO is nullable — CLSQL must handle NIL → SQL NULL correctly.
;; ROW_ID is bigint auto_increment; never set manually.

(clsql:def-view-class dod-procure-entity-fact ()
  ((row-id
    :db-kind :key
    :db-constraints :not-null
    :type integer
    :initarg :row-id
    :accessor row-id)
   (entity-id
    :type (string 100)
    :initarg :entity-id
    :accessor entity-id)
   (tenant-id
    :type integer
    :initarg :tenant-id
    :accessor tenant-id)
   (fact-key
    :type (string 200)
    :initarg :fact-key
    :accessor fact-key)
   (fact-val
    :type (string 65535)           ; maps text column
    :initarg :fact-val
    :accessor fact-val)
   (fact-type
    :type (string 20)
    :initarg :fact-type
    :accessor fact-type
    :initform "string")
   (source-type
    :type (string 30)
    :initarg :source-type
    :accessor source-type)
   (confidence
    :type float
    :initarg :confidence
    :accessor confidence
    :initform 1.0)
   (valid-from
    :type wall-time
    :initarg :valid-from
    :accessor valid-from)
   (valid-to
    :type wall-time
    :initarg :valid-to
    :accessor valid-to
    :initform nil)
   (asserted-by
    :type (string 100)
    :initarg :asserted-by
    :accessor asserted-by
    :initform nil)
   (created
    :type wall-time
    :initarg :created
    :accessor created)
   (COMPANY
    :accessor get-company
    :db-kind :join
    :db-info (:join-class dod-company
              :home-key tenant-id
              :foreign-key row-id
              :set nil)))
  (:base-table dod_procure_entity_fact))

;;; ─── Service / Adapter / Presenter / View class declarations ─────────────────

(defclass AIEntityFactAdapter   (AdapterService)   ())
(defclass AIEntityFactDBService (DBAdapterService)  ())
(defclass AIEntityFactPresenter (PresenterService)  ())
(defclass AIEntityFactService   (BusinessService)   ())
(defclass AIEntityFactHTMLView  (HTMLView)          ())
(defclass AIEntityFactJSONView  (JSONView)          ())
