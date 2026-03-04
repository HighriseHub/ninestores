;; ============================================================================
;; DOD_CUST_WALLET Enhancement Migration Script (Common Lisp + CLSQL)
;; ============================================================================
;; Purpose: Upgrade existing DOD_CUST_WALLET table with enhanced tracking,
;;          limits, and control features
;; Target: MySQL 5.7+ via CLSQL
;; ============================================================================

;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)

(defun migrate-2026Feb-update-customer-wallet-table ()
;; Step 1: Add Balance Management Columns
;; ----------------------------------------------------------------------------
  (unless (column-exists-p "DOD_CUST_WALLET" "TOTAL_ADVANCES_RECEIVED")
    (clsql:execute-command 
     "ALTER TABLE DOD_CUST_WALLET ADD COLUMN TOTAL_ADVANCES_RECEIVED DECIMAL(15,2) DEFAULT 0 COMMENT 'Total advances received ';"))
  
  (unless (column-exists-p "DOD_CUST_WALLET" "TOTAL_ADVANCES_ADJUSTED")
    (clsql:execute-command 
     "ALTER TABLE DOD_CUST_WALLET ADD COLUMN TOTAL_ADVANCES_ADJUSTED DECIMAL(15,2) DEFAULT 0 COMMENT 'Total ever spent' AFTER TOTAL_ADVANCES_RECEIVED;"))
  
  ;; Update comment on existing balance column
  (unless (column-exists-p "DOD_CUST_WALLET" "UNADJUSTED_ADVANCE_VALUE")
    (clsql:execute-command 
     "ALTER TABLE DOD_CUST_WALLET ADD  COLUMN UNADJUSTED_ADVANCE_VALUE DECIMAL(15,2) DEFAULT 0 COMMENT 'Current wallet balance';"))

  (unless (column-exists-p "DOD_CUST_WALLET" "UNADJUSTED_GST_AMOUNT")
    (clsql:execute-command
     "ALTER TABLE DOD_CUST_WALLET ADD COLUMN UNADJUSTED_GST_AMOUNT DECIMAL(15,2) DEFAULT 0.00  AFTER UNADJUSTED_ADVANCE_VALUE;"))
  
  ;; Step 2: Add Relationship Status
  ;; ----------------------------------------------------------------------------
  (unless (column-exists-p "DOD_CUST_WALLET" "WALLET_STATUS")
    (clsql:execute-command 
     "ALTER TABLE DOD_CUST_WALLET ADD COLUMN wallet_status ENUM('ACTIVE', 'INACTIVE', 'SUSPENDED', 'CLOSED') DEFAULT 'ACTIVE' AFTER lifetime_spent;"))
  
  ;; Step 3: Add Activity Tracking Columns
  ;; ----------------------------------------------------------------------------
  (unless (column-exists-p "DOD_CUST_WALLET" "LAST_LOADED_AT")
    (clsql:execute-command 
     "ALTER TABLE DOD_CUST_WALLET ADD COLUMN last_loaded_at TIMESTAMP NULL COMMENT 'Last time money was added' AFTER wallet_status;"))

  (unless (column-exists-p "DOD_CUST_WALLET" "OLDEST_VOUCHER_DATE")
    (clsql:execute-command
     "ALTER TABLE DOD_CUST_WALLET ADD COLUMN OLDEST_VOUCHER_DATE DATE NULL AFTER LAST_LOADED_AT"))

  (unless (column-exists-p "DOD_CUST_WALLET" "LAST_TRANSACTION_AT")
    (clsql:execute-command 
     "ALTER TABLE DOD_CUST_WALLET ADD COLUMN last_transaction_at TIMESTAMP NULL COMMENT 'Last purchase from this vendor' AFTER last_loaded_at;"))

  ;; -- 4. Add GSTIN Context (Critical for multi-location businesses)
  
  (unless (column-exists-p "DOD_CUST_WALLET" "VENDOR_GSTIN")
    (clsql:execute-command 
     "ALTER TABLE DOD_CUST_WALLET ADD COLUMN VENDOR_GSTIN VARCHAR(15) NOT NULL AFTER VENDOR_ID;"))

  (unless (column-exists-p "DOD_CUST_WALLET" "CUSTOMER_GSTIN")
    (clsql:execute-command 
     "ALTER TABLE DOD_CUST_WALLET     ADD COLUMN CUSTOMER_GSTIN VARCHAR(15) AFTER CUST_ID;"))

  ;; Step 4: Add Auto-Reload Controls
  ;; ----------------------------------------------------------------------------
  (unless (column-exists-p "DOD_CUST_WALLET" "AUTO_RELOAD_ENABLED")
    (clsql:execute-command 
     "ALTER TABLE DOD_CUST_WALLET ADD COLUMN auto_reload_enabled BOOLEAN DEFAULT FALSE COMMENT 'Auto-reload when balance low' AFTER first_transaction_at;"))
  
  (unless (column-exists-p "DOD_CUST_WALLET" "AUTO_RELOAD_THRESHOLD")
    (clsql:execute-command 
     "ALTER TABLE DOD_CUST_WALLET ADD COLUMN auto_reload_threshold DECIMAL(15,2) NULL COMMENT 'Reload when balance drops below this' AFTER auto_reload_enabled;"))

  (unless (column-exists-p "DOD_CUST_WALLET" "AUTO_RELOAD_AMOUNT")
    (clsql:execute-command 
     "ALTER TABLE DOD_CUST_WALLET ADD COLUMN auto_reload_amount DECIMAL(15,2) NULL COMMENT 'Amount to reload' AFTER auto_reload_threshold;"))
  
  
  ;; Step 5: Add Monthly Budget Controls
  ;; ----------------------------------------------------------------------------
  (unless (column-exists-p "DOD_CUST_WALLET" "MONTHLY_BUDGET_LIMIT")
    (clsql:execute-command 
     "ALTER TABLE DOD_CUST_WALLET ADD COLUMN monthly_budget_limit DECIMAL(15,2) NULL COMMENT 'Max spend per month with this vendor' AFTER auto_reload_amount;"))
  
  (unless (column-exists-p "DOD_CUST_WALLET" "CURRENT_MONTH_SPENT")
    (clsql:execute-command 
     "ALTER TABLE DOD_CUST_WALLET ADD COLUMN current_month_spent DECIMAL(15,2) DEFAULT 0 AFTER monthly_budget_limit;"))
  
  
  ;; Step 6: Add Notification Settings
  ;; ----------------------------------------------------------------------------
  (unless (column-exists-p "DOD_CUST_WALLET" "LOW_BALANCE_ALERT_ENABLED")
    (clsql:execute-command 
     "ALTER TABLE DOD_CUST_WALLET ADD COLUMN low_balance_alert_enabled BOOLEAN DEFAULT TRUE AFTER current_month_spent;"))
  
  (unless (column-exists-p "DOD_CUST_WALLET" "LOW_BALANCE_THRESHOLD")
    (clsql:execute-command 
     "ALTER TABLE DOD_CUST_WALLET ADD COLUMN low_balance_threshold DECIMAL(15,2) DEFAULT 5000 AFTER low_balance_alert_enabled;"))

  
  ;; Step 7: Add Suspension Tracking
  ;; ----------------------------------------------------------------------------
  (unless (column-exists-p "DOD_CUST_WALLET" "SUSPENDED_AT")
    (clsql:execute-command 
     "ALTER TABLE DOD_CUST_WALLET ADD COLUMN suspended_at TIMESTAMP NULL AFTER low_balance_threshold;"))

  (unless (column-exists-p "DOD_CUST_WALLET" "SUSPENDED_BY")
    (clsql:execute-command 
     "ALTER TABLE DOD_CUST_WALLET ADD COLUMN suspended_by MEDIUMINT NULL AFTER suspended_at;"))
  
  (unless (column-exists-p "DOD_CUST_WALLET" "SUSPENSION_REASON")
    (clsql:execute-command 
     "ALTER TABLE DOD_CUST_WALLET ADD COLUMN suspension_reason TEXT NULL AFTER suspended_by;"))
  
  ;; Add foreign key for suspended_by (if DOD_USERS table exists)
  (unless (foreign-key-exists-p "DOD_CUST_WALLET" "fk_wallet_suspended_by")
    (clsql:execute-command 
     "ALTER TABLE DOD_CUST_WALLET ADD CONSTRAINT fk_wallet_suspended_by FOREIGN KEY (suspended_by) REFERENCES DOD_USERS(ROW_ID);"))
  
  ;; Step 8: Add Closure Tracking
  ;; ----------------------------------------------------------------------------
  (unless (column-exists-p "DOD_CUST_WALLET" "CLOSED_AT")
    (clsql:execute-command 
     "ALTER TABLE DOD_CUST_WALLET ADD COLUMN closed_at TIMESTAMP NULL AFTER suspension_reason;"))
  
  (unless (column-exists-p "DOD_CUST_WALLET" "CLOSED_BY")
    (clsql:execute-command 
     "ALTER TABLE DOD_CUST_WALLET ADD COLUMN closed_by MEDIUMINT NULL AFTER closed_at;"))
  
  (unless (column-exists-p "DOD_CUST_WALLET" "CLOSURE_REASON")
    (clsql:execute-command 
     "ALTER TABLE DOD_CUST_WALLET ADD COLUMN closure_reason TEXT NULL AFTER closed_by;"))
  
  ;; Add foreign key for closed_by (if DOD_USERS table exists)
  (unless (foreign-key-exists-p "DOD_CUST_WALLET" "fk_wallet_closed_by")
    (clsql:execute-command 
     "ALTER TABLE DOD_CUST_WALLET ADD CONSTRAINT fk_wallet_closed_by FOREIGN KEY (closed_by) REFERENCES DOD_USERS(row_id);"))
  
  
  ;; Step 9: Add/Update Metadata Columns
  ;; ----------------------------------------------------------------------------
  (unless (column-exists-p "DOD_CUST_WALLET" "UPDATED")
  (clsql:execute-command 
   "ALTER TABLE DOD_CUST_WALLET ADD COLUMN updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP AFTER created;"))
  
  
  ;; Step 10: Add Indexes for Performance
  ;; ----------------------------------------------------------------------------
  (unless (index-exists-p "DOD_CUST_WALLET" "idx_status")
    (clsql:execute-command 
     "ALTER TABLE DOD_CUST_WALLET ADD INDEX idx_status (wallet_status);"))
  
  (unless (index-exists-p "DOD_CUST_WALLET" "idx_cust_active")
    (clsql:execute-command 
     "ALTER TABLE DOD_CUST_WALLET ADD INDEX idx_cust_active (cust_id, wallet_status);"))
  
  (unless (index-exists-p "DOD_CUST_WALLET" "idx_last_activity")
    (clsql:execute-command 
     "ALTER TABLE DOD_CUST_WALLET ADD INDEX idx_last_activity (last_transaction_at);"))
  
  
  ;; Step 11: Populate Historical Data (Optional)
  ;; ----------------------------------------------------------------------------
  ;; Set first_transaction_at to created_at for existing records
  (clsql:execute-command 
   "UPDATE DOD_CUST_WALLET 
   SET first_transaction_at = created 
   WHERE first_transaction_at IS NULL;")
  
  ;; Initialize lifetime values based on current balance (if needed)
  (clsql:execute-command 
   "UPDATE DOD_CUST_WALLET 
   SET lifetime_loaded = balance 
   WHERE lifetime_loaded = 0 AND balance > 0;")
  
  )

(defun migrate-2026Feb-create-proforma-invoices-table ()
  "Create customer users table which will enable us to have user profiles for customers who can login and do transactions"
  (flet ((create-table-if-not-exists (table-name ddl)
	   (unless (table-exists-p table-name)
             (clsql:execute-command ddl))))
    (create-table-if-not-exists
     "DOD_PROFORMA_INVOICES"
     "CREATE TABLE DOD_PROFORMA_INVOICES (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    proforma_no VARCHAR(20) NOT NULL,
    customer_id BIGINT NOT NULL,
    vendor_id BIGINT NOT NULL,
    
    -- GST Compliance Fields
    vendor_gstin VARCHAR(15) NOT NULL,
    customer_gstin VARCHAR(15), -- Optional if customer is unregistered
    place_of_supply VARCHAR(50) NOT NULL, -- State Name/Code (Critical for IGST vs CGST/SGST)
    is_reverse_charge CHAR(1) DEFAULT 'N',
    
    total_taxable_value DECIMAL(15, 2) NOT NULL,
    total_gst_amount DECIMAL(15, 2) NOT NULL,
    total_invoice_value DECIMAL(15, 2) NOT NULL,
    
    -- Audit & Tombstone Fields
    STATUS VARCHAR(20) DEFAULT 'ACTIVE', -- DRAFT, SENT, PAID, EXPIRED
    DELETED_STATE CHAR(1) DEFAULT 'N',
    TENANT_ID MEDIUMINT NOT NULL,
    CREATED TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UPDATED TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        INDEX (proforma_no),
    INDEX (vendor_id, customer_id),
FOREIGN KEY (tenant_id) REFERENCES DOD_COMPANY (row_id)  
) ENGINE=InnoDB;")))


(defun migrate-2026Feb-create-advance-receipt-vouchers-table ()
  "Create customer users table which will enable us to have user profiles for customers who can login and do transactions"
  (flet ((create-table-if-not-exists (table-name ddl)
	   (unless (table-exists-p table-name)
             (clsql:execute-command ddl))))
    (create-table-if-not-exists
     "DOD_ADVANCE_RECEIPT_VOUCHERS"
     "CREATE TABLE DOD_ADVANCE_RECEIPT_VOUCHERS (
    -- 1. Primary Identifiers & Linkages
    row_id MEDIUMINT PRIMARY KEY AUTO_INCREMENT,
    voucher_no VARCHAR(16) NOT NULL COMMENT 'GST mandated 16-character limit',
    proforma_id BIGINT NULL,
    customer_id BIGINT NOT NULL,
    vendor_id BIGINT NOT NULL,
    TENANT_ID MEDIUMINT NOT NULL,

    -- 2. Financial Values (The Core Transaction)
    amount_received DECIMAL(15,2) NOT NULL COMMENT 'Gross amount received from customer',
    taxable_value DECIMAL(15,2) NOT NULL COMMENT 'Net value excluding GST',
    total_gst_paid DECIMAL(15,2) NOT NULL COMMENT 'Total tax liability generated',
    igst_amount DECIMAL(15,2) DEFAULT 0.00,
    cgst_amount DECIMAL(15,2) DEFAULT 0.00,
    sgst_amount DECIMAL(15,2) DEFAULT 0.00,
    cess_amount DECIMAL(15,2) DEFAULT 0.00,

    -- 3. Adjustment & Utilization Tracking
    total_adjusted DECIMAL(15,2) DEFAULT 0.00 COMMENT 'Amount already utilized against invoices',
    balance_remaining DECIMAL(15,2) COMMENT 'Unutilized advance = amount_received - total_adjusted',
    gst_adjusted DECIMAL(15,2) DEFAULT 0.00 COMMENT 'GST amount already reversed in adjustments',
    gst_remaining DECIMAL(15,2) COMMENT 'GST yet to be reversed',
    total_adjustments_count INT DEFAULT 0,
    first_adjustment_date DATE,
    last_adjustment_date DATE,

    -- 4. Payment Details (The Audit Trail)
    payment_mode VARCHAR(50) COMMENT 'NEFT/RTGS/UPI/CHEQUE/DD/CASH',
    payment_reference VARCHAR(100) NOT NULL COMMENT 'Bank UTR/UPI Txn ID - Vital for Reconciliation',
    payment_txn_id MEDIUMINT COMMENT 'Link to internal payment gateway log',
    bank_name VARCHAR(100) COMMENT 'Remitter bank name',
    cheque_number VARCHAR(20),
    cheque_date DATE,
    cheque_clearance_date DATE,
    payment_proof_path VARCHAR(500) COMMENT 'Path to bank statement or cheque image',

    -- 5. Status & Lifecycle Management
    STATUS VARCHAR(20) DEFAULT 'ACTIVE', -- Legacy support
    voucher_status ENUM('ACTIVE', 'PARTIALLY_ADJUSTED', 'FULLY_ADJUSTED', 'REFUNDED', 'EXPIRED', 'CANCELLED') DEFAULT 'ACTIVE',
    receipt_date DATE NOT NULL,
    expiry_date DATE NOT NULL COMMENT 'Used for 365-day Deemed Deposit alert',
    aging_days INT COMMENT 'Calculated field for reporting',
    DELETED_STATE CHAR(1) DEFAULT 'N',

    -- 6. Refund Processing
    refund_requested BOOLEAN DEFAULT FALSE,
    refund_date DATE,
    refund_amount DECIMAL(15,2),
    refund_reference VARCHAR(100),
    refund_reason TEXT,

    -- 7. Document & Internal Notes
    receipt_pdf_path VARCHAR(500) COMMENT 'S3/Storage link for the generated Receipt Voucher',
    purpose TEXT,
    remarks TEXT,

    -- 8. Approval & Audit Trail
    requires_approval BOOLEAN DEFAULT FALSE,
    approved_by MEDIUMINT,
    approved_at TIMESTAMP NULL,
    CREATED TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by MEDIUMINT,
    UPDATED TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    updated_by MEDIUMINT,

    -- 9. Indexes & Constraints
    INDEX idx_voucher_no (voucher_no),
    INDEX idx_cust_vend (customer_id, vendor_id),
    INDEX idx_proforma (proforma_id),
    INDEX idx_tenant (TENANT_ID),
    INDEX idx_voucher_status (voucher_status),
    INDEX idx_balance_remaining (balance_remaining),
    INDEX idx_payment_ref (payment_reference),
    INDEX idx_expiry (expiry_date),
    INDEX idx_receipt_date (receipt_date),
    
    CONSTRAINT fk_advance_payment_txn 
        FOREIGN KEY (payment_txn_id) REFERENCES DOD_PAYMENT_TRANSACTION(ROW_ID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;")))


(defun migrate-2026Feb-create-invoice-advance-adjustments-table ()
  "Create customer users table which will enable us to have user profiles for customers who can login and do transactions"
  (flet ((create-table-if-not-exists (table-name ddl)
	   (unless (table-exists-p table-name)
             (clsql:execute-command ddl))))
    (create-table-if-not-exists
     "DOD_INVOICE_ALLOCATIONS"
     "CREATE TABLE DOD_INVOICE_ALLOCATIONS (
    -- 1. Primary Identifiers & Linkages
    row_id MEDIUMINT PRIMARY KEY AUTO_INCREMENT,
    tax_invoice_id BIGINT NOT NULL COMMENT 'The target invoice being paid/adjusted',
    TENANT_ID MEDIUMINT NOT NULL,

    -- 2. Allocation Source (Advance vs. Direct Payment vs. Others)
    allocation_type ENUM('ADVANCE', 'PAYMENT', 'CREDIT_NOTE', 'ADJUSTMENT', 'WRITE_OFF') 
        DEFAULT 'ADVANCE' NOT NULL,
    voucher_id MEDIUMINT NULL COMMENT 'Link to DOD_ADVANCE_RECEIPT_VOUCHERS (if ADVANCE)',
    payment_id MEDIUMINT NULL COMMENT 'Link to DOD_PAYMENT_TRANSACTION (if PAYMENT)',

    -- 3. Financial Splits
    amount_adjusted DECIMAL(15,2) NOT NULL COMMENT 'Gross amount allocated to the invoice',
    tds_amount DECIMAL(15,2) DEFAULT 0.00 COMMENT 'TDS deducted on payment (Section 194Q/etc)',
    net_allocated DECIMAL(15,2) COMMENT 'Amount after TDS = amount_adjusted - tds_amount',

    -- 4. Tax Reversal Tracking (Crucial for GST Compliance)
    -- When an advance is consumed, the Advance Tax is reversed to avoid double taxation
    tax_reversed_igst DECIMAL(15,2) DEFAULT 0.00,
    tax_reversed_cgst DECIMAL(15,2) DEFAULT 0.00,
    tax_reversed_sgst DECIMAL(15,2) DEFAULT 0.00,

    -- 5. Lifecycle & Reversal Logic
    STATUS ENUM('APPLIED', 'REVERSED', 'PENDING', 'ACTIVE') DEFAULT 'APPLIED',
    allocation_date DATE NOT NULL,
    reversed BOOLEAN DEFAULT FALSE,
    reversed_at TIMESTAMP NULL,
    reversal_reason TEXT,

    -- 6. Audit Trail & Meta
    DELETED_STATE CHAR(1) DEFAULT 'N',
    created_by MEDIUMINT,
    CREATED TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UPDATED TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    -- 7. Indexes for High-Speed Reconciliation
    INDEX idx_invoice (tax_invoice_id),
    INDEX idx_voucher (voucher_id),
    INDEX idx_payment (payment_id),
    INDEX idx_tenant (TENANT_ID),
    INDEX idx_allocation_type (allocation_type),
    INDEX idx_allocation_date (allocation_date),

    -- 8. Constraints (Ensuring Data Integrity)
    CONSTRAINT fk_alloc_voucher FOREIGN KEY (voucher_id) 
        REFERENCES DOD_ADVANCE_RECEIPT_VOUCHERS(row_id),
    CONSTRAINT fk_alloc_payment FOREIGN KEY (payment_id) 
        REFERENCES DOD_PAYMENT_TRANSACTION(ROW_ID),
    
    -- Business Rule: Ensures the right reference is present for the type
    CONSTRAINT chk_allocation_refs CHECK (
        (allocation_type = 'ADVANCE' AND voucher_id IS NOT NULL) OR
        (allocation_type = 'PAYMENT' AND payment_id IS NOT NULL) OR
        (allocation_type IN ('CREDIT_NOTE', 'ADJUSTMENT', 'WRITE_OFF'))
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;")))
