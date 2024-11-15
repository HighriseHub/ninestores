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
-- Table structure for table `DOD_BUS_TRANSACTION`
--

DROP TABLE IF EXISTS `DOD_BUS_TRANSACTION`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `DOD_BUS_TRANSACTION` (
  `ROW_ID` mediumint NOT NULL AUTO_INCREMENT,
  `NAME` varchar(100) DEFAULT NULL,
  `URI` varchar(100) DEFAULT NULL,
  `AUTH_POLICY_ID` mediumint NOT NULL,
  `TRANS_TYPE` varchar(15) DEFAULT NULL,
  `CREATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `UPDATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `CREATED_BY` mediumint DEFAULT NULL,
  `ACTIVE_FLG` char(1) DEFAULT NULL,
  `DELETED_STATE` char(1) DEFAULT NULL,
  `TENANT_ID` mediumint NOT NULL,
  `TRANS_FUNC` varchar(100) DEFAULT NULL,
  `ABAC_SUBJECT_ID` mediumint DEFAULT NULL,
  PRIMARY KEY (`ROW_ID`),
  KEY `TENANT_ID` (`TENANT_ID`),
  KEY `AUTH_POLICY_ID` (`AUTH_POLICY_ID`),
  KEY `ABAC_SUBJECT_ID` (`ABAC_SUBJECT_ID`),
  CONSTRAINT `DOD_BUS_TRANSACTION_ibfk_1` FOREIGN KEY (`TENANT_ID`) REFERENCES `DOD_COMPANY` (`ROW_ID`),
  CONSTRAINT `DOD_BUS_TRANSACTION_ibfk_2` FOREIGN KEY (`AUTH_POLICY_ID`) REFERENCES `DOD_AUTH_POLICY` (`ROW_ID`),
  CONSTRAINT `DOD_BUS_TRANSACTION_ibfk_3` FOREIGN KEY (`ABAC_SUBJECT_ID`) REFERENCES `DOD_ABAC_SUBJECT` (`ROW_ID`)
) ENGINE=InnoDB AUTO_INCREMENT=43 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `DOD_BUS_TRANSACTION`
--

LOCK TABLES `DOD_BUS_TRANSACTION` WRITE;
/*!40000 ALTER TABLE `DOD_BUS_TRANSACTION` DISABLE KEYS */;
INSERT INTO `DOD_BUS_TRANSACTION` VALUES (1,'com.hhub.transaction.create.company','/hhub/createcompanyaction',1,'CREATE','2022-12-17 14:46:53','2022-12-17 14:46:53',NULL,'Y','N',1,'com-hhub-transaction-create-company',NULL),(2,'com.hhub.transaction.create.company','/hhub/createcompanyaction',1,'CREATE','2022-12-17 14:48:05','2022-12-17 14:48:43',NULL,'Y','Y',1,'com-hhub-transaction-create-company',NULL),(3,'com.hhub.transaction.create.attribute','/hhub/dasaddattribute',24,'CREATE','2022-12-17 14:48:05','2023-06-25 16:47:23',NULL,'Y','N',1,'com-hhub-transaction-create-attribute',NULL),(4,'com.hhub.transaction.policy.create','/hhub/dasaddpolicyaction',25,'CREATE','2022-12-17 14:48:05','2023-06-25 16:47:49',NULL,'Y','N',1,'com-hhub-transaction-policy-create',NULL),(5,'com.hhub.transaction.create.order','/hhub/dodmyorderaddaction',26,'CREATE','2022-12-17 14:48:05','2023-06-25 16:48:14',NULL,'Y','N',1,'com-hhub-transaction-create-order',NULL),(6,'com.hhub.transaction.cust.edit.order.item','/hhub/dodcustorditemedit',27,'UPDATE','2022-12-17 14:48:05','2023-06-25 16:48:54',NULL,'Y','N',1,'com-hhub-transaction-cust-edit-order-item',NULL),(7,'com.hhub.transaction.sadmin.home','/hhub/sadminhome',28,'READ','2022-12-17 14:48:05','2023-06-25 16:46:09',NULL,'Y','N',1,'com-hhub-transaction-sadmin-home',NULL),(8,'com.hhub.transaction.sadmin.login','/hhub/sadminlogin',29,'READ','2022-12-17 14:48:05','2023-06-25 16:45:34',NULL,'Y','N',1,'com-hhub-transaction-sadmin-login',NULL),(9,'com.hhub.transaction.sadmin.create.users.page','/hhub/sadmincreateusers',30,'READ','2022-12-17 14:48:05','2023-06-25 16:49:27',NULL,'Y','N',1,'com-hhub-transaction-sadmin-create-users-page',NULL),(10,'com.hhub.transaction.sadmin.profile','/hhub/hhubsadminprofile',31,'READ','2022-12-17 14:48:05','2023-06-25 16:49:40',NULL,'Y','N',1,'com-hhub-transaction-sadmin-profile',NULL),(11,'com.hhub.transaction.compadmin.home','/hhub/hhubcadindex',32,'READ','2022-12-17 14:48:05','2023-06-25 16:49:51',NULL,'Y','N',1,'com-hhub-transaction-compadmin-home',NULL),(12,'com.hhub.transaction.cad.login.page','/hhub/cad-login.html',33,'READ','2022-12-17 14:48:05','2023-06-25 16:50:02',NULL,'Y','N',1,'com-hhub-transaction-cad-login-page',NULL),(13,'com.hhub.transaction.cad.login.action','/hhub/hhubcadloginaction',34,'READ','2022-12-17 14:48:05','2023-06-25 16:50:13',NULL,'Y','N',1,'com-hhub-transaction-cad-login-action',NULL),(14,'com.hhub.transaction.cad.logout','/hhub/hhubcadlogout',35,'READ','2022-12-17 14:48:05','2023-06-25 16:50:23',NULL,'Y','N',1,'com-hhub-transaction-cad-logout',NULL),(15,'com.hhub.transaction.cad.product.approve.action','/hhub/hhubcadprdapproveaction',36,'UPDATE','2022-12-17 14:48:05','2023-06-25 16:50:36',NULL,'Y','N',1,'com-hhub-transaction-cad-product-approve-action',NULL),(16,'com.hhub.transaction.cad.product.reject.action','/hhub/hhubcadprdrejectaction',37,'UPDATE','2022-12-17 14:48:05','2023-06-26 08:07:38',NULL,'Y','N',1,'com-hhub-transaction-cad-product-reject-action',NULL),(17,'com.hhub.transaction.vendor.bulk.products.add','/hhub/dodvenuploadproductscsvfileaction',39,'CREATE','2022-12-17 14:48:05','2023-06-26 08:06:08',NULL,'Y','N',1,'com-hhub-transaction-vendor-bulk-products-add',NULL),(18,'com.hhub.transaction.suspendaccount','/hhub/suspendaccount',40,'UPDATE','2022-12-17 14:48:05','2023-06-26 08:07:57',NULL,'Y','N',1,'com-hhub-transaction-suspend-account',NULL),(19,'com.hhub.transaction.restore.account','/hhub/restoreaccount',41,'UPDATE','2022-12-17 14:48:05','2023-06-26 08:08:07',NULL,'Y','N',1,'com-hhub-transaction-restore-account',NULL),(20,'com.hhub.transaction.vendor.product.add.action','/hhub/dodvenaddproductaction',38,'CREATE','2022-12-17 14:48:05','2023-06-26 08:06:32',NULL,'Y','N',1,'com-hhub-transaction-vendor-product-add-action',NULL),(21,'com.hhub.transaction.customer&vendor.create','/hhub/dodcustregisteraction',42,'CREATE','2022-12-17 14:48:05','2023-06-25 16:50:58',NULL,'Y','N',1,'com-hhub-transaction-customer&vendor-create',NULL),(22,'com.hhub.transaction.vendor.order.setfulfilled','/hhub/dodvenordfulfilled',43,'UPDATE','2022-12-17 14:48:05','2023-06-25 16:51:11',NULL,'Y','N',1,'com-hhub-transaction-vendor-order-setfulfilled',NULL),(23,'com.hhub.transaction.abac.security.page','/hhub/dasabacsecurity',44,'READ','2022-12-17 14:48:05','2023-06-25 16:51:23',NULL,'Y','N',1,'com-hhub-transaction-abac-security-page',NULL),(24,'com.hhub.transaction.prodcatg.add.action','/hhub/hhubprodcatgaddaction',45,'CREATE','2023-04-06 10:54:37','2023-06-16 06:29:18',NULL,'Y','N',1,'com-hhub-transaction-prodcatg-add-action',NULL),(25,'com.hhub.transaction.publish.account.exturl','/hhub/hhubpublishaccountexturl',46,'UPDATE','2023-06-05 10:01:20','2023-06-05 10:01:40',NULL,'Y','N',1,'com-hhub-transaction-publish-account-exturl',NULL),(26,'com.hhub.transaction.compadmin.updatedetails.action','/hhub/hhubcompadminupdateaction',47,'UPDATE','2023-06-05 12:33:17','2023-06-05 12:33:38',NULL,'Y','N',1,'com-hhub-transaction-compadmin-updatedetails-action',NULL),(27,'com.hhub.transaction.vendor.approve.action','/hhub/hhubvendorapproveaction',48,'UPDATE','2023-06-24 11:53:38','2023-06-24 11:53:55',NULL,'Y','N',1,'com-hhub-transaction-vendor-approve-action',NULL),(28,'com.hhub.transaction.vendor.reject.action','/hhub/hhubvendorrejectaction',49,'UPDATE','2023-06-24 11:55:29','2023-06-24 11:55:43',NULL,'Y','N',1,'com-hhub-transaction-vendor-reject-action',NULL),(29,'com.hhub.transaction.vend.prd.shipinfo.add.action','/hhub/hhubvendaddprodshipinfoaction',50,'UPDATE','2023-07-28 18:39:01','2023-07-28 18:39:24',NULL,'Y','N',1,'com-hhub-transaction-vend-prd-shipinfo-add-action',NULL),(30,'com.hhub.transaction.gst.hsn.codes','/hhub/gsthsncodes',51,'READ','2024-08-12 13:25:56','2024-08-22 18:27:10',NULL,'Y','N',1,'com-hhub-transaction-gst-hsn-codes-page',NULL),(31,'com.hhub.transaction.create.gst.hsn.code.action','/hhub/createhsncodeaction',52,'CREATE','2024-08-20 13:09:17','2024-08-22 18:27:21',NULL,'Y','N',1,'com-hhub-transaction-create-gst-hsn-code-action',NULL),(32,'com.hhub.transaction.search.gst.hsn.codes.action','/hhub/searchhsncodesaction',53,'READ','2024-08-22 18:20:23','2024-08-22 18:26:51',NULL,'Y','N',1,'com-hhub-transaction-search-gst-hsn-codes-action',NULL),(33,'com.hhub.transaction.update.gst.hsn.code.action','/hhub/updatehsncodeaction',54,'UPDATE','2024-08-27 17:26:02','2024-08-27 17:27:04',NULL,'Y','N',1,'com-hhub-transaction-update-gst-hsn-code-action',NULL),(34,'com.hhub.transaction.show.invoices.page','/hhub/displayinvoices',57,'READ','2024-09-03 17:27:29','2024-09-03 17:30:48',NULL,'Y','N',1,'com-hhub-transaction-show-invoices-page',NULL),(35,'com.hhub.transaction.search.invoice.action','/hhub/searchinvoicesaction',58,'READ','2024-09-03 17:28:15','2024-09-03 17:30:38',NULL,'Y','N',1,'com-hhub-transaction-search-invoice-action',NULL),(36,'com.hhub.transaction.create.invoice.action','/hhub/createinvoiceaction',55,'CREATE','2024-09-03 17:28:40','2024-09-03 17:29:51',NULL,'Y','N',1,'com-hhub-transaction-create-invoice-action',NULL),(37,'com.hhub.transaction.update.invoice.action','/hhub/updateinvoiceaction',56,'UPDATE','2024-09-03 17:29:05','2024-09-03 17:29:23',NULL,'Y','N',1,'com-hhub-transaction-update-invoice-action',NULL),(38,'com.hhub.transaction.update.invoiceitem.action','/hhub/updateInvoiceItemaction',59,'UPDATE','2024-10-20 16:20:03','2024-10-20 16:20:23',NULL,'Y','N',1,'com-hhub-transaction-update-invoiceitem-action',NULL),(39,'com.hhub.transaction.delete-invoiceitem-action','/hhub/deleteinvoiceitemaction',60,'DELETE','2024-10-21 13:39:23','2024-10-21 13:39:44',NULL,'Y','N',1,'com-hhub-transaction-delete-invoiceitem-action',NULL),(40,'com.hhub.transaction.invoice.paid.action','/hhub/vinvoicepaidaction',61,'UPDATE','2024-10-28 18:38:38','2024-10-28 18:39:32',NULL,'Y','N',1,'com-hhub-transaction-invoice-paid-action',NULL),(41,'com.hhub.transaction.show.invoice.confirm.page','/hhub/vshowinvoiceconfirmpage',62,'READ','2024-10-30 06:48:07','2024-10-30 06:48:24',NULL,'Y','N',1,'com-hhub-transaction-show-invoice-confirm-page',NULL),(42,'com.hhub.transaction.show.invoice.payment.page','/hhub/vinvoicepaymentpage',63,'READ','2024-10-30 07:19:32','2024-10-30 07:19:47',NULL,'Y','N',1,'com-hhub-transaction-show-invoice-payment-page',NULL);
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

-- Dump completed on 2024-11-15 12:04:44
