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
			 required: true,
			 index: true
		 },
		 // 保留LY的Id
		 sLyId: {
			 type: 'integer',
			 required: true,
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
		 
		 // position
		 lon: {
             type: 'string',
			 unique: true
		 },
		 lat: {
             type: 'string',
			 unique: true
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
			 minLength: 10,
			 maxLength: 120,
			 required: true,
			 unique: true
			 //index: true
		 },
		 // 交通指南
		 traffic: {
			 type: 'text',
			 required: false
		 },
		 summary: {
             type: 'string',
			 minLength: 10,
			 maxLength: 250,
			 required: true,
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
			 required: true,
			 unique: true
		 },
		 
		 // -1：暂时下线, 0：不可预订, 1：可预订
		 bookFlag: {
             type: 'integer',
             required: true
		 },
		 
		 // 是否需要证件
		 ifUseCard: {
             type: 'boolean',
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