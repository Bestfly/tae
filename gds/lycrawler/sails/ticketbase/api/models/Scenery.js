/**
* Scenery.js
*
* @description :: TODO: You might write a short summary of how this model works and what it represents here.
* @docs        :: http://sailsjs.org/#!documentation/models
*/

module.exports = {

	schema: true,
	
    attributes: {
         CityId: {
			 model: 'City',
			 columnName: 'CityId',
			 required: true,
			 index: true
         },
		 DivisionId: {
			 model: 'Division',
			 columnName: 'DivisionId',
			 //有些景点没有区划信息
			 required: false,
			 index: true
		 },
		 // 保留LY的Id
		 sLyId: {
			 type: 'integer',
			 required: true,
			 unique: true
		 },
		 sMgId: {
			 type: 'string',
			 required: false,
			 unique: true
		 },
		 grade: {
			 type: 'integer',
		 },
		 commentCount: {
			 type: 'integer',
		 },
		 questionCount: {
			 type: 'integer',
		 },
		 viewCount: {
			 type: 'integer',
		 },
		 blogCount: {
			 type: 'integer',
		 },
		 
		 // google position
		 glon: {
             type: 'string',
			 //unique: true
		 },
		 glat: {
             type: 'string',
			 //unique: true
		 },
		 
		 // baidu position
		 blon: {
             type: 'string',
			 //unique: true
		 },
		 blat: {
             type: 'string',
			 //unique: true
		 },
		 
		 // about
		 name: {
             type: 'string',
			 minLength: 2,
			 maxLength: 50,
			 required: true,
			 unique: true
			 //index: true
		 },
		 aliasName: {
             type: 'string'
		 },
		 // 周边景点ids
		 NearbySceneryIds: {
			 type: 'string',
			 required: false
		 },
		 // 周边酒店ids
		 NearbyHotelIds: {
			 type: 'string',
			 required: false
		 },
		 // 关联城市ids
		 NearbyCityIds: {
			 type: 'string',
			 required: false
		 },
		 address: {
             type: 'string',
			 minLength: 3,
			 maxLength: 120,
			 required: true
			 //unique: true#同一地址可能多个景点
			 //index: true
		 },
		 // 交通指南
		 traffic: {
			 type: 'text',
			 required: false
		 },
		 summary: {
             type: 'string',
			 minLength: 2,
			 maxLength: 600,
			 required: true
			 //unique: true
			 //index: true
		 },
		 SceneryDetail: {
			 type: 'text',
			 required: true
		 },
		 // baseURL + imgPath
		 imgPath: {
             type: 'url',
			 minLength: 15,
			 required: false
			 //unique: true
		 },
		 
		 // -1：暂时下线, 0：不可预订, 1：可预订
		 bookFlag: {
             type: 'integer',
             required: true
		 },
		 
		 // 是否需要证件
		 ifUseCard: {
             type: 'integer',
             required: false
		 },
		 LowestPrice: {
			 type: 'decimal',
			 max: 4999.99,
			 min: 0.01
		 },
		 // when bookFlag == 1, required is true;
         payMode: {
			 // 1 面付, 2 在线付, 3456789预留 
             type: 'integer',
             required: false
         },
		 buyNotie: {
			 type: 'string'
		 },
		 
		 // 扩展预留 ｜ 待处理的图 |
		 remark: {
			 type: 'text',
			 required: false
		 }
	 }
};