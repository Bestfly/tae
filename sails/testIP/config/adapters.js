/**
 * Global adapter config
 * 
 * The `adapters` configuration object lets you create different global "saved settings"
 * that you can mix and match in your models.  The `default` option indicates which 
 * "saved setting" should be used if a model doesn't have an adapter specified.
 *
 * Keep in mind that options you define directly in your model definitions
 * will override these settings.
 *
 * For more information on adapter configuration, check out:
 * http://sailsjs.org/#documentation
 */

module.exports.adapters = {
  'default': 'mysql',

  mysql: {
    module   : 'sails-mysql',
    host     : 'localhost',
    port     : 3306,
    user     : 'rhomobi_dev',
    password : 'b6x7p6b6x7p6',
    database : 'proxy'

    // OR (explicit sets take precedence)
    // module   : 'sails-mysql',
    // url      : 'mysql2://USER:PASSWORD@HOST:PORT/DATABASENAME'
  }
};