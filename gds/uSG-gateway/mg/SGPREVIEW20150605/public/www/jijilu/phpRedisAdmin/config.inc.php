<?php

$config = array(
  'servers' => array(
    0 => array(
      'name' => 'MasterSRV-0', // Optional name.
      'host' => '10.10.130.93',
      'port' => 16390,

      // Optional Redis authentication.
      'auth' => '142ffb5bfa1-cn-jijilu-dg-a75' // Warning: The password is sent in plain-text to the Redis server.
    ),

    1 => array(
      'name' => 'MasterSRV-2',
      'host' => '10.10.130.93',
      'port' => 16392,
      'auth' => '142ffb5bfa1-cn-jijilu-dg-a75' // Warning: The password is sent in plain-text to the Redis server.
    ),

    2 => array(
      'name' => 'MasterSRV-4',
      'host' => '10.10.130.93',
      'port' => 16394,
      'auth' => '142ffb5bfa1-cn-jijilu-dg-a75' // Warning: The password is sent in plain-text to the Redis server.
    )

  ),


  'seperator' => ':',


  // Uncomment to show less information and make phpRedisAdmin fire less commands to the Redis server. Recommended for a really busy Redis server.
  //'faster' => true,


  // Uncomment to enable HTTP authentication
  'login' => array(
    // Username => Password
    // Multiple combinations can be used
    'admin' => array(
      'password' => 'd15801359366ev',
    ),
    /*'guest' => array(
      'password' => 'd15801359366ev',
      'servers'  => array(0) // Optional list of servers this user can access.
    )*/
  ),




  // You can ignore settings below this point.

  'maxkeylen' => 100
);

?>
