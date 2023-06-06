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
-- Table structure for table `DOD_BUS_TRANSACTION`
--

DROP TABLE IF EXISTS `DOD_BUS_TRANSACTION`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `DOD_BUS_TRANSACTION` (
  `ROW_ID` mediumint(9) NOT NULL AUTO_INCREMENT,
  `NAME` varchar(100) DEFAULT NULL,
  `URI` varchar(100) DEFAULT NULL,
  `AUTH_POLICY_ID` mediumint(9) NOT NULL,
  `TRANS_TYPE` varchar(15) DEFAULT NULL,
  `CREATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
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
  CONSTRAINT `DOD_BUS_TRANSACTION_ibfk_3` FOREIGN KEY (`AUTH_POLICY_ID`) REFERENCES `DOD_AUTH_POLICY` (`ROW_ID`),
  CONSTRAINT `DOD_BUS_TRANSACTION_ibfk_4` FOREIGN KEY (`ABAC_SUBJECT_ID`) REFERENCES `DOD_ABAC_SUBJECT` (`ROW_ID`)
) ENGINE=InnoDB AUTO_INCREMENT=28 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `DOD_BUS_TRANSACTION`
--

LOCK TABLES `DOD_BUS_TRANSACTION` WRITE;
/*!40000 ALTER TABLE `DOD_BUS_TRANSACTION` DISABLE KEYS */;
INSERT INTO `DOD_BUS_TRANSACTION` VALUES (1,'com.hhub.transaction.create.company','/hhub/createcompanyaction',1,'CREATE','2017-12-19 08:01:37',NULL,'Y','N',1,'com-hhub-transaction-create-company',NULL),(5,'com.hhub.transaction.create.attribute','/hhub/dasaddattribute',9,'CREATE','2018-01-17 12:17:43',NULL,'Y','N',1,'com-hhub-transaction-create-attribute',NULL),(6,'com.hhub.transaction.policy.create','/hhub/dasaddpolicyaction',10,'CREATE','2018-01-18 10:43:56',NULL,'Y','N',1,'com-hhub-transaction-policy-create',NULL),(9,'com.hhub.transaction.create.order','/hhub/dodmyorderaddaction',11,'CREATE','2018-05-02 10:25:39',NULL,'Y','N',1,'com-hhub-transaction-create-order',NULL),(10,'com.hhub.transaction.cust.edit.order.item','/hhub/dodcustorditemedit',12,'UPDATE','2018-07-04 05:54:25',NULL,'Y','N',1,'com-hhub-transaction-cust-edit-order-item',NULL),(11,'com.hhub.transaction.sadmin.home','/hhub/sadminhome',13,'READ','2018-09-10 17:24:44',NULL,'Y','N',1,'com-hhub-transaction-sadmin-home',NULL),(12,'com.hhub.transaction.sadmin.login','/hhub/sadminlogin',14,'READ','2018-09-15 11:05:51',NULL,'Y','N',1,'com-hhub-transaction-sadmin-login',NULL),(13,'com.hhub.transaction.sadmin.create.users.page','/hhub/sadmincreateusers',15,'READ','2018-11-17 18:28:37',NULL,'Y','N',1,'com-hhub-transaction-sadmin-create-users-page',NULL),(14,'com.hhub.transaction.sadmin.profile','/hhub/hhubsadminprofile',16,'READ','2018-12-09 02:36:20',NULL,'Y','N',1,'com-hhub-transaction-sadmin-profile',NULL),(15,'com.hhub.transaction.compadmin.home','/hhub/hhubcadindex',17,'READ','2019-01-08 12:41:03',NULL,'Y','N',1,'com-hhub-transaction-compadmin-home',NULL),(16,'com.hhub.transaction.cad.login.page','/hhub/cad-login.html',18,'READ','2019-01-13 02:37:46',NULL,'Y','N',1,'com-hhub-transaction-cad-login-page',NULL),(17,'com.hhub.transaction.cad.login.action','/hhub/hhubcadloginaction',19,'READ','2019-01-13 06:57:18',NULL,'Y','N',1,'com-hhub-transaction-cad-login-action',NULL),(18,'com.hhub.transaction.cad.logout','/hhub/hhubcadlogout',20,'READ','2019-01-13 07:09:14',NULL,'Y','N',1,'com-hhub-transaction-cad-logout',NULL),(19,'com.hhub.transaction.cad.product.approve.action','/hhub/hhubcadprdapproveaction',21,'UPDATE','2019-01-13 07:20:52',NULL,'Y','N',1,'com-hhub-transaction-cad-product-approve-action',NULL),(20,'com.hhub.transaction.cad.product.reject.action','/hhub/hhubcadprdrejectaction',22,'UPDATE','2019-01-13 08:31:02',NULL,'Y','N',1,'com-hhub-transaction-cad-product-reject-action',NULL),(21,'com.hhub.transaction.vendor.bulk.products.add','/hhub/dodvenuploadproductscsvfileaction',23,'CREATE','2020-10-13 12:29:54',NULL,'Y','N',1,'com-hhub-transaction-vendor-bulk-products-add',NULL),(22,'com.hhub.transaction.suspendaccount','/hhub/suspendaccount',24,'UPDATE','2021-01-13 12:57:05',NULL,'Y','N',1,'com-hhub-transaction-suspend-account',NULL),(23,'com.hhub.transaction.restore.account','/hhub/restoreaccount',25,'UPDATE','2021-01-14 00:24:55',NULL,'Y','N',1,'com-hhub-transaction-restore-account',NULL),(24,'com.hhub.transaction.vendor.product.add.action','/hhub/dodvenaddproductaction',26,'CREATE','2021-01-14 01:06:51',NULL,'Y','N',1,'com-hhub-transaction-vendor-product-add-action',NULL),(25,'com.hhub.transaction.customer&vendor.create','/hhub/dodcustregisteraction',27,'CREATE','2021-04-01 17:47:52',NULL,'Y','N',1,'com-hhub-transaction-customer&vendor-create',NULL),(26,'com.hhub.transaction.vendor.order.setfulfilled','/hhub/dodvenordfulfilled',28,'UPDATE','2021-04-06 16:35:00',NULL,'Y','N',1,'com-hhub-transaction-vendor-order-setfulfilled',NULL),(27,'com.hhub.transaction.abac.security.page','/hhub/dasabacsecurity',29,'READ','2022-01-17 08:47:35',NULL,'Y','N',1,'com-hhub-transaction-abac-security-page',NULL);
/*!40000 ALTER TABLE `DOD_BUS_TRANSACTION` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2022-12-09 20:06:48
