<?php

$config = array(
  'servers' => array(
    0 => array(
      'name' => 'SRV6399', // Optional name.
      'host' => '10.10.42.31',
      'port' => 6399,
      // Optional Redis authentication.
      //'auth' => '142ffb5bfa1-cn-jijilu-dg-a01' // Warning: The password is sent in plain-text to the Redis server.
    ),
	
    1 => array(
      'name' => 'SRV6389',
      'host' => '127.0.0.1',
      'port' => 6389,
	  'auth' => '142ffb5bfa1-cn-jijilu-dg-a01'
    ),
	
    2 => array(
      'name' => 'RhoConnect',
      'host' => '192.168.1.134',
      'port' => 6389,
      'db'   => 0, // Optional database number, see http://redis.io/commands/select
	  'auth' => '142ffb5bfa1-cn-jijilu-dg-a01'
    )
  ),


  'seperator' => ':',


  // Uncomment to show less information and make phpRedisAdmin fire less commands to the Redis server. Recommended for a really busy Redis server.
  //'faster' => true,


  // Uncomment to enable HTTP authentication
  /*'login' => array(
    // Username => Password
    // Multiple combinations can be used
    'admin' => array(
      'password' => 'adminpassword',
    ),
    'guest' => array(
      'password' => '',
      'servers'  => array(1) // Optional list of servers this user can access.
    )
  ),*/




  // You can ignore settings below this point.

  'maxkeylen' => 100
);

?>
