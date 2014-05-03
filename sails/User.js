/**
 * User
 *
 * @module      :: Model
 * @description :: A short summary of how this model works and what it represents.
 * @docs		:: http://sailsjs.org/#!documentation/models
 */




module.exports = {

  migrate: 'drop', // drops all your tables and then re-create them Note: You loose underlying.

  attributes: {
	  
	  username: {
	    type: 'string',
	    required: true,
	    unique: true
	  },

	  firstname: {
	    type: 'string',
	    required: true
	  },

	  lastname: {
	    type: 'string',
	    required: true
	  },

	  password: {
	    type: 'string',
	    required: true
	  },

	  birthdate: {
	    type: 'date',
	    required: true
	  },

	  email: {
	    type: 'email',
	    required: true,
	    unique: true
	  },

	  phonenumber: 'string',

	  // Create users full name automaticly
	  fullname: function(){
	    return this.firstname + ' ' + this.lastname;
	  }
	  
  }
};