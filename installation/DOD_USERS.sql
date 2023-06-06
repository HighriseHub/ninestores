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
-- Table structure for table `DOD_USERS`
--

DROP TABLE IF EXISTS `DOD_USERS`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
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
  `UPDATED` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
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
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `DOD_USERS`
--

LOCK TABLES `DOD_USERS` WRITE;
/*!40000 ALTER TABLE `DOD_USERS` DISABLE KEYS */;
INSERT INTO `DOD_USERS` VALUES (1,'Super Admin','superadmin','P@ssword1','',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2017-12-18 18:30:00',-1,'2017-12-18 18:30:00',-1,'Y','N',1,NULL,NULL,NULL,NULL,NULL),(2,'Operator1','opr1','P@ssword1','',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2017-12-18 18:30:00',-1,'2017-12-18 18:30:00',-1,'Y','N',1,NULL,NULL,NULL,NULL,NULL),(3,'Demo Administrator','demoadmin','demo','demoadmin@highrisehub.com',NULL,NULL,NULL,NULL,NULL,NULL,'9999999999',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2018-10-18 18:30:00',-1,'2018-10-18 18:30:00',-1,'Y','N',2,NULL,'Ã¶Ã¬GÂ‰vÃœÃ‹Ã³o2S~%ÃÃ›ÃšÃ¡Ã­Ã€Â¥1Â¹Ã¤(Â¯Â¹Ã¦\ZÂ„/Ã¿ÃÂ¬Ã´Â´Â´Ãcb{ÂºÃÃžÂ»p\\ÃŽÂ=gÂ½',NULL,NULL,NULL),(5,'Venugopal Hanumanthaiah','vanamaaliadmin','venu','venu6977@gmail.com',NULL,NULL,NULL,NULL,NULL,NULL,'9482534747',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2018-12-17 15:29:26',1,'0000-00-00 00:00:00',1,NULL,'N',33,NULL,'ÃÂ¹ÃžnÂˆÃQÃeÂ¹^iÃ·<BÂ”ÂÂ…hÃ…8~Â–jlÂÂ†Ã‘Â¼Ã‘VÂ¬&fÃžÂ­!QMCÂ¶Â±IÃªÃ¤Ã™Â±ÂÂ³Â±',NULL,NULL,NULL),(11,'Gopalan Granduer Admin1','GGAdmin1','?fFÂ¸Ã“Ã‡','ggadmin1@highrisehub.com',NULL,NULL,NULL,NULL,NULL,NULL,'9999900006',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2019-01-08 11:17:44',4,'0000-00-00 00:00:00',4,NULL,'N',4,NULL,'M6ÃƒÃµÃƒrÃœÃ¯Ã¹{Â¿.Ã”8&Â¨Â·Â§`ÃŒÂ™hÃ¡Ã¦ÃÂ•Ã•Â­~/%|PÃ©O\\Â¬`o+Ã­0\r\rZÃÃ¡Ã•ÂªÂ”[Â¼',NULL,NULL,NULL),(12,'Gopalan Granduer Operator1','ggopr1','ggopr1','ggopr1@highrisehub.com',NULL,NULL,NULL,NULL,NULL,NULL,'9999900007',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2019-01-09 05:57:19',4,'0000-00-00 00:00:00',4,NULL,'N',4,NULL,'!Â°>RÂµ1sÂ±Â_Ã—Ã¥Â’Ã²\nKnÃŽÃ¥Â‘MÃ¾b?Â¬X_Â²ÂŒ\0Ã›:ÂŽÃ¡sÃ¼\rEÃuÂ§$Ã˜o&OÃŽ_',NULL,NULL,NULL),(13,'Girish G','girishg','Ã”ÂÂÂ Ã›Â²ÂŸ','',NULL,NULL,NULL,NULL,NULL,NULL,'9845578104',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2021-04-20 12:16:58',34,'0000-00-00 00:00:00',34,NULL,'N',34,NULL,'Ã•Â»ÂžÃ¯=Ã·Â¸Â†Ã¿<Ã´SÂ¦xÂ©Ãƒ%0Â·Ã°ÃžÃ­oÃ¢Ã¸Â—!ÂÂ¾k$lÃ±tEh+ÃÃ¤5vÃ¶MÃ!Â£Â@Â¯1Âµ~',NULL,NULL,NULL),(14,'Gopalan Atlantis Administrator','gaadmin','Ã¹Ã¦pÂ”[Â–1','gaadmin@welcome.com',NULL,NULL,NULL,NULL,NULL,NULL,'9999999998',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2021-09-29 17:32:56',3,'0000-00-00 00:00:00',3,NULL,'N',3,NULL,'Â‰8Ã¯ÂÂ±Â¤dw/*Â¸ ÃžÃ¼Ãž[Â½Ã²Ã©Ã²Â§UÃŒÂ¥Â¬?Ã˜\rÃ‰ÂžU Â˜Â±Â©*:Ã·Ã´Ã¦#ÃµÃ‘\ZÂ³Ã«Ã½',NULL,NULL,NULL);
/*!40000 ALTER TABLE `DOD_USERS` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2022-12-09 20:04:49
