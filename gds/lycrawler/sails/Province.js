/**
* Province.js
*
* @description :: TODO: You might write a short summary of how this model works and what it represents here.
* @docs        :: http://sailsjs.org/#!documentation/models
*/

module.exports = {

	schema: true,
	
    attributes: {
         CountryCode: {
			 model: 'Country',
			 columnName: 'CountryCode'
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
             required: true,
			 //index: true
			 //unique: true
         },
		 prefixLetter: {
             type: 'string',
			 minLength: 1,
			 maxLength: 1,
			 required: true,
			 index: true
		 }
	 }
};

