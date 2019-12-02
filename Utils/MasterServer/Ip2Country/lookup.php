<?php
// Get rid of the first entry, which is always the file name
array_shift($argv);
if (empty($argv))
    die("lookup <ip> [<ip>...]\r\n");
// Load the class and initialize
require_once 'Ip2Country.php';
$ipc = new Ip2Country('./data/ip2country.dat');

// Lookup IP addresses
foreach($argv as $ip) {
    $result = $ipc->lookup($ip);
    echo "Country for $ip is " . $result['full'] . " (" . $result['short'] . ")\r\n";
}
