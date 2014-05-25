-- phpMyAdmin SQL Dump
-- version 3.2.4
-- http://www.phpmyadmin.net
--
-- Host: 127.0.0.1
-- Generation Time: May 04, 2014 at 05:11 PM
-- Server version: 5.1.38
-- PHP Version: 5.3.1

SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;

--
-- Database: `proxy`
--

-- --------------------------------------------------------

--
-- Table structure for table `proxies`
--

CREATE TABLE IF NOT EXISTS `proxies` (
  `uid` varchar(40) COLLATE utf8_unicode_ci DEFAULT NULL,
  `ipValue` varchar(21) COLLATE utf8_unicode_ci DEFAULT NULL,
  `line` tinyint(1) DEFAULT NULL,
  `country` char(2) COLLATE utf8_unicode_ci DEFAULT NULL,
  `region` varchar(20) COLLATE utf8_unicode_ci DEFAULT NULL,
  `speed` varchar(255) COLLATE utf8_unicode_ci,
  `fatchHit` int(11) DEFAULT NULL,
  `status` tinyint(1) DEFAULT NULL,
  `effect` tinyint(1) DEFAULT NULL,
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `createdAt` datetime DEFAULT NULL,
  `updatedAt` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `ipValue` (`ipValue`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci AUTO_INCREMENT=1 ;

--
-- Dumping data for table `proxies`
--

