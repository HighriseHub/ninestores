
select 'dropping the tables' as ' ';

drop table if exists DOD_INVOICE_ITEMS; SELECT 'dropping Invoice Items table .'; 
drop table if exists DOD_INVOICE_HEADER; SELECT 'dropping Invoice header table .'; 
drop table if exists DOD_GST_HSN_CODES; SELECT 'dropping GST HSN codes table .';
drop table if exists DOD_GST_SAC_CODES; SELECT 'dropping GST SAC codes table .'; 
drop table if exists DOD_CURRENCY; SELECT 'dropping currency table, which defines currency.'; 
drop table if exists DOD_PRODUCT_PRICING; SELECT 'dropping product pricing table, which will let the vendor enter product pricing.'; 
drop table if exists DOD_VENDOR_SHIP_ZONES; SELECT 'dropping shipping zones table, which will let the vendor choose the shipping methods.'; 
drop table if exists DOD_SHIPPING_METHODS; SELECT 'dropping shipping methods table, which will let the vendor choose the shipping methods.'; 
drop table if exists DOD_ORDER_SUBSCRIPTION; SELECT 'dropping product preference table, which will let the vendor know what the product preferences of the user are.'; 
drop table if exists DOD_ORDER_TRACK; select 'dropping order status table'; 
drop table if exists DOD_ORDER_ITEMS_TRACK; select 'dropping order details track table'; 
drop table if exists DOD_PRD_STOCK; select 'dropping product stock table.';
drop table if exists DOD_CUST_WALLET; select 'dropping customer wallet table.'; 
drop table if exists DOD_REVIEWS; select 'dropping reviews table';
drop table if exists DOD_PAYMENT_TRANSACTION;  SELECT 'dropping payment transaction ';
drop table if exists DOD_USER_ROLES; select 'a table to store users and roles associaiton'; 
drop table if exists DOD_AUTH_POLICY_ATTR; select 'an intermediate table to store all attributes associated with a policy'; 
drop table if exists DOD_AUTH_ATTR_LOOKUP; select 'a table to store the attributes for authorization'; 
drop table if exists DOD_BUS_TRANSACTION; select 'a table to store the business transactions for abac security'; 
drop table if exists DOD_AUTH_POLICY; select 'a table to store the authorization policy'; 
drop table if exists DOD_BUS_OBJECT; select 'a table to store the business object for abac security'; 
drop table if exists DOD_VENDOR_TENANTS; select 'a table to store the tenant information for a given vendor'; 
drop table if exists DOD_PASSWORD_RESET; select ' a table to reset password for customers, vendors and employees'; 
drop table if exists DOD_VENDOR_APPOINTMENT; select 'a table for vendor appointments'; 
drop table if exists DOD_VENDOR_AVAILABILITY_DAY; select 'a table for vendor availability';
drop table if exists DOD_WEBPUSH_NOTIFY; select 'a table for web push notification subscriptions';
drop table if exists DOD_ABAC_SUBJECT; select 'a table to store the subject for abac security'; 
drop table if exists DOD_COMP_PRICING_PLANS; select 'a table to store company pricing plans';
drop table if exists DOD_ORDER_SHIPMENT; select 'a table to store order shipment ';
drop table if exists DOD_UPI_PAYMENTS; select 'a table to store vendor upi payments';
drop table if exists DOD_ORDER_ITEMS; select 'dropping order details table.'; 
drop table if exists DOD_STOCK_MOVEMENT; select 'dropping stock movement table.';
drop table if exists DOD_STOCK; select 'dropping stock table.';
drop table if exists DOD_WAREHOUSE; select 'dropping warehouse table.';
drop table if exists DOD_PRD_MASTER; select 'dropping product master table.';
drop table if exists DOD_PRD_CATG; select 'dropping product categories table.';
drop table if exists DOD_VENDOR_ORDERS;  select 'a table to store all the orders for a particular vendor.';
drop table if exists DOD_VEND_PROFILE; select 'dropping vendor profile table'; 
drop table if exists DOD_ORDER; select 'dropping order table'; 
drop table if exists DOD_CUST_PROFILE; SELECT  'dropping customer profile table.';
drop table if exists DOD_ROLES; select 'a table to store all the roles'; 
drop table if exists DOD_USERS; select 'dropping users table'; 
drop table if exists DOD_COMPANY;  SELECT 'dropping apartment complex/society/group ';


select 'tables dropped' as ' ';


select 'creating table DOD_INVOICE_HEADER' as ' ';
CREATE TABLE `DOD_INVOICE_HEADER` (
  `ROW_ID` mediumint NOT NULL AUTO_INCREMENT,
  `INVNUM` varchar(50) NOT NULL,
  `INVDATE` date NOT NULL,
  `CONTEXT_ID` varchar(100) DEFAULT NULL,
  `CUSTID` mediumint DEFAULT NULL,
  `VENDOR_ID` mediumint DEFAULT NULL,
  `CUSTNAME` varchar(255) NOT NULL,
  `CUSTADDR` text,
  `CUSTGSTIN` varchar(15) DEFAULT NULL,
  `STATECODE` varchar(2) NOT NULL,
  `BILLADDR` text,
  `SHIPADDR` text,
  `PLACEOFSUPPLY` varchar(50) NOT NULL,
  `REVCHARGE` enum('Yes','No') DEFAULT 'No',
  `TRANSMODE` varchar(50) DEFAULT NULL,
  `VNUM` varchar(20) DEFAULT NULL,
  `TOTALVALUE` decimal(15,2) NOT NULL,
  `TOTALINWORDS` varchar(255) NOT NULL,
  `BANKACCNUM` varchar(20) DEFAULT NULL,
  `BANKIFSCCODE` varchar(11) DEFAULT NULL,
  `TNC` text,
  `AUTHSIGN` varchar(100) DEFAULT NULL,
  `FINYEAR` varchar(9) NOT NULL,
  `EXTERNAL_URL` varchar(2048) character set utf8 collate utf8_general_ci null default null,
  `USER_ID` mediumint DEFAULT NULL,
  `CREATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `UPDATED` timestamp NULL DEFAULT NULL,
  `STATUS` varchar(20) DEFAULT 'DRAFT',
  `DELETED_STATE` char(1) DEFAULT NULL,
  `TENANT_ID` mediumint DEFAULT NULL,
  PRIMARY KEY (`ROW_ID`),
  UNIQUE KEY `INVNUM` (`INVNUM`),
  KEY `TENANT_ID` (`TENANT_ID`),
  KEY `CUSTID` (`CUSTID`),
  KEY `VENDOR_ID` (`VENDOR_ID`),
  KEY `USER_ID` (`USER_ID`),
  CONSTRAINT `DOD_INVOICE_HEADER_ibfk_1` FOREIGN KEY (`TENANT_ID`) REFERENCES `DOD_COMPANY` (`ROW_ID`),
  CONSTRAINT `DOD_INVOICE_HEADER_ibfk_2` FOREIGN KEY (`CUSTID`) REFERENCES `DOD_CUST_PROFILE` (`ROW_ID`),
  CONSTRAINT `DOD_INVOICE_HEADER_ibfk_3` FOREIGN KEY (`VENDOR_ID`) REFERENCES `DOD_VEND_PROFILE` (`ROW_ID`),
  CONSTRAINT `DOD_INVOICE_HEADER_ibfk_4` FOREIGN KEY (`USER_ID`) REFERENCES `DOD_USERS` (`ROW_ID`)
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;



select 'creating table DOD_INVOICE_ITEMS' as ' ';
CREATE TABLE `DOD_INVOICE_ITEMS` (
  `ROW_ID` mediumint NOT NULL AUTO_INCREMENT,
  `INVHEADID` mediumint NOT NULL,
  `PRD_ID` mediumint NOT NULL,
  `PRDDESC` text NOT NULL,
  `HSNCODE` varchar(10) NOT NULL,
  `QTY` smallint NOT NULL,
  `UOM` varchar(10) NOT NULL,
  `PRICE` decimal(10,2) NOT NULL,
  `DISCOUNT` decimal(10,2) DEFAULT '0.00',
  `TAXABLE_VALUE` decimal(15,2) NOT NULL,
  `CGSTRATE` decimal(5,2) NOT NULL,
  `CGSTAMT` decimal(15,2) NOT NULL,
  `SGSTRATE` decimal(5,2) NOT NULL,
  `SGSTAMT` decimal(15,2) NOT NULL,
  `IGSTRATE` decimal(5,2) NOT NULL,
  `IGSTAMT` decimal(15,2) NOT NULL,
  `TOTALITEMVAL` decimal(15,2) NOT NULL,
  `CREATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `UPDATED` timestamp NULL DEFAULT NULL,
  `STATUS` varchar(20) DEFAULT 'PENDING',
  `DELETED_STATE` char(1) DEFAULT NULL,
  `TENANT_ID` mediumint DEFAULT NULL,
  PRIMARY KEY (`ROW_ID`),
  KEY `TENANT_ID` (`TENANT_ID`),
  KEY `PRD_ID` (`PRD_ID`),
  KEY `INVHEADID` (`INVHEADID`),
  CONSTRAINT `DOD_INVOICE_ITEMS_ibfk_1` FOREIGN KEY (`TENANT_ID`) REFERENCES `DOD_COMPANY` (`ROW_ID`) ON DELETE CASCADE,
  CONSTRAINT `DOD_INVOICE_ITEMS_ibfk_2` FOREIGN KEY (`PRD_ID`) REFERENCES `DOD_PRD_MASTER` (`ROW_ID`) ON DELETE CASCADE,
  CONSTRAINT `DOD_INVOICE_ITEMS_ibfk_3` FOREIGN KEY (`INVHEADID`) REFERENCES `DOD_INVOICE_HEADER` (`ROW_ID`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=54 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

select 'creating table dod_gst_hsn_codes' as ' ';
CREATE TABLE `DOD_GST_HSN_CODES` (
  `ROW_ID` mediumint NOT NULL AUTO_INCREMENT,
  `HSN_CODE` varchar(10) NOT NULL,
  `HSN_CODE_4DIGIT` varchar(6) NOT NULL,
  `HSN_DESCRIPTION` text NOT NULL,
  `CGST` decimal(4,2) DEFAULT NULL,
  `SGST` decimal(4,2) DEFAULT NULL,
  `IGST` decimal(4,2) DEFAULT NULL,
  `COMP_CESS` decimal(4,2) DEFAULT NULL,
  `COMP_CESS_FUNC` varchar(255) DEFAULT NULL,
  `GST_HSN_FUNC` varchar(255) DEFAULT NULL,
  `TENANT_ID` mediumint DEFAULT NULL,
  PRIMARY KEY (`ROW_ID`),
  UNIQUE KEY `HSN_CODE` (`HSN_CODE`),
  KEY `DOD_GST_HSN_CODES_ibfk_1` (`TENANT_ID`),
  CONSTRAINT `DOD_GST_HSN_CODES_ibfk_1` FOREIGN KEY (`TENANT_ID`) REFERENCES `DOD_COMPANY` (`ROW_ID`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=73074 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;



select 'creating table dod_gst_sac_codes' as ' ';
CREATE TABLE `DOD_GST_SAC_CODES` (
  `ROW_ID` mediumint NOT NULL AUTO_INCREMENT,
  `SAC_CODE` varchar(10) NOT NULL,
  `SAC_CODE_4DIGIT` varchar(6) NOT NULL,
  `SAC_DESCRIPTION` text NOT NULL,
  `CONDITION_TXT` text,
  `CGST` decimal(4,2) DEFAULT NULL,
  `SGST` decimal(4,2) DEFAULT NULL,
  `IGST` decimal(4,2) DEFAULT NULL,
  `GST_SAC_FUNC` varchar(255) DEFAULT NULL,
  `TENANT_ID` mediumint DEFAULT NULL,
  PRIMARY KEY (`ROW_ID`),
  UNIQUE KEY `SAC_CODE` (`SAC_CODE`),
  KEY `DOD_GST_SAC_CODES_ibfk_1` (`TENANT_ID`),
  CONSTRAINT `DOD_GST_SAC_CODES_ibfk_1` FOREIGN KEY (`TENANT_ID`) REFERENCES `DOD_COMPANY` (`ROW_ID`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

select 'creating table dod_currency' as ' ';
CREATE TABLE `DOD_CURRENCY` (
  `COUNTRY` VARCHAR(50),
  `CURRENCY` varchar(20),	
  `CODE` varchar(10),	
  `CURR_SYMBOL` varchar(5));

select 'creating table dod_free_shipping_method' as ' ';
CREATE TABLE `DOD_VENDOR_SHIP_ZONES` (
  `ROW_ID` mediumint(9) NOT NULL AUTO_INCREMENT,
  `ZONENAME` varchar(70) DEFAULT NULL,
  `VENDOR_ID` mediumint(9) DEFAULT NULL, 
  `ZIPCODERANGECSV` varchar(1024) DEFAULT NULL, 
  `CREATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `DELETED_STATE` char(1) DEFAULT NULL,
  `ACTIVE_FLAG` char(1) DEFAULT NULL,
  `TENANT_ID` mediumint(9) DEFAULT NULL,
  PRIMARY KEY (`ROW_ID`),
  KEY `TENANT_ID` (`TENANT_ID`),
  KEY `VENDOR_ID` (`VENDOR_ID`),
  CONSTRAINT `DOD_VENDOR_SHIP_ZONES_ibfk_1` FOREIGN KEY (`TENANT_ID`) REFERENCES `DOD_COMPANY` (`ROW_ID`),
  CONSTRAINT `DOD_VENDOR_SHIP_ZONES_ibfk_2` FOREIGN KEY (`VENDOR_ID`) REFERENCES `DOD_VEND_PROFILE` (`ROW_ID`)
);


select 'creating table dod_free_shipping_method' as ' ';
CREATE TABLE `DOD_SHIPPING_METHODS` (
  `ROW_ID` mediumint(9) NOT NULL AUTO_INCREMENT,
  `NAME` varchar(70) DEFAULT NULL,
  `FREESHIPENABLED` char(1) DEFAULT NULL,
  `FLATRATESHIPENABLED` char(1) DEFAULT NULL,
  `TABLERATESHIPENABLED` char(1) DEFAULT NULL,
  `EXTSHIPENABLED` char(1) DEFAULT NULL, 
  `STOREPICKUPENABLED` char(1) DEFAULT NULL,
  `MINORDERAMT` decimal(7,2) DEFAULT NULL,
  `FLATRATETYPE` char(3) DEFAULT "ORD", 'PER ORDER - ORD, PER ITEM - ITM'
  `FLATRATEPRICE` decimal(7,2) DEFAULT NULL,   
  `RATETABLECSV` varchar(500) DEFAULT NULL,	   
  `SHIPPARTNERKEY` varchar(50) DEFAULT NULL,
  `SHIPPARTNERSECRET` varchar(50) DEFAULT NULL,	   
  `VENDOR_ID` mediumint(9) DEFAULT NULL, 
  `CREATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `DELETED_STATE` char(1) DEFAULT NULL,
  `ACTIVE_FLAG` char(1) DEFAULT NULL,
  `TENANT_ID` mediumint(9) DEFAULT NULL,
  PRIMARY KEY (`ROW_ID`),
  KEY `TENANT_ID` (`TENANT_ID`),
  KEY `VENDOR_ID` (`VENDOR_ID`),
  CONSTRAINT `DOD_SHIPPING_METHODS_ibfk_1` FOREIGN KEY (`TENANT_ID`) REFERENCES `DOD_COMPANY` (`ROW_ID`),
  CONSTRAINT `DOD_SHIPPING_METHODS_ibfk_2` FOREIGN KEY (`VENDOR_ID`) REFERENCES `DOD_VEND_PROFILE` (`ROW_ID`)
);

select 'creating table dod_free_shipping_method' as ' ';
CREATE TABLE `DOD_VPAYMENT_METHODS` (
  `ROW_ID` mediumint(9) NOT NULL AUTO_INCREMENT,
  `CODENABLED` char(1) DEFAULT 'Y',
  `UPIENABLED` char(1) DEFAULT 'Y',
  `PAYPROVIDERSENABLED` char(1) DEFAULT 'Y',
  `WALLETENABLED` char(1) DEFAULT 'Y',
  `PAYLATERENABLED` char(1) DEFAULT 'N',
  `VENDOR_ID` mediumint(9) DEFAULT NULL, 
  `CREATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `DELETED_STATE` char(1) DEFAULT NULL,
  `ACTIVE_FLAG` char(1) DEFAULT NULL,
  `TENANT_ID` mediumint(9) DEFAULT NULL,
  PRIMARY KEY (`ROW_ID`),
  KEY `TENANT_ID` (`TENANT_ID`),
  KEY `VENDOR_ID` (`VENDOR_ID`),
  CONSTRAINT `DOD_PAYMENT_METHODS_ibfk_1` FOREIGN KEY (`TENANT_ID`) REFERENCES `DOD_COMPANY` (`ROW_ID`),
  CONSTRAINT `DOD_PAYMENT_METHODS_ibfk_2` FOREIGN KEY (`VENDOR_ID`) REFERENCES `DOD_VEND_PROFILE` (`ROW_ID`)
);

select 'creating table dod_free_shipping_method' as ' ';
CREATE TABLE `DOD_VPAYMENT_PROVIDERS` (
  `ROW_ID` mediumint(9) NOT NULL AUTO_INCREMENT,
  `NAME` varchar(100) DEFAULT NULL,
  `PROVIDER_URL` varchar(512) DEFAULT NULL,
  `RETURN_URL` varchar(512) DEFAULT NULL,
  `CANCEL_URL` varchar(512) DEFAULT NULL,
  `FAILURE_URL` varchar(512) DEFAULT NULL,
  `PAYMENT_API_KEY` varchar(512) DEFAULT NULL,
  `PAYMENT_API_SALT` varchar(512) DEFAULT NULL,
  `PAYMENT_GATEWAY_MODE` varchar(10) DEFAULT 'TEST',
  `VENDOR_ID` mediumint(9) DEFAULT NULL, 
  `CREATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `DELETED_STATE` char(1) DEFAULT NULL,
  `ACTIVE_FLAG` char(1) DEFAULT NULL,
  `TENANT_ID` mediumint(9) DEFAULT NULL,
  PRIMARY KEY (`ROW_ID`),
  KEY `TENANT_ID` (`TENANT_ID`),
  KEY `VENDOR_ID` (`VENDOR_ID`),
  CONSTRAINT `DOD_PAYMENT_PROVIDERS_ibfk_1` FOREIGN KEY (`TENANT_ID`) REFERENCES `DOD_COMPANY` (`ROW_ID`),
  CONSTRAINT `DOD_PAYMENT_PROVIDERS_ibfk_2` FOREIGN KEY (`VENDOR_ID`) REFERENCES `DOD_VEND_PROFILE` (`ROW_ID`)
);

select 'creating table dod_company' as ' ';
CREATE TABLE `DOD_COMPANY` (
  `ROW_ID` mediumint(9) NOT NULL AUTO_INCREMENT,
  `NAME` varchar(255) NOT NULL,
  `ADDRESS` varchar(512) NOT NULL,
  `CITY` varchar(256) NOT NULL,
  `STATE` varchar(256) DEFAULT NULL,
  `COUNTRY` varchar(100) DEFAULT NULL,
  `ZIPCODE` char(10) DEFAULT NULL,
  `PRIMARY_CONTACT` varchar(255) DEFAULT NULL,
  `CREATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `CREATED_BY` mediumint(9) DEFAULT NULL,
  `UPDATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `UPDATED_BY` mediumint(9) DEFAULT NULL,
  `ACTIVE_FLG` char(1) NOT NULL,
  `DELETED_STATE` char(1) DEFAULT NULL,
  `WEBSITE` varchar(256) DEFAULT NULL,
  `CMP_TYPE` varchar(30) NOT NULL DEFAULT 'TRIAL',
  `SUSPEND_FLAG` char(1) NOT NULL DEFAULT 'N',
  `TSHIRT_SIZE` char(2) DEFAULT 'SM',
  `REVENUE` int(11) DEFAULT NULL,
  `SUBSCRIPTION_PLAN` varchar(50) NOT NULL DEFAULT 'TRIAL',
  `EXTERNAL_URL` varchar(255) character set utf8 collate utf8_general_ci null default null,
  PRIMARY KEY (`ROW_ID`)
);


select 'creating table dod_users' as ' ';
CREATE TABLE `DOD_USERS` (
  `ROW_ID` mediumint(9) NOT NULL AUTO_INCREMENT,
  `NAME` varchar(30) NOT NULL,
  `USERNAME` varchar(30) NOT NULL,
  `PASSWORD` varchar(100) NOT NULL,
  `EMAIL` varchar(255) NOT NULL,
  `FIRSTNAME` varchar(50) DEFAULT NULL,
  `LASTNAME` varchar(50) DEFAULT NULL,
  `FULLNAME` varchar(50) DEFAULT NULL,
  `SALUTATION` varchar(10) DEFAULT NULL,
  `TITLE` varchar(255) DEFAULT NULL,
  `PHONE_HOME` varchar(50) DEFAULT NULL,
  `PHONE_MOBILE` varchar(50) DEFAULT NULL,
  `PHONE_OFFICE` varchar(50) DEFAULT NULL,
  `PRIMARY_ADDRESS_STREET` varchar(150) DEFAULT NULL,
  `PRIMARY_ADDRESS_CITY` varchar(100) DEFAULT NULL,
  `PRIMARY_ADDRESS_STATE` varchar(100) DEFAULT NULL,
  `PRIMARY_ADDRESS_POSTALCODE` varchar(20) DEFAULT NULL,
  `PRIMARY_ADDRESS_COUNTRY` varchar(255) DEFAULT NULL,
  `BIRTHDATE` datetime DEFAULT NULL,
  `PICTURE` varchar(255) DEFAULT NULL,
  `CREATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `CREATED_BY` mediumint(9) DEFAULT NULL,
  `UPDATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `UPDATED_BY` mediumint(9) DEFAULT NULL,
  `ACTIVE_FLG` char(1) DEFAULT NULL,
  `DELETED_STATE` char(1) DEFAULT NULL,
  `TENANT_ID` mediumint(9) NOT NULL,
  `PARENT_ID` mediumint(9) DEFAULT NULL,
  `SALT` varchar(128) DEFAULT NULL,
  `APPROVAL_FLAG` char(1) DEFAULT NULL,
  `APPROVED_BY` varchar(30) DEFAULT NULL,
  `APPROVAL_STATUS` varchar(20) DEFAULT NULL,
  PRIMARY KEY (`ROW_ID`),
  UNIQUE KEY `USERNAME` (`USERNAME`),
  KEY `TENANT_ID` (`TENANT_ID`),
  KEY `PARENT_ID` (`PARENT_ID`),
  CONSTRAINT `DOD_USERS_ibfk_1` FOREIGN KEY (`TENANT_ID`) REFERENCES `DOD_COMPANY` (`ROW_ID`),
  CONSTRAINT `DOD_USERS_ibfk_2` FOREIGN KEY (`PARENT_ID`) REFERENCES `DOD_USERS` (`ROW_ID`)
);


select 'creating table dod_vend_profile' as ' ';
CREATE TABLE `DOD_VEND_PROFILE` (
  `ROW_ID` mediumint(9) NOT NULL AUTO_INCREMENT,
  `NAME` varchar(70) NOT NULL,
  `ADDRESS` varchar(70) NOT NULL,
  `PHONE` varchar(30) NOT NULL,
  `USERNAME` varchar(30) NOT NULL,
  `PASSWORD` varchar(100) NOT NULL,
  `SALT` varchar(128) DEFAULT NULL,
  `EMAIL` varchar(255) DEFAULT NULL,
  `FIRSTNAME` varchar(50) DEFAULT NULL,
  `LASTNAME` varchar(50) DEFAULT NULL,
  `FULLNAME` varchar(50) DEFAULT NULL,
  `SALUTATION` varchar(10) DEFAULT NULL,
  `TITLE` varchar(255) DEFAULT NULL,
  `BIRTHDATE` datetime DEFAULT NULL,
  `PICTURE_PATH` varchar(256) DEFAULT NULL,
  `CITY` varchar(256) DEFAULT NULL,
  `ZIPCODE` varchar(10) DEFAULT NULL,
  `GSTNUMBER` varchar(20) DEFAULT NULL,
  `STATE` varchar(256) DEFAULT NULL,
  `COUNTRY` varchar(100) DEFAULT NULL,
  `CREATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `UPDATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `DELETED_STATE` char(1) DEFAULT NULL,
  `TENANT_ID` mediumint(9) NOT NULL,
  
  `APPROVED_FLAG` char(1) DEFAULT NULL,
  `APPROVAL_STATUS` varchar(20) DEFAULT NULL,
  `APPROVED_BY` varchar(30) DEFAULT NULL,
  `ACTIVE_FLAG` char(1) DEFAULT NULL,
 
  `PUSH_NOTIFY_SUBS_FLAG` char(1) DEFAULT NULL,
  `EMAIL_ADD_VERIFIED` char(1) DEFAULT NULL,
  `SUSPEND_FLAG` char(1) DEFAULT NULL,
  `UPI_ID` varchar(70) DEFAULT NULL,
  `SHIPPING_ENABLED` char(1) DEFAULT "N",
  `INVOICE_SETTINGS` text DEFAULT NULL, 
    PRIMARY KEY (`ROW_ID`),  
    UNIQUE KEY `UC_Vendor` (`PHONE`,`TENANT_ID`),
    KEY `TENANT_ID` (`TENANT_ID`),
    CONSTRAINT `DOD_VEND_PROFILE_ibfk_1` FOREIGN KEY (`TENANT_ID`) REFERENCES `DOD_COMPANY` (`ROW_ID`)
);
 


select 'creating table dod_cust_profile' as ' ';    
CREATE TABLE `DOD_CUST_PROFILE` (
  `ROW_ID` mediumint(9) NOT NULL AUTO_INCREMENT,
  `NAME` varchar(70) NOT NULL,
  `ADDRESS` varchar(256) DEFAULT NULL,
  `PHONE` varchar(30) NOT NULL,
  `USERNAME` varchar(30) NOT NULL,
  `PASSWORD` varchar(128) NOT NULL,
  `SALT` varchar(128) DEFAULT NULL,
  `EMAIL` varchar(255) DEFAULT NULL,
  `FIRSTNAME` varchar(50) DEFAULT NULL,
  `LASTNAME` varchar(50) DEFAULT NULL,
  `FULLNAME` varchar(50) DEFAULT NULL,
  `SALUTATION` varchar(10) DEFAULT NULL,
  `TITLE` varchar(255) DEFAULT NULL,
  `BIRTHDATE` datetime DEFAULT NULL,
  `PICTURE_PATH` varchar(256) DEFAULT NULL,
  `CITY` varchar(256) DEFAULT NULL,
  `STATE` varchar(256) DEFAULT NULL,
  `COUNTRY` varchar(100) DEFAULT NULL,
  `ZIPCODE` char(10) DEFAULT NULL,
  `CREATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `UPDATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `DELETED_STATE` char(1) DEFAULT NULL,
  `TENANT_ID` mediumint(9) NOT NULL,
  `APPROVED_FLAG` char(1) DEFAULT NULL,
  `APPROVAL_STATUS` varchar(20) DEFAULT NULL,
  `APPROVED_BY` varchar(30) DEFAULT NULL,
  `CUST_TYPE` varchar(50) DEFAULT NULL,
  `active_flag` char(1) NOT NULL DEFAULT 'N',
  `EMAIL_ADD_VERIFIED` char(1) DEFAULT NULL,
  `SUSPEND_FLAG` char(1) DEFAULT NULL,
  `UPI_ID` varchar(70) DEFAULT NULL,
  PRIMARY KEY (`ROW_ID`),
  UNIQUE KEY `UC_Customer` (`PHONE`,`TENANT_ID`,`CUST_TYPE`),
  KEY `TENANT_ID` (`TENANT_ID`),
  CONSTRAINT `DOD_CUST_PROFILE_ibfk_1` FOREIGN KEY (`TENANT_ID`) REFERENCES `DOD_COMPANY` (`ROW_ID`)
);



select  'this is a daily transaction table to calculate the demand for the product on a daily basis.';
select  'we can copy the rows from dod_prd_pref table by running a daily job and consider that as daily ondemand preference'; 
select 'creating table dod_order' as ' ';

CREATE TABLE `DOD_ORDER` (
  `ROW_ID` mediumint(9) NOT NULL AUTO_INCREMENT,
  `ORD_DATE` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `CUST_ID` mediumint(9) NOT NULL,
  `REQ_DATE` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `SHIPPED_DATE` timestamp NULL DEFAULT NULL,
  `SHIP_ADDRESS` varchar(200) DEFAULT NULL,
  `ORDER_FULFILLED` char(1) DEFAULT NULL,
  `STATUS` char(3) DEFAULT NULL,
  `PAYMENT_MODE` char(3) DEFAULT NULL,
  `CONTEXT_ID` varchar(100) DEFAULT NULL,
  `ORDER_AMT` decimal(7,2) DEFAULT NULL,
  `COMMENTS` varchar(255) DEFAULT NULL,
  `CREATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `UPDATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `TENANT_ID` mediumint(9) DEFAULT NULL,
  `DELETED_STATE` char(1) DEFAULT NULL,
  `ORDER_TYPE` char(4) DEFAULT NULL,
  `SHIPZIPCODE` varchar(10) DEFAULT NULL,
  `SHIPCITY` varchar(50) DEFAULT NULL,
  `SHIPSTATE` varchar(50) DEFAULT NULL,
  `BILLADDRESS` varchar(200) DEFAULT NULL,
  `BILLZIPCODE` varchar(10) DEFAULT NULL,
  `BILLCITY` varchar(50) DEFAULT NULL,
  `BILLSTATE` varchar(50) DEFAULT NULL,
  `COUNTRY` varchar(50) DEFAULT 'India',
  `BILLSAMEASSHIP` char(1) DEFAULT 'Y',
  `GSTNUMBER` varchar(20) DEFAULT NULL,
  `GSTORGNAME` varchar(50) DEFAULT NULL,
  `TOTAL_DISCOUNT` decimal(7,2) DEFAULT NULL,
  `TOTAL_TAX` decimal(7,2) DEFAULT NULL,
  `SHIPPING_COST` decimal(7,2) DEFAULT NULL,
  `STOREPICKUPENABLED` char(1) DEFAULT NULL,
  PRIMARY KEY (`ROW_ID`),
  KEY `TENANT_ID` (`TENANT_ID`),
  KEY `CUST_ID` (`CUST_ID`),
  CONSTRAINT `DOD_ORDER_ibfk_1` FOREIGN KEY (`TENANT_ID`) REFERENCES `DOD_COMPANY` (`ROW_ID`),
  CONSTRAINT `DOD_ORDER_ibfk_2` FOREIGN KEY (`CUST_ID`) REFERENCES `DOD_CUST_PROFILE` (`ROW_ID`)
);


select 'creating table dod_prd_cat' as ' ';
CREATE TABLE `DOD_PRD_CATG` (
  `ROW_ID` mediumint(9) NOT NULL AUTO_INCREMENT,
  `CATG_NAME` varchar(70) DEFAULT NULL,
  `lft` int(11) NOT NULL,
  `rgt` int(11) NOT NULL,
  `CREATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `DELETED_STATE` char(1) DEFAULT NULL,
  `ACTIVE_FLAG` char(1) DEFAULT NULL,
  `TENANT_ID` mediumint(9) DEFAULT NULL,
  PRIMARY KEY (`ROW_ID`),
  KEY `TENANT_ID` (`TENANT_ID`),
  CONSTRAINT `DOD_PRD_CATG_ibfk_1` FOREIGN KEY (`TENANT_ID`) REFERENCES `DOD_COMPANY` (`ROW_ID`)
);

select 'creating table dod_prd_master' as ' ';
CREATE TABLE `DOD_PRD_MASTER` (
  `ROW_ID` mediumint(9) NOT NULL AUTO_INCREMENT,
  `PRD_NAME` varchar(70) DEFAULT NULL,
  `DESCRIPTION` varchar(1024) DEFAULT NULL,
  `VENDOR_ID` mediumint(9) DEFAULT NULL,
  `CATG_ID` mediumint(9) DEFAULT NULL,
  `QTY_PER_UNIT` varchar(30) DEFAULT NULL,
  `PRD_IMAGE_PATH` TEXT DEFAULT NULL,
  `UNIT_PRICE` decimal(7,2) DEFAULT NULL,
  `UNITS_IN_STOCK` smallint DEFAULT NULL,
  `CREATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `UPDATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `DELETED_STATE` char(1) DEFAULT NULL,
  `SUBSCRIBE_FLAG` char(1) DEFAULT NULL,
  `TENANT_ID` mediumint(9) DEFAULT NULL,
  `active_flag` char(1) DEFAULT NULL,
  `approved_flag` char(1) DEFAULT NULL,
  `approval_status` varchar(20) DEFAULT NULL,
  `approved_by` varchar(30),	
  `PRD_TYPE` char(4) DEFAULT 'SALE',
  `HSN_CODE` varchar(8) DEFAULT NULL,
  `sku` varchar(20) character set utf8 collate utf8_general_ci null default null,
  `upc` varchar(20) character set utf8 collate utf8_general_ci null default null,
  `ean` varchar(20) character set utf8 collate utf8_general_ci null default null,
  `jan` varchar(20) character set utf8 collate utf8_general_ci null default null,
  `isbn` varchar(20) character set utf8 collate utf8_general_ci null default null,
  `serial_no` varchar(20) character set utf8 collate utf8_general_ci null default null,
  `external_url` varchar(255) character set utf8 collate utf8_general_ci null default null,
  `SHIPPING_LENGTH_CMS` smallint DEFAULT NULL,
  `SHIPPING_WIDTH_CMS` smallint DEFAULT NULL,
  `SHIPPING_HEIGHT_CMS` smallint DEFAULT NULL,
  `SHIPPING_WEIGHT_KG` decimal (5,2) DEFAULT NULL,
  PRIMARY KEY (`ROW_ID`),
  KEY `TENANT_ID` (`TENANT_ID`),
  KEY `VENDOR_ID` (`VENDOR_ID`),
  KEY `CATG_ID` (`CATG_ID`),
  CONSTRAINT `DOD_PRD_MASTER_ibfk_1` FOREIGN KEY (`TENANT_ID`) REFERENCES `DOD_COMPANY` (`ROW_ID`),
  CONSTRAINT `DOD_PRD_MASTER_ibfk_2` FOREIGN KEY (`VENDOR_ID`) REFERENCES `DOD_VEND_PROFILE` (`ROW_ID`),
  CONSTRAINT `DOD_PRD_MASTER_ibfk_3` FOREIGN KEY (`CATG_ID`) REFERENCES `DOD_PRD_CATG` (`ROW_ID`)
);

select 'creating table DOD_PRODUCT_PRICING' as ' ';
CREATE TABLE `DOD_PRODUCT_PRICING` (
`ROW_ID` mediumint(9) NOT NULL AUTO_INCREMENT,
`PRODUCT_ID` mediumint (9) DEFAULT NULL,
`PRICE` DECIMAL(10, 2) NOT NULL,
`DISCOUNT`  DECIMAL(5, 2) DEFAULT 0,
`CURRENCY` VARCHAR(3) DEFAULT 'USD',
`START_DATE` TIMESTAMP,
`END_DATE` TIMESTAMP,
`CREATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
`UPDATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
`DELETED_STATE` char(1) DEFAULT NULL,
`ACTIVE_FLAG` char(1) DEFAULT NULL,
`TENANT_ID` mediumint(9) DEFAULT NULL,
PRIMARY KEY (`ROW_ID`),
KEY `TENANT_ID` (`TENANT_ID`),
KEY `PRODUCT_ID` (`PRODUCT_ID`),
CONSTRAINT `DOD_PRODUCT_PRICING_ibfk_1` FOREIGN KEY (`TENANT_ID`) REFERENCES `DOD_COMPANY` (`ROW_ID`),
CONSTRAINT `DOD_PRODUCT_PRICING_ibfk_2` FOREIGN KEY (`PRODUCT_ID`) REFERENCES `DOD_PRD_MASTER` (`ROW_ID`),
INDEX (PRODUCT_ID)
);



select 'creating table DOD_WAREHOUSE' as ' ';
CREATE TABLE `DOD_WAREHOUSE` (
`ROW_ID` mediumint(9) NOT NULL AUTO_INCREMENT,
`W_NAME` varchar(100) NOT NULL,
`W_ADDR1` varchar(100),
`W_ADDR2` varchar(100), 
`W_PIN` varchar(6),
`W_CITY` varchar(30),
`W_STATE`  varchar(30),
`W_COUNTRY` varchar(30),
`W_MANAGER` varchar(100),
`W_PHONE` varchar(16),
`W_ALT_PHONE` varchar(16),
`W_EMAIL` varchar(100),
`CREATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
`UPDATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
`DELETED_STATE` char(1) DEFAULT NULL,
`ACTIVE_FLAG` char(1) DEFAULT NULL,
`TENANT_ID` mediumint(9) DEFAULT NULL,
PRIMARY KEY (`ROW_ID`),
KEY `TENANT_ID` (`TENANT_ID`),
CONSTRAINT `DOD_WAREHOUSE_ibfk_1` FOREIGN KEY (`TENANT_ID`) REFERENCES `DOD_COMPANY` (`ROW_ID`)
);

select 'creating table DOD_STOCK' as ' ';
CREATE TABLE `DOD_STOCK` (
`ROW_ID` mediumint(9) NOT NULL AUTO_INCREMENT,
`PRD_ID` mediumint(9) NOT NULL,
`WAREHOUSE_ID` mediumint(9) NOT NULL,
`UNITS_IN_STOCK` smallint DEFAULT NULL,
`MINSTOCK` smallint DEFAULT NULL,
`MAXSTOCK` smallint DEFAULT NULL,
`EXPIRY_DATE` timestamp DEFAULT NULL,
`CREATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
`UPDATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
`DELETED_STATE` char(1) DEFAULT NULL,
`ACTIVE_FLAG` char(1) DEFAULT NULL,
`TENANT_ID` mediumint(9) DEFAULT NULL,
PRIMARY KEY (`ROW_ID`),
KEY `TENANT_ID` (`TENANT_ID`),
KEY `PRD_ID` (`PRD_ID`),
KEY `WAREHOUSE_ID` (`WAREHOUSE_ID`),
CONSTRAINT `DOD_STOCK_ibfk_1` FOREIGN KEY (`TENANT_ID`) REFERENCES `DOD_COMPANY` (`ROW_ID`),
CONSTRAINT `DOD_STOCK_ibfk_2` FOREIGN KEY (`PRD_ID`) REFERENCES `DOD_PRD_MASTER` (`ROW_ID`),
CONSTRAINT `DOD_STOCK_ibfk_3` FOREIGN KEY (`WAREHOUSE_ID`) REFERENCES `DOD_WAREHOUSE` (`ROW_ID`)
);

select 'creating table DOD_STOCK_MOVEMENT' as ' ';
CREATE TABLE `DOD_STOCK_MOVEMENT` (
`ROW_ID` mediumint(9) NOT NULL AUTO_INCREMENT,
`STOCK_ID` mediumint(9) NOT NULL,
`QTY_MOVED` smallint NOT NULL,
`CREATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
`DELETED_STATE` char(1) DEFAULT NULL,
`TENANT_ID` mediumint(9) DEFAULT NULL,
PRIMARY KEY (`ROW_ID`),
KEY `TENANT_ID` (`TENANT_ID`),
KEY `STOCK_ID` (`STOCK_ID`),
CONSTRAINT `DOD_STOCK_MOVEMENT_ibfk_1` FOREIGN KEY (`STOCK_ID`) REFERENCES `DOD_STOCK` (`ROW_ID`),
CONSTRAINT `DOD_STOCK_MOVEMENT_ibfk_2` FOREIGN KEY (`TENANT_ID`) REFERENCES `DOD_COMPANY` (`ROW_ID`)
);

select 'creating table DOD_ORDER_SUBSCRIPTION' as ' ';
CREATE TABLE `DOD_ORDER_SUBSCRIPTION` (
  `ROW_ID` mediumint(9) NOT NULL AUTO_INCREMENT,
  `CUST_ID` mediumint(9) DEFAULT NULL,
  `PRD_ID` mediumint(9) DEFAULT NULL,
  `PRD_QTY` mediumint(9) DEFAULT NULL,
  `SUN` char(1) DEFAULT NULL,
  `MON` char(1) DEFAULT NULL,
  `TUE` char(1) DEFAULT NULL,
  `WED` char(1) DEFAULT NULL,
  `THU` char(1) DEFAULT NULL,
  `FRI` char(1) DEFAULT NULL,
  `SAT` char(1) DEFAULT NULL,
  `START_DATE` timestamp,
  `END_DATE` timestamp,
  `FREQUENCY` varchar(10) DEFAULT 'WEEKLY',
  `CREATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `UPDATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `TENANT_ID` mediumint(9) DEFAULT NULL,
  `DELETED_STATE` char(1) DEFAULT NULL,
  `ACTIVE_FLAG` char(1) NOT NULL DEFAULT 'Y',
  PRIMARY KEY (`ROW_ID`),
  KEY `TENANT_ID` (`TENANT_ID`),
  KEY `CUST_ID` (`CUST_ID`),
  KEY `PRD_ID` (`PRD_ID`),
  CONSTRAINT `DOD_ORDER_SUBSCRIPTION_ibfk_1` FOREIGN KEY (`TENANT_ID`) REFERENCES `DOD_COMPANY` (`ROW_ID`),
  CONSTRAINT `DOD_ORDER_SUBSCRIPTION_ibfk_2` FOREIGN KEY (`CUST_ID`) REFERENCES `DOD_CUST_PROFILE` (`ROW_ID`),
  CONSTRAINT `DOD_ORDER_SUBSCRIPTION_ibfk_3` FOREIGN KEY (`PRD_ID`) REFERENCES `DOD_PRD_MASTER` (`ROW_ID`)
);

  
 
select 'creating table dod_ord_details' as ' ';
CREATE TABLE `DOD_ORDER_ITEMS` (
  `ROW_ID` mediumint(9) NOT NULL AUTO_INCREMENT,
  `ORDER_ID` mediumint(9) NOT NULL,
  `VENDOR_ID` mediumint(9) NOT NULL,
  `PRD_ID` mediumint(9) NOT NULL,
  `UNIT_PRICE` decimal(7,2) DEFAULT NULL,
  `PRD_QTY` mediumint(9) DEFAULT NULL,
  `FULFILLED` char(1) DEFAULT NULL,
  `STATUS` char(3) DEFAULT NULL,
  `CREATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `UPDATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `DELETED_STATE` char(1) DEFAULT NULL,
  `TENANT_ID` mediumint(9) DEFAULT NULL,
  `COMMENTS` varchar(255) DEFAULT NULL,
  `CGST` decimal(4,2) DEFAULT NULL,
  `SGST` decimal(4,2) DEFAULT NULL,
  `IGST` decimal(4,2) DEFAULT NULL,
  `DISC_RATE` decimal(4,2) DEFAULT NULL,
  `ADDL_TAX1_RATE` decimal(4,2) DEFAULT NULL,
  PRIMARY KEY (`ROW_ID`),
  KEY `TENANT_ID` (`TENANT_ID`),
  CONSTRAINT `DOD_ORDER_ITEMS_ibfk_1` FOREIGN KEY (`TENANT_ID`) REFERENCES `DOD_COMPANY` (`ROW_ID`)
);

select 'creating table dod_vendor_orders' as ' ';
CREATE TABLE `DOD_VENDOR_ORDERS` (
  `ROW_ID` mediumint(9) NOT NULL AUTO_INCREMENT,
  `ORDER_ID` mediumint(9) NOT NULL,
  `CUST_ID` mediumint(9) NOT NULL,
  `VENDOR_ID` mediumint(9) NOT NULL,
  `ORD_DATE` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `REQ_DATE` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `SHIPPED_DATE` timestamp NULL DEFAULT NULL,
  `SHIP_ADDRESS` varchar(200) DEFAULT NULL,
  `PAYMENT_MODE` char(3) DEFAULT NULL,
  `ORDER_AMT` decimal(7,2) DEFAULT NULL,
  `FULFILLED` char(1) DEFAULT NULL,
  `STATUS` char(3) DEFAULT NULL,
  `CREATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `UPDATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `DELETED_STATE` char(1) DEFAULT NULL,
  `TENANT_ID` mediumint(9) DEFAULT NULL,
  `COMMENTS` varchar(255) DEFAULT NULL,
  `SHIPZIPCODE` varchar(10) DEFAULT NULL,
  `SHIPCITY` varchar(50) DEFAULT NULL,
  `SHIPSTATE` varchar(50) DEFAULT NULL,
  `BILLADDRESS` varchar(200) DEFAULT NULL,
  `BILLZIPCODE` varchar(10) DEFAULT NULL,
  `BILLCITY` varchar(50) DEFAULT NULL,
  `BILLSTATE` varchar(50) DEFAULT NULL,
  `COUNTRY` varchar(50) DEFAULT NULL,
  `BILLSAMEASSHIP` char(1) DEFAULT 'Y',
  `STOREPICKUPENABLED` char(1) DEFAULT NULL,	
  `TOTAL_DISCOUNT` decimal(7,2) DEFAULT NULL,
  `TOTAL_TAX` decimal(7,2) DEFAULT NULL,
  `GSTNUMBER` varchar(20) DEFAULT NULL,
  `GSTORGNAME` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`ROW_ID`),
  KEY `TENANT_ID` (`TENANT_ID`),
  CONSTRAINT `DOD_VENDOR_ORDERS_ibfk_1` FOREIGN KEY (`TENANT_ID`) REFERENCES `DOD_COMPANY` (`ROW_ID`)
); 


CREATE TABLE `DOD_ORDER_TRACK` (
  `ROW_ID` mediumint(9) NOT NULL AUTO_INCREMENT,
  `ORDER_ID` mediumint(9) NOT NULL,
  `STATUS` char(3) DEFAULT NULL,
  `REMARKS` varchar(70) DEFAULT NULL,
  `UPDATED_BY` varchar(70) DEFAULT NULL,
  `TENANT_ID` mediumint(9) DEFAULT NULL,
  `UPDATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `CREATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`ROW_ID`),
  KEY `TENANT_ID` (`TENANT_ID`),
  KEY `ORDER_ID` (`ORDER_ID`),
  CONSTRAINT `DOD_ORDER_TRACK_ibfk_1` FOREIGN KEY (`TENANT_ID`) REFERENCES `DOD_COMPANY` (`ROW_ID`),
  CONSTRAINT `DOD_ORDER_TRACK_ibfk_2` FOREIGN KEY (`ORDER_ID`) REFERENCES `DOD_ORDER` (`ROW_ID`)
);

CREATE TABLE `DOD_ORDER_ITEMS_TRACK` (
  `ROW_ID` mediumint(9) NOT NULL AUTO_INCREMENT,
  `ORDER_ID` mediumint(9) NOT NULL,
  `ITEM_ID` mediumint(9) NOT NULL,
  `STATUS` char(3) DEFAULT NULL,
  `REMARKS` varchar(70) DEFAULT NULL,
  `UPDATED_BY` varchar(70) DEFAULT NULL,
  `UPDATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `TENANT_ID` mediumint(9) DEFAULT NULL,
  `CREATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`ROW_ID`),
  KEY `TENANT_ID` (`TENANT_ID`),
  KEY `ORDER_ID` (`ORDER_ID`),	
  KEY `ITEM_ID` (`ITEM_ID`),
  CONSTRAINT `DOD_ORDER_ITEMS_TRACK_ibfk_1` FOREIGN KEY (`TENANT_ID`) REFERENCES `DOD_COMPANY` (`ROW_ID`),
  CONSTRAINT `DOD_ORDER_ITEMS_TRACK_ibfk_2` FOREIGN KEY (`ORDER_ID`) REFERENCES `DOD_ORDER` (`ROW_ID`),
  CONSTRAINT `DOD_ORDER_ITEMS_TRACK_ibfk_3` FOREIGN KEY (`ITEM_ID`) REFERENCES `DOD_ORDER_ITEMS` (`ROW_ID`)
); 
select 'creating table dod_order_shipment' as ' ';
create table DOD_ORDER_SHIPMENT (
row_id mediumint auto_increment,
cust_order_id mediumint, 
vend_order_id mediumint,
waybill_no varchar(10),
order_date timestamp,
order_amt decimal(7,2),
total_discount decimal(2,2), 
name varchar(70),
company_name varchar(70),
addr1 varchar(100),
addr2 varchar(100),
addr3 varchar(100),
pin varchar(6),
city varchar(30),
state varchar(30),
country varchar(30),
phone varchar(16),
alt_phone varchar(16),
email varchar(100),
is_billing_same_as_shipping varchar(3),
billing_name varchar(70),
billing_company_name varchar(70),
billing_addr1 varchar(100),
billing_addr2 varchar(100),
billing_addr3 varchar(100),
biling_pin varchar(6),
billing_city varchar(30),
billing_state varchar(30),
billing_country varchar(30),
billing_phone varchar(16),
billing_alt_phone varchar(16),
billing_email varchar(100),
ship_length_cm smallint,
ship_width_cm smallint,
ship_height_cm smallint, 
weight float(5,2),
shipping_charges float(7,2),
giftwrap_charges float(7,2),
tran_charges float(7,2),
cod_charges float(7,2),
advance_amount float(7,2),
cod_amount float(7,2),
payment_mode char(4),
eway_bill_no varchar(20),
return_address_id smallint,
pickup_address_id smallint,
logistics varchar(20),
order_type varchar(10) default "forward",
s_type varchar(10),
tenant_id mediumint(9) DEFAULT NULL,
PRIMARY KEY (`ROW_ID`),
KEY `TENANT_ID` (`TENANT_ID`),
KEY `CUST_ORDER_ID` (`CUST_ORDER_ID`),
KEY `VEND_ORDER_ID` (`VEND_ORDER_ID`),
CONSTRAINT `DOD_ORDER_SHIPMENT_ibfk_1` FOREIGN KEY (`TENANT_ID`) REFERENCES `DOD_COMPANY` (`ROW_ID`),  
CONSTRAINT `DOD_ORDER_SHIPMENT_ibfk_2` FOREIGN KEY (`CUST_ORDER_ID`) REFERENCES `DOD_ORDER` (`ROW_ID`),
CONSTRAINT `DOD_ORDER_SHIPMENT_ibfk_3` FOREIGN KEY (`VEND_ORDER_ID`) REFERENCES `DOD_VENDOR_ORDERS` (`ROW_ID`)
);


select 'creating table dod_cust_wallet' as ' ';
CREATE TABLE `DOD_CUST_WALLET` (
  `ROW_ID` mediumint(9) NOT NULL AUTO_INCREMENT,
  `CUST_ID` mediumint(9) NOT NULL,
  `VENDOR_ID` mediumint(9) NOT NULL,
  `BALANCE` decimal(7,2) DEFAULT '0.00',
  `CREATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `UPDATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `DELETED_STATE` char(1) DEFAULT NULL,
  `TENANT_ID` mediumint(9) NOT NULL,
  PRIMARY KEY (`ROW_ID`),
  KEY `TENANT_ID` (`TENANT_ID`),
  KEY `CUST_ID` (`CUST_ID`),
  KEY `VENDOR_ID` (`VENDOR_ID`),
  CONSTRAINT `DOD_CUST_WALLET_ibfk_1` FOREIGN KEY (`TENANT_ID`) REFERENCES `DOD_COMPANY` (`ROW_ID`),
  CONSTRAINT `DOD_CUST_WALLET_ibfk_2` FOREIGN KEY (`CUST_ID`) REFERENCES `DOD_CUST_PROFILE` (`ROW_ID`),
  CONSTRAINT `DOD_CUST_WALLET_ibfk_3` FOREIGN KEY (`VENDOR_ID`) REFERENCES `DOD_VEND_PROFILE` (`ROW_ID`)
);



select 'creating table dod_vendor_tenants' as ' ';
CREATE TABLE `DOD_VENDOR_TENANTS` (
  `ROW_ID` mediumint(9) NOT NULL AUTO_INCREMENT,
  `VENDOR_ID` mediumint(9) NOT NULL,
  `TENANT_ID` mediumint(9) NOT NULL,
  `DEFAULT_FLAG` char(1) DEFAULT NULL,
  `DELETED_STATE` char(1) DEFAULT NULL,
  PRIMARY KEY (`ROW_ID`)
);


select 'creating table dod_upi_payments' as ' ';
CREATE TABLE `DOD_UPI_PAYMENTS` (
  `ROW_ID` mediumint(9) NOT NULL AUTO_INCREMENT,
  `TRANSACTION_ID` varchar(20) DEFAULT NULL,
  `VENDOR_ID` mediumint(9) NOT NULL,
  `CUST_ID` mediumint(9) NOT NULL,
  `AMOUNT` decimal(9,2) NOT NULL,
  `STATUS` char(10) DEFAULT NULL,
  `UTRNUM` varchar(20) NOT NULL,
  `PHONE` varchar(20) NOT NULL,
  `VENDORCONFIRM` char(1) DEFAULT NULL,
  `CREATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `UPDATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `CREATED_BY` mediumint(9) DEFAULT NULL,
  `UPDATED_BY` mediumint(9) DEFAULT NULL,
  `DELETED_STATE` char(1) DEFAULT NULL,
  `TENANT_ID` mediumint(9) DEFAULT NULL,
   PRIMARY KEY (`ROW_ID`),
   KEY `TENANT_ID` (`TENANT_ID`),
   CONSTRAINT `DOD_UPI_PAYMENTS_ibfk_1` FOREIGN KEY (`TENANT_ID`) REFERENCES `DOD_COMPANY` (`ROW_ID`)
);

select 'creating table dod_reviews' as ' ';
CREATE TABLE `DOD_REVIEWS` (
  `ROW_ID` mediumint(9) NOT NULL AUTO_INCREMENT,
  `RATING` smallint DEFAULT '0',
  `CREATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `DESCRIPTION` varchar(256) DEFAULT NULL,
  `DELETED_STATE` char(1) DEFAULT NULL,
  `TENANT_ID` mediumint(9) DEFAULT NULL,
  `PRODUCT_ID` mediumint(9) DEFAULT NULL,
  `CUSTOMER_ID` mediumint(9) DEFAULT NULL,
  `ORDER_ID` mediumint(9) DEFAULT NULL,
  PRIMARY KEY (`ROW_ID`),
  KEY `TENANT_ID` (`TENANT_ID`),
  KEY `PRODUCT_ID` (`PRODUCT_ID`),
  KEY `CUSTOMER_ID` (`CUSTOMER_ID`),
  KEY `ORDER_ID` (`ORDER_ID`),
  CONSTRAINT `DOD_REVIEWS_ibfk_1` FOREIGN KEY (`TENANT_ID`) REFERENCES `DOD_COMPANY` (`ROW_ID`),
  CONSTRAINT `DOD_REVIEWS_ibfk_2` FOREIGN KEY (`PRODUCT_ID`) REFERENCES `DOD_PRD_MASTER` (`ROW_ID`),
  CONSTRAINT `DOD_REVIEWS_ibfk_3` FOREIGN KEY (`CUSTOMER_ID`) REFERENCES `DOD_CUST_PROFILE` (`ROW_ID`),
  CONSTRAINT `DOD_REVIEWS_ibfk_4` FOREIGN KEY (`ORDER_ID`) REFERENCES `DOD_ORDER` (`ROW_ID`)
);


CREATE TABLE `DOD_ROLES` (
  `ROW_ID` mediumint(9) NOT NULL AUTO_INCREMENT,
  `NAME` varchar(30) DEFAULT NULL,
  `DESCRIPTION` varchar(255) DEFAULT NULL,
  `CREATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `CREATED_BY` mediumint(9) DEFAULT NULL,
  `ACTIVE_FLG` char(1) DEFAULT NULL,
  `DELETED_STATE` char(1) DEFAULT NULL,
  `UPDATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `UPDATED_BY` mediumint(9) DEFAULT NULL,
  PRIMARY KEY (`ROW_ID`)
);

select 'creating table dod_user_roles' as ' ';
CREATE TABLE `DOD_USER_ROLES` (
  `ROW_ID` mediumint(9) NOT NULL AUTO_INCREMENT,
  `USER_ID` mediumint(9) NOT NULL,
  `ROLE_ID` mediumint(9) NOT NULL,
  `TENANT_ID` mediumint(9) NOT NULL,
  PRIMARY KEY (`ROW_ID`),
  KEY `TENANT_ID` (`TENANT_ID`),
  KEY `USER_ID` (`USER_ID`),
  KEY `ROLE_ID` (`ROLE_ID`),
  CONSTRAINT `DOD_USER_ROLES_ibfk_1` FOREIGN KEY (`TENANT_ID`) REFERENCES `DOD_COMPANY` (`ROW_ID`),
  CONSTRAINT `DOD_USER_ROLES_ibfk_2` FOREIGN KEY (`USER_ID`) REFERENCES `DOD_USERS` (`ROW_ID`),
  CONSTRAINT `DOD_USER_ROLES_ibfk_3` FOREIGN KEY (`ROLE_ID`) REFERENCES `DOD_ROLES` (`ROW_ID`)
);

select 'creating table dod_password_reset' as ' ';
CREATE TABLE `DOD_PASSWORD_RESET` (
  `ROW_ID` mediumint(9) NOT NULL AUTO_INCREMENT,
  `USER_TYPE` varchar(30) NOT NULL,
  `EMAIL` varchar(255) NOT NULL,
  `CREATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `UPDATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `TOKEN` varchar(512) NOT NULL,
  `ACTIVE_FLG` char(1) NOT NULL DEFAULT 'N',
  `TENANT_ID` mediumint(9) NOT NULL,
  `DELETED_STATE` char(1) DEFAULT NULL,
  PRIMARY KEY (`ROW_ID`),
  KEY `TENANT_ID` (`TENANT_ID`),			
  CONSTRAINT `DOD_PASSWORD_RESET_ibfk_1` FOREIGN KEY (`TENANT_ID`) REFERENCES `DOD_COMPANY` (`ROW_ID`)
);



select 'creating table dod_auth_attr' as ' ';
CREATE TABLE `DOD_AUTH_ATTR_LOOKUP` (
  `ROW_ID` mediumint(9) NOT NULL AUTO_INCREMENT,
  `NAME` varchar(50) DEFAULT NULL,
  `DESCRIPTION` varchar(100) DEFAULT NULL,
-- lisp function where the underlying code to get the attribute value from business logic will be written.
-- this function is hidden from the ui.  
  `ATTR_FUNC` varchar(100) NOT NULL,
-- lisp function to get a list of unique values for that particular attribute.   
   `ATTR_UNIQUE_FUNC` varchar(100) NOT NULL,
-- attribute types are "action" "subject" "resource" "context_based" 
   `ATTR_TYPE` varchar(50) DEFAULT NULL,
  `CREATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `CREATED_BY` mediumint(9) DEFAULT NULL,
  `ACTIVE_FLG` char(1) DEFAULT NULL,
  `DELETED_STATE` char(1) DEFAULT NULL,
  `TENANT_ID` mediumint(9) NOT NULL,
  PRIMARY KEY (`ROW_ID`),
  KEY `TENANT_ID` (`TENANT_ID`),
  CONSTRAINT `DOD_AUTH_ATTR_LOOKUP_ibfk_1` FOREIGN KEY (`TENANT_ID`) REFERENCES `DOD_COMPANY` (`ROW_ID`)
);

select 'creating table dod_auth_policy' as ' ';
CREATE TABLE `DOD_AUTH_POLICY` (
  `ROW_ID` mediumint(9) NOT NULL AUTO_INCREMENT,
  `NAME` varchar(50) DEFAULT NULL,
  `DESCRIPTION` varchar(100) DEFAULT NULL,
-- whoever is creating a policy here has to paste a lisp function which is syntactically correct. 
  `POLICY_FUNC` varchar(255) DEFAULT NULL,
  `CREATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `UPDATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `CREATED_BY` mediumint(9) DEFAULT NULL,
  `ACTIVE_FLG` char(1) DEFAULT NULL,
  `DELETED_STATE` char(1) DEFAULT NULL,
  `TENANT_ID` mediumint(9) NOT NULL,
  PRIMARY KEY (`ROW_ID`),
  KEY `TENANT_ID` (`TENANT_ID`), 
  CONSTRAINT `DOD_AUTH_POLICY_ibfk_1` FOREIGN KEY (`TENANT_ID`) REFERENCES `DOD_COMPANY` (`ROW_ID`) 
) ;


select 'creating table dod_auth_policy_attr' as ' '; 
CREATE TABLE `DOD_AUTH_POLICY_ATTR` (
  `ROW_ID` mediumint(9) NOT NULL AUTO_INCREMENT,
  `POLICY_ID` mediumint(9) DEFAULT NULL,
  `ATTRIBUTE_ID` mediumint(9) DEFAULT NULL,
  `ATTR_VAL` varchar(100) NOT NULL DEFAULT '<substitute>',
  `TENANT_ID` mediumint(9) NOT NULL,
  PRIMARY KEY (`ROW_ID`),
  KEY `TENANT_ID` (`TENANT_ID`),
  KEY `ATTRIBUTE_ID` (`ATTRIBUTE_ID`),
  KEY `POLICY_ID` (`POLICY_ID`),
  CONSTRAINT `DOD_AUTH_POLICY_ATTR_ibfk_1` FOREIGN KEY (`TENANT_ID`) REFERENCES `DOD_COMPANY` (`ROW_ID`),
  CONSTRAINT `DOD_AUTH_POLICY_ATTR_ibfk_2` FOREIGN KEY (`ATTRIBUTE_ID`) REFERENCES `DOD_AUTH_ATTR_LOOKUP` (`ROW_ID`),
  CONSTRAINT `DOD_AUTH_POLICY_ATTR_ibfk_3` FOREIGN KEY (`POLICY_ID`) REFERENCES `DOD_AUTH_POLICY` (`ROW_ID`)
);

select 'creating table dod_bus_object' as ' ' ; 
CREATE TABLE `DOD_BUS_OBJECT` (
  `ROW_ID` mediumint(9) NOT NULL AUTO_INCREMENT,
  `NAME` varchar(100) DEFAULT NULL,
  `CREATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `UPDATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `CREATED_BY` mediumint(9) DEFAULT NULL,
  `ACTIVE_FLG` char(1) DEFAULT NULL,
  `DELETED_STATE` char(1) DEFAULT NULL,
  `TENANT_ID` mediumint(9) NOT NULL,
  `hhub_type` varchar(100) NOT NULL,
  PRIMARY KEY (`ROW_ID`),
  KEY `TENANT_ID` (`TENANT_ID`),
  CONSTRAINT `DOD_BUS_OBJECT_ibfk_1` FOREIGN KEY (`TENANT_ID`) REFERENCES `DOD_COMPANY` (`ROW_ID`)
);

select 'creating table dod_abac_subject' as ' ' ;
CREATE TABLE `DOD_ABAC_SUBJECT` (
  `ROW_ID` mediumint(9) NOT NULL AUTO_INCREMENT,
  `NAME` varchar(100) DEFAULT NULL,
  `CREATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `UPDATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `CREATED_BY` mediumint(9) DEFAULT NULL,
  `ACTIVE_FLG` char(1) DEFAULT NULL,
  `DELETED_STATE` char(1) DEFAULT NULL,
  `TENANT_ID` mediumint(9) NOT NULL,
  `hhub_type` varchar(100) NOT NULL,
  PRIMARY KEY (`ROW_ID`),
  KEY `TENANT_ID` (`TENANT_ID`),
  CONSTRAINT `DOD_ABAC_SUBJECT_ibfk_1` FOREIGN KEY (`TENANT_ID`) REFERENCES `DOD_COMPANY` (`ROW_ID`)
);



select 'creating table dod_bus_transaction' as ' ';
CREATE TABLE `DOD_BUS_TRANSACTION` (
  `ROW_ID` mediumint(9) NOT NULL AUTO_INCREMENT,
  `NAME` varchar(100) DEFAULT NULL,
  `URI` varchar(100) DEFAULT NULL,
  `AUTH_POLICY_ID` mediumint(9) NOT NULL,
  `TRANS_TYPE` varchar(15) DEFAULT NULL,
  `CREATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `UPDATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `CREATED_BY` mediumint(9) DEFAULT NULL,
  `ACTIVE_FLG` char(1) DEFAULT NULL,
  `DELETED_STATE` char(1) DEFAULT NULL,
  `TENANT_ID` mediumint(9) NOT NULL,
  `TRANS_FUNC` varchar(100) DEFAULT NULL,
  `ABAC_SUBJECT_ID` mediumint(9) DEFAULT NULL,
  PRIMARY KEY (`ROW_ID`),
  KEY `TENANT_ID` (`TENANT_ID`),
  KEY `AUTH_POLICY_ID` (`AUTH_POLICY_ID`),
  KEY `ABAC_SUBJECT_ID` (`ABAC_SUBJECT_ID`),
  CONSTRAINT `DOD_BUS_TRANSACTION_ibfk_1` FOREIGN KEY (`TENANT_ID`) REFERENCES `DOD_COMPANY` (`ROW_ID`),
  CONSTRAINT `DOD_BUS_TRANSACTION_ibfk_2` FOREIGN KEY (`AUTH_POLICY_ID`) REFERENCES `DOD_AUTH_POLICY` (`ROW_ID`),
  CONSTRAINT `DOD_BUS_TRANSACTION_ibfk_3` FOREIGN KEY (`ABAC_SUBJECT_ID`) REFERENCES `DOD_ABAC_SUBJECT` (`ROW_ID`)
);


select 'creating table dod_vendor_availability_day' as ' ';
CREATE TABLE `DOD_VENDOR_AVAILABILITY_DAY` (
  `ROW_ID` mediumint(9) NOT NULL AUTO_INCREMENT,
  `VENDOR_ID` mediumint(9) NOT NULL,
  `AVAIL_DATE` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `START_TIME` timestamp, 
  `END_TIME` timestamp,
  `LEAVE_FLAG` char(1) DEFAULT NULL,
  `BREAK_START_TIME` timestamp,
  `BREAK_END_TIME` timestamp,
  `COMMENTS` varchar(512) DEFAULT NULL,
  `CREATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `UPDATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `CREATED_BY` mediumint(9) DEFAULT NULL,
  `ACTIVE_FLG` char(1) DEFAULT NULL,
  `DELETED_STATE` char(1) DEFAULT NULL,
  `TENANT_ID` mediumint(9) NOT NULL,
  PRIMARY KEY (`ROW_ID`),
  KEY `TENANT_ID` (`TENANT_ID`),
  KEY `VENDOR_ID` (`VENDOR_ID`),
  CONSTRAINT `DOD_VENDOR_AVAILABILITY_DAY_ibfk_1` FOREIGN KEY (`TENANT_ID`) REFERENCES `DOD_COMPANY` (`ROW_ID`),
  CONSTRAINT `DOD_VENDOR_AVAILABILITY_DAY_ibfk_2` FOREIGN KEY (`VENDOR_ID`) REFERENCES `DOD_VEND_PROFILE` (`ROW_ID`)
);


select 'creating table dod_vendor_availability' as ' ';
CREATE TABLE `DOD_VENDOR_APPOINTMENT` (
  `ROW_ID` mediumint(9) NOT NULL AUTO_INCREMENT,
  `VENDOR_ID` mediumint(9) NOT NULL,
  `CUST_ID` mediumint(9) DEFAULT NULL,
  `APPT_DATE` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `START_TIME` timestamp,
  `END_TIME` timestamp,
  `STATUS` varchar(30) DEFAULT NULL,
  `COMMENTS` varchar(512) DEFAULT NULL,
  `CREATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `UPDATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `CREATED_BY` mediumint(9) DEFAULT NULL,
  `ACTIVE_FLG` char(1) DEFAULT NULL,
  `DELETED_STATE` char(1) DEFAULT NULL,
  `TENANT_ID` mediumint(9) NOT NULL,
  PRIMARY KEY (`ROW_ID`),
  KEY `TENANT_ID` (`TENANT_ID`),
  KEY `VENDOR_ID` (`VENDOR_ID`),
  KEY `CUST_ID` (`CUST_ID`),
  CONSTRAINT `DOD_VENDOR_APPOINTMENT_ibfk_1` FOREIGN KEY (`TENANT_ID`) REFERENCES `DOD_COMPANY` (`ROW_ID`),
  CONSTRAINT `DOD_VENDOR_APPOINTMENT_ibfk_2` FOREIGN KEY (`VENDOR_ID`) REFERENCES `DOD_VEND_PROFILE` (`ROW_ID`),
  CONSTRAINT `DOD_VENDOR_APPOINTMENT_ibfk_3` FOREIGN KEY (`CUST_ID`) REFERENCES `DOD_CUST_PROFILE` (`ROW_ID`)
);




select 'creating table dod_webpush_notify' as ' ';
CREATE TABLE `DOD_WEBPUSH_NOTIFY` (
  `ROW_ID` mediumint(9) NOT NULL AUTO_INCREMENT,
  `CUST_ID` mediumint(9) DEFAULT NULL,
  `VENDOR_ID` mediumint(9) DEFAULT NULL,
  `PERSON_TYPE` varchar(30) NOT NULL,
  `BROWSER_NAME` varchar(30) NOT NULL,
  `ENDPOINT` varchar(512) NOT NULL,
  `PUBLICKEY` varchar(100) NOT NULL,
  `AUTH` varchar(100) NOT NULL,
  `EXPIRED` char(1) DEFAULT NULL,
  `PERM_GRANTED` char(1) DEFAULT NULL,
  `CREATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `UPDATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `CREATED_BY` mediumint(9) DEFAULT NULL,
  `ACTIVE_FLAG` char(1) DEFAULT NULL,
  `DELETED_STATE` char(1) DEFAULT NULL,
  `TENANT_ID` mediumint(9) NOT NULL,
  PRIMARY KEY (`ROW_ID`),
  KEY `TENANT_ID` (`TENANT_ID`),
  KEY `VENDOR_ID` (`VENDOR_ID`),
  KEY `CUST_ID` (`CUST_ID`),
  CONSTRAINT `DOD_WEBPUSH_NOTIFY_ibfk_1` FOREIGN KEY (`TENANT_ID`) REFERENCES `DOD_COMPANY` (`ROW_ID`),
  CONSTRAINT `DOD_WEBPUSH_NOTIFY_ibfk_2` FOREIGN KEY (`VENDOR_ID`) REFERENCES `DOD_VEND_PROFILE` (`ROW_ID`),
  CONSTRAINT `DOD_WEBPUSH_NOTIFY_ibfk_3` FOREIGN KEY (`CUST_ID`) REFERENCES `DOD_CUST_PROFILE` (`ROW_ID`)
);


CREATE TABLE `DOD_PAYMENT_TRANSACTION` (
  `ROW_ID` mediumint(9) NOT NULL AUTO_INCREMENT,
  `ORDER_ID` varchar(100) NOT NULL,
  `AMT` decimal(7,2) NOT NULL,
  `CURRENCY` varchar(10) DEFAULT NULL,
  `DESCRIPTION` varchar(200) DEFAULT NULL,
  `CUSTOMER_ID` mediumint(9) NOT NULL,
  `VENDOR_ID` mediumint(9) NOT NULL,
  `PAYMENT_MODE` varchar(20) DEFAULT NULL,
  `TRANSACTION_ID` varchar(30) NOT NULL,
  `PAYMENT_DATETIME` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `RESPONSE_CODE` smallint(6) DEFAULT NULL,
  `RESPONSE_MESSAGE` varchar(100) DEFAULT NULL,
  `ERROR_DESC` varchar(100) DEFAULT NULL,
  `CREATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `CREATED_BY` mediumint(9) DEFAULT NULL,
  `DELETED_STATE` char(1) DEFAULT NULL,
  `TENANT_ID` mediumint(9) NOT NULL,
  PRIMARY KEY (`ROW_ID`),
  KEY `TENANT_ID` (`TENANT_ID`),
  KEY `CUSTOMER_ID` (`CUSTOMER_ID`),
  KEY `VENDOR_ID` (`VENDOR_ID`),
  CONSTRAINT `DOD_PAYMENT_TRANSACTION_ibfk_1` FOREIGN KEY (`TENANT_ID`) REFERENCES `DOD_COMPANY` (`ROW_ID`),
  CONSTRAINT `DOD_PAYMENT_TRANSACTION_ibfk_2` FOREIGN KEY (`CUSTOMER_ID`) REFERENCES `DOD_CUST_PROFILE` (`ROW_ID`),
  CONSTRAINT `DOD_PAYMENT_TRANSACTION_ibfk_3` FOREIGN KEY (`VENDOR_ID`) REFERENCES `DOD_VEND_PROFILE` (`ROW_ID`)
);
