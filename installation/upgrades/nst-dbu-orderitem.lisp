;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)


(defun migrate-2026Feb-modify-customer-order-table ()
  (when (table-exists-p "DOD_ORDER")
    (clsql:execute-command
     "ALTER TABLE DOD_ORDER
    -- Fix size issues
    MODIFY COLUMN TOTAL_DISCOUNT DECIMAL(15,2) COMMENT 'Total discount amount',
    MODIFY COLUMN TOTAL_TAX DECIMAL(15,2) COMMENT 'Total GST amount',
    
    -- GST compliance fields
    ADD COLUMN PLACE_OF_SUPPLY VARCHAR(50) COMMENT 'State name for GST',
    ADD COLUMN PLACE_OF_SUPPLY_CODE VARCHAR(2) COMMENT 'State code (01-37)',
    ADD COLUMN SUPPLY_TYPE ENUM('INTRA_STATE', 'INTER_STATE') 
        COMMENT 'Derived from billing vs shipping state',
    
    -- Tax breakdown (for reporting)
    ADD COLUMN TOTAL_TAXABLE_VALUE DECIMAL(15,2) COMMENT 'Sum of all taxable values',
    ADD COLUMN TOTAL_CGST DECIMAL(15,2) DEFAULT 0,
    ADD COLUMN TOTAL_SGST DECIMAL(15,2) DEFAULT 0,
    ADD COLUMN TOTAL_IGST DECIMAL(15,2) DEFAULT 0,
    ADD COLUMN TOTAL_CESS DECIMAL(15,2) DEFAULT 0,
    
    -- Special cases
    ADD COLUMN REVERSE_CHARGE_APPLICABLE BOOLEAN DEFAULT FALSE,
    ADD COLUMN EWAY_BILL_REQUIRED BOOLEAN DEFAULT FALSE 
        COMMENT 'If value > 50k and goods',
    
    -- TDS (B2B)
    ADD COLUMN TDS_APPLICABLE BOOLEAN DEFAULT FALSE,
    ADD COLUMN TDS_AMOUNT DECIMAL(15,2) DEFAULT 0,
    
    -- Invoice reference (when converted)
    ADD COLUMN INVOICE_NUMBER VARCHAR(50) COMMENT 'When IS_CONVERTED_TO_INVOICE = Y',
    ADD COLUMN INVOICE_DATE DATE COMMENT 'Tax invoice date',
    
    -- Add indexes
    ADD INDEX idx_gstnumber (GSTNUMBER),
    ADD INDEX idx_converted (IS_CONVERTED_TO_INVOICE),
    ADD INDEX idx_place_of_supply (PLACE_OF_SUPPLY_CODE);")))



(defun migrate-2026Feb-modify-customer-order-items-table ()
  (when (table-exists-p "DOD_ORDER_ITEMS")
    (clsql:execute-command
     "ALTER TABLE DOD_ORDER_ITEMS
    -- Fix size
    MODIFY COLUMN UNIT_PRICE DECIMAL(15,2) COMMENT 'Unit price (MRP or discounted)',
    
    -- MANDATORY for GSTR-1 compliance
    ADD COLUMN HSN_CODE VARCHAR(8) COMMENT 'Copy from product at order time' AFTER PRD_ID,
    ADD COLUMN SAC_CODE VARCHAR(8) COMMENT 'If service' AFTER HSN_CODE,
    ADD COLUMN ITEM_DESCRIPTION VARCHAR(500) COMMENT 'Product name at order time' AFTER SAC_CODE,
    ADD COLUMN UQC VARCHAR(10) COMMENT 'Unit quantity code (KGS/NOS/LTR)' AFTER ITEM_DESCRIPTION,
    
    -- Cess
    ADD COLUMN CESS_RATE DECIMAL(4,2) DEFAULT 0 COMMENT 'Cess percentage' AFTER IGST,
    ADD COLUMN CESS_AMOUNT DECIMAL(15,2) DEFAULT 0 AFTER IGSTAMT,
    
    -- Discount amount (not just rate)
    ADD COLUMN DISCOUNT_AMOUNT DECIMAL(15,2) DEFAULT 0 
        COMMENT 'Absolute discount = TAXABLEVALUE * DISC_RATE / 100' AFTER DISC_RATE,
    
    -- Original MRP (before discount)
    ADD COLUMN MRP DECIMAL(15,2) COMMENT 'Original price before discount' AFTER UNIT_PRICE,
    
    -- ITC eligibility (from product)
    ADD COLUMN ITC_ELIGIBLE ENUM('ELIGIBLE', 'INELIGIBLE', 'BLOCKED') 
        DEFAULT 'ELIGIBLE' COMMENT 'Copy from product',
    
    -- Add indexes
    ADD INDEX idx_order (ORDER_ID),
    ADD INDEX idx_vendor (VENDOR_ID),
    ADD INDEX idx_product (PRD_ID),
    ADD INDEX idx_hsn (HSN_CODE);")))

