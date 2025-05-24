;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)

(defun get-applied-migrations ()
  (mapcar #'first
          (clsql:query "SELECT version FROM DOD_SCHEMA_MIGRATIONS ORDER BY row_id ASC" :field-names nil)))

(defun apply-migrations (username password)
  (let ((applied (get-applied-migrations)))
    (crm-db-connect :servername *crm-database-server* :strdb *crm-database-name* :strusr username  :strpwd password :strdbtype :mysql)
    (dolist (migration *migrations*)
      (destructuring-bind (version fn description) migration
        (unless (member version applied :test #'string=)
          (format t "Applying migration ~A...~%" version)
	  (format t "Description: ~A~%" description)
          (funcall fn)
          (clsql:execute-command  (format nil "INSERT INTO DOD_SCHEMA_MIGRATIONS (version) VALUES ('~A');" version))
          (format t "Migration ~A applied.~%" version))))
    (clsql:disconnect)))

(defun column-exists-p (table column)
  (let* ((sql (format nil
                      "SELECT COUNT(*) FROM information_schema.columns
                       WHERE table_schema = DATABASE()
                         AND table_name = '~A'
                         AND column_name = '~A'"
                      table column))
         (result (clsql:query sql :flatp t)))
    (> (first result) 0)))



(defparameter *migrations*
  '(("05082025-add-product-code"  migrate-2025May-add-product-code "Added human readable Product code to DOD_PRD_MASTER table")
    ;; Add more migrations here
    ("09052025-add-price&discount-columns"  migrate-2025May-add-discount-column "Added current price and current discount to DOD_PRD_MASTER table")
   ))


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

