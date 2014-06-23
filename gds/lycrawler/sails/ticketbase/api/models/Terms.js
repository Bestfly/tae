/**
* Terms.js
*
* @description :: TODO: You might write a short summary of how this model works and what it represents here.
* @docs        :: http://sailsjs.org/#!documentation/models
*/

module.exports = {

	schema: true,
	
    attributes: {

		 name: {
             type: 'string',
			 required: true,
			 index: true,
			 unique: true
		 },
         slug: {
             type: 'string',
             minLength: 2,
             maxLength: 50,
             required: true,
			 //index: true
			 unique: true
         },
		 term_group: {
             type: 'integer',
			 required: true
			 //index: true
		 }
	 }
};

