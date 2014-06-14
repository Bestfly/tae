-- Adminer 3.6.2 MySQL dump

SET NAMES utf8;
SET foreign_key_checks = 0;
SET time_zone = 'SYSTEM';
SET sql_mode = 'NO_AUTO_VALUE_ON_ZERO';

DROP TABLE IF EXISTS `city`;
CREATE TABLE `city` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `country` int(11) NOT NULL COMMENT '所属国家',
  `province` int(11) NOT NULL COMMENT '所属省份',
  `code` char(3) NOT NULL COMMENT '三字码',
  `name` varchar(50) NOT NULL COMMENT '中文名称',
  `ename` varchar(50) NOT NULL COMMENT '英文名称',
  `airport` varchar(50) NOT NULL COMMENT '机场代码',
  `prefixLetter` char(1) NOT NULL COMMENT '首字母',
  PRIMARY KEY (`id`),
  KEY `province` (`province`),
  KEY `country` (`country`),
  CONSTRAINT `city_ibfk_2` FOREIGN KEY (`province`) REFERENCES `province` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `city_ibfk_3` FOREIGN KEY (`country`) REFERENCES `country` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='城市表';


DROP TABLE IF EXISTS `country`;
CREATE TABLE `country` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `code` char(2) NOT NULL COMMENT '国家二字码',
  `name` varchar(50) NOT NULL COMMENT '中文名称',
  `ename` varchar(50) NOT NULL COMMENT '英文名称',
  `prefixLetter` char(1) NOT NULL COMMENT '首字母',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='国家';


DROP TABLE IF EXISTS `division`;
CREATE TABLE `division` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `city` int(11) NOT NULL COMMENT '所属城市',
  `name` varchar(50) NOT NULL COMMENT '中文名称',
  `ename` varchar(50) NOT NULL COMMENT '英文名称',
  `prefixLetter` char(1) NOT NULL COMMENT '首字母',
  PRIMARY KEY (`id`),
  KEY `city` (`city`),
  CONSTRAINT `division_ibfk_1` FOREIGN KEY (`city`) REFERENCES `city` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='行政区划';


DROP TABLE IF EXISTS `province`;
CREATE TABLE `province` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `country` int(11) NOT NULL COMMENT '所属国家',
  `name` varchar(50) NOT NULL COMMENT '中文名称',
  `ename` varchar(50) NOT NULL COMMENT '英文名称',
  `prefixLetter` char(1) NOT NULL COMMENT '首字母',
  PRIMARY KEY (`id`),
  KEY `country` (`country`),
  CONSTRAINT `province_ibfk_1` FOREIGN KEY (`country`) REFERENCES `country` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='省份/州';


-- 2014-06-04 10:06:49
