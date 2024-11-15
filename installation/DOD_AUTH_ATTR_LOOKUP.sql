-- MySQL dump 10.13  Distrib 8.0.40, for Linux (x86_64)
--
-- Host: localhost    Database: hhubdb
-- ------------------------------------------------------
-- Server version	8.0.40-0ubuntu0.22.04.1

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `DOD_AUTH_ATTR_LOOKUP`
--

DROP TABLE IF EXISTS `DOD_AUTH_ATTR_LOOKUP`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `DOD_AUTH_ATTR_LOOKUP` (
  `ROW_ID` mediumint NOT NULL AUTO_INCREMENT,
  `NAME` varchar(50) DEFAULT NULL,
  `DESCRIPTION` varchar(100) DEFAULT NULL,
  `ATTR_FUNC` varchar(100) NOT NULL,
  `ATTR_UNIQUE_FUNC` varchar(100) NOT NULL,
  `ATTR_TYPE` varchar(50) DEFAULT NULL,
  `CREATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `CREATED_BY` mediumint DEFAULT NULL,
  `ACTIVE_FLG` char(1) DEFAULT NULL,
  `DELETED_STATE` char(1) DEFAULT NULL,
  `TENANT_ID` mediumint NOT NULL,
  PRIMARY KEY (`ROW_ID`),
  KEY `TENANT_ID` (`TENANT_ID`),
  CONSTRAINT `DOD_AUTH_ATTR_LOOKUP_ibfk_1` FOREIGN KEY (`TENANT_ID`) REFERENCES `DOD_COMPANY` (`ROW_ID`)
) ENGINE=InnoDB AUTO_INCREMENT=75 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `DOD_AUTH_ATTR_LOOKUP`
--

LOCK TABLES `DOD_AUTH_ATTR_LOOKUP` WRITE;
/*!40000 ALTER TABLE `DOD_AUTH_ATTR_LOOKUP` DISABLE KEYS */;
INSERT INTO `DOD_AUTH_ATTR_LOOKUP` VALUES (46,'com.hhub.attribute.role.name','Role name is described. The attribute function will get the role name of the currently logged in use','com-hhub-attribute-role-name','','OBJECT','2022-12-18 06:48:12',NULL,'Y','N',1),(47,'com.hhub.attribute.login.vendor.name','Return the Vendor\"s name in the current login context for Vendor website.','com-hhub-attribute-login-vendor-name','','SUBJECT','2022-12-18 06:48:12',NULL,'Y','N',1),(48,'com.hhub.attribute.login.cust.name','Get the name of customer in current login context of the customer website.','com-hhub-attribute-login-cust-name','','SUBJECT','2022-12-18 06:48:12',NULL,'Y','N',1),(49,'com.hhub.attribute.login.user.name','User who has logged into the System admin website. ','com-hhub-attribute-login-user-name','','SUBJECT','2022-12-18 06:48:12',NULL,'Y','N',1),(50,'com.hhub.attribute.login.user.role','Role of the user who is logged into the system admin site. ','com-hhub-attribute-login-user-role','','SUBJECT','2022-12-18 06:48:12',NULL,'Y','N',1),(51,'com.hhub.attribute.customer.order.cutoff.time','Time deadline before which the customer has to order something. ','com-hhub-attribute-customer-order-cutoff-time','','ENVIRONMENT','2022-12-18 06:48:12',NULL,'Y','N',1),(52,'com.hhub.attribute.role.instance','Get the logged in users\" role instance. ','com-hhub-attribute-role-instance','','OBJECT','2022-12-18 06:48:12',NULL,'Y','N',1),(53,'com.hhub.attribute.customer.type','Type of the customer. There are STANDARD  GUEST customers. ','com-hhub-attribute-customer-type','','SUBJECT','2022-12-18 06:48:12',NULL,'Y','N',1),(54,'com.hhub.attribute.vendor.issuspended','Check whether vendor is suspended','com-hhub-attribute-vendor-issuspended','','SUBJECT','2022-12-18 06:48:12',NULL,'Y','N',1),(55,'com.hhub.attribute.company.currentprodcatgcount','Get the company\'s current product category count. ','com-hhub-attribute-company-currentprodcatgcount','','OBJECT','2022-12-18 06:48:12',NULL,'Y','N',1),(56,'com.hhub.attribute.vendor.issuspended','Check whether Vendor is Suspended','com-hhub-attribute-vendor-issuspended','','SUBJECT','2022-12-18 06:48:12',NULL,'Y','N',1),(57,'com.hhub.attribute.company.issuspended','Checks whether a Company/Account is suspended','com-hhub-attribute-company-issuspended','','OBJECT','2022-12-18 06:48:12',NULL,'Y','N',1),(58,'com.hhub.attribute.company.maxvendorcount','Maximum Number of Vendors allowedrnHHUBTEST = 1rnBASIC = 5rnPROFESSIONAL = 10','com-hhub-attribute-company-maxvendorcount','','OBJECT','2022-12-18 06:48:12',NULL,'Y','N',1),(59,'com.hhub.attribute.vendor.maxproductcount','Max product count rnHHUBTEST = 100rnBASIC = 1000rnPROFESSIONAL = 3000','com-hhub-attribute-vendor-maxproductcount','','OBJECT','2022-12-18 06:48:12',NULL,'Y','N',1),(60,'com.hhub.attribute.company.prdbulkupload.enabled','Whether products bulk upload for a company is enabled or not. ','com-hhub-attribute-company-prdbulkupload-enabled','','OBJECT','2022-12-18 06:48:12',NULL,'Y','N',1),(61,'com.hhub.attribute.account.trial.maxvendors','This attribute defines the number of vendors allowed for a given company/account type','com-hhub-attribute-account-trial-maxvendors','','OBJECT','2022-12-18 06:48:12',NULL,'Y','N',1),(62,'com.hhub.attribute.company.maxcustomercount','Max customer count for a given company. ','com-hhub-attribute-company-maxcustomercount','','OBJECT','2022-12-18 06:48:12',NULL,'Y','N',1),(63,'com.hhub.attribute.company.prdsubs.enabled','Product subscriptions enabled for a company. Based on type of company. TRIAL = N  BASIC = ENABLED','com-hhub-attribute-company-prdsubs-enabled','','OBJECT','2022-12-18 06:48:12',NULL,'Y','N',1),(64,'com.hhub.attribute.company.prdsubs.enabled','Product subscriptions enabled for a company. Based on type of company. TRIAL = N  BASIC = ENABLED','com-hhub-attribute-company-prdsubs-enabled','','OBJECT','2022-12-18 06:48:12',NULL,'Y','N',1),(65,'com.hhub.attribute.company.wallets.enabled','Wallets enabled for company type. TRIAL = N  BASIC = N  PROFESSIONAL = Y','com-hhub-attribute-company-wallets-enabled','','OBJECT','2022-12-18 06:48:12',NULL,'Y','N',1),(66,'com.hhub.attribute.company.codorders.enabled','Cash on demand orders enabled for company type. TRIAL = N  BASIC = N  PROFESSIONAL = Y','com-hhub-attribute-company-codorders-enabled','','OBJECT','2022-12-18 06:48:12',NULL,'Y','N',1),(67,'com.hhub.attribute.company.subscription.plan','TRIAL  BASIC  STANDARD','com-hhub-attribute-company-subscription-plan','','OBJECT','2022-12-18 06:48:12',NULL,'Y','N',1),(68,'com.hhub.attribute.company.maxprodcatgcount','Product category count for a given vendor is based on the subscription plan for that company. \r\nTRIA','com-hhub-attribute-company-maxprodcatgcount','','OBJECT','2023-04-06 10:48:57',NULL,'Y','N',1),(69,'com.hhub.attribute.vendor.shipping.enabled','Checks whether shipping is enabled for a vendor','com-hhub-attribute-vendor-shipping-enabled','','SUBJECT','2023-07-28 18:36:25',NULL,'Y','N',1),(70,'com.hhub.attribute.vendor.freeship.enabled','Free shipping method is enabled for a vendor','com-hhub-attribute-vendor-freeship-enabled','','OBJECT','2023-10-09 09:50:15',NULL,'Y','N',1),(71,'com.hhub.attribute.vendor.flatrateship.enabled','Checks whether Flatrate shipping is enabled for a vendor','com-hhub-attribute-vendor-flatrateship-enabled','','OBJECT','2023-10-09 09:54:52',NULL,'Y','N',1),(72,'com.hhub.attribute.vendor.tablerateship.enabled','Checks whether tablerate or zonewise shipping is enabled for a vendor.','com-hhub-attribute-vendor-tablerateship-enabled','','OBJECT','2023-10-09 09:56:11',NULL,'Y','N',1),(73,'com.hhub.attribute.vendor.externalship.enabled','checks whether external shipping partners are enabled for a vendor','com-hhub-attribute-vendor-externalship-enabled','','OBJECT','2023-10-09 09:56:52',NULL,'Y','N',1),(74,'com.hhub.attribute.vendor.storepickup.enabled','Check whether store pickup is enabled for a vendor.','com-hhub-attribute-vendor-storepickup-enabled','','OBJECT','2023-10-12 05:27:40',NULL,'Y','N',1);
/*!40000 ALTER TABLE `DOD_AUTH_ATTR_LOOKUP` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2024-11-15 12:04:32
