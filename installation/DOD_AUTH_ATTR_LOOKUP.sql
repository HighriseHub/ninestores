-- MySQL dump 10.13  Distrib 5.7.32, for Linux (x86_64)
--
-- Host: localhost    Database: DAIRYONDEMAND
-- ------------------------------------------------------
-- Server version	5.7.32

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
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
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `DOD_AUTH_ATTR_LOOKUP` (
  `ROW_ID` mediumint(9) NOT NULL AUTO_INCREMENT,
  `NAME` varchar(50) DEFAULT NULL,
  `DESCRIPTION` varchar(100) DEFAULT NULL,
  `ATTR_FUNC` varchar(100) NOT NULL,
  `ATTR_UNIQUE_FUNC` varchar(100) NOT NULL,
  `ATTR_TYPE` varchar(50) DEFAULT NULL,
  `CREATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `CREATED_BY` mediumint(9) DEFAULT NULL,
  `ACTIVE_FLG` char(1) DEFAULT NULL,
  `DELETED_STATE` char(1) DEFAULT NULL,
  `TENANT_ID` mediumint(9) NOT NULL,
  PRIMARY KEY (`ROW_ID`),
  KEY `TENANT_ID` (`TENANT_ID`),
  CONSTRAINT `DOD_AUTH_ATTR_LOOKUP_ibfk_1` FOREIGN KEY (`TENANT_ID`) REFERENCES `DOD_COMPANY` (`ROW_ID`)
) ENGINE=InnoDB AUTO_INCREMENT=37 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `DOD_AUTH_ATTR_LOOKUP`
--

LOCK TABLES `DOD_AUTH_ATTR_LOOKUP` WRITE;
/*!40000 ALTER TABLE `DOD_AUTH_ATTR_LOOKUP` DISABLE KEYS */;
INSERT INTO `DOD_AUTH_ATTR_LOOKUP` VALUES (1,'com.hhub.attribute.role.name','Role name is described. The attribute function will get the role name of the currently logged in use','com-hhub-attribute-role-name','DOD-UNIQUE-ATTR-ROLE.NAME','OBJECT','2017-12-19 08:01:37',NULL,'Y','N',1),(3,'com.hhub.attribute.login.vendor.name','Return the Vendor\'s name in the current login context for Vendor website. ','com-hhub-attribute-login-vendor-name','','SUBJECT','2018-01-18 08:33:53',NULL,'Y','N',1),(4,'com.hhub.attribute.login.cust.name','Get the name of customer in current login context of the customer website.','com-hhub-attribute-login-cust-name','','SUBJECT','2018-01-18 13:42:56',NULL,'Y','N',1),(5,'com.hhub.attribute.login.user.name','User who has logged into the System admin website. ','com-hhub-attribute-login-user-name','','SUBJECT','2018-01-19 06:20:50',NULL,'Y','N',1),(6,'com.hhub.attribute.login.user.role','Role of the user who is logged into the system admin site. ','com-hhub-attribute-login-user-role','','SUBJECT','2018-05-02 17:57:31',NULL,'Y','N',1),(12,'com.hhub.attribute.customer.order.cutoff.time','Time deadline before which the customer has to order something. ','com-hhub-attribute-customer-order-cutoff-time','','ENVIRONMENT','2018-05-03 12:04:17',NULL,'Y','N',1),(21,'com.hhub.attribute.role.instance','Get the logged in users\' role instance. ','com-hhub-attribute-role-instance','','OBJECT','2019-01-09 06:31:49',NULL,'Y','N',1),(22,'com.hhub.attribute.customer.type','Type of the customer. There are STANDARD, GUEST customers. ','com-hhub-attribute-customer-type','','SUBJECT','2019-07-27 01:20:09',NULL,'Y','N',1),(23,'com.hhub.attribute.vendor.issuspended','Check whether vendor is suspended','com-hhub-attribute-vendor-issuspended','','SUBJECT','2021-01-12 07:18:06',NULL,'Y','N',1),(24,'com.hhub.attribute.vendor.issuspended','Check whether Vendor is Suspended','com-hhub-attribute-vendor-issuspended','','SUBJECT','2021-01-12 07:19:36',NULL,'Y','N',1),(25,'com.hhub.attribute.vendor.issuspended','Check whether Vendor is Suspended','com-hhub-attribute-vendor-issuspended','','SUBJECT','2021-01-12 07:21:39',NULL,'Y','N',1),(26,'com.hhub.attribute.company.issuspended','Checks whether a Company/Account is suspended','com-hhub-attribute-company-issuspended','','OBJECT','2021-01-12 07:24:54',NULL,'Y','N',1),(27,'com.hhub.attribute.company.maxvendorcount','Maximum Number of Vendors allowed\r\nHHUBTEST = 1\r\nBASIC = 5\r\nPROFESSIONAL = 10','com-hhub-attribute-company-maxvendorcount','','OBJECT','2021-01-26 06:24:32',NULL,'Y','N',1),(28,'com.hhub.attribute.company.maxproductcount','Max product count \r\nHHUBTEST = 100\r\nBASIC = 1000\r\nPROFESSIONAL = 3000','com-hhub-attribute-company-maxproductcount','','OBJECT','2021-01-26 11:39:42',NULL,'Y','N',1),(29,'com.hhub.attribute.company.prdbulkupload.enabled','Whether products bulk upload for a company is enabled or not. ','com-hhub-attribute-company-prdbulkupload-enabled','','OBJECT','2021-01-26 11:47:51',NULL,'Y','N',1),(30,'com.hhub.attribute.account.trial.maxvendors','This attribute defines the number of vendors allowed for a given company/account type','com-hhub-attribute-account-trial-maxvendors','','OBJECT','2021-04-01 07:27:14',NULL,'Y','N',1),(31,'com.hhub.attribute.company.maxcustomercount','Max customer count for a given company. ','com-hhub-attribute-company-maxcustomercount','','OBJECT','2021-04-01 07:29:03',NULL,'Y','N',1),(32,'com.hhub.attribute.company.prdsubs.enabled','Product subscriptions enabled for a company. Based on type of company. TRIAL = N, BASIC = ENABLED , ','com-hhub-attribute-company-prdsubs-enabled','','OBJECT','2021-04-03 15:13:38',NULL,'Y','N',1),(33,'com.hhub.attribute.company.prdsubs.enabled','Product subscriptions enabled for a company. Based on type of company. TRIAL = N, BASIC = ENABLED , ','com-hhub-attribute-company-prdsubs-enabled','','OBJECT','2021-04-03 15:15:13',NULL,'Y','N',1),(34,'com.hhub.attribute.company.wallets.enabled','Wallets enabled for company type. TRIAL = N, BASIC = N, PROFESSIONAL = Y','com-hhub-attribute-company-wallets-enabled','','OBJECT','2021-04-03 15:49:28',NULL,'Y','N',1),(35,'com.hhub.attribute.company.codorders.enabled','Cash on demand orders enabled for company type. TRIAL = N, BASIC = N, PROFESSIONAL = Y','com-hhub-attribute-company-codorders-enabled','','OBJECT','2021-04-03 15:50:14',NULL,'Y','N',1),(36,'com.hhub.attribute.company.subscription.plan','TRIAL, BASIC, STANDARD','com-hhub-attribute-company-subscription-plan','','OBJECT','2021-09-29 05:01:18',NULL,'Y','N',1);
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

-- Dump completed on 2022-12-09 20:05:38
