;;; nst-sch-mig.lisp
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.

;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)



(defparameter *migrations*
  '(("05082025-add-product-code"  migrate-2025May-add-product-code "Added human readable Product code to DOD_PRD_MASTER table")
    ;; Add more migrations here
    ("09052025-add-price&discount-columns"  migrate-2025May-add-discount-column "Added current price and current discount to DOD_PRD_MASTER table")
    ("16062025-modify-dod_order-table"  migrate-2025Jun-dod-order-schema "Modify dod_order table add many columns, drop columns, add indexes and foreign keys")
    ("22082025-modify-dod_order_items-table"  migrate-2025Aug-OrderItem-upgrade "Modify dod_order_items table add many columns")
    ("02092025-modify-dod_order_items-sgst"  migrate-2025Sep-orderitem-upgrade-sgst "Modify dod_order_items table modify the sgst column to decimal(4,2) and drop taxable_value column")
    ("08022026-create-vendor-settings-definition-table"  migrate-2026Feb-create-vendor-settings-definition-table "Create vendor settings definitions table")
    ("08022026-create-vendor-settings-table"  migrate-2026Feb-create-vendor-settings-table "Create vendor settings table")
    ("26012026-create-organizations-table"  migrate-2026Jan-create-organization-tables "Create organization tables")
    ("26012026-create-contacts and addresses-table"  migrate-2026Jan-create-contacts&addresses-tables "Create contacts and addresses  tables")
    ("27012026-create-gstupgrade-tables"  migrate-2026Jan-create-gstupgrade-tables "Create gst upgrade tables")
    ("27012026-update-customer-table"  migrate-2026Jan-update-customer-table "Update Customer table to support GST changes for B2B support")
    ("30012026-update-customer-wallet-table"  migrate-2026Feb-update-customer-wallet-table "Update Customer wallet table to support vendor management in B2B use cases")
    ("02022026-create-customer-users-table"   migrate-2026Feb-create-customer-users-table "Create customer users table for B2B use cases")
    ("02022026-update-customer-users-table"   migrate-2026Feb-update-customer-users-table "Update customer users table for B2B use cases. Copy data from DOD_CUST_PROFILE table.")
    ("08022026-update-customer-users-table"   migrate-2026Feb-create-event-trace-table "Create event trace table which will help taking decisions using AI.")
    ("11022026-update-customer-wallet-table"   migrate-2026Feb-update-customer-wallet-table "Update the customer wallet table to support advance receipt payments.")
    ("11022026-create-proforma-invoice-table"   migrate-2026Feb-create-proforma-invoices-table "Create proforma invoice table.")
    ("11022026-create-advance-receipt-vouchers-table"   migrate-2026Feb-create-advance-receipt-vouchers-table "Create advance receipt vouchers table.")
    ("11022026-create-invoice-advance-adjustments-table"   migrate-2026Feb-create-invoice-advance-adjustments-table "Create invoice advance adjustments table.")
    ("13022026-create-buyer-vendor-account-table"   migrate-2026Feb-create-buyer-vendor-account-table  "Create buyer vendor relationship table where we capture the advance payments.")
    ("13022026-create-gst-reconciliation-table"   migrate-2026Feb-create-gst-reconciliation-table  "Create gst reconciliation table for the customer.")
    ("13022026-create-invoice-gst-reconciliation-table"   migrate-2026Feb-create-invoice-gst-reconciliation-table   "Create invoice gst reconciliation table for the customer.")
    ("13022026-create-vendor-gstr1-status-table"   migrate-2026Feb-create-vendor-gstr1-status-table   "Create vendor gstr1 status check table for a customer.")
    ("13022026-update-invoice-header-table"   migrate-2026Feb-update-invoice-header-table    "Update invoice header to support GST changes.")
    ("13022026-create-tds-certificates-table"   migrate-2026Feb-create-tds-certificates-table    "Create tds certificates table.")
    ("13022026-modify-payment-transactions-table"   migrate-2026Feb-modify-payment-transaction-table    "Modify the payment transaction table.")
    ("13022026-modify-customer-order-table"   migrate-2026Feb-modify-customer-order-table    "Modify the customer order table.")
    ("13022026-modify-customer-order-items-table"   migrate-2026Feb-modify-customer-order-items-table    "Modify the customer order items table.")
    ("16022026-modify-warehouse-table"   migrate-2026Feb-update-warehouse-table "Modify the warehouse table.")
    ("16022026-create-warehouse-location-table"   migrate-2026Feb-create-warehouse-location-table "Create warehouse location table.")
    ("22022026-create-batch-lot-table"   migrate-2026Feb-create-batch-lot-table "Create batch lot table.")
    ("22022026-create-stock-table"   migrate-2026Feb-create-stock-table "Create stock table.")
    ("22022026-create-stock-movement-table"   migrate-2026Feb-create-stock-movement-table "Create stock movement table.")
    ("22022026-create-stock-reservation-table"   migrate-2026Feb-create-stock-reservation-table "Create stock reservation table.")
    ("22022026-create-stock-count-table"   migrate-2026Feb-create-stock-count-table "Create stock count table.")
    ("22022026-update-vendor-orders-table"   migrate-2026March-modify-vendor-order-table "Update vendor orders table to support more GST fields.")
    ("15032026-create-eway-bill-table"   migrate-2026March-create-eway-bill-table    "Create eway bill table.")
    ("15032026-create-delivery-order-table"   migrate-2026March-create-delivery-order-table    "Create delivery order table.")
    ("15032026-create-delivery-items-table"   migrate-2026March-create-delivery-items-table    "Create delivery items table.")
    ("15032026-create-goods-receipt-note-table"   migrate-2026March-create-goods-receipt-note-table    "Create goods receipt note table.")
    ("15032026-create-goods-receipt-note-items-table"   migrate-2026March-create-goods-receipt-note-items-table    "Create goods receipt note items table.")
    ("15032026-add-constraints-to-delivery-items-and-goo"   migrate-2026March-add-constraints-to-delivery-items-and-goods-receipt    "Add constraints to delivery items and goods receipt.")
    ("22032026-create-procure-ai-entity-table"   migrate-2026March-create-procure-ai-entity-table    "Create AI procurement entity table.")
    ("22032026-create-procure-ai-entity-fact-table"   migrate-2026March-create-procure-ai-entity-fact-table    "Create AI procurement entity fact table.")
    ("22032026-create-procure-ai-commerce-event-table"    migrate-2026March-create-procure-ai-commerce-event-table    "Create procure AI commerce event table.")
    ("22032026-create-procure-ai-commerce-state-table"    migrate-2026March-create-procure-ai-commerce-state-table    "Create procure AI commerce state table.")
    ("22032026-create-procure-ai-signal-table"    migrate-2026March-create-procure-ai-signal-table    "Create procure AI signal table.")
    ("22032026-create-procure-ai-chat-signal-table"    migrate-2026March-create-procure-ai-chat-signal-table    "Create procure AI chat signal table.")
    ("22032026-create-procure-ai-signal-route-table"    migrate-2026March-create-procure-ai-signal-route-table    "Create procure AI signal route table.")
    ("22032026-create-procure-ai-policy-table"    migrate-2026March-create-procure-ai-policy-table    "Create procure AI policy table.")
    ("22032026-create-procure-ai-exception-table"    migrate-2026March-create-procure-ai-exception-table    "Create procure AI exception table.")
    ("22032026-create-procure-ai-skill-table"    migrate-2026March-create-procure-ai-skill-table    "Create procure AI skill table.")
    ("22032026-create-procure-ai-agent-context-table"    migrate-2026March-create-procure-ai-agent-context-table    "Create procure AI agent context table.")
    ("22032026-create-procure-ai-prediction-table"    migrate-2026March-create-procure-ai-prediction-table    "Create procure AI prediction table.")
    ("22032026-create-procure-ai-planned-action-table"    migrate-2026March-create-procure-ai-planned-action-table    "Create procure AI planned action table.")
    ("22032026-create-procure-ai-symentic-index-table"    migrate-2026March-create-procure-ai-symentic-index-table    "Create procure AI symentic index table.")
    ("22032026-insert-seed-data-to-ai-tables"    migrate-2026March-insert-seed-data-to-ai-tables    "Insert seed data to ai tables.")
    ("06052026-create-view-customer-inward-invoices"   migrate-2026May-create-customer-inward-invoices-view    "Create a view which shows customer inward invoices.")
    ))




(defun get-applied-migrations ()
  (mapcar #'first
          (clsql:query "SELECT version FROM DOD_SCHEMA_MIGRATIONS ORDER BY row_id ASC" :field-names nil)))

(defun apply-migrations (username password)
  (unwind-protect
       (progn
         (crm-db-connect :servername *crm-database-server*
                         :strdb *crm-database-name*
                         :strusr username
                         :strpwd password
                         :strdbtype :mysql)
         (handler-case
             (let ((applied (get-applied-migrations)))
               (dolist (migration *migrations*)
                 (destructuring-bind (version fn description) migration
                   (unless (member version applied :test #'string=)
                     (format t "Applying migration ~A...~%" version)
                     (format t "Description: ~A~%" description)
                     (funcall fn)
		     (sleep 1)
                     (clsql:execute-command
                      (format nil "INSERT INTO DOD_SCHEMA_MIGRATIONS (version) VALUES ('~A');" version))
                     (format t "Migration ~A applied.~%" version)))))
           (error (e)
             (format *error-output* "Migration error: ~A~%" e))))
    (when (clsql:connected-databases)
      (clsql:disconnect))))

(defun column-exists-p (table column)
  (let* ((sql (format nil
                      "SELECT COUNT(*) FROM information_schema.columns
                       WHERE table_schema = DATABASE()
                         AND table_name = '~A'
                         AND column_name = '~A'"
                      table column))
         (result (clsql:query sql :flatp t)))
    (> (first result) 0)))


(defun column-type-equals-p (table-name column-name expected-type)
  (let* ((query (format nil
                        "SELECT DATA_TYPE, NUMERIC_PRECISION, NUMERIC_SCALE
                         FROM information_schema.columns
                         WHERE table_name = '~A' AND column_name = '~A' AND table_schema = DATABASE();"
                        table-name column-name))
         (result (clsql:query query :flatp t)))
    (when result
      (destructuring-bind (data-type precision scale) result
        (let ((actual (format nil "~A(~A,~A)" (string-upcase data-type) precision scale)))
          (string= actual (string-upcase expected-type)))))))


(defun index-exists-p (table-name index-name)
  (let* ((query (format nil
                        "SELECT 1 FROM information_schema.statistics
                         WHERE table_name = '~A' AND index_name = '~A' AND table_schema = DATABASE();"
                        table-name index-name))
         (result (clsql:query query :flatp t)))
    (not (null result))))

(defun foreign-key-exists-p (table-name fk-name)
  (let* ((query (format nil
                        "SELECT 1 FROM information_schema.table_constraints
                         WHERE table_name = '~A' AND constraint_name = '~A'
                         AND constraint_type = 'FOREIGN KEY' AND table_schema = DATABASE();"
                        table-name fk-name))
         (result (clsql:query query :flatp t)))
    (not (null result))))

(defun table-exists-p (table)
  (let* ((sql (format nil
                      "SELECT COUNT(*) FROM information_schema.tables
                       WHERE table_schema = DATABASE()
                         AND table_name = '~A'"
                      table))
         (result (clsql:query sql :flatp t)))
    (> (first result) 0)))


(defun migrate-2025Sep-orderitem-upgrade-sgst ()
  (when (column-exists-p "DOD_ORDER_ITEMS" "SGST")
    (clsql:execute-command "ALTER TABLE DOD_ORDER_ITEMS MODIFY COLUMN SGST decimal(4,2);"))
  (when (column-exists-p "DOD_ORDER_ITEMS" "TAXABLE_VALUE")
    (clsql:execute-command "ALTER TABLE DOD_ORDER_ITEMS DROP COLUMN TAXABLE_VALUE;")))

(defun migrate-2025Aug-OrderItem-upgrade ()
  ;; 1 - Add column - TAXABLE_VALUE
  (unless (column-exists-p "DOD_ORDER_ITEMS" "TAXABLEVALUE")
    (clsql:execute-command "ALTER TABLE DOD_ORDER_ITEMS ADD COLUMN TAXABLEVALUE  decimal(15,2);"))
  ;; 2 - Add column - SGSTAMT
  (unless (column-exists-p "DOD_ORDER_ITEMS" "SGSTAMT")
    (clsql:execute-command "ALTER TABLE DOD_ORDER_ITEMS ADD COLUMN SGSTAMT decimal(15,2);"))
  ;; 2 - Add column - CGSTAMT
  (unless (column-exists-p "DOD_ORDER_ITEMS" "CGSTAMT")
    (clsql:execute-command "ALTER TABLE DOD_ORDER_ITEMS ADD COLUMN CGSTAMT decimal(15,2);"))
  ;; 2 - Add column - IGSTAMT
  (unless (column-exists-p "DOD_ORDER_ITEMS" "IGSTAMT")
    (clsql:execute-command "ALTER TABLE DOD_ORDER_ITEMS ADD COLUMN IGSTAMT decimal(15,2);"))
  ;; 2 - Add column - TOTALITEMVAL
  (unless (column-exists-p "DOD_ORDER_ITEMS" "TOTALITEMVAL")
    (clsql:execute-command "ALTER TABLE DOD_ORDER_ITEMS ADD COLUMN TOTALITEMVAL decimal(15,2);")))


(defun migrate-2025May-add-discount-column ()
  ;; Add Current pricing and Current discount columns to dod_prd_master table
  (unless (column-exists-p "DOD_PRD_MASTER" "unit-price")
    (clsql:execute-command "ALTER TABLE DOD_PRD_MASTER DROP COLUMN unit_price;"))
  (unless (column-exists-p "DOD_PRD_MASTER" "current_price")
    (clsql:execute-command
     "ALTER TABLE DOD_PRD_MASTER ADD COLUMN current_price DECIMAL(10, 2);"))
  (unless (column-exists-p "DOD_PRD_MASTER" "current_discount")
    (clsql:execute-command
     "ALTER TABLE DOD_PRD_MASTER ADD COLUMN current_discount DECIMAL(5, 2);")))


(defun migrate-2025May-add-product-code ()
  ;; 1 - Add column
  (unless (column-exists-p "DOD_PRD_MASTER" "PRODUCT_CODE")
    (clsql:execute-command "ALTER TABLE DOD_PRD_MASTER ADD COLUMN PRODUCT_CODE VARCHAR(50);"))
  ;; 2. Update with unique values 
  (clsql:execute-command "UPDATE DOD_PRD_MASTER SET product_code = CONCAT('PRD', LPAD(row_id, 6, '0')) WHERE product_code IS NULL OR product_code = '';")
  ;; 3. Set NOT NULL  
  (clsql:execute-command "ALTER TABLE DOD_PRD_MASTER MODIFY COLUMN PRODUCT_CODE VARCHAR(50) NOT NULL;")
  ;; 4. Add UNIQUE constraint 
  (clsql:execute-command "ALTER TABLE DOD_PRD_MASTER ADD UNIQUE (PRODUCT_CODE);"))



(defun migrate-2025Jun-dod-order-schema ()
  ;; Add missing columns to DOD_ORDER table based on the target schema

  ;; ORDNUM
  (unless (column-exists-p "DOD_ORDER" "ORDNUM")
    (clsql:execute-command
     "ALTER TABLE DOD_ORDER ADD COLUMN ORDNUM VARCHAR(50);"))
  
  ;; CUSTNAME
  (unless (column-exists-p "DOD_ORDER" "CUSTNAME")
    (clsql:execute-command
     "ALTER TABLE DOD_ORDER ADD COLUMN CUSTNAME VARCHAR(255);"))

  ;; IS_CONVERTED_TO_INVOICE
  (unless (column-exists-p "DOD_ORDER" "IS_CONVERTED_TO_INVOICE")
    (clsql:execute-command
     "ALTER TABLE DOD_ORDER ADD COLUMN IS_CONVERTED_TO_INVOICE CHAR(1) DEFAULT 'N';"))

  ;; IS_CANCELLED
  (unless (column-exists-p "DOD_ORDER" "IS_CANCELLED")
    (clsql:execute-command
     "ALTER TABLE DOD_ORDER ADD COLUMN IS_CANCELLED CHAR(1) DEFAULT 'N';"))

  ;; CANCEL_REASON
  (unless (column-exists-p "DOD_ORDER" "CANCEL_REASON")
    (clsql:execute-command
     "ALTER TABLE DOD_ORDER ADD COLUMN CANCEL_REASON TEXT DEFAULT NULL;"))

  ;; ORDER_SOURCE
  (unless (column-exists-p "DOD_ORDER" "ORDER_SOURCE")
    (clsql:execute-command
     "ALTER TABLE DOD_ORDER ADD COLUMN ORDER_SOURCE ENUM('POS', 'ONLINE', 'WHATSAPP', 'API') DEFAULT 'ONLINE';"))

  ;; EXPECTED_DELIVERY_DATE
  (unless (column-exists-p "DOD_ORDER" "EXPECTED_DELIVERY_DATE")
    (clsql:execute-command
     "ALTER TABLE DOD_ORDER ADD COLUMN EXPECTED_DELIVERY_DATE TIMESTAMP DEFAULT NULL;"))
  
  ;; EXTERNAL_URL
  (unless (column-exists-p "DOD_ORDER" "EXTERNAL_URL")
    (clsql:execute-command
     "ALTER TABLE DOD_ORDER ADD COLUMN EXTERNAL_URL VARCHAR(2048) CHARACTER SET utf8 COLLATE utf8_general_ci DEFAULT NULL;"))

  (clsql:execute-command
   "ALTER TABLE DOD_ORDER MODIFY COLUMN ORDER_AMT DECIMAL(15,2) DEFAULT 0.00;")

  ;; TOTAL_DISCOUNT
  (unless (column-exists-p "DOD_ORDER" "TOTAL_DISCOUNT")
    (clsql:execute-command
     "ALTER TABLE DOD_ORDER ADD COLUMN TOTAL_DISCOUNT DECIMAL(15,2) DEFAULT 0.00;"))

    ;; TOTAL_TAX
  (unless (column-exists-p "DOD_ORDER" "TOTAL_TAX")
    (clsql:execute-command
     "ALTER TABLE DOD_ORDER ADD COLUMN TOTAL_TAX DECIMAL(15,2) DEFAULT 0.00;"))

  (clsql:execute-command
   "ALTER TABLE DOD_ORDER MODIFY COLUMN SHIPPING_COST DECIMAL(15,2) DEFAULT 0.00;")

  (unless (column-exists-p "DOD_ORDER" "SHIPADDR")
    (clsql:execute-command
     "ALTER TABLE DOD_ORDER ADD COLUMN SHIPADDR TEXT;"))
  (unless (column-exists-p "DOD_ORDER" "BILLADDR")
    (clsql:execute-command
     "ALTER TABLE DOD_ORDER ADD COLUMN BILLADDR TEXT;"))
  )



  
