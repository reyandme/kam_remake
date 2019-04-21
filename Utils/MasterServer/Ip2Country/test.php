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
$ipc->preload();
// Do a ton of lookups
echo "Timing test...\r\n";
t(function() use ($ipc) {
    for($i=0; $i<256; $i++)
    {
        $ipc->lookup("$i.0.0.0"); 
        $ipc->lookup("$i.$i.0.0"); 
        $ipc->lookup("$i.$i.$i.0"); 
        $ipc->lookup("$i.$i.$i.$i"); 
        $ipc->lookup("0.$i.$i.$i"); 
        $ipc->lookup("0.0.$i.$i"); 
        $ipc->lookup("0.0.0.$i"); 
    }
    
    for($i=0; $i<25000; $i++)
        $ipc->lookup(implode('.', array(rand(0,255), rand(0,255), rand(0,255), rand(0,255))));
});
$testdata = str_split(file_get_contents('../data/test.dat'), 6);
echo "Testing for correctness against generated test data...\r\n";
t(function() use ($ipc, $testdata) {
    $count = 0;
    foreach($testdata as $test)
    {
        $ipbin = substr($test, 0, 4);
        $ipcountry = substr($test, 4, 2);
        $country = $ipc->lookupbin($ipbin);
        
        if ($ipcountry != $country)
            echo "Problem: $ipcountry <> $country for ", bin2hex($ipbin), "\r\n";
        $count++;
    }
    echo "$count tests processed\r\n";
});
// Display statistics
echo "Memory used=", memory_get_usage(), ", peak=", memory_get_peak_usage(), "\r\n";
