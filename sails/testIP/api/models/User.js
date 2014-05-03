/**
 * User
 *
 * @module      :: Model
 * @description :: A short summary of how this model works and what it represents.
 * @docs		:: http://sailsjs.org/#!documentation/models
 */

// User.js

module.exports = {
	//migrate: 'drop', // drops all your tables and then re-create them Note: You loose underlying.
    attributes: {
         username: {
			 type: 'STRING',
			 required: true,
			 unique: true
         },
         password: {
			 type: 'STRING',
			 required: true,
         }
    }
};


