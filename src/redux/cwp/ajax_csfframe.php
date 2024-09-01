<?php

	$env = http_build_query($_POST);
	if ($env == "") {
		$env = http_build_query($_GET);
	}
	$env = $env."&CWPSESSID=".$_SERVER["REQUEST_URI"];

	exec ("/usr/local/cwpsrv/htdocs/resources/admin/modules/csf.pl \"$env\"", $result, $return_var);

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
?>