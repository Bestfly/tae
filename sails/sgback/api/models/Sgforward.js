/**
* Sgforward.js
*
* @description :: TODO: You might write a short summary of how this model works and what it represents here.
* @docs        :: http://sailsjs.org/#!documentation/models
*/

module.exports = {
	
	
	tableName: 'forwards',
	
	schema: true,
	
    // Toggle the auto primary key (id) off
    // autoPK: false,
	
    attributes: {
		
         method: {
             type: 'string',
             minLength: 3,
             maxLength: 4,
             required: true
         },
		 serviceType: {
             type: 'string',
			 required: true,
			 index: true
		 },
		 serviceName: {
             type: 'string',
			 required: true,
			 index: true
		 },
         url: {
             type: 'url',
			 minLength: 15,
			 required: false
         },
		 //default 0
		 count: {
			 type: 'integer',
			 required: true
		 },
		 // 扩展预留 ｜ 待处理的图 |
		 remark: {
			 type: 'text',
			 required: false
		 }
	 }

};

