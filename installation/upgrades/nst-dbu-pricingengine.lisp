;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)


(defun migrate-2025Jul-create-pricing-tables ()
  "Create all pricing-related tables for new pricing engine (SAP-free naming)."
  ;; Helper macro to check and create table
  (flet ((create-table-if-not-exists (table-name ddl)
           (unless (table-exists-p table-name)
             (clsql:execute-command ddl))))

    ;; 1. PRICE_RULESET
    (create-table-if-not-exists
     "DOD_PRICING_MODEL"
     "CREATE TABLE DOD_PRICING_MODEL (
        ROW_ID SERIAL PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        description TEXT,
        tenant_id INTEGER,
        category VARCHAR(50),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );")

    ;; 2. PRICING_COMPONENTS
    (create-table-if-not-exists
     "DOD_PRICING_COMPONENTS"
     "CREATE TABLE DOD_PRICING_COMPONENTS (
        ROW_ID SERIAL PRIMARY KEY,
        code VARCHAR(20) UNIQUE NOT NULL,
        description TEXT,
        value_type VARCHAR(20), -- e.g., PERCENTAGE, ABSOLUTE
        active BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );")

    ;; 3. PRICING_MODEL_COMPONENTS
    (create-table-if-not-exists
     "DOD_PRICING_MODEL_COMPONENTS"
     "CREATE TABLE DOD_PRICING_MODEL_COMPONENTS (
        ROW_ID SERIAL PRIMARY KEY,
        pricing_model_id INTEGER NOT NULL,
        pricing_component_id INTEGER NOT NULL,
        sequence_order INTEGER NOT NULL,
        handler_id INTEGER, -- Optional override
        FOREIGN KEY (ruleset_id) REFERENCES PRICE_RULESET(ruleset_id),
        FOREIGN KEY (component_type_id) REFERENCES PRICE_COMPONENT_TYPE(component_type_id),
        FOREIGN KEY (handler_id) REFERENCES PRICE_COMPUTE_HANDLER(handler_id)
      );")

    ;; 4. PRICE_COMPONENT_VALUE
    (create-table-if-not-exists
     "DOD_PRICING_COMPONENT_VALUE"
     "CREATE TABLE DOD_PRICING_COMPONENT_VALUES (
        ROW_ID SERIAL PRIMARY KEY,
        product_id INTEGER NOT NULL,
        component_type_id INTEGER NOT NULL,
        value NUMERIC(10,2),
        value_expr TEXT, -- for Lisp closure name or override
        customer_segment_id INTEGER,
        valid_from DATE,
        valid_to DATE,
        FOREIGN KEY (component_type_id) REFERENCES PRICE_COMPONENT_TYPE(component_type_id),
        FOREIGN KEY (customer_segment_id) REFERENCES CUSTOMER_SEGMENT_MASTER(segment_id)
      );")

    ;; 5. PRICE_COMPUTE_HANDLER
    (create-table-if-not-exists
     "PRICE_COMPUTE_HANDLER"
     "CREATE TABLE PRICE_COMPUTE_HANDLER (
        ROR_ID SERIAL PRIMARY KEY,
        handler_name VARCHAR(100) NOT NULL,
        closure_function TEXT NOT NULL,
        description TEXT,
        active BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );")

    ;; 6. CUSTOMER_SEGMENT_MASTER
    (create-table-if-not-exists
     "CUSTOMER_SEGMENT_MASTER"
     "CREATE TABLE CUSTOMER_SEGMENT_MASTER (
        segment_id SERIAL PRIMARY KEY,
        segment_code VARCHAR(30) UNIQUE NOT NULL,
        description TEXT
      );")))



