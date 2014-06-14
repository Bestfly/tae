/**
* Tag.js
*
* @description :: TODO: You might write a short summary of how this model works and what it represents here.
* @docs        :: http://sailsjs.org/#!documentation/models
*/

module.exports = {

	schema: true,
	
    attributes: {
		 name: {
             type: 'string',
			 minLength: 2,
			 maxLength: 20,
			 required: true,
			 //index: true
			 unique: true
		 },
         ename: {
             type: 'string',
             minLength: 2,
             maxLength: 50,
             required: false
         },
		 remark: {
			 type: 'string',
			 required: false
		 },
         category: {
			 //1 impression, 2 suitherd, 3 theme, 456789预留 
             type: 'integer',
             required: true
         },
		 type : {
			 //1 scenery, 23456789预留 
             type: 'integer',
             required: true
		 }
	 }
};

