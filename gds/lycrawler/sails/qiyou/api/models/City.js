/**
* City.js
*
* @description :: TODO: You might write a short summary of how this model works and what it represents here.
* @docs        :: http://sailsjs.org/#!documentation/models
*/

module.exports = {

	//tableName: 'proxies',
	
	schema: true,
	
    // Toggle the auto primary key (id) off
    // autoPK: false,
	
    attributes: {
         CountryCode: {
			 model: 'Country',
			 columnName: 'CountryCode',
			 required: true,
			 index: true
         },
		 ProvinceId: {
			 model: 'Province',
			 columnName: 'ProvinceId',
			 required: true,
			 index: true
		 },
         code: {
             type: 'string',
             minLength: 3,
             maxLength: 3,
             required: false,
			 //primaryKey: true
			 unique: true
         },
		 LyId: {
			 type: 'integer',
			 required: true,
			 unique: true
		 },
		 name: {
             type: 'string',
			 minLength: 2,
			 maxLength: 50,
			 required: true,
			 //index: true
			 unique: true
		 },
         ename: {
             type: 'string',
             minLength: 2,
             maxLength: 50,
             required: false,
			 //index: true
			 //unique: true
         },
         airport: {
             type: 'string',
             minLength: 3,
             maxLength: 50,
             required: false,
			 //index: true
         },
		 prefixLetter: {
             type: 'string',
			 minLength: 1,
			 maxLength: 1,
			 required: false,
			 //index: true
		 }
	 }
};

