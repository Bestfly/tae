-- phpMyAdmin SQL Dump
-- version 3.2.4
-- http://www.phpmyadmin.net
--
-- Host: 127.0.0.1
-- Generation Time: Jun 12, 2014 at 06:59 AM
-- Server version: 5.1.38
-- PHP Version: 5.3.1

SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;

--
-- Database: `qiyou`
--

-- --------------------------------------------------------

--
-- Table structure for table `city`
--

CREATE TABLE IF NOT EXISTS `city` (
  `CountryCode` char(2) COLLATE utf8_unicode_ci DEFAULT NULL,
  `ProvinceId` int(11) DEFAULT NULL,
  `code` char(3) COLLATE utf8_unicode_ci DEFAULT NULL,
  `LyId` int(11) DEFAULT NULL,
  `name` varchar(50) COLLATE utf8_unicode_ci DEFAULT NULL,
  `ename` varchar(50) COLLATE utf8_unicode_ci DEFAULT NULL,
  `airport` varchar(120) COLLATE utf8_unicode_ci DEFAULT NULL,
  `prefixLetter` char(1) COLLATE utf8_unicode_ci DEFAULT NULL,
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `createdAt` datetime DEFAULT NULL,
  `updatedAt` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `code` (`code`),
  UNIQUE KEY `LyId` (`LyId`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci AUTO_INCREMENT=1 ;

--
-- Dumping data for table `city`
--


-- --------------------------------------------------------

--
-- Table structure for table `country`
--

CREATE TABLE IF NOT EXISTS `country` (
  `code` char(2) COLLATE utf8_unicode_ci NOT NULL,
  `name` varchar(50) COLLATE utf8_unicode_ci DEFAULT NULL,
  `ename` varchar(50) COLLATE utf8_unicode_ci DEFAULT NULL,
  `prefixLetter` char(1) COLLATE utf8_unicode_ci DEFAULT NULL,
  `createdAt` datetime DEFAULT NULL,
  `updatedAt` datetime DEFAULT NULL,
  PRIMARY KEY (`code`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `country`
--

INSERT INTO `country` (`code`, `name`, `ename`, `prefixLetter`, `createdAt`, `updatedAt`) VALUES
('CN', '中国', 'China', 'C', '2014-06-12 14:51:00', '2014-06-12 14:51:00');

-- --------------------------------------------------------

--
-- Table structure for table `division`
--

CREATE TABLE IF NOT EXISTS `division` (
  `CityId` int(11) DEFAULT NULL,
  `name` varchar(50) COLLATE utf8_unicode_ci DEFAULT NULL,
  `ename` varchar(50) COLLATE utf8_unicode_ci DEFAULT NULL,
  `dLyId` int(11) DEFAULT NULL COMMENT '保留LY行政区划Id',
  `prefixLetter` char(1) COLLATE utf8_unicode_ci DEFAULT NULL,
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `createdAt` datetime DEFAULT NULL,
  `updatedAt` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`),
  UNIQUE KEY `LyId` (`dLyId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci AUTO_INCREMENT=1 ;

--
-- Dumping data for table `division`
--


-- --------------------------------------------------------

--
-- Table structure for table `province`
--

CREATE TABLE IF NOT EXISTS `province` (
  `CountryCode` char(2) COLLATE utf8_unicode_ci DEFAULT NULL,
  `name` varchar(50) COLLATE utf8_unicode_ci DEFAULT NULL,
  `ename` varchar(50) COLLATE utf8_unicode_ci DEFAULT NULL,
  `prefixLetter` char(1) COLLATE utf8_unicode_ci DEFAULT NULL,
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `createdAt` datetime DEFAULT NULL,
  `updatedAt` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci AUTO_INCREMENT=1 ;

--
-- Dumping data for table `province`
--


-- --------------------------------------------------------

--
-- Table structure for table `scenery`
--

CREATE TABLE IF NOT EXISTS `scenery` (
  `CityId` int(11) DEFAULT NULL COMMENT '关联城市表Id',
  `DivisionId` int(11) DEFAULT NULL COMMENT '关联行政区划表Id',
  `sLyId` int(11) DEFAULT NULL COMMENT '保留LY景区Id',
  `grade` tinyint(4) DEFAULT NULL COMMENT '等级,事先规则约定1,2,3,4,5,6',
  `commentCount` int(11) DEFAULT NULL,
  `questionCount` int(11) DEFAULT NULL,
  `viewCount` int(11) DEFAULT NULL,
  `blogCount` int(11) DEFAULT NULL,
  `lon` varchar(20) COLLATE utf8_unicode_ci DEFAULT NULL COMMENT '经度',
  `lat` varchar(20) COLLATE utf8_unicode_ci DEFAULT NULL COMMENT '纬度',
  `name` varchar(50) COLLATE utf8_unicode_ci DEFAULT NULL,
  `aliasName` varchar(100) COLLATE utf8_unicode_ci DEFAULT NULL COMMENT '多个以“|”隔开',
  `themeName` varchar(100) COLLATE utf8_unicode_ci DEFAULT NULL COMMENT '多个以“|”隔开',
  `suitherdName` varchar(100) COLLATE utf8_unicode_ci DEFAULT NULL COMMENT '多个以“|”隔开',
  `impressionName` varchar(100) COLLATE utf8_unicode_ci DEFAULT NULL COMMENT '多个以“|”隔开',
  `themeIds` varchar(100) COLLATE utf8_unicode_ci DEFAULT NULL COMMENT '多个以“|”隔开',
  `suitherdIds` varchar(100) COLLATE utf8_unicode_ci DEFAULT NULL COMMENT '多个以“|”隔开',
  `impressionIds` varchar(100) COLLATE utf8_unicode_ci DEFAULT NULL COMMENT '多个以“|”隔开',
  `NearbySceneryIds` varchar(100) COLLATE utf8_unicode_ci DEFAULT NULL COMMENT '多个以“|”隔开',
  `NearbyHotelIds` varchar(100) COLLATE utf8_unicode_ci DEFAULT NULL COMMENT '多个以“|”隔开',
  `address` varchar(120) COLLATE utf8_unicode_ci DEFAULT NULL,
  `summary` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `SceneryDetail` longtext COLLATE utf8_unicode_ci,
  `imgPath` varchar(100) COLLATE utf8_unicode_ci DEFAULT NULL,
  `bookFlag` tinyint(4) DEFAULT NULL COMMENT '-1：暂时下线, 0：不可预订, 1：可预订',
  `ifUseCard` tinyint(1) DEFAULT NULL COMMENT '是否需要证件, 0：不需要, 1：需要',
  `LowestPrice` decimal(10,2) DEFAULT NULL COMMENT '该景点的最低价格，可能是儿童价',
  `payMode` tinyint(1) DEFAULT NULL COMMENT '1 面付, 2 在线付, 3456789预留',
  `buyNotie` varchar(500) COLLATE utf8_unicode_ci DEFAULT NULL,
  `remark` longtext COLLATE utf8_unicode_ci,
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `createdAt` datetime DEFAULT NULL,
  `updatedAt` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `sLyId` (`sLyId`),
  UNIQUE KEY `lon` (`lon`),
  UNIQUE KEY `lat` (`lat`),
  UNIQUE KEY `name` (`name`),
  UNIQUE KEY `address` (`address`),
  UNIQUE KEY `imgPath` (`imgPath`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci AUTO_INCREMENT=1 ;

--
-- Dumping data for table `scenery`
--

