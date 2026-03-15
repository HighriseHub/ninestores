;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)



(defun migrate-2026March-create-delivery-order-table ()
  (flet ((create-table-if-not-exists (table-name ddl)
           (unless (table-exists-p table-name)
             (clsql:execute-command ddl))))
    
    ;; 1. DOD_DELIVERY_ORDER
    (create-table-if-not-exists
     "DOD_DELIVERY_ORDER"
     "CREATE TABLE DOD_DELIVERY_ORDER (
  ROW_ID                mediumint      NOT NULL AUTO_INCREMENT,

  -- Source references
  VENDOR_ORDER_ID       mediumint      NOT NULL,
  CUST_ORDER_ID         mediumint      NOT NULL,
  EWAY_BILL_ID          mediumint      DEFAULT NULL,
  INVOICE_ID            mediumint      DEFAULT NULL,

  -- GST Rule 55 mandatory
  DO_NUMBER             varchar(50)    NOT NULL,
  DO_DATE               date           NOT NULL,
  FINANCIAL_YEAR        varchar(9)     NOT NULL,

  -- GST parties
  SUPPLIER_GSTIN        varchar(15)    NOT NULL,
  SUPPLIER_LEGAL_NAME   varchar(200)   DEFAULT NULL,
  SUPPLIER_STATE_CODE   varchar(2)     NOT NULL,
  RECIPIENT_GSTIN       varchar(15)    DEFAULT NULL,
  RECIPIENT_NAME        varchar(200)   DEFAULT NULL,
  RECIPIENT_STATE_CODE  varchar(2)     NOT NULL,

  -- Supply classification
  REASON_FOR_TRANSPORT  enum(
                          'SUPPLY',
                          'RETURN',
                          'JOBWORK',
                          'CONSIGNMENT',
                          'OTHERS'
                        ) NOT NULL DEFAULT 'SUPPLY',
  SUPPLY_TYPE           enum(
                          'INTRA_STATE',
                          'INTER_STATE'
                        ) NOT NULL,
  PLACE_OF_SUPPLY_CODE  varchar(2)     NOT NULL,

  -- Transport
  TRANSPORTER_NAME      varchar(200)   DEFAULT NULL,
  TRANSPORTER_GSTIN     varchar(15)    DEFAULT NULL,
  VEHICLE_NUMBER        varchar(20)    DEFAULT NULL,
  TRANSPORT_MODE        enum(
                          'ROAD',
                          'RAIL',
                          'AIR',
                          'SHIP'
                        ) DEFAULT 'ROAD',
  DISPATCH_DATE         timestamp      DEFAULT NULL,
  EXPECTED_DELIVERY_DATE date          DEFAULT NULL,

  -- Financial totals
  TOTAL_TAXABLE_VALUE   decimal(15,2)  NOT NULL DEFAULT 0.00,
  TOTAL_CGST            decimal(15,2)  NOT NULL DEFAULT 0.00,
  TOTAL_SGST            decimal(15,2)  NOT NULL DEFAULT 0.00,
  TOTAL_IGST            decimal(15,2)  NOT NULL DEFAULT 0.00,
  TOTAL_CESS            decimal(15,2)  NOT NULL DEFAULT 0.00,
  TOTAL_DO_VALUE        decimal(15,2)  NOT NULL DEFAULT 0.00,

  -- Lifecycle
  STATUS                enum(
                          'DRAFT',
                          'ISSUED',
                          'IN_TRANSIT',
                          'DELIVERED',
                          'CANCELLED'
                        ) NOT NULL DEFAULT 'DRAFT',
  CANCELLED_AT          timestamp      DEFAULT NULL,
  CANCELLATION_REASON   varchar(500)   DEFAULT NULL,

  -- Invoice control
  IS_INVOICED           char(1)        NOT NULL DEFAULT 'N',

  -- Audit
  REMARKS               varchar(500)   DEFAULT NULL,
  CREATED_BY            mediumint      NOT NULL,
  CREATED               timestamp      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UPDATED               timestamp      NOT NULL DEFAULT CURRENT_TIMESTAMP
                                       ON UPDATE CURRENT_TIMESTAMP,
  DELETED_STATE         char(1)        NOT NULL DEFAULT 'N',
  TENANT_ID             mediumint      NOT NULL,

  PRIMARY KEY           (ROW_ID),
  UNIQUE KEY  uk_do_number_fy_tenant   (DO_NUMBER, FINANCIAL_YEAR, TENANT_ID),
  UNIQUE KEY  uk_do_vendor_order       (VENDOR_ORDER_ID, TENANT_ID),
  INDEX       idx_do_cust_order        (CUST_ORDER_ID),
  INDEX       idx_do_eway_bill         (EWAY_BILL_ID),
  INDEX       idx_do_invoice           (INVOICE_ID),
  INDEX       idx_do_status            (STATUS),
  INDEX       idx_do_tenant            (TENANT_ID),
  INDEX       idx_do_date              (DO_DATE)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;")))

(defun migrate-2026March-create-delivery-items-table ()
  (flet ((create-table-if-not-exists (table-name ddl)
           (unless (table-exists-p table-name)
             (clsql:execute-command ddl))))
    
    ;; 1. DOD_DELIVERY_ORDER
    (create-table-if-not-exists
     "DOD_DELIVERY_ITEMS"
     "CREATE TABLE DOD_DELIVERY_ITEMS (
  ROW_ID              mediumint      NOT NULL AUTO_INCREMENT,

  -- Parent references
  DO_ID               mediumint      NOT NULL,
  ORDER_ITEM_ID       mediumint      NOT NULL,
  PRODUCT_ID          mediumint      NOT NULL,

  -- GST Rule 55 mandatory at line level
  HSN_CODE            varchar(10)    NOT NULL,
  PRODUCT_DESCRIPTION varchar(500)   NOT NULL,
  UOM                 varchar(10)    NOT NULL DEFAULT 'NOS',

  -- Quantities
  ORDERED_QTY         decimal(10,3)  NOT NULL,
  ISSUED_QTY          decimal(10,3)  NOT NULL,

  -- Pricing and GST
  UNIT_PRICE          decimal(15,2)  NOT NULL,
  DISCOUNT_AMT        decimal(15,2)  NOT NULL DEFAULT 0.00,
  TAXABLE_VALUE       decimal(15,2)  NOT NULL,
  CGST_RATE           decimal(5,2)   NOT NULL DEFAULT 0.00,
  SGST_RATE           decimal(5,2)   NOT NULL DEFAULT 0.00,
  IGST_RATE           decimal(5,2)   NOT NULL DEFAULT 0.00,
  CESS_RATE           decimal(5,2)   NOT NULL DEFAULT 0.00,
  CGST_AMT            decimal(15,2)  NOT NULL DEFAULT 0.00,
  SGST_AMT            decimal(15,2)  NOT NULL DEFAULT 0.00,
  IGST_AMT            decimal(15,2)  NOT NULL DEFAULT 0.00,
  CESS_AMT            decimal(15,2)  NOT NULL DEFAULT 0.00,
  LINE_TOTAL          decimal(15,2)  NOT NULL,

  -- Batch/lot (optional but useful for FMCG/pharma tenants)
  BATCH_LOT_ID        mediumint      DEFAULT NULL,
  BATCH_NUMBER        varchar(50)    DEFAULT NULL,
  EXPIRY_DATE         date           DEFAULT NULL,

  TENANT_ID           mediumint      NOT NULL,

  PRIMARY KEY         (ROW_ID),
  INDEX idx_di_do           (DO_ID),
  INDEX idx_di_order_item   (ORDER_ITEM_ID),
  INDEX idx_di_product      (PRODUCT_ID),
  INDEX idx_di_tenant       (TENANT_ID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;")))
  
(defun migrate-2026March-create-goods-receipt-note-table ()
  (flet ((create-table-if-not-exists (table-name ddl)
           (unless (table-exists-p table-name)
             (clsql:execute-command ddl))))
    
    ;; 1. DOD_DELIVERY_ORDER
    (create-table-if-not-exists
     "DOD_GOODS_RECEIPT_NOTE_HEADER"
     "CREATE TABLE DOD_GOODS_RECEIPT_NOTE_HEADER (
  ROW_ID                mediumint      NOT NULL AUTO_INCREMENT,

  -- Source references
  DO_ID                 mediumint      NOT NULL,
  VENDOR_ORDER_ID       mediumint      NOT NULL,
  CUST_ORDER_ID         mediumint      NOT NULL,

  -- GRN identity
  GRN_NUMBER            varchar(50)    NOT NULL,
  GRN_DATE              date           NOT NULL,
  FINANCIAL_YEAR        varchar(9)     NOT NULL,

  -- Receipt classification
  RECEIPT_TYPE          enum(
                          'FULL',
                          'PARTIAL',
                          'REJECTED'
                        ) NOT NULL DEFAULT 'FULL',

  -- Receiver details
  RECEIVED_BY           mediumint      NOT NULL,
  RECEIVED_BY_NAME      varchar(200)   NOT NULL,
  RECEIPT_WAREHOUSE_ID  mediumint      DEFAULT NULL,

  -- Three-way match result
  MATCH_STATUS          enum(
                          'PENDING',
                          'MATCHED',
                          'QUANTITY_MISMATCH',
                          'QUALITY_REJECTED',
                          'PRICE_MISMATCH',
                          'CONTRADICTION'
                        ) NOT NULL DEFAULT 'PENDING',
  MATCH_NOTES           varchar(500)   DEFAULT NULL,

  -- Financial summary
  TOTAL_ORDERED_VALUE   decimal(15,2)  NOT NULL DEFAULT 0.00,
  TOTAL_ACCEPTED_VALUE  decimal(15,2)  NOT NULL DEFAULT 0.00,
  TOTAL_REJECTED_VALUE  decimal(15,2)  NOT NULL DEFAULT 0.00,

  -- Debit note flag (raised when accepted < ordered)
  DEBIT_NOTE_REQUIRED   char(1)        NOT NULL DEFAULT 'N',
  DEBIT_NOTE_ID         mediumint      DEFAULT NULL,

  -- Invoice approval gate
  INVOICE_APPROVED      char(1)        NOT NULL DEFAULT 'N',
  INVOICE_APPROVED_BY   mediumint      DEFAULT NULL,
  INVOICE_APPROVED_AT   timestamp      DEFAULT NULL,
  INVOICE_ID            mediumint      DEFAULT NULL,

  -- Audit
  REMARKS               varchar(500)   DEFAULT NULL,
  CREATED               timestamp      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UPDATED               timestamp      NOT NULL DEFAULT CURRENT_TIMESTAMP
                                       ON UPDATE CURRENT_TIMESTAMP,
  DELETED_STATE         char(1)        NOT NULL DEFAULT 'N',
  TENANT_ID             mediumint      NOT NULL,

  PRIMARY KEY           (ROW_ID),
  UNIQUE KEY  uk_grn_number_fy_tenant  (GRN_NUMBER, FINANCIAL_YEAR, TENANT_ID),
  UNIQUE KEY  uk_grn_do                (DO_ID, TENANT_ID),
  INDEX       idx_grn_vendor_order     (VENDOR_ORDER_ID),
  INDEX       idx_grn_cust_order       (CUST_ORDER_ID),
  INDEX       idx_grn_match_status     (MATCH_STATUS),
  INDEX       idx_grn_invoice          (INVOICE_ID),
  INDEX       idx_grn_tenant           (TENANT_ID),
  INDEX       idx_grn_date             (GRN_DATE)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;")))
  
(defun migrate-2026March-create-goods-receipt-note-items-table ()
  (flet ((create-table-if-not-exists (table-name ddl)
           (unless (table-exists-p table-name)
             (clsql:execute-command ddl))))
    
    ;; 1. DOD_DELIVERY_ORDER
    (create-table-if-not-exists
     "DOD_GOODS_RECEIPT_NOTE_ITEMS"
     "CREATE TABLE DOD_GOODS_RECEIPT_NOTE_ITEMS (
  ROW_ID                mediumint      NOT NULL AUTO_INCREMENT,

  -- Parent references
  GRN_ID                mediumint      NOT NULL,
  DO_ITEM_ID            mediumint      NOT NULL,
  ORDER_ITEM_ID         mediumint      NOT NULL,
  PRODUCT_ID            mediumint      NOT NULL,
  HSN_CODE              varchar(10)    NOT NULL,

  -- Quantity reconciliation (core of three-way match)
  ORDERED_QTY           decimal(10,3)  NOT NULL,
  DELIVERED_QTY         decimal(10,3)  NOT NULL,
  ACCEPTED_QTY          decimal(10,3)  NOT NULL,
  REJECTED_QTY          decimal(10,3)  NOT NULL DEFAULT 0.000,
  SHORTAGE_QTY          decimal(10,3)  NOT NULL DEFAULT 0.000,

  -- Rejection detail
  REJECTION_REASON      enum(
                          'QUALITY',
                          'DAMAGED',
                          'WRONG_ITEM',
                          'EXCESS_QTY',
                          'EXPIRED',
                          'OTHERS'
                        ) DEFAULT NULL,
  REJECTION_NOTES       varchar(500)   DEFAULT NULL,

  -- Line match status (maps to Belnap directly)
  LINE_MATCH_STATUS     enum(
                          'MATCHED',        -- :T  ordered=delivered=accepted
                          'SHORT',          -- :F  accepted < delivered
                          'REJECTED',       -- :F  accepted = 0
                          'EXCESS',         -- :C  accepted > ordered
                          'UNKNOWN'         -- :U  not yet confirmed
                        ) NOT NULL DEFAULT 'UNKNOWN',

  -- Value impact
  UNIT_PRICE            decimal(15,2)  NOT NULL,
  ACCEPTED_VALUE        decimal(15,2)  NOT NULL DEFAULT 0.00,
  REJECTED_VALUE        decimal(15,2)  NOT NULL DEFAULT 0.00,

  -- Batch tracking
  BATCH_LOT_ID          mediumint      DEFAULT NULL,
  BATCH_NUMBER          varchar(50)    DEFAULT NULL,
  EXPIRY_DATE           date           DEFAULT NULL,

  TENANT_ID             mediumint      NOT NULL,

  PRIMARY KEY           (ROW_ID),
  INDEX idx_grni_grn          (GRN_ID),
  INDEX idx_grni_do_item      (DO_ITEM_ID),
  INDEX idx_grni_order_item   (ORDER_ITEM_ID),
  INDEX idx_grni_product      (PRODUCT_ID),
  INDEX idx_grni_tenant       (TENANT_ID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;")))


;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)

(defun migrate-2026March-add-constraints-to-delivery-items-and-goods-receipt ()
  (handler-case
      (progn
        (clsql:execute-command
          "ALTER TABLE DOD_DELIVERY_ITEMS
           ADD CONSTRAINT fk_di_do
           FOREIGN KEY (DO_ID) REFERENCES DOD_DELIVERY_ORDER (ROW_ID)")

        (clsql:execute-command
          "ALTER TABLE DOD_GOODS_RECEIPT_NOTE_HEADER
           ADD CONSTRAINT fk_grn_do
           FOREIGN KEY (DO_ID) REFERENCES DOD_DELIVERY_ORDER (ROW_ID)")

        (clsql:execute-command
          "ALTER TABLE DOD_GOODS_RECEIPT_NOTE_ITEMS
           ADD CONSTRAINT fk_grni_grn
           FOREIGN KEY (GRN_ID) REFERENCES DOD_GOODS_RECEIPT_NOTE_HEADER (ROW_ID)")

        (clsql:execute-command
          "ALTER TABLE DOD_GOODS_RECEIPT_NOTE_ITEMS
           ADD CONSTRAINT fk_grni_do_item
           FOREIGN KEY (DO_ITEM_ID) REFERENCES DOD_DELIVERY_ITEMS (ROW_ID)")

        (format t "~%Migration complete: all FK constraints added successfully."))

    (clsql:sql-database-error (e)
      (format t "~%Migration error: ~A" e))))


(defun migrate-2026Jan-update-customer-table ()
  "Update the customer table to support a B2B organization"
  (unless (column-exists-p "DOD_CUST_PROFILE" "COMPANY_NAME")
    (clsql:execute-command "ALTER TABLE DOD_CUST_PROFILE  ADD COLUMN COMPANY_NAME VARCHAR(255) COMMENT 'Legal/trading company name';"))
  (unless (column-exists-p "DOD_CUST_PROFILE" "LEGAL_NAME")
    (clsql:execute-command "ALTER TABLE DOD_CUST_PROFILE  ADD COLUMN LEGAL_NAME VARCHAR(255) COMMENT 'Legal registered name (if different)';"))
  (unless (column-exists-p "DOD_CUST_PROFILE" "GSTIN")
    (clsql:execute-command "ALTER TABLE DOD_CUST_PROFILE ADD COLUMN GSTIN VARCHAR(15) COMMENT 'GST Identification Number';"))
  (unless (column-exists-p "DOD_CUST_PROFILE" "PAN_NUMBER")
    (clsql:execute-command "ALTER TABLE DOD_CUST_PROFILE ADD COLUMN PAN_NUMBER VARCHAR(10) COMMENT 'PAN (if no GSTIN or for proprietor)';"))
  (unless (column-exists-p "DOD_CUST_PROFILE" "BUSINESS_TYPE")
    (clsql:execute-command "ALTER TABLE DOD_CUST_PROFILE ADD COLUMN BUSINESS_TYPE ENUM('MANUFACTURER', 'WHOLESALER', 'RETAILER', 'RESTAURANT', 'OFFICE', 'CONSTRUCTION','SERVICES', 'INDIVIDUAL', 'OTHER') DEFAULT 'INDIVIDUAL' COMMENT 'Type of buyer';"))
  (unless (column-exists-p "DOD_CUST_PROFILE" "ORGANIZATION_TYPE")
    (clsql:execute-command "ALTER TABLE DOD_CUST_PROFILE ADD COLUMN ORGANIZATION_TYPE ENUM('COMPANY', 'PARTNERSHIP', 'PROPRIETORSHIP', 'LLP', 'TRUST', 'SOCIETY', 'INDIVIDUAL')  DEFAULT 'INDIVIDUAL';"))
  (unless (column-exists-p "DOD_CUST_PROFILE" "GST_REGISTRATION_TYPE")
    (clsql:execute-command "ALTER TABLE DOD_CUST_PROFILE ADD COLUMN GST_REGISTRATION_TYPE ENUM('REGULAR', 'COMPOSITION', 'UNREGISTERED', 'SEZ') DEFAULT 'UNREGISTERED';"))
  (unless (column-exists-p "DOD_CUST_PROFILE" "TAN_NUMBER")
    (clsql:execute-command "ALTER TABLE DOD_CUST_PROFILE ADD COLUMN TAN_NUMBER VARCHAR(10) COMMENT 'Tax Deduction Account Number';"))
  (unless (column-exists-p "DOD_CUST_PROFILE" "MSME_NUMBER")
    (clsql:execute-command "ALTER TABLE DOD_CUST_PROFILE ADD COLUMN MSME_NUMBER VARCHAR(50) COMMENT 'MSME/Udyam registration';"))
  (unless (column-exists-p "DOD_CUST_PROFILE" "IS_TAX_EXEMPT")
    (clsql:execute-command "ALTER TABLE DOD_CUST_PROFILE ADD COLUMN IS_TAX_EXEMPT CHAR(1) DEFAULT 'N';"))
  (unless (column-exists-p "DOD_CUST_PROFILE" "TAX_EXEMPTION_CERT")
    (clsql:execute-command "ALTER TABLE DOD_CUST_PROFILE ADD COLUMN TAX_EXEMPTION_CERT VARCHAR(100) COMMENT 'Certificate number';"))
  (unless (column-exists-p "DOD_CUST_PROFILE" "BUSINESS_ESTABLISHED_DATE")
    (clsql:execute-command "ALTER TABLE DOD_CUST_PROFILE ADD COLUMN BUSINESS_ESTABLISHED_DATE DATE COMMENT 'When business started';"))
  (unless (column-exists-p "DOD_CUST_PROFILE" "ANNUAL_TURNOVER")
    (clsql:execute-command "ALTER TABLE DOD_CUST_PROFILE ADD COLUMN ANNUAL_TURNOVER DECIMAL(15,2) COMMENT 'Approximate annual revenue';"))
  (unless (column-exists-p "DOD_CUST_PROFILE" "EMPLOYEE_COUNT")
    (clsql:execute-command "ALTER TABLE DOD_CUST_PROFILE ADD COLUMN EMPLOYEE_COUNT INT COMMENT 'Number of employees';"))
  (unless (column-exists-p "DOD_CUST_PROFILE" "INDUSTRY")
    (clsql:execute-command "ALTER TABLE DOD_CUST_PROFILE ADD COLUMN INDUSTRY VARCHAR(100) COMMENT 'Industry/sector';"))
  (unless (column-exists-p "DOD_CUST_PROFILE" "CREDIT_LIMIT")
    (clsql:execute-command "ALTER TABLE DOD_CUST_PROFILE ADD COLUMN CREDIT_LIMIT DECIMAL(15,2) DEFAULT 0 COMMENT 'Maximum credit allowed';"))
  (unless (column-exists-p "DOD_CUST_PROFILE" "PAYMENT_TERMS")
    (clsql:execute-command "ALTER TABLE DOD_CUST_PROFILE ADD COLUMN PAYMENT_TERMS VARCHAR(50) DEFAULT 'PREPAID' COMMENT 'PREPAID, COD, NET7, NET15, NET30, NET60';"))
  (unless (column-exists-p "DOD_CUST_PROFILE" "CREDIT_DAYS")
    (clsql:execute-command "ALTER TABLE DOD_CUST_PROFILE ADD COLUMN CREDIT_DAYS INT DEFAULT 0 COMMENT 'Payment due in days';"))
  (unless (column-exists-p "DOD_CUST_PROFILE" "PRIMARY_CONTACT_NAME")
    (clsql:execute-command "ALTER TABLE DOD_CUST_PROFILE ADD COLUMN PRIMARY_CONTACT_NAME VARCHAR(255) COMMENT 'Main contact person name';"))
  (unless (column-exists-p "DOD_CUST_PROFILE" "PRIMARY_CONTACT_PHONE")
    (clsql:execute-command "ALTER TABLE DOD_CUST_PROFILE ADD COLUMN PRIMARY_CONTACT_PHONE VARCHAR(30) COMMENT 'Contact person phone';"))
  (unless (column-exists-p "DOD_CUST_PROFILE" "PRIMARY_CONTACT_EMAIL")
    (clsql:execute-command "ALTER TABLE DOD_CUST_PROFILE ADD COLUMN PRIMARY_CONTACT_EMAIL VARCHAR(255) COMMENT 'Contact person email';"))
  (unless (column-exists-p "DOD_CUST_PROFILE" "PRIMARY_CONTACT_DESIGNATION")
    (clsql:execute-command "ALTER TABLE DOD_CUST_PROFILE ADD COLUMN PRIMARY_CONTACT_DESIGNATION VARCHAR(100) COMMENT 'Job title';"))
  (unless (column-exists-p "DOD_CUST_PROFILE" "ACCOUNTS_CONTACT_NAME")
    (clsql:execute-command "ALTER TABLE DOD_CUST_PROFILE ADD COLUMN ACCOUNTS_CONTACT_NAME VARCHAR(255);"))
  (unless (column-exists-p "DOD_CUST_PROFILE" "ACCOUNTS_CONTACT_PHONE")
    (clsql:execute-command "ALTER TABLE DOD_CUST_PROFILE ADD COLUMN ACCOUNTS_CONTACT_PHONE VARCHAR(30);"))
  (unless (column-exists-p "DOD_CUST_PROFILE" "ACCOUNTS_CONTACT_EMAIL")
    (clsql:execute-command "ALTER TABLE DOD_CUST_PROFILE ADD COLUMN ACCOUNTS_CONTACT_EMAIL VARCHAR(255);"))
  (unless (column-exists-p "DOD_CUST_PROFILE" "BANK_ACCOUNT_NUMBER")
    (clsql:execute-command "ALTER TABLE DOD_CUST_PROFILE ADD COLUMN BANK_ACCOUNT_NUMBER VARCHAR(30);"))
  (unless (column-exists-p "DOD_CUST_PROFILE" "BANK_IFSC_CODE")
    (clsql:execute-command "ALTER TABLE DOD_CUST_PROFILE ADD COLUMN BANK_IFSC_CODE VARCHAR(11);"))
  (unless (column-exists-p "DOD_CUST_PROFILE" "BANK_NAME")
    (clsql:execute-command "ALTER TABLE DOD_CUST_PROFILE ADD COLUMN BANK_NAME VARCHAR(100);"))
  (unless (column-exists-p "DOD_CUST_PROFILE" "BANK_BRANCH")
    (clsql:execute-command "ALTER TABLE DOD_CUST_PROFILE ADD COLUMN BANK_BRANCH VARCHAR(100);"))
  (unless (column-exists-p "DOD_CUST_PROFILE" "BANK_ACCOUNT_HOLDER_NAME")
    (clsql:execute-command "ALTER TABLE DOD_CUST_PROFILE ADD COLUMN BANK_ACCOUNT_HOLDER_NAME VARCHAR(255);"))
  (unless (column-exists-p "DOD_CUST_PROFILE" "REGISTERED_ADDRESS")
    (clsql:execute-command "ALTER TABLE DOD_CUST_PROFILE ADD COLUMN REGISTERED_ADDRESS TEXT COMMENT 'Official registered address';"))
  (unless (column-exists-p "DOD_CUST_PROFILE" "BILLING_ADDRESS")
    (clsql:execute-command "ALTER TABLE DOD_CUST_PROFILE ADD COLUMN BILLING_ADDRESS TEXT COMMENT 'Billing address if different';"))
  (unless (column-exists-p "DOD_CUST_PROFILE" "SHIPPING_ADDRESS")
    (clsql:execute-command "ALTER TABLE DOD_CUST_PROFILE ADD COLUMN SHIPPING_ADDRESS TEXT COMMENT 'Default shipping address';"))
  (unless (column-exists-p "DOD_CUST_PROFILE" "REGISTERED_STATE")
    (clsql:execute-command "ALTER TABLE DOD_CUST_PROFILE ADD COLUMN REGISTERED_STATE VARCHAR(256);"))
  (unless (column-exists-p "DOD_CUST_PROFILE" "REGISTERED_CITY")
    (clsql:execute-command "ALTER TABLE DOD_CUST_PROFILE ADD COLUMN REGISTERED_CITY VARCHAR(256);"))
  (unless (column-exists-p "DOD_CUST_PROFILE" "REGISTERED_ZIPCODE")
    (clsql:execute-command "ALTER TABLE DOD_CUST_PROFILE ADD COLUMN REGISTERED_ZIPCODE VARCHAR(10);"))
  (unless (column-exists-p "DOD_CUST_PROFILE" "KYC_STATUS")
    (clsql:execute-command "ALTER TABLE DOD_CUST_PROFILE ADD COLUMN KYC_STATUS ENUM('PENDING', 'VERIFIED', 'REJECTED') DEFAULT 'PENDING';"))
  (unless (column-exists-p "DOD_CUST_PROFILE" "KYC_VERIFIED_DATE")
    (clsql:execute-command "ALTER TABLE DOD_CUST_PROFILE ADD COLUMN KYC_VERIFIED_DATE TIMESTAMP NULL;"))
  (unless (column-exists-p "DOD_CUST_PROFILE" "KYC_VERIFIED_BY")
    (clsql:execute-command "ALTER TABLE DOD_CUST_PROFILE ADD COLUMN KYC_VERIFIED_BY MEDIUMINT COMMENT 'Admin user who verified';"))
  (unless (column-exists-p "DOD_CUST_PROFILE" "KYC_DOCUMENTS")
    (clsql:execute-command "ALTER TABLE DOD_CUST_PROFILE ADD COLUMN KYC_DOCUMENTS TEXT COMMENT 'JSON array of uploaded doc paths';"))
  (unless (column-exists-p "DOD_CUST_PROFILE" "BLACKLISTED_VENDORS")
    (clsql:execute-command "ALTER TABLE DOD_CUST_PROFILE ADD COLUMN BLACKLISTED_VENDORS TEXT COMMENT 'Vendors buyer wont buy from';"))
  (unless (column-exists-p "DOD_CUST_PROFILE" "LAST_ORDER_DATE")
    (clsql:execute-command "ALTER TABLE DOD_CUST_PROFILE ADD COLUMN LAST_ORDER_DATE TIMESTAMP NULL;"))
  (unless (column-exists-p "DOD_CUST_PROFILE" "TOTAL_ORDERS")
    (clsql:execute-command "ALTER TABLE DOD_CUST_PROFILE ADD COLUMN TOTAL_ORDERS INT DEFAULT 0;"))
  (unless (column-exists-p "DOD_CUST_PROFILE" "TOTAL_SPENT")
    (clsql:execute-command "ALTER TABLE DOD_CUST_PROFILE ADD COLUMN TOTAL_SPENT DECIMAL(15,2) DEFAULT 0;"))
  (unless (column-exists-p "DOD_CUST_PROFILE" "LOYALTY_POINTS")
    (clsql:execute-command "ALTER TABLE DOD_CUST_PROFILE ADD COLUMN LOYALTY_POINTS INT DEFAULT 0;"))
  (unless (index-exists-p "DOD_CUST_PROFILE" "idx_gstin")
    (clsql:execute-command "ALTER TABLE DOD_CUST_PROFILE ADD INDEX idx_gstin (GSTIN);"))
  (unless (index-exists-p "DOD_CUST_PROFILE" "idx_gstin")
    (clsql:execute-command "ALTER TABLE DOD_CUST_PROFILE ADD INDEX idx_gstin (GSTIN);"))
  (unless (index-exists-p "DOD_CUST_PROFILE" "idx_pan")
    (clsql:execute-command "ALTER TABLE DOD_CUST_PROFILE ADD INDEX idx_pan (PAN_NUMBER);"))
  (unless (index-exists-p "DOD_CUST_PROFILE" "idx_company_name")
      (clsql:execute-command "ALTER TABLE DOD_CUST_PROFILE ADD INDEX idx_company_name (COMPANY_NAME);"))
  (unless (index-exists-p "DOD_CUST_PROFILE" "idx_business_type")
    (clsql:execute-command "ALTER TABLE DOD_CUST_PROFILE ADD INDEX idx_business_type (BUSINESS_TYPE);"))
  (unless (index-exists-p "DOD_CUST_PROFILE" "idx_kyc_status")
    (clsql:execute-command "ALTER TABLE DOD_CUST_PROFILE ADD INDEX idx_kyc_status (KYC_STATUS);")))
  

(defun migrate-2026Jan-create-gstupgrade-tables ()
  "Create GST upgrade GSTR1 export table."
  ;; Helper macro to check and create table
  (flet ((create-table-if-not-exists (table-name ddl)
           (unless (table-exists-p table-name)
             (clsql:execute-command ddl))))

    ;; 1. DOD_ORGANIZATIONS
    (create-table-if-not-exists
     "DOD_GSTR1_EXPORTS"
     "CREATE TABLE DOD_GSTR1_EXPORTS (
    ROW_ID MEDIUMINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    VENDOR_ID MEDIUMINT NOT NULL,
    
    -- Period
    TAX_PERIOD VARCHAR(6) NOT NULL COMMENT 'MMYYYY format: 012026 for Jan 2026',
    FIN_YEAR VARCHAR(9) NOT NULL COMMENT '2025-26',
    
    -- Generation details
    GENERATED_AT TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    GENERATED_BY MEDIUMINT COMMENT 'User who generated',
    
    -- Invoice selection
    TOTAL_INVOICES INT COMMENT 'How many invoices included',
    INVOICE_IDS TEXT COMMENT 'Comma-separated invoice IDs included',
    
    -- Summary stats (for quick preview)
    TOTAL_B2B_INVOICES INT DEFAULT 0,
    TOTAL_B2C_LARGE_INVOICES INT DEFAULT 0,
    TOTAL_B2C_SMALL_INVOICES INT DEFAULT 0,
    TOTAL_TAXABLE_VALUE DECIMAL(15,2) DEFAULT 0,
    TOTAL_TAX_AMOUNT DECIMAL(15,2) DEFAULT 0,
    
    -- JSON storage
    JSON_DATA LONGTEXT COMMENT 'Generated GSTR-1 JSON',
    JSON_FILE_PATH VARCHAR(500) COMMENT 'S3 or filesystem path if stored externally',
    
    -- Upload tracking
    UPLOADED_TO_GSTN CHAR(1) DEFAULT 'N',
    UPLOAD_DATE TIMESTAMP NULL,
    ARN VARCHAR(50) COMMENT 'Acknowledgement Reference Number from GSTN',
    
    -- Status
    STATUS VARCHAR(20) DEFAULT 'GENERATED' COMMENT 'GENERATED, DOWNLOADED, UPLOADED, FILED',
    
    -- Metadata
    TENANT_ID MEDIUMINT NOT NULL,
    DELETED_STATE CHAR(1) DEFAULT 'N',
    
    INDEX idx_vendor_period (VENDOR_ID, TAX_PERIOD),
    INDEX idx_status (STATUS),
    INDEX idx_tenant (TENANT_ID),
    
    FOREIGN KEY (VENDOR_ID) REFERENCES DOD_VEND_PROFILE(ROW_ID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='GSTR-1 export history and JSON storage';")

    (create-table-if-not-exists
     "DOD_INVOICE_GSTR1_TRACKING"
     "CREATE TABLE DOD_INVOICE_GSTR1_TRACKING (
    ROW_ID MEDIUMINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    INVOICE_ID MEDIUMINT NOT NULL,
    VENDOR_ID MEDIUMINT NOT NULL,
    
    -- Inclusion flags
    INCLUDE_IN_GSTR1 CHAR(1) DEFAULT 'Y' COMMENT 'Y/N - vendor can exclude',
    EXCLUSION_REASON VARCHAR(255) COMMENT 'Why excluded if N',
    
    -- Last included in which GSTR-1
    LAST_GSTR1_EXPORT_ID MEDIUMINT COMMENT 'FK to DOD_GSTR1_EXPORTS',
    LAST_INCLUDED_PERIOD VARCHAR(6) COMMENT 'Which period was it last included',
    
    -- Validation status
    VALIDATION_STATUS VARCHAR(20) DEFAULT 'PENDING' COMMENT 'VALID, INVALID, WARNING',
    VALIDATION_ERRORS TEXT COMMENT 'JSON array of validation errors',
    
    -- Metadata
    CREATED TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UPDATED TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    TENANT_ID MEDIUMINT NOT NULL,
    
    UNIQUE KEY uk_invoice (INVOICE_ID),
    INDEX idx_vendor (VENDOR_ID),
    INDEX idx_include (INCLUDE_IN_GSTR1),
    
    FOREIGN KEY (INVOICE_ID) REFERENCES DOD_INVOICE_HEADER(ROW_ID),
    FOREIGN KEY (VENDOR_ID) REFERENCES DOD_VEND_PROFILE(ROW_ID)
) ENGINE=InnoDB;")

    (unless (column-exists-p "DOD_VEND_PROFILE" "LEGAL_NAME")
      (clsql:execute-command "ALTER TABLE DOD_VEND_PROFILE ADD COLUMN  LEGAL_NAME VARCHAR(255) COMMENT 'Legal name as per GSTIN';"))

    (unless (column-exists-p "DOD_VEND_PROFILE" "TRADE_NAME")
      (clsql:execute-command "ALTER TABLE DOD_VEND_PROFILE ADD COLUMN  TRADE_NAME VARCHAR(255) COMMENT 'Trade name if different';"))
    (unless (column-exists-p "DOD_VEND_PROFILE" "PAN_NUMBER")
      (clsql:execute-command "ALTER TABLE DOD_VEND_PROFILE ADD COLUMN  PAN_NUMBER VARCHAR(10) COMMENT 'PAN from GSTIN';"))
    (unless (column-exists-p "DOD_VEND_PROFILE" "GST_STATE_CODE")
      (clsql:execute-command "ALTER TABLE DOD_VEND_PROFILE ADD COLUMN  GST_STATE_CODE VARCHAR(2) COMMENT 'State code from GSTIN';"))
    (unless (column-exists-p "DOD_VEND_PROFILE" "GST_REGISTRATION_TYPE")
      (clsql:execute-command "ALTER TABLE DOD_VEND_PROFILE ADD COLUMN  GST_REGISTRATION_TYPE VARCHAR(20) DEFAULT 'REGULAR' COMMENT 'REGULAR, COMPOSITION, SEZ, etc.';"))
    (unless (column-exists-p "DOD_VEND_PROFILE" "GST_FILING_FREQUENCY")
      (clsql:execute-command "ALTER TABLE DOD_VEND_PROFILE ADD COLUMN  GST_FILING_FREQUENCY VARCHAR(10) DEFAULT 'MONTHLY' COMMENT 'MONTHLY or QUARTERLY';"))
    (unless (column-exists-p "DOD_VEND_PROFILE" "FY_START_MONTH")
      (clsql:execute-command "ALTER TABLE DOD_VEND_PROFILE ADD COLUMN  FY_START_MONTH TINYINT DEFAULT 4 COMMENT 'Financial year start month (4=April)';"))


    (unless (column-exists-p "DOD_CUST_PROFILE" "LEGAL_COMPANY_NAME")
      (clsql:execute-command "ALTER TABLE DOD_CUST_PROFILE ADD COLUMN  LEGAL_COMPANY_NAME VARCHAR(255) COMMENT 'Legal company name';"))
    (unless (column-exists-p "DOD_CUST_PROFILE" "GST_CUSTOMER_TYPE")
      (clsql:execute-command "ALTER TABLE DOD_CUST_PROFILE ADD COLUMN  GST_CUSTOMER_TYPE VARCHAR(20) DEFAULT 'B2C' COMMENT 'B2B, B2C, EXPORT, SEZ';"))

    (unless (column-exists-p "DOD_CUST_PROFILE" "GSTIN")
      (clsql:execute-command "ALTER TABLE DOD_CUST_PROFILE ADD COLUMN  GSTIN VARCHAR(15) COMMENT 'Customer GSTIN for B2B';"))

    )) 




(defun migrate-2026Feb-create-buyer-vendor-account-table ()
  "Create customer vendor table to track the money transfer from customer to vendor."
  ;; Helper macro to check and create table
  (flet ((create-table-if-not-exists (table-name ddl)
           (unless (table-exists-p table-name)
             (clsql:execute-command ddl))))

    (create-table-if-not-exists
     "DOD_BUYER_VENDOR_ACCOUNT"
     "
-- This replaces/enhances the concept of DOD_CUST_WALLET
-- Focuses on B2B relationship, credit terms, and compliance tracking
CREATE TABLE DOD_BUYER_VENDOR_ACCOUNT (
    ROW_ID MEDIUMINT PRIMARY KEY AUTO_INCREMENT,
    
    -- Relationship
    CUST_ID MEDIUMINT NOT NULL,
    VENDOR_ID MEDIUMINT NOT NULL,
    
    -- Account Status
    ACCOUNT_STATUS ENUM('ACTIVE', 'SUSPENDED', 'CLOSED') DEFAULT 'ACTIVE',
    
    -- GST Verification (CRITICAL for compliance)
    VENDOR_GSTIN VARCHAR(15) NOT NULL,
    VENDOR_GSTIN_VERIFIED BOOLEAN DEFAULT FALSE,
    GSTIN_VERIFIED_AT TIMESTAMP NULL,
    VENDOR_LEGAL_NAME VARCHAR(200),
    VENDOR_STATE_CODE VARCHAR(2),
    GSTIN_STATUS ENUM('ACTIVE', 'CANCELLED', 'SUSPENDED') DEFAULT 'ACTIVE',
    
    -- Credit Terms
    CREDIT_LIMIT DECIMAL(15,2) DEFAULT 0,
    CREDIT_DAYS INT DEFAULT 0,
    
    -- Running Balances (Computed)
    CURRENT_ADVANCE_BALANCE DECIMAL(15,2) DEFAULT 0,
    CURRENT_OUTSTANDING DECIMAL(15,2) DEFAULT 0,
    
    -- Compliance Tracking (THE VALUE!)
    LAST_GSTR1_FILED_PERIOD VARCHAR(7) COMMENT 'YYYY-MM',
    GSTR1_FILING_RELIABILITY_SCORE DECIMAL(5,2) COMMENT '0-100 score',
    ITC_MATCH_RATE DECIMAL(5,2) COMMENT '% of invoices matched in GSTR-2B',
    TOTAL_ITC_AT_RISK DECIMAL(15,2) COMMENT 'ITC stuck due to vendor non-filing',
    
    -- Statistics
    TOTAL_TRANSACTIONS DECIMAL(15,2) DEFAULT 0,
    TOTAL_INVOICES_COUNT INT DEFAULT 0,
    AVG_PAYMENT_DELAY_DAYS INT,
    
    -- Preferences
    AUTO_APPROVE_INVOICES BOOLEAN DEFAULT FALSE,
    ALERT_ON_GSTR1_DELAY BOOLEAN DEFAULT TRUE,
    ALERT_ON_ITC_MISMATCH BOOLEAN DEFAULT TRUE,
    
    -- Metadata
    CREATED TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CREATED_BY MEDIUMINT,
    UPDATED TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    DELETED_STATE CHAR(1) DEFAULT 'N',
    TENANT_ID MEDIUMINT NOT NULL,
    
    UNIQUE KEY uk_cust_vendor (CUST_ID, VENDOR_ID, TENANT_ID),
    INDEX idx_gstin (VENDOR_GSTIN),
    INDEX idx_status (ACCOUNT_STATUS),
    
    CONSTRAINT fk_account_cust FOREIGN KEY (CUST_ID) 
        REFERENCES DOD_CUST_PROFILE(ROW_ID),
    CONSTRAINT fk_account_vendor FOREIGN KEY (VENDOR_ID) 
        REFERENCES DOD_VEND_PROFILE(ROW_ID)
);")))
    
(defun migrate-2026Feb-create-gst-reconciliation-table ()
  "Create customer vendor table to track the money transfer from customer to vendor."
  ;; Helper macro to check and create table
  (flet ((create-table-if-not-exists (table-name ddl)
           (unless (table-exists-p table-name)
             (clsql:execute-command ddl))))

    (create-table-if-not-exists
     "DOD_GST_RECONCILIATION"
     "-- This is your killer feature - automated ITC reconciliation

CREATE TABLE DOD_GST_RECONCILIATION (
    ROW_ID MEDIUMINT PRIMARY KEY AUTO_INCREMENT,
    
    -- Who & When
    CUST_ID MEDIUMINT NOT NULL COMMENT 'Buyer doing reconciliation',
    RETURN_PERIOD VARCHAR(7) NOT NULL COMMENT 'YYYY-MM',
    FINANCIAL_YEAR VARCHAR(10) COMMENT '2024-25',
    
    -- Summary Counts
    TOTAL_INVOICES_IN_BOOKS INT DEFAULT 0,
    TOTAL_INVOICES_IN_GSTR2B INT DEFAULT 0,
    MATCHED_INVOICES INT DEFAULT 0,
    MISMATCHED_INVOICES INT DEFAULT 0,
    MISSING_IN_GSTR2B INT DEFAULT 0 COMMENT 'Vendor not filed',
    EXTRA_IN_GSTR2B INT DEFAULT 0 COMMENT 'In GSTR-2B but not in our system',
    
    -- ITC Summary (THE VALUE!)
    ITC_AS_PER_BOOKS DECIMAL(15,2) DEFAULT 0,
    ITC_AS_PER_GSTR2B DECIMAL(15,2) DEFAULT 0,
    ITC_DIFFERENCE DECIMAL(15,2) DEFAULT 0,
    ITC_CLAIMABLE DECIMAL(15,2) DEFAULT 0 COMMENT 'Safe to claim',
    ITC_AT_RISK DECIMAL(15,2) DEFAULT 0 COMMENT 'Vendor not filed yet',
    
    -- Status
    RECONCILIATION_STATUS ENUM('PENDING', 'IN_PROGRESS', 'COMPLETED', 
                                'ISSUES_FOUND', 'FAILED') DEFAULT 'PENDING',
    RECONCILED_AT TIMESTAMP NULL,
    RECONCILED_BY MEDIUMINT,
    
    -- Issues (JSON for flexibility)
    ISSUES_JSON TEXT COMMENT 'Detailed mismatch information',
    RESOLUTION_NOTES TEXT,
    
    -- GSTR-2B Fetch Details
    GSTR2B_FETCHED BOOLEAN DEFAULT FALSE,
    GSTR2B_FETCH_DATE TIMESTAMP NULL,
    GSTR2B_SOURCE ENUM('API', 'MANUAL_UPLOAD', 'CACHED') DEFAULT 'API',
    GSTR2B_FILE_PATH VARCHAR(500) COMMENT 'If manually uploaded',
    
    -- Automation
    AUTO_RECONCILE_ENABLED BOOLEAN DEFAULT TRUE,
    NEXT_AUTO_RECON_AT TIMESTAMP NULL,
    
    -- Metadata
    CREATED TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UPDATED TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    DELETED_STATE CHAR(1) DEFAULT 'N',
    TENANT_ID MEDIUMINT NOT NULL,
    
    UNIQUE KEY uk_cust_period (CUST_ID, RETURN_PERIOD, TENANT_ID),
    INDEX idx_period (RETURN_PERIOD),
    INDEX idx_status (RECONCILIATION_STATUS),
    INDEX idx_customer (CUST_ID),
    
    CONSTRAINT fk_recon_customer FOREIGN KEY (CUST_ID) 
        REFERENCES DOD_CUST_PROFILE(ROW_ID)
);")))

(defun migrate-2026Feb-create-invoice-gst-reconciliation-table ()
  "Create customer vendor table to track the money transfer from customer to vendor."
  ;; Helper macro to check and create table
  (flet ((create-table-if-not-exists (table-name ddl)
           (unless (table-exists-p table-name)
             (clsql:execute-command ddl))))

    (create-table-if-not-exists
     "DOD_INVOICE_GST_RECONCILIATION"
     "-- Track each invoice's reconciliation status

CREATE TABLE DOD_INVOICE_GST_RECONCILIATION (
    ROW_ID MEDIUMINT PRIMARY KEY AUTO_INCREMENT,
    
    -- References
    RECONCILIATION_ID MEDIUMINT NOT NULL COMMENT 'Parent reconciliation',
    INVOICE_ID MEDIUMINT NOT NULL COMMENT 'Our invoice',
    
    -- GSTR-2B Match Status
    IN_GSTR2B BOOLEAN DEFAULT FALSE,
    MATCH_STATUS ENUM('NOT_CHECKED', 'MATCHED', 'AMOUNT_MISMATCH', 
                      'GST_MISMATCH', 'MISSING', 'DUPLICATE') DEFAULT 'NOT_CHECKED',
    
    -- Our Data
    OUR_INVOICE_NUMBER VARCHAR(50),
    OUR_INVOICE_DATE DATE,
    OUR_TAXABLE_AMOUNT DECIMAL(15,2),
    OUR_GST_AMOUNT DECIMAL(15,2),
    OUR_TOTAL DECIMAL(15,2),
    
    -- GSTR-2B Data
    GSTR2B_INVOICE_NUMBER VARCHAR(50),
    GSTR2B_INVOICE_DATE DATE,
    GSTR2B_TAXABLE_AMOUNT DECIMAL(15,2),
    GSTR2B_GST_AMOUNT DECIMAL(15,2),
    GSTR2B_TOTAL DECIMAL(15,2),
    GSTR2B_IRN VARCHAR(64) COMMENT 'E-invoice IRN from GSTR-2B',
    
    -- Mismatch Details
    MISMATCH_TYPE VARCHAR(100) COMMENT 'amount/gst_rate/date/etc',
    AMOUNT_DIFFERENCE DECIMAL(15,2),
    GST_DIFFERENCE DECIMAL(15,2),
    MISMATCH_REASON TEXT,
    
    -- Resolution
    ISSUE_RESOLVED BOOLEAN DEFAULT FALSE,
    RESOLVED_AT TIMESTAMP NULL,
    RESOLVED_BY MEDIUMINT,
    RESOLUTION_ACTION VARCHAR(100) COMMENT 'vendor_corrected/our_error/accepted_difference',
    RESOLUTION_NOTES TEXT,
    
    -- ITC Impact
    ITC_CLAIMABLE BOOLEAN DEFAULT FALSE,
    ITC_AMOUNT DECIMAL(15,2),
    ITC_BLOCKED_REASON VARCHAR(200),
    
    -- Metadata
    CREATED TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UPDATED TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    DELETED_STATE CHAR(1) DEFAULT 'N',
    TENANT_ID MEDIUMINT NOT NULL,
    
    INDEX idx_reconciliation (RECONCILIATION_ID),
    INDEX idx_invoice (INVOICE_ID),
    INDEX idx_match_status (MATCH_STATUS),
    INDEX idx_in_gstr2b (IN_GSTR2B),
    
    CONSTRAINT fk_inv_recon_parent FOREIGN KEY (RECONCILIATION_ID) 
        REFERENCES DOD_GST_RECONCILIATION(ROW_ID),
    CONSTRAINT fk_inv_recon_invoice FOREIGN KEY (INVOICE_ID) 
        REFERENCES DOD_INVOICE_HEADER(ROW_ID)
);")))

(defun migrate-2026Feb-create-vendor-gstr1-status-table ()
  "Create vendor gstr1 status table for a customer to verify whether the vendor has filed gstr1."
  ;; Helper macro to check and create table
  (flet ((create-table-if-not-exists (table-name ddl)
           (unless (table-exists-p table-name)
             (clsql:execute-command ddl))))

    (create-table-if-not-exists
     "DOD_VENDOR_GSTR1_STATUS"
     "-- Track if vendors are filing GSTR-1 on time (impacts buyer's ITC)

CREATE TABLE DOD_VENDOR_GSTR1_STATUS (
    ROW_ID MEDIUMINT PRIMARY KEY AUTO_INCREMENT,
    
    -- Vendor & Period
    VENDOR_ID MEDIUMINT NOT NULL,
    VENDOR_GSTIN VARCHAR(15) NOT NULL,
    RETURN_PERIOD VARCHAR(7) NOT NULL COMMENT 'YYYY-MM',
    
    -- Filing Status
    FILING_STATUS ENUM('NOT_FILED', 'FILED', 'FILED_LATE', 'NOT_REQUIRED') 
        DEFAULT 'NOT_FILED',
    FILED_DATE DATE,
    DUE_DATE DATE NOT NULL,
    DAYS_LATE INT DEFAULT 0,
    
    -- Invoice Counts
    TOTAL_INVOICES_EXPECTED INT COMMENT 'From our system',
    TOTAL_INVOICES_UPLOADED INT COMMENT 'As per GSTN',
    
    -- Impact Assessment
    AFFECTED_BUYERS_COUNT INT DEFAULT 0 COMMENT 'Buyers on our platform',
    TOTAL_ITC_AT_RISK DECIMAL(15,2) DEFAULT 0 COMMENT 'Total ITC stuck',
    
    -- Alerts & Reminders
    REMINDER_SENT BOOLEAN DEFAULT FALSE,
    REMINDER_SENT_AT TIMESTAMP NULL,
    REMINDER_COUNT INT DEFAULT 0,
    ESCALATED_TO_BUYERS BOOLEAN DEFAULT FALSE COMMENT 'Informed buyers',
    
    -- Verification
    VERIFIED_FROM_GSTN BOOLEAN DEFAULT FALSE,
    LAST_VERIFIED_AT TIMESTAMP NULL,
    
    -- Notes
    REMARKS TEXT,
    
    -- Metadata
    CREATED TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UPDATED TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    DELETED_STATE CHAR(1) DEFAULT 'N',
    TENANT_ID MEDIUMINT NOT NULL,
    
    UNIQUE KEY uk_vendor_period (VENDOR_ID, RETURN_PERIOD, TENANT_ID),
    INDEX idx_vendor (VENDOR_ID),
    INDEX idx_gstin (VENDOR_GSTIN),
    INDEX idx_period (RETURN_PERIOD),
    INDEX idx_status (FILING_STATUS),
    INDEX idx_due_date (DUE_DATE),
    
    CONSTRAINT fk_gstr1_vendor FOREIGN KEY (VENDOR_ID) 
        REFERENCES DOD_VEND_PROFILE(ROW_ID)
);")))



(defun migrate-2026Feb-update-invoice-header-table ()
  (when (table-exists-p "DOD_INVOICE_HEADER")
    (clsql:execute-command "ALTER TABLE DOD_INVOICE_HEADER
    -- 1. E-Invoicing (IRN) Tracking
    ADD COLUMN E_INVOICE_REQUIRED BOOLEAN DEFAULT FALSE COMMENT 'Based on turnover threshold',
    ADD COLUMN IRN VARCHAR(64) UNIQUE COMMENT 'Invoice Reference Number from e-invoice',
    ADD COLUMN IRN_DATE TIMESTAMP NULL,
    ADD COLUMN ACK_NUMBER VARCHAR(20) COMMENT 'Acknowledgment number from NIC',
    ADD COLUMN ACK_DATE TIMESTAMP NULL,
    ADD COLUMN QR_CODE_PATH VARCHAR(500) COMMENT 'Storage path for e-invoice QR code image',
    
    -- 2. GSTR-1 & GSTR-2B Compliance
    ADD COLUMN UPLOADED_TO_GSTN BOOLEAN DEFAULT FALSE COMMENT 'Vendor filing status',
    ADD COLUMN GSTN_UPLOAD_DATE TIMESTAMP NULL,
    ADD COLUMN GSTR1_PERIOD VARCHAR(7) COMMENT 'Format: YYYY-MM',
    ADD COLUMN IN_GSTR2B BOOLEAN DEFAULT FALSE COMMENT 'Reflected in Buyer 2B',
    ADD COLUMN GSTR2B_MATCH_STATUS ENUM('NOT_CHECKED', 'MATCHED', 'MISMATCHED', 'MISSING') DEFAULT 'NOT_CHECKED',
    ADD COLUMN GSTR2B_VERIFIED_DATE DATE,
    
    -- 3. Input Tax Credit (ITC) Lifecycle
    ADD COLUMN ITC_ELIGIBLE BOOLEAN DEFAULT TRUE,
    ADD COLUMN ITC_CLAIMED BOOLEAN DEFAULT FALSE,
    ADD COLUMN ITC_CLAIM_MONTH VARCHAR(7) COMMENT 'Format: YYYY-MM',
    ADD COLUMN ITC_AMOUNT DECIMAL(15,2) COMMENT 'Actual ITC amount for the ledger',
    
    -- 4. Financial Reconciliation & Payment Tracking
    ADD COLUMN ADVANCE_ADJUSTED DECIMAL(15,2) DEFAULT 0.00 COMMENT 'Consumed from DOD_ADVANCE_RECEIPT_VOUCHERS',
    ADD COLUMN PAYMENT_ALLOCATED DECIMAL(15,2) DEFAULT 0.00 COMMENT 'Consumed from Direct Payments',
    ADD COLUMN TOTAL_ALLOCATED DECIMAL(15,2) DEFAULT 0.00 COMMENT 'Sum of Advances + Payments',
    ADD COLUMN TOTAL_TDS_DEDUCTED DECIMAL(15,2) DEFAULT 0.00 COMMENT 'Section 194Q / 194C / etc',
    ADD COLUMN BALANCE_DUE DECIMAL(15,2) COMMENT 'TotalValue - (Allocated + TDS)',
    ADD COLUMN ADVANCE_GST_REVERSED DECIMAL(15,2) DEFAULT 0.00 COMMENT 'GST already paid on advances',
    ADD COLUMN PAYMENT_STATUS ENUM('UNPAID', 'PARTIALLY_PAID', 'PAID', 'OVERPAID') DEFAULT 'UNPAID',
    
    -- 5. Reverse Charge (RCM) Tracking
    -- Note: Existing REVCHARGE enum handles the flag; these handle the lifecycle
    ADD COLUMN RCM_PAID BOOLEAN DEFAULT FALSE,
    ADD COLUMN RCM_PAID_DATE DATE,

    -- 6. Optimized Compliance Indexes
    ADD INDEX idx_irn (IRN),
    ADD INDEX idx_gstr2b_status (IN_GSTR2B, GSTR2B_MATCH_STATUS),
    ADD INDEX idx_gstr1_period (GSTR1_PERIOD),
    ADD INDEX idx_itc_status (ITC_CLAIMED, ITC_CLAIM_MONTH),
    ADD INDEX idx_payment_status (PAYMENT_STATUS);")))
  


(defun migrate-2026March-create-eway-bill-table ()
  "Create vendor gstr1 status table for a customer to verify whether the vendor has filed gstr1."
  ;; Helper macro to check and create table
  (flet ((create-table-if-not-exists (table-name ddl)
           (unless (table-exists-p table-name)
             (clsql:execute-command ddl))))

    (create-table-if-not-exists
     "DOD_EWAY_BILL"
     "-- Track e-way bills for invoice shipments

CREATE TABLE DOD_EWAY_BILL (
    ROW_ID MEDIUMINT PRIMARY KEY AUTO_INCREMENT,
    
    -- References
    INVOICE_ID MEDIUMINT NOT NULL,
    DO_ID MEDIUMINT NOT NULL, 
    ORDER_SHIPMENT_ID MEDIUMINT COMMENT 'From DOD_ORDER_SHIPMENT',
    
    -- E-Way Bill Details
    EWAY_BILL_NUMBER VARCHAR(12) UNIQUE NOT NULL,
    EWAY_BILL_DATE TIMESTAMP NOT NULL,
    VALID_UNTIL TIMESTAMP NOT NULL,
    
    -- Transporter Details
    TRANSPORTER_ID VARCHAR(15) COMMENT 'Transporter GSTIN',
    TRANSPORTER_NAME VARCHAR(200),
    TRANSPORT_MODE ENUM('ROAD', 'RAIL', 'AIR', 'SHIP') DEFAULT 'ROAD',
    VEHICLE_NUMBER VARCHAR(20),
    VEHICLE_TYPE ENUM('REGULAR', 'ODC') DEFAULT 'REGULAR',
    
    -- Transport Document
    TRANSPORT_DOC_NUMBER VARCHAR(50),
    TRANSPORT_DOC_DATE DATE,
    
    -- Distance
    DISTANCE_KM INT,
    
    -- Status
    EWAY_STATUS ENUM('ACTIVE', 'EXTENDED', 'EXPIRED', 'CANCELLED') 
        DEFAULT 'ACTIVE',
    CANCELLED_AT TIMESTAMP NULL,
    CANCELLATION_REASON TEXT,
    
    -- Part-B Update (Vehicle change)
    PART_B_UPDATED BOOLEAN DEFAULT FALSE,
    PART_B_UPDATE_COUNT INT DEFAULT 0,
    LAST_VEHICLE_UPDATE TIMESTAMP NULL,
    
    -- Documents
    EWAY_BILL_PDF_PATH VARCHAR(500),
    
    -- Metadata
    GENERATED_BY MEDIUMINT,
    CREATED TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UPDATED TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    DELETED_STATE CHAR(1) DEFAULT 'N',
    TENANT_ID MEDIUMINT NOT NULL,
    
    INDEX idx_invoice (INVOICE_ID),
    INDEX idx_eway_number (EWAY_BILL_NUMBER),
    INDEX idx_valid_until (VALID_UNTIL),
    INDEX idx_status (EWAY_STATUS),
    
    CONSTRAINT fk_eway_invoice FOREIGN KEY (INVOICE_ID) 
        REFERENCES DOD_INVOICE_HEADER(ROW_ID)
);")))

(defun migrate-2026Feb-create-tds-certificates-table ()
  "Create vendor gstr1 status table for a customer to verify whether the vendor has filed gstr1."
  ;; Helper macro to check and create table
  (flet ((create-table-if-not-exists (table-name ddl)
           (unless (table-exists-p table-name)
             (clsql:execute-command ddl))))

    (create-table-if-not-exists
     "DOD_TDS_CERTIFICATES"
     "-- Track TDS deductions and certificates

CREATE TABLE DOD_TDS_CERTIFICATES (
    ROW_ID MEDIUMINT PRIMARY KEY AUTO_INCREMENT,
    
    -- Deductor (Buyer)
    CUST_ID MEDIUMINT NOT NULL,
    DEDUCTOR_TAN VARCHAR(10) NOT NULL,
    DEDUCTOR_PAN VARCHAR(10),
    
    -- Deductee (Vendor)
    VENDOR_ID MEDIUMINT NOT NULL,
    DEDUCTEE_PAN VARCHAR(10) NOT NULL,
    
    -- TDS Details
    TDS_SECTION VARCHAR(10) NOT NULL COMMENT '194C/194J/194Q',
    FINANCIAL_YEAR VARCHAR(10) NOT NULL COMMENT '2024-25',
    QUARTER VARCHAR(2) COMMENT 'Q1/Q2/Q3/Q4',
    
    -- Certificate Details
    CERTIFICATE_NUMBER VARCHAR(50) UNIQUE,
    CERTIFICATE_DATE DATE,
    CERTIFICATE_FILE_PATH VARCHAR(500),
    
    -- Amounts
    TOTAL_PAYMENT DECIMAL(15,2) NOT NULL,
    TDS_RATE DECIMAL(5,2) NOT NULL,
    TDS_AMOUNT DECIMAL(15,2) NOT NULL,
    
    -- Challan Details
    CHALLAN_NUMBER VARCHAR(50),
    CHALLAN_DATE DATE,
    BSR_CODE VARCHAR(7),
    
    -- Form 26AS
    IN_FORM_26AS BOOLEAN DEFAULT FALSE,
    FORM_26AS_VERIFIED_AT TIMESTAMP NULL,
    
    -- Invoice Links (JSON array of invoice IDs)
    RELATED_INVOICES_JSON TEXT COMMENT 'JSON array',
    
    -- Status
    CERTIFICATE_STATUS ENUM('PENDING', 'ISSUED', 'VERIFIED', 'DISPUTED') 
        DEFAULT 'PENDING',
    
    -- Metadata
    ISSUED_BY MEDIUMINT,
    CREATED TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UPDATED TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    DELETED_STATE CHAR(1) DEFAULT 'N',
    TENANT_ID MEDIUMINT NOT NULL,
    
    INDEX idx_customer (CUST_ID),
    INDEX idx_vendor (VENDOR_ID),
    INDEX idx_fy_quarter (FINANCIAL_YEAR, QUARTER),
    INDEX idx_certificate (CERTIFICATE_NUMBER),
    
    CONSTRAINT fk_tds_customer FOREIGN KEY (CUST_ID) 
        REFERENCES DOD_CUST_PROFILE(ROW_ID),
    CONSTRAINT fk_tds_vendor FOREIGN KEY (VENDOR_ID) 
        REFERENCES DOD_VEND_PROFILE(ROW_ID)
);")))
     

(defun migrate-2026Feb-modify-payment-transaction-table ()
  (when (table-exists-p "DOD_PAYMENT_TRANSACTION")
    (clsql:execute-command "
ALTER TABLE DOD_PAYMENT_TRANSACTION ADD COLUMN PAYMENT_NUMBER VARCHAR(50) NOT NULL COMMENT 'Unique payment identifier PAY-YYYY-NNNNN' AFTER ROW_ID, MODIFY COLUMN AMT DECIMAL(15,2) NOT NULL COMMENT 'Payment amount - increased for B2B', ADD COLUMN PAYMENT_TYPE ENUM('ADVANCE', 'INVOICE', 'ORDER', 'SUBSCRIPTION', 'COD_SETTLEMENT', 'REFUND', 'OTHER') DEFAULT 'ORDER' COMMENT 'What is this payment for?' AFTER VENDOR_ID, ADD COLUMN PAYMENT_METHOD ENUM('UPI', 'NEFT', 'RTGS', 'IMPS', 'CARD', 'DEBIT_CARD', 'CREDIT_CARD', 'CHEQUE', 'DD', 'CASH', 'WALLET', 'NET_BANKING', 'OTHER') COMMENT 'Standardized payment method', DROP COLUMN PAYMENT_MODE, ADD COLUMN GATEWAY_NAME VARCHAR(50) COMMENT 'Razorpay/Paytm/PhonePe/etc' AFTER PAYMENT_METHOD, ADD COLUMN GATEWAY_TXN_ID VARCHAR(100) COMMENT 'Gateway transaction ID' AFTER GATEWAY_NAME, ADD COLUMN GATEWAY_FEE DECIMAL(15,2) DEFAULT 0.00 COMMENT 'Gateway processing fee' AFTER GATEWAY_TXN_ID, ADD COLUMN UPI_PAYMENT_ID MEDIUMINT COMMENT 'Link to DOD_UPI_PAYMENTS' AFTER PAYMENT_METHOD, ADD COLUMN CARD_PAYMENT_ID MEDIUMINT COMMENT 'Link to DOD_CARD_PAYMENTS' AFTER UPI_PAYMENT_ID, ADD COLUMN CHEQUE_PAYMENT_ID MEDIUMINT COMMENT 'Link to DOD_CHEQUE_PAYMENTS' AFTER CARD_PAYMENT_ID, ADD COLUMN PAYMENT_REFERENCE VARCHAR(100) COMMENT 'UTR/Cheque No/Card Last 4' AFTER TRANSACTION_ID, ADD COLUMN BANK_NAME VARCHAR(100) COMMENT 'Bank name' AFTER PAYMENT_REFERENCE, ADD COLUMN ACCOUNT_LAST4 VARCHAR(4) COMMENT 'Last 4 digits' AFTER BANK_NAME, ADD COLUMN IFSC_CODE VARCHAR(11) COMMENT 'IFSC code' AFTER ACCOUNT_LAST4, ADD COLUMN PAYMENT_STATUS ENUM('PENDING', 'PROCESSING', 'SUCCESS', 'FAILED', 'REFUNDED', 'CANCELLED', 'DISPUTED') DEFAULT 'SUCCESS' AFTER PAYMENT_REFERENCE, ADD COLUMN REFUNDED BOOLEAN DEFAULT FALSE AFTER PAYMENT_STATUS, ADD COLUMN REFUND_AMOUNT DECIMAL(15,2) AFTER REFUNDED, ADD COLUMN REFUND_DATE DATE AFTER REFUND_AMOUNT, ADD COLUMN REFUND_REFERENCE VARCHAR(100) AFTER REFUND_DATE, ADD COLUMN REFUND_REASON TEXT AFTER REFUND_REFERENCE, ADD COLUMN PAYMENT_DATE DATE COMMENT 'Payment date only' AFTER PAYMENT_STATUS, CHANGE COLUMN PAYMENT_DATETIME PAYMENT_TIMESTAMP TIMESTAMP DEFAULT CURRENT_TIMESTAMP, ADD COLUMN ADVANCE_VOUCHER_ID MEDIUMINT COMMENT 'Link to DOD_ADVANCE_RECEIPT_VOUCHERS' AFTER PAYMENT_DATE, ADD COLUMN INVOICE_ID MEDIUMINT COMMENT 'Link to DOD_INVOICE_HEADER' AFTER ADVANCE_VOUCHER_ID, ADD COLUMN RECONCILED BOOLEAN DEFAULT FALSE AFTER REFUND_REASON, ADD COLUMN RECONCILIATION_DATE DATE AFTER RECONCILED, ADD COLUMN RECONCILIATION_NOTES TEXT AFTER RECONCILIATION_DATE, MODIFY COLUMN DESCRIPTION TEXT COMMENT 'Payment description', ADD COLUMN REMARKS TEXT COMMENT 'Internal notes' AFTER DESCRIPTION, ADD COLUMN PAYMENT_PROOF_PATH VARCHAR(500) AFTER RECONCILIATION_NOTES, ADD COLUMN RECEIPT_PDF_PATH VARCHAR(500) AFTER PAYMENT_PROOF_PATH, ADD COLUMN UPDATED TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP AFTER CREATED;
")))
