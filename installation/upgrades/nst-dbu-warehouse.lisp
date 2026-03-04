;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)

(defun migrate-2026Feb-create-stock-count-table ()
 "Create customer users table which will enable us to have user profiles for customers who can login and do transactions"
  (flet ((create-table-if-not-exists (table-name ddl)
	   (unless (table-exists-p table-name)
             (clsql:execute-command ddl))))
    (create-table-if-not-exists
     "DOD_STOCK_COUNT"
     "CREATE TABLE `DOD_STOCK_COUNT` (
  `ROW_ID` mediumint NOT NULL AUTO_INCREMENT,
  `COUNT_NUMBER` varchar(50) NOT NULL COMMENT 'Stock count reference',
  
  -- COUNT DETAILS
  `COUNT_TYPE` enum(
    'CYCLE_COUNT',
    'ANNUAL_COUNT',
    'SPOT_CHECK',
    'LOCATION_COUNT',
    'ABC_COUNT'
  ) NOT NULL,
  
  `COUNT_STATUS` enum(
    'PLANNED',
    'IN_PROGRESS',
    'COMPLETED',
    'APPROVED',
    'CANCELLED'
  ) DEFAULT 'PLANNED',
  
  -- SCOPE
  `WAREHOUSE_ID` mediumint NOT NULL,
  `LOCATION_ID` mediumint DEFAULT NULL COMMENT 'Specific location or NULL for full warehouse',
  `PRD_ID` mediumint DEFAULT NULL COMMENT 'Specific product or NULL for all',
  
  -- STOCK REFERENCE
  `STOCK_ID` mediumint DEFAULT NULL COMMENT 'FK to DOD_STOCK',
  `BATCH_ID` mediumint DEFAULT NULL,
  
  -- COUNT RESULTS
  `SYSTEM_QTY` decimal(12,3) DEFAULT NULL COMMENT 'Quantity per system',
  `COUNTED_QTY` decimal(12,3) DEFAULT NULL COMMENT 'Physically counted quantity',
  `VARIANCE_QTY` decimal(12,3) GENERATED ALWAYS AS (
    `COUNTED_QTY` - `SYSTEM_QTY`
  ) VIRTUAL COMMENT 'Difference',
  
  `VARIANCE_VALUE` decimal(15,2) DEFAULT NULL COMMENT 'Financial impact',
  
  -- TOLERANCE & APPROVAL
  `VARIANCE_PERCENTAGE` decimal(5,2) GENERATED ALWAYS AS (
    CASE WHEN `SYSTEM_QTY` > 0 
         THEN ((`COUNTED_QTY` - `SYSTEM_QTY`) / `SYSTEM_QTY`) * 100 
         ELSE NULL END
  ) VIRTUAL,
  
  `WITHIN_TOLERANCE` tinyint(1) DEFAULT NULL COMMENT 'Within acceptable variance',
  `TOLERANCE_PERCENTAGE` decimal(5,2) DEFAULT '2.00' COMMENT 'Acceptable variance %',
  
  -- ACTIONS
  `ADJUSTMENT_REQUIRED` tinyint(1) DEFAULT '0',
  `ADJUSTMENT_CREATED` tinyint(1) DEFAULT '0',
  `ADJUSTMENT_MOVEMENT_ID` mediumint DEFAULT NULL COMMENT 'FK to DOD_STOCK_MOVEMENT',
  
  -- USER & DATES
  `PLANNED_DATE` date DEFAULT NULL,
  `COUNT_DATE` timestamp NULL DEFAULT NULL,
  `COUNTED_BY` varchar(100) DEFAULT NULL,
  `VERIFIED_BY` varchar(100) DEFAULT NULL,
  `APPROVED_BY` varchar(100) DEFAULT NULL,
  `APPROVED_DATE` timestamp NULL DEFAULT NULL,
  
  -- REMARKS
  `COUNT_REMARKS` text DEFAULT NULL,
  `VARIANCE_REASON` text DEFAULT NULL,
  
  -- AUDIT
  `CREATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `UPDATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `DELETED_STATE` char(1) DEFAULT 'N',
  `TENANT_ID` mediumint DEFAULT NULL,
  
  PRIMARY KEY (`ROW_ID`),
  UNIQUE KEY `uk_count_number` (`COUNT_NUMBER`, `TENANT_ID`),
  
  KEY `idx_warehouse` (`WAREHOUSE_ID`),
  KEY `idx_location` (`LOCATION_ID`),
  KEY `idx_product` (`PRD_ID`),
  KEY `idx_stock` (`STOCK_ID`),
  KEY `idx_count_status` (`COUNT_STATUS`),
  KEY `idx_count_date` (`COUNT_DATE`),
  KEY `idx_tenant` (`TENANT_ID`),
  
  CONSTRAINT `fk_count_warehouse` FOREIGN KEY (`WAREHOUSE_ID`) 
    REFERENCES `DOD_WAREHOUSE` (`ROW_ID`),
  CONSTRAINT `fk_count_location` FOREIGN KEY (`LOCATION_ID`) 
    REFERENCES `DOD_WAREHOUSE_LOCATION` (`ROW_ID`),
  CONSTRAINT `fk_count_product` FOREIGN KEY (`PRD_ID`) 
    REFERENCES `DOD_PRD_MASTER` (`ROW_ID`),
  CONSTRAINT `fk_count_stock` FOREIGN KEY (`STOCK_ID`) 
    REFERENCES `DOD_STOCK` (`ROW_ID`),
  CONSTRAINT `fk_count_adjustment` FOREIGN KEY (`ADJUSTMENT_MOVEMENT_ID`) 
    REFERENCES `DOD_STOCK_MOVEMENT` (`ROW_ID`),
  CONSTRAINT `fk_count_tenant` FOREIGN KEY (`TENANT_ID`) 
    REFERENCES `DOD_COMPANY` (`ROW_ID`)
    
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
COMMENT='Cycle counting and stock variance management';")))

(defun migrate-2026Feb-create-stock-reservation-table ()
 "Create customer users table which will enable us to have user profiles for customers who can login and do transactions"
  (flet ((create-table-if-not-exists (table-name ddl)
	   (unless (table-exists-p table-name)
             (clsql:execute-command ddl))))
    (create-table-if-not-exists
     "DOD_STOCK_RESERVATION"
     "CREATE TABLE `DOD_STOCK_RESERVATION` (
  `ROW_ID` mediumint NOT NULL AUTO_INCREMENT,
  `RESERVATION_NUMBER` varchar(50) NOT NULL COMMENT 'Unique reservation ID',
  
  -- STOCK & ORDER REFERENCE
  `STOCK_ID` mediumint NOT NULL COMMENT 'FK to DOD_STOCK',
  `PRD_ID` mediumint NOT NULL COMMENT 'FK to DOD_PRD_MASTER',
  `ORDER_ID` mediumint NOT NULL COMMENT 'FK to sales/production order',
  `ORDER_LINE_ID` mediumint DEFAULT NULL COMMENT 'Order line item',
  `ORDER_NUMBER` varchar(50) NOT NULL COMMENT 'Order reference number',
  
  -- RESERVATION DETAILS
  `QTY_RESERVED` decimal(12,3) NOT NULL COMMENT 'Quantity reserved',
  `QTY_PICKED` decimal(12,3) DEFAULT '0.000' COMMENT 'Quantity already picked',
  `QTY_SHIPPED` decimal(12,3) DEFAULT '0.000' COMMENT 'Quantity shipped',
  
  -- STATUS
  `RESERVATION_STATUS` enum(
    'RESERVED',
    'PARTIALLY_PICKED',
    'PICKED',
    'SHIPPED',
    'CANCELLED',
    'EXPIRED'
  ) DEFAULT 'RESERVED',
  
  -- DATES
  `RESERVATION_DATE` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `REQUIRED_DATE` date DEFAULT NULL COMMENT 'When stock is needed',
  `EXPIRY_DATE` timestamp DEFAULT NULL COMMENT 'Reservation expires after this',
  `PICKED_DATE` timestamp NULL DEFAULT NULL,
  `SHIPPED_DATE` timestamp NULL DEFAULT NULL,
  
  -- USER TRACKING
  `RESERVED_BY` varchar(100) DEFAULT NULL,
  `PICKED_BY` varchar(100) DEFAULT NULL,
  
  -- AUDIT
  `CREATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `UPDATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `DELETED_STATE` char(1) DEFAULT 'N',
  `TENANT_ID` mediumint DEFAULT NULL,
  
  PRIMARY KEY (`ROW_ID`),
  UNIQUE KEY `uk_reservation_number` (`RESERVATION_NUMBER`, `TENANT_ID`),
  
  KEY `idx_stock` (`STOCK_ID`),
  KEY `idx_product` (`PRD_ID`),
  KEY `idx_order` (`ORDER_NUMBER`),
  KEY `idx_status` (`RESERVATION_STATUS`),
  KEY `idx_required_date` (`REQUIRED_DATE`),
  KEY `idx_tenant` (`TENANT_ID`),
  
  CONSTRAINT `fk_reservation_stock` FOREIGN KEY (`STOCK_ID`) 
    REFERENCES `DOD_STOCK` (`ROW_ID`),
  CONSTRAINT `fk_reservation_product` FOREIGN KEY (`PRD_ID`) 
    REFERENCES `DOD_PRD_MASTER` (`ROW_ID`),
  CONSTRAINT `fk_reservation_tenant` FOREIGN KEY (`TENANT_ID`) 
    REFERENCES `DOD_COMPANY` (`ROW_ID`)
    
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
COMMENT='Stock reservations for order fulfillment';")))



(defun migrate-2026Feb-create-stock-movement-table ()
 "Create customer users table which will enable us to have user profiles for customers who can login and do transactions"
  (flet ((create-table-if-not-exists (table-name ddl)
	   (unless (table-exists-p table-name)
             (clsql:execute-command ddl))))
    (create-table-if-not-exists
     "DOD_STOCK_MOVEMENT"
     "CREATE TABLE `DOD_STOCK_MOVEMENT` (
  `ROW_ID` mediumint NOT NULL AUTO_INCREMENT,
  `MOVEMENT_NUMBER` varchar(50) NOT NULL COMMENT 'Unique movement transaction number',
  
  -- STOCK REFERENCE
  `STOCK_ID` mediumint NOT NULL COMMENT 'FK to DOD_STOCK',
  `PRD_ID` mediumint NOT NULL COMMENT 'FK to DOD_PRD_MASTER (denormalized for performance)',
  `BATCH_ID` mediumint DEFAULT NULL COMMENT 'FK to DOD_BATCH_LOT',
  
  -- MOVEMENT TYPE & DIRECTION
  `MOVEMENT_TYPE` enum(
    'GOODS_RECEIPT',         -- Inbound from supplier
    'GOODS_ISSUE',           -- Outbound to customer
    'STOCK_TRANSFER',        -- Between warehouses/locations
    'PRODUCTION_RECEIPT',    -- From manufacturing
    'PRODUCTION_ISSUE',      -- To manufacturing
    'RETURN_FROM_CUSTOMER',  -- Sales return
    'RETURN_TO_VENDOR',      -- Purchase return
    'ADJUSTMENT_POSITIVE',   -- Stock increase (correction)
    'ADJUSTMENT_NEGATIVE',   -- Stock decrease (correction)
    'DAMAGE',                -- Damaged goods
    'EXPIRY',                -- Expired goods removal
    'CYCLE_COUNT',           -- Stock count adjustment
    'SCRAP',                 -- Scrapped/written off
    'SAMPLE',                -- Sample issue
    'RESERVATION',           -- Reserved for order
    'RESERVATION_RELEASE'    -- Reservation cancelled
  ) NOT NULL COMMENT 'Type of stock movement',
  
  `DIRECTION` enum('IN','OUT','TRANSFER','ADJUSTMENT') NOT NULL COMMENT 'Movement direction',
  
  -- QUANTITY
  `QTY_MOVED` decimal(12,3) NOT NULL COMMENT 'Quantity moved (positive or negative)',
  `QTY_BEFORE` decimal(12,3) DEFAULT NULL COMMENT 'Stock before movement',
  `QTY_AFTER` decimal(12,3) DEFAULT NULL COMMENT 'Stock after movement',
  `UOM` varchar(10) DEFAULT NULL COMMENT 'Unit of measure',
  
  -- SOURCE & DESTINATION
  `SOURCE_WAREHOUSE_ID` mediumint DEFAULT NULL COMMENT 'From warehouse',
  `SOURCE_LOCATION_ID` mediumint DEFAULT NULL COMMENT 'From location',
  `DEST_WAREHOUSE_ID` mediumint DEFAULT NULL COMMENT 'To warehouse',
  `DEST_LOCATION_ID` mediumint DEFAULT NULL COMMENT 'To location',
  
  -- REFERENCE DOCUMENTS
  `REFERENCE_TYPE` enum(
    'PURCHASE_ORDER',
    'SALES_ORDER',
    'TRANSFER_ORDER',
    'PRODUCTION_ORDER',
    'RETURN_ORDER',
    'ADJUSTMENT_MEMO',
    'GRN',
    'DELIVERY_NOTE',
    'INVOICE'
  ) DEFAULT NULL COMMENT 'Type of originating document',
  
  `REFERENCE_NUMBER` varchar(50) DEFAULT NULL COMMENT 'PO/SO/TO number',
  `REFERENCE_LINE_NUMBER` smallint DEFAULT NULL COMMENT 'Line item in reference doc',
  `INVOICE_NUMBER` varchar(50) DEFAULT NULL,
  `GRN_NUMBER` varchar(50) DEFAULT NULL COMMENT 'Goods Receipt Note',
  
  -- REASON & APPROVAL
  `REASON_CODE` varchar(20) DEFAULT NULL COMMENT 'Movement reason code',
  `REMARKS` text DEFAULT NULL COMMENT 'Movement description/notes',
  `APPROVED_BY` varchar(100) DEFAULT NULL COMMENT 'Approver name/ID',
  `APPROVED_DATE` timestamp NULL DEFAULT NULL,
  
  -- COST & VALUATION
  `UNIT_COST` decimal(12,2) DEFAULT NULL COMMENT 'Cost per unit at movement',
  `TOTAL_COST` decimal(15,2) DEFAULT NULL COMMENT 'Total value moved',
  `CURRENCY_CODE` char(3) DEFAULT 'INR',
  
  -- GST DETAILS (for movements requiring tax)
  `HSN_CODE` varchar(10) DEFAULT NULL,
  `GST_RATE` decimal(5,2) DEFAULT NULL,
  `SGST_AMOUNT` decimal(12,2) DEFAULT NULL,
  `CGST_AMOUNT` decimal(12,2) DEFAULT NULL,
  `IGST_AMOUNT` decimal(12,2) DEFAULT NULL,
  
  -- E-WAY BILL (for interstate movements)
  `EWAY_BILL_NUMBER` varchar(20) DEFAULT NULL,
  `EWAY_BILL_DATE` date DEFAULT NULL,
  `VEHICLE_NUMBER` varchar(20) DEFAULT NULL,
  `TRANSPORTER_ID` varchar(15) DEFAULT NULL COMMENT 'Transporter GSTIN',
  
  -- USER & DEVICE TRACKING
  `CREATED_BY` varchar(100) NOT NULL COMMENT 'User who created movement',
  `DEVICE_ID` varchar(50) DEFAULT NULL COMMENT 'Handheld/device identifier',
  `MOVEMENT_DATE` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Actual movement date/time',
  
  -- AUDIT
  `CREATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `UPDATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `DELETED_STATE` char(1) DEFAULT 'N',
  `TENANT_ID` mediumint DEFAULT NULL,
  
  PRIMARY KEY (`ROW_ID`),
  UNIQUE KEY `uk_movement_number` (`MOVEMENT_NUMBER`, `TENANT_ID`),
  
  KEY `idx_stock` (`STOCK_ID`),
  KEY `idx_product` (`PRD_ID`),
  KEY `idx_batch` (`BATCH_ID`),
  KEY `idx_movement_type` (`MOVEMENT_TYPE`, `MOVEMENT_DATE`),
  KEY `idx_direction` (`DIRECTION`),
  KEY `idx_reference` (`REFERENCE_TYPE`, `REFERENCE_NUMBER`),
  KEY `idx_source_warehouse` (`SOURCE_WAREHOUSE_ID`),
  KEY `idx_dest_warehouse` (`DEST_WAREHOUSE_ID`),
  KEY `idx_movement_date` (`MOVEMENT_DATE`),
  KEY `idx_created_by` (`CREATED_BY`),
  KEY `idx_tenant` (`TENANT_ID`),
  
  -- COMPOSITE: Movement history queries
  KEY `idx_stock_date` (`STOCK_ID`, `MOVEMENT_DATE`),
  KEY `idx_product_warehouse` (`PRD_ID`, `SOURCE_WAREHOUSE_ID`, `MOVEMENT_DATE`),
  
  CONSTRAINT `fk_movement_stock` FOREIGN KEY (`STOCK_ID`) 
    REFERENCES `DOD_STOCK` (`ROW_ID`),
  CONSTRAINT `fk_movement_product` FOREIGN KEY (`PRD_ID`) 
    REFERENCES `DOD_PRD_MASTER` (`ROW_ID`),
  CONSTRAINT `fk_movement_batch` FOREIGN KEY (`BATCH_ID`) 
    REFERENCES `DOD_BATCH_LOT` (`ROW_ID`),
  CONSTRAINT `fk_movement_source_wh` FOREIGN KEY (`SOURCE_WAREHOUSE_ID`) 
    REFERENCES `DOD_WAREHOUSE` (`ROW_ID`),
  CONSTRAINT `fk_movement_dest_wh` FOREIGN KEY (`DEST_WAREHOUSE_ID`) 
    REFERENCES `DOD_WAREHOUSE` (`ROW_ID`),
  CONSTRAINT `fk_movement_source_loc` FOREIGN KEY (`SOURCE_LOCATION_ID`) 
    REFERENCES `DOD_WAREHOUSE_LOCATION` (`ROW_ID`),
  CONSTRAINT `fk_movement_dest_loc` FOREIGN KEY (`DEST_LOCATION_ID`) 
    REFERENCES `DOD_WAREHOUSE_LOCATION` (`ROW_ID`),
  CONSTRAINT `fk_movement_tenant` FOREIGN KEY (`TENANT_ID`) 
    REFERENCES `DOD_COMPANY` (`ROW_ID`)
    
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
COMMENT='Complete stock movement audit trail with document references';")))


(defun migrate-2026Feb-create-stock-table ()
 "Create customer users table which will enable us to have user profiles for customers who can login and do transactions"
  (flet ((create-table-if-not-exists (table-name ddl)
	   (unless (table-exists-p table-name)
             (clsql:execute-command ddl))))
    (create-table-if-not-exists
     "DOD_STOCK"
     "CREATE TABLE `DOD_STOCK` (
  `ROW_ID` mediumint NOT NULL AUTO_INCREMENT,
  
  -- PRODUCT & LOCATION
  `PRD_ID` mediumint NOT NULL COMMENT 'FK to DOD_PRD_MASTER',
  `WAREHOUSE_ID` mediumint NOT NULL COMMENT 'FK to DOD_WAREHOUSE',
  `LOCATION_ID` mediumint DEFAULT NULL COMMENT 'FK to DOD_WAREHOUSE_LOCATION (shelf/bin)',
  
  -- BATCH/LOT TRACKING
  `BATCH_ID` mediumint DEFAULT NULL COMMENT 'FK to DOD_BATCH_LOT',
  `SERIAL_NUMBER` varchar(100) DEFAULT NULL COMMENT 'For serialized items',
  
  -- QUANTITY TRACKING
  `UNITS_IN_STOCK` decimal(12,3) NOT NULL DEFAULT '0.000' COMMENT 'Available quantity',
  `UNITS_RESERVED` decimal(12,3) DEFAULT '0.000' COMMENT 'Reserved for orders',
  `UNITS_BLOCKED` decimal(12,3) DEFAULT '0.000' COMMENT 'Blocked/quarantine/damaged',
  `UNITS_IN_TRANSIT` decimal(12,3) DEFAULT '0.000' COMMENT 'In transit to this location',
  
  -- STOCK STATUS
  `STOCK_STATUS` enum(
    'AVAILABLE',
    'RESERVED',
    'QUARANTINE',
    'DAMAGED',
    'BLOCKED',
    'EXPIRED',
    'RETURN_TO_VENDOR'
  ) DEFAULT 'AVAILABLE' COMMENT 'Stock quality/availability status',
  
  -- STOCK LEVELS (REPLENISHMENT)
  `MIN_STOCK` decimal(12,3) DEFAULT NULL COMMENT 'Reorder point',
  `MAX_STOCK` decimal(12,3) DEFAULT NULL COMMENT 'Maximum stock level',
  `REORDER_QTY` decimal(12,3) DEFAULT NULL COMMENT 'Economic order quantity',
  
  -- HSN-LEVEL TRACKING (FOR GST)
  `HSN_CODE` varchar(10) DEFAULT NULL COMMENT 'HSN code for GST reporting',
  `GST_RATE` decimal(5,2) DEFAULT NULL COMMENT 'Applicable GST rate %',
  
  -- VALUATION (FOR FIFO/LIFO/WEIGHTED AVG)
  `UNIT_COST` decimal(12,2) DEFAULT NULL COMMENT 'Cost per unit for valuation',
  `TOTAL_VALUE` decimal(15,2) DEFAULT NULL COMMENT 'Total stock value',
  `VALUATION_DATE` date DEFAULT NULL COMMENT 'Last valuation date',
  
  -- EXPIRY MANAGEMENT
  `EXPIRY_DATE` date DEFAULT NULL COMMENT 'Batch expiry date',
  `DAYS_TO_EXPIRY` smallint DEFAULT NULL COMMENT 'Calculated days until expiry',
  
  -- PHYSICAL ATTRIBUTES
  `PALLET_ID` varchar(50) DEFAULT NULL COMMENT 'Pallet/container identifier',
  `GROSS_WEIGHT_KG` decimal(10,2) DEFAULT NULL,
  `NET_WEIGHT_KG` decimal(10,2) DEFAULT NULL,
  `VOLUME_CBM` decimal(10,3) DEFAULT NULL,
  
  -- LAST MOVEMENT TRACKING
  `LAST_MOVEMENT_DATE` timestamp NULL DEFAULT NULL,
  `LAST_MOVEMENT_TYPE` varchar(50) DEFAULT NULL,
  `LAST_COUNTED_DATE` date DEFAULT NULL COMMENT 'Last cycle count date',
  
  -- AUDIT
  `CREATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `UPDATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `DELETED_STATE` char(1) DEFAULT 'N',
  `ACTIVE_FLAG` char(1) DEFAULT 'Y',
  `TENANT_ID` mediumint DEFAULT NULL,
  
  PRIMARY KEY (`ROW_ID`),
  
  -- UNIQUE: One stock record per Product-Warehouse-Location-Batch-Serial combination
  UNIQUE KEY `uk_stock_combination` (`PRD_ID`, `WAREHOUSE_ID`, `LOCATION_ID`, `BATCH_ID`, `SERIAL_NUMBER`, `TENANT_ID`),
  
  KEY `idx_product` (`PRD_ID`),
  KEY `idx_warehouse` (`WAREHOUSE_ID`),
  KEY `idx_location` (`LOCATION_ID`),
  KEY `idx_batch` (`BATCH_ID`),
  KEY `idx_serial` (`SERIAL_NUMBER`),
  KEY `idx_stock_status` (`STOCK_STATUS`, `ACTIVE_FLAG`),
  KEY `idx_expiry` (`EXPIRY_DATE`),
  KEY `idx_hsn` (`HSN_CODE`),
  KEY `idx_tenant` (`TENANT_ID`),
  
  -- COMPOSITE: Common query patterns
  KEY `idx_wh_prd_available` (`WAREHOUSE_ID`, `PRD_ID`, `STOCK_STATUS`, `UNITS_IN_STOCK`),
  KEY `idx_low_stock` (`WAREHOUSE_ID`, `MIN_STOCK`, `UNITS_IN_STOCK`),
  KEY `idx_expiring_soon` (`WAREHOUSE_ID`, `EXPIRY_DATE`, `STOCK_STATUS`),
  
  CONSTRAINT `fk_stock_product` FOREIGN KEY (`PRD_ID`) 
    REFERENCES `DOD_PRD_MASTER` (`ROW_ID`),
  CONSTRAINT `fk_stock_warehouse` FOREIGN KEY (`WAREHOUSE_ID`) 
    REFERENCES `DOD_WAREHOUSE` (`ROW_ID`),
  CONSTRAINT `fk_stock_location` FOREIGN KEY (`LOCATION_ID`) 
    REFERENCES `DOD_WAREHOUSE_LOCATION` (`ROW_ID`),
  CONSTRAINT `fk_stock_batch` FOREIGN KEY (`BATCH_ID`) 
    REFERENCES `DOD_BATCH_LOT` (`ROW_ID`),
  CONSTRAINT `fk_stock_tenant` FOREIGN KEY (`TENANT_ID`) 
    REFERENCES `DOD_COMPANY` (`ROW_ID`)
    
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
COMMENT='Stock inventory with shelf-level, batch, and serial tracking';")))
   

(defun migrate-2026Feb-create-batch-lot-table ()
 "Create customer users table which will enable us to have user profiles for customers who can login and do transactions"
  (flet ((create-table-if-not-exists (table-name ddl)
	   (unless (table-exists-p table-name)
             (clsql:execute-command ddl))))
    (create-table-if-not-exists
     "DOD_BATCH-LOT"
     "CREATE TABLE `DOD_BATCH_LOT` (
  `ROW_ID` mediumint NOT NULL AUTO_INCREMENT,
  `BATCH_NUMBER` varchar(50) NOT NULL COMMENT 'Batch/Lot number from supplier/manufacturer',
  `INTERNAL_BATCH_CODE` varchar(50) DEFAULT NULL COMMENT 'Internal batch tracking code',
  
  -- PRODUCT REFERENCE
  `PRD_ID` mediumint NOT NULL COMMENT 'FK to DOD_PRD_MASTER',
  
  -- BATCH DETAILS
  `MANUFACTURING_DATE` date DEFAULT NULL,
  `EXPIRY_DATE` date DEFAULT NULL COMMENT 'Best before / expiry date',
  `RECEIVED_DATE` date DEFAULT NULL,
  `SUPPLIER_ID` mediumint DEFAULT NULL COMMENT 'FK to supplier/vendor',
  
  -- QUALITY CONTROL
  `QC_STATUS` enum(
    'PENDING',
    'APPROVED',
    'REJECTED',
    'QUARANTINE',
    'HOLD'
  ) DEFAULT 'PENDING' COMMENT 'Quality control status',
  
  `QC_DATE` date DEFAULT NULL,
  `QC_REMARKS` text DEFAULT NULL,
  `QC_INSPECTOR` varchar(100) DEFAULT NULL,
  
  -- BATCH ATTRIBUTES (for tracking/traceability)
  `PURCHASE_ORDER_NUMBER` varchar(50) DEFAULT NULL,
  `INVOICE_NUMBER` varchar(50) DEFAULT NULL,
  `COST_PER_UNIT` decimal(12,2) DEFAULT NULL COMMENT 'Landing cost for valuation',
  `CURRENCY_CODE` char(3) DEFAULT 'INR',
  
  -- CERTIFICATE & COMPLIANCE
  `CERTIFICATE_NUMBER` varchar(100) DEFAULT NULL,
  `COUNTRY_OF_ORIGIN` varchar(50) DEFAULT NULL,
  `REGULATORY_APPROVAL` varchar(200) DEFAULT NULL,
  
  -- AUDIT
  `CREATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `UPDATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `DELETED_STATE` char(1) DEFAULT 'N',
  `ACTIVE_FLAG` char(1) DEFAULT 'Y',
  `TENANT_ID` mediumint DEFAULT NULL,
  
  PRIMARY KEY (`ROW_ID`),
  UNIQUE KEY `uk_batch_product` (`BATCH_NUMBER`, `PRD_ID`, `TENANT_ID`),
  KEY `idx_product` (`PRD_ID`),
  KEY `idx_expiry` (`EXPIRY_DATE`, `ACTIVE_FLAG`),
  KEY `idx_qc_status` (`QC_STATUS`),
  KEY `idx_supplier` (`SUPPLIER_ID`),
  KEY `idx_tenant` (`TENANT_ID`),
  
  CONSTRAINT `fk_batch_product` FOREIGN KEY (`PRD_ID`) 
    REFERENCES `DOD_PRD_MASTER` (`ROW_ID`),
  CONSTRAINT `fk_batch_tenant` FOREIGN KEY (`TENANT_ID`) 
    REFERENCES `DOD_COMPANY` (`ROW_ID`)
    
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
COMMENT='Batch/Lot master for inventory traceability and FEFO';")))


(defun migrate-2026Feb-create-warehouse-location-table ()
 "Create customer users table which will enable us to have user profiles for customers who can login and do transactions"
  (flet ((create-table-if-not-exists (table-name ddl)
	   (unless (table-exists-p table-name)
             (clsql:execute-command ddl))))
    (create-table-if-not-exists
     "DOD_WAREHOUSE_LOCATION"
     "CREATE TABLE `DOD_WAREHOUSE_LOCATION` (
  `ROW_ID` mediumint NOT NULL AUTO_INCREMENT,
  `WAREHOUSE_ID` mediumint NOT NULL COMMENT 'FK to DOD_WAREHOUSE',
  
  -- HIERARCHICAL LOCATION (Warehouse → Zone → Aisle → Rack → Shelf → Bin)
  `LOCATION_CODE` varchar(30) NOT NULL COMMENT 'Unique location code (e.g., WH01-A-R01-S03-B05)',
  `LOCATION_NAME` varchar(100) DEFAULT NULL COMMENT 'Friendly name',
  
  -- HIERARCHY LEVELS
  `ZONE_CODE` varchar(10) DEFAULT NULL COMMENT 'Zone/Area (e.g., A, B, Cold Storage, Quarantine)',
  `AISLE_CODE` varchar(10) DEFAULT NULL COMMENT 'Aisle (e.g., A01, A02)',
  `RACK_CODE` varchar(10) DEFAULT NULL COMMENT 'Rack/Bay (e.g., R01, R02)',
  `SHELF_CODE` varchar(10) DEFAULT NULL COMMENT 'Shelf level (e.g., S01, S02)',
  `BIN_CODE` varchar(10) DEFAULT NULL COMMENT 'Bin/Position (e.g., B01, B02)',
  
  -- PARENT-CHILD RELATIONSHIP (for hierarchical queries)
  `PARENT_LOCATION_ID` mediumint DEFAULT NULL COMMENT 'FK to parent location (self-reference)',
  `LOCATION_LEVEL` enum('ZONE','AISLE','RACK','SHELF','BIN') NOT NULL COMMENT 'Level in hierarchy',
  
  -- LOCATION TYPE & RESTRICTIONS
  `LOCATION_TYPE` enum(
    'STORAGE',
    'PICKING',
    'RECEIVING',
    'SHIPPING',
    'QUARANTINE',
    'DAMAGED',
    'RETURN',
    'STAGING'
  ) DEFAULT 'STORAGE' COMMENT 'Purpose of location',
  
  `STORAGE_TYPE` enum(
    'NORMAL',
    'COLD_STORAGE',
    'REFRIGERATED',
    'FROZEN',
    'HAZMAT',
    'FRAGILE',
    'BULK'
  ) DEFAULT 'NORMAL' COMMENT 'Environmental requirements',
  
  -- CAPACITY MANAGEMENT
  `MAX_WEIGHT_KG` decimal(10,2) DEFAULT NULL COMMENT 'Maximum weight capacity',
  `MAX_VOLUME_CBM` decimal(10,2) DEFAULT NULL COMMENT 'Maximum volume in cubic meters',
  `MAX_PALLETS` tinyint DEFAULT NULL COMMENT 'Maximum number of pallets',
  `MAX_SKUS` smallint DEFAULT NULL COMMENT 'Maximum different SKUs',
  
  -- PHYSICAL DIMENSIONS
  `LENGTH_CM` decimal(8,2) DEFAULT NULL,
  `WIDTH_CM` decimal(8,2) DEFAULT NULL,
  `HEIGHT_CM` decimal(8,2) DEFAULT NULL,
  
  -- RESTRICTIONS
  `ALLOW_MIXED_SKUS` tinyint(1) DEFAULT '1' COMMENT 'Can hold multiple products',
  `ALLOW_MIXED_BATCHES` tinyint(1) DEFAULT '1' COMMENT 'Can hold multiple batches of same SKU',
  `PICKABLE` tinyint(1) DEFAULT '1' COMMENT 'Can be used for order picking',
  `REPLENISHABLE` tinyint(1) DEFAULT '1' COMMENT 'Can be replenished',
  
  -- AUDIT
  `CREATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `UPDATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `DELETED_STATE` char(1) DEFAULT 'N',
  `ACTIVE_FLAG` char(1) DEFAULT 'Y',
  `TENANT_ID` mediumint DEFAULT NULL,
  
  PRIMARY KEY (`ROW_ID`),
  UNIQUE KEY `uk_warehouse_location_code` (`WAREHOUSE_ID`, `LOCATION_CODE`),
  KEY `idx_warehouse` (`WAREHOUSE_ID`),
  KEY `idx_parent` (`PARENT_LOCATION_ID`),
  KEY `idx_location_type` (`LOCATION_TYPE`),
  KEY `idx_storage_type` (`STORAGE_TYPE`),
  KEY `idx_zone` (`WAREHOUSE_ID`, `ZONE_CODE`),
  KEY `idx_pickable` (`WAREHOUSE_ID`, `PICKABLE`, `ACTIVE_FLAG`),
  KEY `idx_tenant` (`TENANT_ID`),
  
  CONSTRAINT `fk_wh_location_warehouse` FOREIGN KEY (`WAREHOUSE_ID`) 
    REFERENCES `DOD_WAREHOUSE` (`ROW_ID`),
  CONSTRAINT `fk_wh_location_parent` FOREIGN KEY (`PARENT_LOCATION_ID`) 
    REFERENCES `DOD_WAREHOUSE_LOCATION` (`ROW_ID`),
  CONSTRAINT `fk_wh_location_tenant` FOREIGN KEY (`TENANT_ID`) 
    REFERENCES `DOD_COMPANY` (`ROW_ID`)
    
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
COMMENT='Warehouse storage locations - shelf/bin level tracking';")))
  

(defun  migrate-2026Feb-update-warehouse-table ()
  "Create customer users table which will enable us to have user profiles for customers who can login and do transactions"
  (flet ((create-table-if-not-exists (table-name ddl)
	   (unless (table-exists-p table-name)
             (clsql:execute-command ddl))))
    (create-table-if-not-exists
     "DOD_WAREHOUSE"
     "CREATE TABLE `DOD_WAREHOUSE` (
  `ROW_ID` mediumint NOT NULL AUTO_INCREMENT,
  
  -- UNIQUE IDENTIFIERS
  `WAREHOUSE_UUID` varchar(36) NOT NULL COMMENT 'Internal UUID for API/system integration',
  `WAREHOUSE_CODE` varchar(20) NOT NULL COMMENT 'Human-readable warehouse identifier (e.g., MH-MUM-WH-001)',
  
  -- BASIC INFO
  `W_NAME` varchar(100) NOT NULL,
  `W_ADDR1` varchar(100) DEFAULT NULL,
  `W_ADDR2` varchar(100) DEFAULT NULL,
  `W_PIN` varchar(6) DEFAULT NULL,
  `W_CITY` varchar(30) DEFAULT NULL,
  `W_STATE` varchar(30) DEFAULT NULL,
  `W_COUNTRY` varchar(30) DEFAULT NULL,
  `W_MANAGER` varchar(100) DEFAULT NULL,
  `W_PHONE` varchar(16) DEFAULT NULL,
  `W_ALT_PHONE` varchar(16) DEFAULT NULL,
  `W_EMAIL` varchar(100) DEFAULT NULL,
  
  -- AUDIT FIELDS
  `CREATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `UPDATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `DELETED_STATE` char(1) DEFAULT 'N',
  `ACTIVE_FLAG` char(1) DEFAULT 'Y',
  
  -- MULTI-TENANCY
  `TENANT_ID` mediumint DEFAULT NULL COMMENT 'Company/Organization tenant',
  
  -- OWNERSHIP MODEL (NEW FIELDS)
  `OWNERSHIP_TYPE` enum(
    'SELLER_OWNED',
    'BUYER_OWNED',
    'THIRD_PARTY',
    'PLATFORM_OWNED',
    'BONDED',
    'CONTRACT_MFG'
  ) NOT NULL DEFAULT 'SELLER_OWNED' COMMENT 'Who owns the warehouse facility',
  
  `OWNER_ENTITY_TYPE` enum(
    'SELLER',
    'BUYER',
    'PLATFORM',
    'THIRD_PARTY_LOGISTICS',
    'GOVERNMENT'
  ) NOT NULL DEFAULT 'SELLER' COMMENT 'Type of entity that owns warehouse',
  
  `OWNER_ENTITY_ID` mediumint NOT NULL COMMENT 'FK to owner entity (vendor_id, buyer_company_id, 3pl_provider_id, etc.)',
  
  `OPERATOR_ENTITY_TYPE` enum(
    'SELLER',
    'BUYER',
    'PLATFORM',
    'THIRD_PARTY_LOGISTICS'
  ) DEFAULT NULL COMMENT 'Who manages day-to-day operations (may differ from owner)',
  
  `OPERATOR_ENTITY_ID` mediumint DEFAULT NULL COMMENT 'FK to operator entity if different from owner',
  
  `LEGAL_ENTITY_TYPE` enum(
    'SELLER',
    'BUYER',
    'PLATFORM',
    'THIRD_PARTY_LOGISTICS'
  ) NOT NULL DEFAULT 'SELLER' COMMENT 'Entity registered for GST/tax purposes',
  
  -- GST COMPLIANCE
  `WAREHOUSE_GSTIN` varchar(15) NOT NULL COMMENT 'GST identification number',
  `GSTIN_STATUS` enum('ACTIVE','CANCELLED','SUSPENDED') DEFAULT 'ACTIVE',
  `LEGAL_NAME` varchar(200) DEFAULT NULL COMMENT 'Legal business name as per GST registration',
  `IS_PRIMARY_LOCATION` tinyint(1) DEFAULT '0' COMMENT 'Principal place of business for GSTIN',
  `STATE_CODE` varchar(2) NOT NULL COMMENT 'GST state code (01-37), first 2 digits of GSTIN',
  `REGISTRATION_TYPE` enum(
    'REGULAR',
    'COMPOSITION',
    'SEZ',
    'EXPORT_WAREHOUSE',
    'UNREGISTERED'
  ) DEFAULT 'REGULAR',
  `PAN_NUMBER` varchar(10) DEFAULT NULL COMMENT 'PAN of legal entity if separate from owner',
  
  -- WAREHOUSE CLASSIFICATION
  `WAREHOUSE_TYPE` enum(
    'OWN',
    'THIRD_PARTY',
    'CONSIGNMENT',
    'BRANCH',
    'GODOWN'
  ) DEFAULT 'OWN' COMMENT 'Physical warehouse type/arrangement',
  
  `WAREHOUSE_PURPOSE` enum(
    'SALES',
    'STOCK_TRANSFER',
    'MANUFACTURING',
    'BOTH'
  ) DEFAULT 'SALES',
  
  -- LOGISTICS & COMPLIANCE
  `DEFAULT_TRANSPORTER_ID` varchar(15) DEFAULT NULL COMMENT 'Default transporter GSTIN',
  `DEFAULT_TRANSPORTER_NAME` varchar(200) DEFAULT NULL,
  `EWAY_BILL_ENABLED` tinyint(1) DEFAULT '1' COMMENT 'Generate e-way bills from this warehouse',
  
  -- LOCATION COORDINATES
  `LATITUDE` decimal(10,8) DEFAULT NULL COMMENT 'GPS latitude for e-way bill distance calculation',
  `LONGITUDE` decimal(11,8) DEFAULT NULL COMMENT 'GPS longitude',
  
  -- INVENTORY MANAGEMENT
  `VALUATION_METHOD` enum(
    'FIFO',
    'LIFO',
    'WEIGHTED_AVG'
  ) DEFAULT 'FIFO' COMMENT 'Stock valuation method for transfers',
  
  `HSN_WISE_STOCK` tinyint(1) DEFAULT '0' COMMENT 'Maintain HSN-level stock tracking for GST compliance',
  
  -- PRIMARY KEY & CONSTRAINTS
  PRIMARY KEY (`ROW_ID`),
  
  -- UNIQUE CONSTRAINTS
  UNIQUE KEY `uk_warehouse_uuid` (`WAREHOUSE_UUID`),
  UNIQUE KEY `uk_warehouse_code` (`WAREHOUSE_CODE`),
  
  -- COMPOSITE UNIQUE: Prevent duplicate warehouse names per GSTIN per tenant
  UNIQUE KEY `uk_gstin_name_tenant` (`WAREHOUSE_GSTIN`, `W_NAME`, `TENANT_ID`),
  
  -- INDEXES FOR PERFORMANCE
  KEY `idx_tenant` (`TENANT_ID`),
  KEY `idx_gstin` (`WAREHOUSE_GSTIN`),
  KEY `idx_state_code` (`STATE_CODE`),
  KEY `idx_warehouse_type` (`WAREHOUSE_TYPE`),
  KEY `idx_active_deleted` (`ACTIVE_FLAG`, `DELETED_STATE`),
  KEY `idx_primary_location` (`IS_PRIMARY_LOCATION`, `WAREHOUSE_GSTIN`),
  
  -- NEW INDEXES FOR OWNERSHIP QUERIES
  KEY `idx_ownership_type` (`OWNERSHIP_TYPE`),
  KEY `idx_owner` (`OWNER_ENTITY_TYPE`, `OWNER_ENTITY_ID`),
  KEY `idx_operator` (`OPERATOR_ENTITY_TYPE`, `OPERATOR_ENTITY_ID`),
  KEY `idx_legal_entity` (`LEGAL_ENTITY_TYPE`),
  
  -- COMPOSITE INDEX: Common query pattern - find all warehouses owned by entity
  KEY `idx_owner_active` (`OWNER_ENTITY_TYPE`, `OWNER_ENTITY_ID`, `ACTIVE_FLAG`, `DELETED_STATE`),
  
  -- FOREIGN KEY CONSTRAINTS
  CONSTRAINT `fk_warehouse_tenant` FOREIGN KEY (`TENANT_ID`) 
    REFERENCES `DOD_COMPANY` (`ROW_ID`) 
    ON DELETE RESTRICT 
    ON UPDATE CASCADE
  
) ENGINE=InnoDB AUTO_INCREMENT=47 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
COMMENT='Warehouse master with flexible ownership model supporting seller/buyer/3PL/platform ownership';")))

