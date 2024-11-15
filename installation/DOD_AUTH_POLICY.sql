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
-- Table structure for table `DOD_AUTH_POLICY`
--

DROP TABLE IF EXISTS `DOD_AUTH_POLICY`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `DOD_AUTH_POLICY` (
  `ROW_ID` mediumint NOT NULL AUTO_INCREMENT,
  `NAME` varchar(50) DEFAULT NULL,
  `DESCRIPTION` varchar(100) DEFAULT NULL,
  `POLICY_FUNC` varchar(255) DEFAULT NULL,
  `CREATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `UPDATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `CREATED_BY` mediumint DEFAULT NULL,
  `ACTIVE_FLG` char(1) DEFAULT NULL,
  `DELETED_STATE` char(1) DEFAULT NULL,
  `TENANT_ID` mediumint NOT NULL,
  PRIMARY KEY (`ROW_ID`),
  KEY `TENANT_ID` (`TENANT_ID`),
  CONSTRAINT `DOD_AUTH_POLICY_ibfk_1` FOREIGN KEY (`TENANT_ID`) REFERENCES `DOD_COMPANY` (`ROW_ID`)
) ENGINE=InnoDB AUTO_INCREMENT=64 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `DOD_AUTH_POLICY`
--

LOCK TABLES `DOD_AUTH_POLICY` WRITE;
/*!40000 ALTER TABLE `DOD_AUTH_POLICY` DISABLE KEYS */;
INSERT INTO `DOD_AUTH_POLICY` VALUES (1,'com.hhub.policy.create.company','Only Superadmin role can create company.....','com-hhub-policy-create-company','2022-12-18 14:13:38','2022-12-18 14:13:38',NULL,'Y','N',1),(24,'com.hhub.policy.create.attribute','A policy for attribute creation.....','com-hhub-policy-create-attribute','2022-12-18 14:19:13','2022-12-18 14:19:13',NULL,'Y','N',1),(25,'com.hhub.policy.create','Policy Create','com-hhub-policy-create','2022-12-18 14:19:13','2022-12-18 14:19:13',NULL,'Y','N',1),(26,'com.hhub.policy.create.order','Policy for order create by customer','com-hhub-policy-create-order','2022-12-18 14:19:13','2022-12-18 14:19:13',NULL,'Y','N',1),(27,'com.hhub.policy.cust.edit.order.item','Policy for customer order edit scenario.','com-hhub-policy-cust-edit-order-item','2022-12-18 14:19:13','2022-12-18 14:19:13',NULL,'Y','N',1),(28,'com.hhub.policy.sadmin.home','Super admin home page after login','com-hhub-policy-sadmin-home','2022-12-18 14:19:13','2022-12-18 14:19:13',NULL,'Y','N',1),(29,'com.hhub.policy.sadmin.login','Super admin login policy','com-hhub-policy-sadmin-login','2022-12-18 14:19:13','2022-12-18 14:19:13',NULL,'Y','N',1),(30,'com.hhub.policy.sadmin.create.users.page','Policy for the Super admin user to edit a user. ','com-hhub-policy-sadmin-create-users-page','2022-12-18 14:19:13','2022-12-18 14:19:13',NULL,'Y','N',1),(31,'com.hhub.policy.sadmin.profile','This is a policy for the Superadmin profile page. ','com-hhub-policy-sadmin-profile','2022-12-18 14:19:13','2022-12-18 14:19:13',NULL,'Y','N',1),(32,'com.hhub.policy.compadmin.home','This is a policy for the Company Admin home page entry','com-hhub-policy-compadmin-home','2022-12-18 14:19:13','2022-12-18 14:19:13',NULL,'Y','N',1),(33,'com.hhub.policy.cad.login.page','Company Administrator Login Page. ','com-hhub-policy-cad-login-page','2022-12-18 14:19:13','2022-12-18 14:19:13',NULL,'Y','N',1),(34,'com.hhub.policy.cad.login.action','Company Administrator login action. This is a dummy policy as the request is initiated by browser','com-hhub-policy-cad-login-action','2022-12-18 14:19:13','2022-12-18 14:19:13',NULL,'Y','N',1),(35,'com.hhub.policy.cad.logout','Company administrator logout policy. ','com-hhub-policy-cad-logout','2022-12-18 14:19:13','2022-12-18 14:19:13',NULL,'Y','N',1),(36,'com.hhub.policy.cad.product.approve.action','This is a governing policy for company administrator to accept the product. ','com-hhub-policy-cad-product-approve-action','2022-12-18 14:19:13','2022-12-18 14:19:13',NULL,'Y','N',1),(37,'com.hhub.policy.cad.product.reject.action','Company Administrator can reject a product. ','com-hhub-policy-cad-product-reject-action','2022-12-18 14:19:13','2022-12-18 14:19:13',NULL,'Y','N',1),(38,'com.hhub.policy.vendor.add.product.action','Policy to execute when a vendor is adding a new product','com-hhub-policy-vendor-add-product-action','2022-12-18 14:19:13','2022-12-18 14:19:13',NULL,'Y','N',1),(39,'com.hhub.policy.vendor.bulk.products.add','Policy to execute when a vendor is adding products in bulk','com-hhub-policy-vendor-bulk-products-add','2022-12-18 14:19:13','2022-12-18 14:19:13',NULL,'Y','N',1),(40,'com.hhub.policy.account.suspend','Policy to suspend an account','com-hhub-policy-account-suspend','2022-12-18 14:19:13','2022-12-18 14:19:13',NULL,'Y','N',1),(41,'com.hhub.policy.account.restore','Policy to Restore an account','com-hhub-policy-account-restore','2022-12-18 14:19:13','2022-12-18 14:19:13',NULL,'Y','N',1),(42,'com.hhub.policy.customer&vendor.create','Policy to be executed when a new vendor is created. ','com-hhub-policy-customer&vendor-create','2022-12-18 14:19:13','2022-12-18 14:19:13',NULL,'Y','N',1),(43,'com.hhub.policy.vendor.order.setfulfilled','Vendor updates the order and sets it to fulfilled. ','com-hhub-policy-vendor-order-setfulfilled','2022-12-18 14:19:13','2022-12-18 14:19:13',NULL,'Y','N',1),(44,'com.hhub.policy.abac.security.page','Policy to display the ABAC Security page. In this page  we will display policies  transactions ','com-hhub-policy-abac-security-page','2022-12-18 14:19:13','2022-12-18 14:19:13',NULL,'Y','N',1),(45,'com.hhub.policy.prodcatg.add.action','Max category count based on subscription type. TRIAL = 10, BASIC = 20, PROFESSIONAL = 30','com-hhub-policy-prodcatg-add-action','2023-04-06 10:52:14','2023-06-16 06:31:21',NULL,'Y','N',1),(46,'com.hhub.policy.publish.account.exturl','Publish account external url. This can be done by the company admin only. ','com-hhub-policy-publish-account-exturl','2023-06-05 10:00:21','2023-06-05 10:00:21',NULL,'Y','N',1),(47,'com.hhub.policy.compadmin.updatedetails.action','Company Admin can update his details like name, address, phone and email.','com-hhub-policy-compadmin-updatedetails-action','2023-06-05 12:31:41','2023-06-05 12:31:41',NULL,'Y','N',1),(48,'com.hhub.policy.vendor.approve.action','Only a company admin can approve the vendor. ','com-hhub-policy-vendor-approve-action','2023-06-24 11:52:59','2023-06-24 11:52:59',NULL,'Y','N',1),(49,'com.hhub.policy.vendor.reject.action','Only a company admin can reject a newly created vendor. ','com-hhub-policy-vendor-reject-action','2023-06-24 11:54:54','2023-06-24 11:54:54',NULL,'Y','N',1),(50,'com.hhub.policy.vendor.prod.ship.infoadd','Vendor adds product shipping information','com-hhub-policy-vendor-prod-ship-infoadd','2023-07-28 18:35:16','2023-07-28 18:35:16',NULL,'Y','N',1),(51,'com.hhub.policy.gst.hsn.codes','GST HSN Codes ','com-hhub-policy-gst-hsn-codes','2024-08-12 13:24:53','2024-08-12 13:24:53',NULL,'Y','N',1),(52,'com.hhub.policy.create.gst.hsn.code.action','Create action for GST HSN CODE','com-hhub-policy-create-gst-hsn-code-action','2024-08-20 13:08:13','2024-08-20 13:08:13',NULL,'Y','N',1),(53,'com.hhub.policy.search.gst.hsn.codes.action','Searches a GST HSN code','com-hhub-policy-search-gst-hsn-codes-action','2024-08-22 18:21:03','2024-08-22 18:21:03',NULL,'Y','N',1),(54,'com.hhub.policy.update.gst.hsn.code.action','Update a given GST HSN Code and its relevant parameters.','com-hhub-policy-update-gst-hsn-code-action','2024-08-27 17:26:46','2024-08-27 17:26:46',NULL,'Y','N',1),(55,'com.hhub.policy.create.invoice.action','Vendor creates an invoice ','com-hhub-policy-create-invoice-action','2024-09-03 17:24:18','2024-09-03 17:24:18',NULL,'Y','N',1),(56,'com.hhub.policy.update.invoice.action','vendor updates an invoice','com-hhub-policy-update-invoice-action','2024-09-03 17:24:42','2024-09-03 17:24:42',NULL,'Y','N',1),(57,'com.hhub.policy.show.invoices.page','vendor display invoice page','com-hhub-policy-show-invoices-page','2024-09-03 17:25:41','2024-09-03 17:25:41',NULL,'Y','N',1),(58,'com.hhub.policy.search.invoice.action','search a given invoice','com-hhub-policy-search-invoice-action','2024-09-03 17:26:45','2024-09-03 17:26:45',NULL,'Y','N',1),(59,'com.hhub.policy.update.invoiceitem.action','Vendor Updates and Invoice Item with Quantity, Price or the Discount. ','com-hhub-policy-update-invoiceitem-action','2024-10-20 16:18:38','2024-10-20 16:18:38',NULL,'Y','N',1),(60,'com.hhub.policy.delete.invoiceitem.action','Delete an Invoice Item by Vendor','com-hhub-policy-delete-invoiceitem-action','2024-10-21 13:38:42','2024-10-21 13:38:42',NULL,'Y','N',1),(61,'com.hhub.policy.invoice.paid.action','Vendor invoice paid action','com-hhub-policy-invoice-paid-action','2024-10-28 18:37:59','2024-10-28 18:37:59',NULL,'Y','N',1),(62,'com.hhub.policy.show.invoice.confirm.page','Vendor show invoice confirmation page','com-hhub-policy-show-invoice-confirm-page','2024-10-30 06:47:28','2024-10-30 06:47:28',NULL,'Y','N',1),(63,'com.hhub.policy.show.invoice.payment.page','Vendor show invoice payment page','com-hhub-policy-show-invoice-payment-page','2024-10-30 07:18:54','2024-10-30 07:18:54',NULL,'Y','N',1);
/*!40000 ALTER TABLE `DOD_AUTH_POLICY` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2024-11-15 12:04:35
