/**
 * Proxy
 *
 * @module      :: Model
 * @description :: A short summary of how this model works and what it represents.
 * @docs		:: http://sailsjs.org/#!documentation/models
 */

module.exports = {
	
	tableName: 'proxies',
	
	schema: true,

    attributes: {
         uid: {
             type: 'string',
             required: true,
			 index: true
         },
		 ipValue: {
             type: 'ipv4',
             required: true,
			 //唯一约束
			 unique: true
		 },
         line: {
			 //0 default, 1 电信, 2 联通, 3 移动, 4 教育, 5 长宽, 678预留, 9 国外 
             type: 'integer',
             required: true
         },
         country: {
             type: 'string',
			 defaultsTo: 'CN',
			 len: 2,
             required: true,
			 index: true
         },
		 region: {
             type: 'string',
			 defaultsTo: 'intl',
			 minLength: 2,
			 maxLength: 10,
			 required: true,
			 index: true
		 },
         speed: 'json',
         fatchHit: {
             type: 'integer',
             required: true
         },
         status: {
             type: 'boolean',
             required: true
         },
         effect: {
             type: 'boolean',
             required: true
         }
    }
};