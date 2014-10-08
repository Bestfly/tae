DROP TABLE IF EXISTS  `tbl_client_auth`;
CREATE TABLE `tbl_client_auth` (
	`id` int(11) NOT NULL,
	`uid` int(11) NOT NULL,
	`sid` int(11) NOT NULL,
	`apikey` char(36) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
	`start_date` date NULL COMMENT '有效期开始时间',
	`end_date` date NULL COMMENT '有效期结束时间',
	`status` tinyint(4) NULL COMMENT '0-停用，1-启用',
	PRIMARY KEY (`id`),
	Unique KEY `key`(`apikey`) USING BTREE,
	Unique KEY `uidsid`(`uid`,`sid`) USING BTREE
) ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_unicode_ci
ROW_FORMAT=COMPACT;
