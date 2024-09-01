<?php
error_reporting(NULL);

$env = http_build_query($_GET);
if ($env == "") {
	$env = http_build_query($_POST);
}
$env = $env."&VESTASESSID=".$_COOKIE["PHPSESSID"];

include($_SERVER['DOCUMENT_ROOT']."/inc/main.php");

if ($_SESSION['user'] != 'admin') {
    header("Location: /list/user");
    exit;
}

exec (VESTA_CMD."csf.pl \"$env\"", $result, $return_var);

$header = 1;
foreach ($result as $line) {
	if ($header) {
		header ("$line\n");
	} else {
		print "$line\n";
	}
	if ($header && $line == "") {
		$header = 0;
	}
}

