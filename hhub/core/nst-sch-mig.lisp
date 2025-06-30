;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)



(defparameter *migrations*
  '(("05082025-add-product-code"  migrate-2025May-add-product-code "Added human readable Product code to DOD_PRD_MASTER table")
    ;; Add more migrations here
    ("09052025-add-price&discount-columns"  migrate-2025May-add-discount-column "Added current price and current discount to DOD_PRD_MASTER table")
    ("16062025-modify-dod_order-table"  migrate-2025Jun-dod-order-schema "Modify dod_order table add many columns, drop columns, add indexes and foreign keys")
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
  (clsql:execute-command "ALTER TABLE DOD_PRD_MASTER ADD COLUMN PRODUCT_CODE VARCHAR(50);")
  ;; 2. Update with unique values 
  (clsql:execute-command "UPDATE dod_prd_master SET product_code = CONCAT('PRD', LPAD(row_id, 6, '0')) WHERE product_code IS NULL OR product_code = '';")
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



  
