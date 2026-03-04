;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)

(defun migrate-2026Feb-create-event-trace-table ()
  "Create customer users table which will enable us to have user profiles for customers who can login and do transactions"
  (flet ((create-table-if-not-exists (table-name ddl)
	   (unless (table-exists-p table-name)
             (clsql:execute-command ddl))))
    (create-table-if-not-exists
     "DOD_TRACE_EVENT"
     "CREATE TABLE DOD_TRACE_EVENT (
  ROW_ID            BIGINT NOT NULL AUTO_INCREMENT,

  -- What entity is this about?
  ENTITY_TYPE       VARCHAR(50) NOT NULL,
  ENTITY_ID         VARCHAR(100) NOT NULL,

  -- High-signal machine-readable identifiers
  EVENT_DOMAIN      VARCHAR(50) NOT NULL,
  EVENT_TYPE        VARCHAR(50) NOT NULL,
  EVENT_CODE        VARCHAR(100) NOT NULL,

  -- Human + AI readable explanation
  NARRATIVE_TEXT    TEXT NOT NULL,

  -- Structured facts captured at event time
  EVENT_DATA        JSON DEFAULT NULL,

  -- Hansel & Gretel: where did this journey start?
  CONTEXT_ID        VARCHAR(100) DEFAULT NULL,
  PARENT_EVENT_ID  BIGINT DEFAULT NULL,

  -- Who/what caused this event?
  ACTOR_TYPE        VARCHAR(30) DEFAULT NULL,
  ACTOR_ID          VARCHAR(100) DEFAULT NULL,

  -- Persona awareness
  PERSONA_TYPE      VARCHAR(30) DEFAULT NULL,

  -- Severity & intent
  SEVERITY          ENUM('INFO','WARN','ERROR','CRITICAL') DEFAULT 'INFO',
  INTENT_DOMAIN     VARCHAR(50) DEFAULT NULL,

  -- Lifecycle / tombstone fields (mirroring your style)
  STATUS            VARCHAR(20) DEFAULT 'ACTIVE',
  DELETED_STATE     CHAR(1) DEFAULT NULL,

  TENANT_ID         MEDIUMINT DEFAULT NULL,

  CREATED           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UPDATED           TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP
                     ON UPDATE CURRENT_TIMESTAMP,

  PRIMARY KEY (ROW_ID),
  KEY IDX_ENTITY (ENTITY_TYPE, ENTITY_ID),
  KEY IDX_EVENT_CODE (EVENT_CODE),
  KEY IDX_CONTEXT (CONTEXT_ID),
  KEY IDX_TENANT (TENANT_ID),
  KEY IDX_CREATED (CREATED),

  CONSTRAINT FK_TRACE_PARENT
    FOREIGN KEY (PARENT_EVENT_ID)
    REFERENCES DOD_TRACE_EVENT (ROW_ID)
    ON DELETE SET NULL
);")))
