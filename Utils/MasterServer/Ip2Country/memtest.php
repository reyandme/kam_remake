<?php
// Load the class
require_once 'Ip2Country.php';
// Just a little function that helps time things
function t($function)
{
    $t0 = microtime(true);
    $result = $function();
    echo " ** time = ", round((microtime(true) - $t0) * 1000, 2), "ms\r\n";
    return $result;
}
// Initialize
$ipc = new Ip2Country('../data/ip2country.dat');
$ipc->lookup('194.218.238.1');
echo "Memory used=", memory_get_usage(), ", peak=", memory_get_peak_usage(), "\r\n";
t(function() use ($ipc) { 
    $ipc->preload();
});
// Display statistics
echo "Memory used=", memory_get_usage(), ", peak=", memory_get_peak_usage(), "\r\n";
