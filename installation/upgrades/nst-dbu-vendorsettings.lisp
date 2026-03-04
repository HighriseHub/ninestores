;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)

(defun migrate-2026Feb-create-vendor-settings-table ()
  "Create Vendor Settings table"
  ;; Helper macro to check and create table
  (flet ((create-table-if-not-exists (table-name ddl)
           (unless (table-exists-p table-name)
             (clsql:execute-command ddl))))

    ;; 1. vendor settings
    (create-table-if-not-exists
     "DOD_VENDOR_SETTINGS"
     "CREATE TABLE DOD_VENDOR_SETTINGS (
  ROW_ID        MEDIUMINT NOT NULL AUTO_INCREMENT PRIMARY KEY,

  VENDOR_ID     MEDIUMINT NOT NULL,
  TENANT_ID     MEDIUMINT DEFAULT NULL,

  SETTING_DEF_ID   MEDIUMINT,
  SETTING_KEY VARCHAR(255) NOT NULL UNIQUE, 
  SETTING_VALUE TEXT DEFAULT NULL,

  CONTEXT_ID    VARCHAR(100) DEFAULT NULL,
  TRACE         JSON DEFAULT NULL,

  STATUS        VARCHAR(20) DEFAULT 'ACTIVE',
  DELETED_STATE CHAR(1) DEFAULT NULL,

  CREATED       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UPDATED       TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                 ON UPDATE CURRENT_TIMESTAMP,

  KEY idx_vendor_setting (VENDOR_ID, SETTING_KEY),
  KEY idx_setting_key (SETTING_KEY),
CONSTRAINT fk_setting_key
    FOREIGN KEY (SETTING_DEF_ID)
    REFERENCES DOD_VENDOR_SETTINGS_DEFINITION (ROW_ID));")))
     
(defun migrate-2026Feb-create-vendor-settings-definition-table ()
  "Create Vendor Settings table"
  ;; Helper macro to check and create table
  (flet ((create-table-if-not-exists (table-name ddl)
           (unless (table-exists-p table-name)
             (clsql:execute-command ddl))))
    ;; 1. vendor settings
    (create-table-if-not-exists
     "DOD_VENDOR_SETTINGS_DEFINITION"
     "CREATE TABLE DOD_VENDOR_SETTINGS_DEFINITION (

ROW_ID        MEDIUMINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
SETTING_KEY VARCHAR(255) NOT NULL,

  INTENT_DOMAIN          VARCHAR(50) NOT NULL,
  DESCRIPTION            TEXT NOT NULL,

  KEYWORDS               JSON NOT NULL,
  ALLOWED_VALUES         JSON DEFAULT NULL,

  CONFIDENCE_THRESHOLD   DECIMAL(3,2) DEFAULT 0.90,

  VISIBILITY_SCOPE       ENUM('vendor','admin','system') DEFAULT 'vendor',

  DATA_TYPE              ENUM('string','number','boolean','json')
                          DEFAULT 'string',

  STATUS                 VARCHAR(20) DEFAULT 'ACTIVE',

  CREATED                TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UPDATED                TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);")))




