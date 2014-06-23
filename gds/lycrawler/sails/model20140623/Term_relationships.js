/**
* Term_relationships.js
*
* @description :: TODO: You might write a short summary of how this model works and what it represents here.
* @docs        :: http://sailsjs.org/#!documentation/models
*/

module.exports = {

	schema: true,
	
    // Toggle the auto primary key (id) off
    autoPK: false,
	
    attributes: {
         TermTaxonomyId: {
			 model: 'Term_taxonomy',
			 columnName: 'term_taxonomy_id',
			 required: true,
			 index: true
         },
		 object_id: {
             type: 'string',
			 required: true,
			 primaryKey: true
		 },
		 //default 0
		 term_order: {
			 type: 'integer',
			 required: true
		 }
	 }
};

