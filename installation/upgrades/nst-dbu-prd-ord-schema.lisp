;;; nst-dbu-prd-ord-schema.lisp
;;;
;;; Schema (DDL) migrations for DOD_PRD_MASTER, DOD_ORDER and DOD_ORDER_ITEMS.
;;;
;;; MOVED OUT OF hhub/core/nst-sch-mig.lisp. That file is the migration FRAMEWORK —
;;; the *migrations* registry, apply-migrations, the loader and the schema/ABAC
;;; helpers — and it should hold no migrations of its own. Every migration function
;;; now lives here in installation/upgrades/, which is exactly what
;;; (load-upgrade-files) loads, so the framework no longer has to be trusted to
;;; carry five exceptions.
;;;
;;; Depends on the helpers in nst-sch-mig.lisp (column-exists-p), which is part of
;;; the system and therefore always loaded before apply-migrations runs.

(in-package :nstores)

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
