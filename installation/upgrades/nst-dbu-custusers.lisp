;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)


(defun migrate-2026Feb-update-customer-users-table ()
  (let ((verifyscript (format nil "SELECT 
    COUNT(*) as total_customers,
    (SELECT COUNT(*) FROM DOD_CUSTOMER_USERS WHERE IS_PRIMARY_USER = 'Y') as migrated_users
FROM DOD_CUST_PROFILE 
WHERE active_flag = 'Y' AND DELETED_STATE != 'Y';"))
	(insertscript (format nil "INSERT INTO DOD_CUSTOMER_USERS (
    CUSTOMER_ID,
    USERNAME,
    PASSWORD,
    SALT,
    FULL_NAME,
    EMAIL,
    PHONE,
    DESIGNATION,
    USER_ROLE,
    IS_PRIMARY_USER,
    IS_ACTIVE,
    EMAIL_VERIFIED,
    
    -- Grant full permissions to existing users (they're owners)
    CAN_CREATE_ORDER,
    CAN_CREATE_BOM,
    CAN_CREATE_PR,
    CAN_APPROVE_PR,
    CAN_APPROVE_ORDER,
    CAN_MANAGE_WALLET,
    CAN_VIEW_INVOICES,
    CAN_DOWNLOAD_REPORTS,
    CAN_MANAGE_USERS,
    CAN_MANAGE_COMPANY_PROFILE,
    
    TENANT_ID,
    CREATED,
    DELETED_STATE
)
SELECT 
    ROW_ID as CUSTOMER_ID,
    RPAD(REPLACE(name, ' ', ''), 10, 'x'),
    PASSWORD,
    SALT,
    COALESCE(FULLNAME, NAME, CONCAT(FIRSTNAME, ' ', LASTNAME)) as FULL_NAME,
    EMAIL,
    PHONE,
    'Owner' as DESIGNATION,
    'OWNER' as USER_ROLE,
    'Y' as IS_PRIMARY_USER,
    active_flag as IS_ACTIVE,
    EMAIL_ADD_VERIFIED as EMAIL_VERIFIED,
    
    -- Full permissions
    'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y',
    
    TENANT_ID,
    CREATED,
    COALESCE(DELETED_STATE, 'N')
FROM DOD_CUST_PROFILE
WHERE active_flag = 'Y'
  AND DELETED_STATE != 'Y';")))
    (when (table-exists-p "DOD_CUSTOMER_USERS")
      (clsql:execute-command insertscript))
    (format T "Run this script after. ~A" verifyscript)))

    

(defun migrate-2026Feb-create-customer-users-table ()
  "Create customer users table which will enable us to have user profiles for customers who can login and do transactions"
  (flet ((create-table-if-not-exists (table-name ddl)
	   (unless (table-exists-p table-name)
             (clsql:execute-command ddl))))
    (create-table-if-not-exists
     "DOD_CUSTOMER_USERS"
     "CREATE TABLE DOD_CUSTOMER_USERS (
    -- Primary Key
    ROW_ID MEDIUMINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        -- Link to Company
    CUSTOMER_ID MEDIUMINT NOT NULL COMMENT 'FK to DOD_CUST_PROFILE - the company this user belongs to',
        -- Login Credentials
    USERNAME VARCHAR(100) NOT NULL COMMENT 'Email or unique username for login',
    PASSWORD VARCHAR(128) NOT NULL COMMENT 'Hashed password',
    SALT VARCHAR(128) COMMENT 'Password salt for hashing',
        -- User Identity
    FULL_NAME VARCHAR(255) NOT NULL COMMENT 'User full name',
    EMAIL VARCHAR(255) NOT NULL COMMENT 'User email address',
    PHONE VARCHAR(30) COMMENT 'User phone number',
    DESIGNATION VARCHAR(100) COMMENT 'Job title/role in company',
    DEPARTMENT VARCHAR(100) COMMENT 'Which department (Production, Accounts, etc.)',
    
    -- User Role & Permissions
    USER_ROLE ENUM(
        'OWNER',                    -- Full access, company owner
        'ADMIN',                    -- Full access, delegated by owner
        'PROCUREMENT_MANAGER',      -- Can create & approve orders, manage BOMs
        'PROCUREMENT_EXECUTIVE',    -- Can create orders, create PRs
        'PRODUCTION_MANAGER',       -- Can create BOMs, create PRs for production
        'ACCOUNTANT',              -- View invoices, download reports, GST compliance
        'FINANCE_APPROVER',        -- Approve large orders/PRs
        'WAREHOUSE_MANAGER',       -- Track shipments, mark goods received
        'VIEWER'                   -- Read-only access
    ) NOT NULL DEFAULT 'VIEWER',
    
    -- Granular Permissions (for flexibility beyond preset roles)
    CAN_CREATE_ORDER CHAR(1) DEFAULT 'N' COMMENT 'Can place orders directly',
    CAN_CREATE_BOM CHAR(1) DEFAULT 'N' COMMENT 'Can create/edit BOM templates',
    CAN_CREATE_PR CHAR(1) DEFAULT 'N' COMMENT 'Can create purchase requisitions',
    CAN_APPROVE_PR CHAR(1) DEFAULT 'N' COMMENT 'Can approve purchase requisitions',
    CAN_APPROVE_ORDER CHAR(1) DEFAULT 'N' COMMENT 'Can approve orders (if approval workflow enabled)',
    CAN_MANAGE_WALLET CHAR(1) DEFAULT 'N' COMMENT 'Can add funds to vendor wallets',
    CAN_VIEW_INVOICES CHAR(1) DEFAULT 'Y' COMMENT 'Can view company invoices',
    CAN_DOWNLOAD_REPORTS CHAR(1) DEFAULT 'N' COMMENT 'Can download GST reports, statements',
    CAN_MANAGE_USERS CHAR(1) DEFAULT 'N' COMMENT 'Can invite/manage other users',
    CAN_MANAGE_COMPANY_PROFILE CHAR(1) DEFAULT 'N' COMMENT 'Can edit company details, GSTIN, etc.',
    
    -- Approval Limits
    ORDER_APPROVAL_LIMIT DECIMAL(15,2) COMMENT 'Max order amount can approve (NULL = no limit)',
    PR_APPROVAL_LIMIT DECIMAL(15,2) COMMENT 'Max PR amount can approve (NULL = no limit)',
    DAILY_ORDER_LIMIT DECIMAL(15,2) COMMENT 'Max can order per day (optional spending control)',
    MONTHLY_ORDER_LIMIT DECIMAL(15,2) COMMENT 'Max can order per month',
    
    -- Vendor Restrictions (optional)
    ALLOWED_VENDORS TEXT COMMENT 'Comma-separated vendor IDs user can order from (NULL = all)',
    RESTRICTED_VENDORS TEXT COMMENT 'Vendor IDs user cannot order from',
    ALLOWED_CATEGORIES TEXT COMMENT 'Category IDs user can order from (NULL = all)',
    
    -- User Status
    IS_ACTIVE CHAR(1) NOT NULL DEFAULT 'Y' COMMENT 'Y/N - can this user login',
    IS_PRIMARY_USER CHAR(1) NOT NULL DEFAULT 'N' COMMENT 'Y/N - first user created (company owner)',
    EMAIL_VERIFIED CHAR(1) DEFAULT 'N' COMMENT 'Has user verified email',
    PHONE_VERIFIED CHAR(1) DEFAULT 'N' COMMENT 'Has user verified phone',
    
    -- Password Management
    PASSWORD_RESET_TOKEN VARCHAR(128) COMMENT 'Token for password reset',
    PASSWORD_RESET_EXPIRY TIMESTAMP NULL COMMENT 'When reset token expires',
    LAST_PASSWORD_CHANGE TIMESTAMP NULL COMMENT 'When password was last changed',
    FORCE_PASSWORD_CHANGE CHAR(1) DEFAULT 'N' COMMENT 'Force user to change password on next login',
    
    -- Session & Security
    LAST_LOGIN_AT TIMESTAMP NULL COMMENT 'Last successful login timestamp',
    LAST_LOGIN_IP VARCHAR(45) COMMENT 'Last login IP address (supports IPv6)',
    FAILED_LOGIN_ATTEMPTS INT DEFAULT 0 COMMENT 'Count of failed login attempts',
    LOCKED_UNTIL TIMESTAMP NULL COMMENT 'Account locked until this time (after too many failed logins)',
    
    -- Notifications
    EMAIL_NOTIFICATIONS CHAR(1) DEFAULT 'Y' COMMENT 'Send email notifications',
    SMS_NOTIFICATIONS CHAR(1) DEFAULT 'N' COMMENT 'Send SMS notifications',
    NOTIFICATION_PREFERENCES TEXT COMMENT 'JSON of notification preferences',
    
    -- Audit Trail
    CREATED TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UPDATED TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CREATED_BY MEDIUMINT COMMENT 'Which user created this user account',
    UPDATED_BY MEDIUMINT COMMENT 'Which user last updated this account',
    
    -- Multi-tenancy
    TENANT_ID MEDIUMINT NOT NULL COMMENT 'Tenant ID for platform isolation',
    
    -- Soft Delete
    DELETED_STATE CHAR(1) DEFAULT 'N' COMMENT 'N=Active, Y=Deleted',
    DELETED_AT TIMESTAMP NULL COMMENT 'When was this user deleted',
    DELETED_BY MEDIUMINT COMMENT 'Who deleted this user',
    
    -- Indexes for Performance
    UNIQUE KEY uk_username (USERNAME, DELETED_STATE),
    UNIQUE KEY uk_email (EMAIL, CUSTOMER_ID, DELETED_STATE),
    INDEX idx_customer_id (CUSTOMER_ID),
    INDEX idx_email (EMAIL),
    INDEX idx_phone (PHONE),
    INDEX idx_user_role (USER_ROLE),
    INDEX idx_is_active (IS_ACTIVE),
    INDEX idx_tenant_id (TENANT_ID),
    INDEX idx_customer_active (CUSTOMER_ID, IS_ACTIVE, DELETED_STATE),
    
    -- Foreign Keys
    CONSTRAINT fk_cust_user_customer 
        FOREIGN KEY (CUSTOMER_ID) 
        REFERENCES DOD_CUST_PROFILE(ROW_ID) 
        ON DELETE CASCADE,
    
    CONSTRAINT fk_cust_user_created_by 
        FOREIGN KEY (CREATED_BY) 
        REFERENCES DOD_CUSTOMER_USERS(ROW_ID) 
        ON DELETE SET NULL,
    
    CONSTRAINT fk_cust_user_updated_by 
        FOREIGN KEY (UPDATED_BY) 
        REFERENCES DOD_CUSTOMER_USERS(ROW_ID) 
        ON DELETE SET NULL,
    
    CONSTRAINT fk_cust_user_deleted_by 
        FOREIGN KEY (DELETED_BY) 
        REFERENCES DOD_CUSTOMER_USERS(ROW_ID) 
        ON DELETE SET NULL

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Users/employees who can login for B2B customer companies';")

    (create-table-if-not-exists
     "DOD_CUSTOMER_USER_ACTIVITY"
     "CREATE TABLE DOD_CUSTOMER_USER_ACTIVITY (
    row_id MEDIUMINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    user_id MEDIUMINT NOT NULL COMMENT 'FK to DOD_CUSTOMER_USERS',
    customer_id MEDIUMINT NOT NULL COMMENT 'FK to DOD_CUST_PROFILE',
    
    activity_type ENUM(
        'LOGIN', 'LOGOUT', 'FAILED_LOGIN',
        'ORDER_CREATED', 'ORDER_APPROVED', 'ORDER_CANCELLED',
        'PR_CREATED', 'PR_APPROVED', 'PR_REJECTED',
        'BOM_CREATED', 'BOM_UPDATED',
        'WALLET_FUNDED', 'INVOICE_DOWNLOADED',
        'PROFILE_UPDATED', 'USER_CREATED', 'USER_DEACTIVATED'
    ) NOT NULL,
    
    activity_description TEXT COMMENT 'Details of what happened',
    reference_id VARCHAR(100) COMMENT 'Order ID, PR ID, etc.',
    ip_address VARCHAR(45),
    user_agent TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    tenant_id MEDIUMINT NOT NULL,
    
    INDEX idx_user_id (user_id),
    INDEX idx_customer_id (customer_id),
    INDEX idx_activity_type (activity_type),
    INDEX idx_created_at (created_at),
    
    FOREIGN KEY (user_id) REFERENCES DOD_CUSTOMER_USERS(ROW_ID),
    FOREIGN KEY (customer_id) REFERENCES DOD_CUST_PROFILE(ROW_ID)
) ENGINE=InnoDB COMMENT='Audit trail of all user activities';")

     (unless (column-exists-p "DOD_ORDER" "CREATED_BY_USER_ID")
       (clsql:execute-command "ALTER TABLE DOD_ORDER ADD COLUMN CREATED_BY_USER_ID MEDIUMINT COMMENT 'Which user created this order';"))

    (unless (column-exists-p "DOD_ORDER" "APPROVED_BY_USER_ID")
      (clsql:execute-command "ALTER TABLE DOD_ORDER ADD COLUMN APPROVED_BY_USER_ID MEDIUMINT COMMENT 'Which user approved this order (if approval required)';"))

    
    
    (unless (index-exists-p "DOD_ORDER" "idx_created_by_user")
      (clsql:execute-command "ALTER TABLE DOD_ORDER ADD INDEX idx_created_by_user (CREATED_BY_USER_ID);"))
    
    (unless (foreign-key-exists-p "DOD_ORDER" "fk_order_created_by_use")
      (clsql:execute-command "ALTER TABLE DOD_ORDER ADD CONSTRAINT fk_order_created_by_user FOREIGN KEY (CREATED_BY_USER_ID) REFERENCES DOD_CUSTOMER_USERS(ROW_ID) ON DELETE SET NULL;"))

    (unless (column-exists-p "DOD_INVOICE_HEADER" "LAST_VIEWED_BY_USER_ID")
      (clsql:execute-command "ALTER TABLE DOD_INVOICE_HEADER ADD COLUMN LAST_VIEWED_BY_USER_ID MEDIUMINT COMMENT 'Last user who viewed this invoice';"))

    (unless (column-exists-p "DOD_INVOICE_HEADER" "LAST_VIEWED_AT")
      (clsql:execute-command "ALTER TABLE DOD_INVOICE_HEADER ADD COLUMN LAST_VIEWED_AT TIMESTAMP NULL;"))

    (unless (foreign-key-exists-p "DOD_INVOICE_HEADER" "fk_invoice_viewed_by")
      (clsql:execute-command "ALTER TABLE DOD_INVOICE_HEADER ADD CONSTRAINT fk_invoice_viewed_by FOREIGN KEY (LAST_VIEWED_BY_USER_ID) REFERENCES DOD_CUSTOMER_USERS(ROW_ID) ON DELETE SET NULL;"))
    
    ))
