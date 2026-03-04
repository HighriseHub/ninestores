;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)

(defun migrate-2026Jan-create-organization-tables ()
  "Create organization table."
  ;; Helper macro to check and create table
  (flet ((create-table-if-not-exists (table-name ddl)
           (unless (table-exists-p table-name)
             (clsql:execute-command ddl))))

    ;; 1. DOD_ORGANIZATIONS
    (create-table-if-not-exists
     "DOD_ORGANIZATIONS"
     "CREATE TABLE DOD_ORGANIZATIONS (
       row_id mediumint PRIMARY KEY AUTO_INCREMENT,
        tenant_id mediumint NOT NULL COMMENT 'Tenant company that owns this data',
        org_code VARCHAR(50) COMMENT 'Unique organization code',
    org_name VARCHAR(255) NOT NULL COMMENT 'Trading/DBA name',
    display_name VARCHAR(255) COMMENT 'UI display name (e.g., \"ABC Corp (Distributor)\")',
    legal_name VARCHAR(255) COMMENT 'Legal registered name',
        parent_org_id mediumint COMMENT 'Parent organization for subsidiaries/franchises',
    
    tax_id VARCHAR(100) COMMENT 'Tax ID/EIN/VAT number',
    registration_number VARCHAR(100) COMMENT 'Business registration number',
    legal_structure ENUM('SOLE_PROPRIETOR', 'PARTNERSHIP', 'LLC', 'CORPORATION', 'NON_PROFIT', 'GOVERNMENT', 'OTHER') COMMENT 'Legal entity type',
    
    email VARCHAR(255),
    phone VARCHAR(50),
    fax VARCHAR(50),
    website VARCHAR(255),
    
    address_line1 VARCHAR(255),
    address_line2 VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100) DEFAULT 'USA',
    postal_code VARCHAR(20),
    
    default_currency_code VARCHAR(3) DEFAULT 'USD',
    fiscal_year_end VARCHAR(5) COMMENT 'MM-DD format, e.g., 12-31',
    
    industry VARCHAR(100),
    company_size ENUM('MICRO', 'SMALL', 'MEDIUM', 'LARGE', 'ENTERPRISE'),
    annual_revenue DECIMAL(15,2),
    employee_count INT,
    
    external_id VARCHAR(100) COMMENT 'External system reference ID',
    external_system VARCHAR(50) COMMENT 'Source system (QuickBooks, Shopify, etc.)',
    
    status ENUM('ACTIVE', 'INACTIVE', 'SUSPENDED', 'PENDING_APPROVAL') DEFAULT 'ACTIVE',
    is_verified BOOLEAN DEFAULT FALSE COMMENT 'Whether organization details are verified',
    notes TEXT COMMENT 'Internal notes about this organization',
    
    deleted_state char(1) NULL,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by MEDIUMINT,
    updated_by mediumint,
    
    INDEX idx_tenant_id (tenant_id),
    INDEX idx_org_code (tenant_id, org_code),
    INDEX idx_org_name (org_name),
    INDEX idx_tax_id (tax_id),
    INDEX idx_status (status),
    INDEX idx_company_status (tenant_id, status),
    INDEX idx_external (external_system, external_id),
    INDEX idx_parent_org (parent_org_id),
    
    UNIQUE KEY uk_company_org_code (tenant_id, org_code),
    
    CONSTRAINT fk_org_company FOREIGN KEY (tenant_id) 
        REFERENCES DOD_COMPANY(row_id) ON DELETE CASCADE,
    CONSTRAINT fk_org_parent FOREIGN KEY (parent_org_id) 
        REFERENCES DOD_ORGANIZATIONS(row_id) ON DELETE SET NULL,
    CONSTRAINT fk_org_created_by FOREIGN KEY (created_by) 
        REFERENCES DOD_USERS(row_id) ON DELETE SET NULL,
    CONSTRAINT fk_org_updated_by FOREIGN KEY (updated_by) 
        REFERENCES DOD_USERS(row_id) ON DELETE SET NULL
 ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Master organization/party table for all legal entities';")

    (create-table-if-not-exists
     "DOD_ORG_RELATIONS"
     "CREATE TABLE DOD_ORG_RELATIONS (
    
    row_id mediumint PRIMARY KEY AUTO_INCREMENT,
    
    tenant_id mediumint NOT NULL COMMENT 'The tenant company',
    org_id mediumint NOT NULL COMMENT 'The organization being related',
    relation_type ENUM('PRIMARY', 'VENDOR', 'CUSTOMER', 'BOTH') NOT NULL COMMENT 'PRIMARY=own company, VENDOR=buy from, CUSTOMER=sell to, BOTH=buy and sell',
    
    business_type ENUM(
        'B2B_CUSTOMER',
        'DISTRIBUTOR',
        'WHOLESALER',
        'RETAILER',
        'RESELLER',
        'DROPSHIPPER',
        'MANUFACTURER',
        'SUPPLIER',
        'SERVICE_PROVIDER',
        'CONTRACTOR',
        'PARTNER',
        'GOVERNMENT',
        'NON_PROFIT'
    ) COMMENT 'Type of business relationship',
    
    
    vendor_profile_id mediumint COMMENT 'Link to legacy DOD_VEND_PROFILE',
    customer_profile_id mediumint COMMENT 'Link to DOD_CUST_PROFILE (for B2C migrated customers)',
    
    
    customer_code VARCHAR(50) COMMENT 'Customer account number',
    vendor_code VARCHAR(50) COMMENT 'Vendor account number',
    
        price_tier VARCHAR(50) COMMENT 'Pricing tier',
    discount_percentage DECIMAL(5,2) COMMENT 'Default discount percentage',
    commission_percentage DECIMAL(5,2) COMMENT 'Commission for distributors/resellers',
    
    
    customer_credit_limit DECIMAL(15,2) COMMENT 'Credit limit for this customer',
    customer_payment_terms VARCHAR(100) COMMENT 'e.g., NET30, NET60, COD',
    customer_payment_method ENUM('CREDIT_CARD', 'ACH', 'WIRE', 'CHECK', 'COD', 'NET_TERMS'),
    
    
    distributor_level ENUM('TIER1', 'TIER2', 'TIER3', 'EXCLUSIVE', 'NON_EXCLUSIVE'),
    territory TEXT COMMENT 'Geographic territory (JSON array or comma-separated)',
    can_dropship BOOLEAN DEFAULT FALSE,
    min_order_quantity INT,
    min_order_value DECIMAL(15,2),
    
    
    resale_certificate VARCHAR(100) COMMENT 'Resale certificate number',
    resale_cert_expiry DATE,
    is_tax_exempt BOOLEAN DEFAULT FALSE,
    tax_exempt_reason VARCHAR(255),
    
    vendor_payment_terms VARCHAR(100) COMMENT 'e.g., NET30, 2/10 NET30',
    vendor_payment_method ENUM('ACH', 'WIRE', 'CHECK', 'CREDIT_CARD'),
    vendor_credit_limit DECIMAL(15,2) COMMENT 'Credit limit vendor extends to us',
    
    default_lead_time_days INT,
    shipping_method VARCHAR(100),
    incoterms VARCHAR(20) COMMENT 'FOB, CIF, EXW, etc.',
    
    vendor_category VARCHAR(100) COMMENT 'Raw materials, finished goods, services',
    is_preferred_vendor BOOLEAN DEFAULT FALSE,
    vendor_rating DECIMAL(3,2) COMMENT 'Rating 0.00-5.00',
    
    default_currency_code VARCHAR(3) DEFAULT 'USD',
    
    primary_contact_id mediumint COMMENT 'FK to DOD_CONTACTS',
    billing_contact_id mediumint COMMENT 'FK to DOD_CONTACTS',
    shipping_contact_id mediumint COMMENT 'FK to DOD_CONTACTS',
    
    
    billing_address_id mediumint COMMENT 'FK to DOD_ADDRESSES',
    shipping_address_id mediumint COMMENT 'FK to DOD_ADDRESSES',
    
    external_id VARCHAR(100) COMMENT 'External system reference',
    external_system VARCHAR(50) COMMENT 'Source system name',
    
    status ENUM('ACTIVE', 'INACTIVE', 'SUSPENDED', 'PENDING_APPROVAL', 'BLACKLISTED') DEFAULT 'ACTIVE',
    relationship_start_date DATE COMMENT 'When relationship began',
    relationship_end_date DATE COMMENT 'When relationship ended',
    
    account_manager_id mediumint COMMENT 'Sales rep or procurement officer',
    tags JSON COMMENT 'Additional tags for filtering',
    internal_notes TEXT,
        deleted_state char(1)  NULL,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by mediumint,
    updated_by mediumint,
    
    INDEX idx_tenant_id (tenant_id),
    INDEX idx_org_id (org_id),
    INDEX idx_relation_type (relation_type),
    INDEX idx_business_type (business_type),
    INDEX idx_company_relation (tenant_id, relation_type, status),
    INDEX idx_company_org (tenant_id, org_id),
    INDEX idx_customer_code (tenant_id, customer_code),
    INDEX idx_vendor_code (tenant_id, vendor_code),
    INDEX idx_external (external_system, external_id),
    
    UNIQUE KEY uk_company_org_relation (tenant_id, org_id, relation_type),
    UNIQUE KEY uk_company_customer_code (tenant_id, customer_code),
    UNIQUE KEY uk_company_vendor_code (tenant_id, vendor_code),
    
    CONSTRAINT fk_rel_company FOREIGN KEY (tenant_id) 
        REFERENCES DOD_COMPANY(row_id) ON DELETE CASCADE,
    CONSTRAINT fk_rel_org FOREIGN KEY (org_id) 
        REFERENCES DOD_ORGANIZATIONS(row_id) ON DELETE CASCADE,
    CONSTRAINT fk_rel_vendor_profile FOREIGN KEY (vendor_profile_id) 
        REFERENCES DOD_VEND_PROFILE(row_id) ON DELETE SET NULL,
    CONSTRAINT fk_rel_customer_profile FOREIGN KEY (customer_profile_id) 
        REFERENCES DOD_CUST_PROFILE(row_id) ON DELETE SET NULL,
    CONSTRAINT fk_rel_created_by FOREIGN KEY (created_by) 
        REFERENCES DOD_USERS(row_id) ON DELETE SET NULL,
    CONSTRAINT fk_rel_updated_by FOREIGN KEY (updated_by) 
        REFERENCES DOD_USERS(row_id) ON DELETE SET NULL,
    CONSTRAINT fk_rel_account_manager FOREIGN KEY (account_manager_id) 
        REFERENCES DOD_USERS(row_id) ON DELETE SET NULL
 ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Relationship context defining how organizations relate to each company';")))


(defun migrate-2026Jan-create-contacts&addresses-tables ()
  "Create contacts and addresses for an organizatin"
  (flet ((create-table-if-not-exists (table-name ddl)
           (unless (table-exists-p table-name)
             (clsql:execute-command ddl))))

    (create-table-if-not-exists
     "DOD_CONTACTS"
     "CREATE TABLE DOD_CONTACTS (
    -- Primary Key
    row_id MEDIUMINT PRIMARY KEY AUTO_INCREMENT,
    -- Ownership
    org_id MEDIUMINT NOT NULL COMMENT 'Organization this contact belongs to',
    tenant_id MEDIUMINT NOT NULL COMMENT 'Tenant company',
    -- Personal Information
    prefix VARCHAR(20) COMMENT 'Mr., Mrs., Dr., etc.',
    first_name VARCHAR(100) NOT NULL,
    middle_name VARCHAR(100),
    last_name VARCHAR(100) NOT NULL,
    suffix VARCHAR(20) COMMENT 'Jr., Sr., III, etc.',
    display_name VARCHAR(255) COMMENT 'Preferred display name',
    
    -- Professional Information
    job_title VARCHAR(100),
    department VARCHAR(100),
    reports_to_contact_id MEDIUMINT COMMENT 'Manager/supervisor',
    
    -- Contact Details
    email VARCHAR(255),
    email_secondary VARCHAR(255),
    phone VARCHAR(50),
    phone_extension VARCHAR(20),
    mobile VARCHAR(50),
    fax VARCHAR(50),
    
    -- Social/Professional Links
    linkedin_url VARCHAR(500),
    
    -- Communication Preferences
    preferred_contact_method ENUM('EMAIL', 'PHONE', 'MOBILE', 'FAX') DEFAULT 'EMAIL',
    language_preference VARCHAR(10) DEFAULT 'en',
    timezone VARCHAR(50),
    
    -- Flags/Roles
    is_primary BOOLEAN DEFAULT FALSE COMMENT 'Primary contact for this org',
    is_billing_contact BOOLEAN DEFAULT FALSE,
    is_shipping_contact BOOLEAN DEFAULT FALSE,
    is_technical_contact BOOLEAN DEFAULT FALSE,
    is_decision_maker BOOLEAN DEFAULT FALSE,
    can_approve_orders BOOLEAN DEFAULT FALSE,
    
    -- Portal Access (if applicable)
    portal_user_id MEDIUMINT COMMENT 'FK to user table if they have portal access',
    
    -- Notes
    notes TEXT COMMENT 'Internal notes about this contact',
    
    -- Status
    status ENUM('ACTIVE', 'INACTIVE', 'DO_NOT_CONTACT') DEFAULT 'ACTIVE',
    -- Soft Delete
    deleted_state char(1) NULL,
    -- Audit Fields
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by MEDIUMINT,
    updated_by MEDIUMINT,
    -- Indexes
    INDEX idx_org_id (org_id),
    INDEX idx_tenant_id (tenant_id),
    INDEX idx_email (email),
    INDEX idx_name (last_name, first_name),
    INDEX idx_status (status, updated_at),
    INDEX idx_primary (org_id, is_primary),
    
    -- Unique Constraints
    UNIQUE KEY uk_org_email (org_id, email),
    
    -- Foreign Keys
    CONSTRAINT fk_contact_org FOREIGN KEY (org_id) 
        REFERENCES DOD_ORGANIZATIONS(row_id) ON DELETE CASCADE,
    CONSTRAINT fk_contact_company FOREIGN KEY (tenant_id) 
        REFERENCES DOD_COMPANY(row_id) ON DELETE CASCADE,
    CONSTRAINT fk_contact_reports_to FOREIGN KEY (reports_to_contact_id) 
        REFERENCES DOD_CONTACTS(row_id) ON DELETE SET NULL,
    CONSTRAINT fk_contact_created_by FOREIGN KEY (created_by) 
        REFERENCES DOD_USERS(row_id) ON DELETE SET NULL,
    CONSTRAINT fk_contact_updated_by FOREIGN KEY (updated_by) 
        REFERENCES DOD_USERS(row_id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Contacts/people within organizations';")

    (create-table-if-not-exists
     "DOD_ADDRESSES"
     "CREATE TABLE DOD_ADDRESSES (
    -- Primary Key
    row_id MEDIUMINT PRIMARY KEY AUTO_INCREMENT,
    
    -- Ownership
    org_id MEDIUMINT NOT NULL COMMENT 'Organization this address belongs to',
    tenant_id MEDIUMINT NOT NULL COMMENT 'Tenant company',
    
    -- Address Type
    address_type ENUM('BILLING', 'SHIPPING', 'MAILING', 'OFFICE', 'WAREHOUSE', 'PLANT', 'RETAIL') NOT NULL,
    address_name VARCHAR(100) COMMENT 'Friendly name: \"Main Warehouse\", \"NYC Office\"',
    
    -- Address Fields
    address_line1 VARCHAR(255) NOT NULL,
    address_line2 VARCHAR(255),
    address_line3 VARCHAR(255) COMMENT 'For international addresses',
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100),
    country VARCHAR(100) NOT NULL DEFAULT 'USA',
    postal_code VARCHAR(20) NOT NULL,
    
    -- Geolocation (optional but useful for shipping)
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    
    -- Contact at this address
    contact_name VARCHAR(255) COMMENT 'Site contact name',
    contact_phone VARCHAR(50),
    contact_email VARCHAR(255),
    
    -- Delivery Instructions
    delivery_instructions TEXT COMMENT 'Gate codes, special instructions',
    
    -- Flags
    is_default BOOLEAN DEFAULT FALSE COMMENT 'Default address for this type',
    is_verified BOOLEAN DEFAULT FALSE COMMENT 'Address verification status',
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Soft Delete
    deleted_state char(1) NULL,
    
    -- Audit Fields
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by MEDIUMINT,
    updated_by MEDIUMINT,
    
    -- Indexes
    INDEX idx_org_id (org_id),
    INDEX idx_tenant_id (tenant_id),
    INDEX idx_address_type (address_type),
    INDEX idx_org_type (org_id, address_type),
    INDEX idx_default (org_id, address_type, is_default),
    INDEX idx_postal_code (postal_code),
    INDEX idx_city_state (city, state),
    
    -- Foreign Keys
    CONSTRAINT fk_addr_org FOREIGN KEY (org_id) 
        REFERENCES DOD_ORGANIZATIONS(row_id) ON DELETE CASCADE,
    CONSTRAINT fk_addr_company FOREIGN KEY (tenant_id) 
        REFERENCES DOD_COMPANY(row_id) ON DELETE CASCADE,
    CONSTRAINT fk_addr_created_by FOREIGN KEY (created_by) 
        REFERENCES DOD_USERS(row_id) ON DELETE SET NULL,
    CONSTRAINT fk_addr_updated_by FOREIGN KEY (updated_by) 
        REFERENCES DOD_USERS(row_id) ON DELETE SET NULL    
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Multiple addresses per organization';")))

