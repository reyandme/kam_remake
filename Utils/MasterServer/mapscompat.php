<?php
require_once("db.php");

if (
    (!array_key_exists('rev', $_REQUEST)) ||
    (!array_key_exists('now', $_REQUEST)) ||
    (!array_key_exists('map', $_REQUEST)) ||
    (!array_key_exists('crc', $_REQUEST)) ||
    (!array_key_exists('playercount', $_REQUEST)) ||
    (!array_key_exists('ip', $_REQUEST))
) {
    die('Invalid request');
}

$con = db_connect();

$rev = $con->real_escape_string($_REQUEST["rev"]);
$now = $con->real_escape_string($_REQUEST["now"]);
$map = $con->real_escape_string($_REQUEST["map"]);
$crc = $con->real_escape_string($_REQUEST["crc"]);
$playercount = intval($con->real_escape_string($_REQUEST["playercount"]));
$ip = $con->real_escape_string($_REQUEST["ip"]);

if(
    $rev === '' ||
    $now === '' ||
    $map === '' ||
    $crc === '' ||
    $ip === ''
) {
    $con->close();
    die("Invalid request");
}

db_init($con);
$query = "INSERT INTO Games (Rev, Timestamp, Map, MapCRC, Players, IP) VALUES ('$rev', '$now', '$map', '$crc', $playercount, '$ip')";

if(!$con->query($query)) {
    error_log("Error adding server: ".mysqli_error($con));
}

$con->close();
die('success');
