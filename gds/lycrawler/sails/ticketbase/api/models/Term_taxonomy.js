/**
* Term_taxonomy.js
*
* @description :: TODO: You might write a short summary of how this model works and what it represents here.
* @docs        :: http://sailsjs.org/#!documentation/models
*/

module.exports = {

	schema: true,
	
    attributes: {
         TermId: {
			 model: 'Terms',
			 columnName: 'term_id',
			 required: true,
			 unique: true
         },
		 taxonomy: {
             type: 'string',
			 required: true,
			 index: true,
			 //unique: true
		 },
         description: {
             type: 'string',
             //minLength: 2,
             required: false
         },
		 //default 0
		 parent: {
			 type: 'integer',
			 required: true
		 },
		 //default 0
		 count: {
			 type: 'integer',
			 required: true
		 }
	 }
};

