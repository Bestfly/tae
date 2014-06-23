/**
* Division.js
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
		 name: {
             type: 'string',
			 minLength: 2,
			 maxLength: 50,
			 required: true
		 },
         ename: {
             type: 'string',
             minLength: 2,
             maxLength: 50
             //required: true,
			 //unique: true
			 //index: true
         },
		 dLyId: {
			 type: 'integer',
			 required: true,
			 unique: true
		 },
		 dMgId: {
			 type: 'integer',
			 //required: true,
			 unique: true
		 },
		 prefixLetter: {
             type: 'string',
			 minLength: 1,
			 maxLength: 1
			 //required: true,
			 //index: true
		 }
	 }
};

