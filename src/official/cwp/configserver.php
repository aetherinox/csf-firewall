<script type="text/javascript">
	$(document).ready(function() {
		var newButtons = ''
		+' <li>'
		+' <a href="#" class="hasUl"><span aria-hidden="true" class="icon16 icomoon-icon-bug"></span>ConfigServer Scripts<span class="hasDrop icon16 icomoon-icon-arrow-down-2"></span></a>'
		+'	<ul class="sub">'
<?php 
	
	if (file_exists("/usr/local/cwpsrv/htdocs/resources/admin/modules/csfofficial.php")) {
		echo "+'		<li><a href=\"index.php?module=csfofficial\"><span class=\"icon16 icomoon-icon-arrow-right-3\"></span>ConfigServer Firewall</a></li>'\n";
	}

	if (file_exists("/usr/local/cwpsrv/htdocs/resources/admin/modules/cxs.php")) {
		echo "+'		<li><a href=\"index.php?module=cxs\"><span class=\"icon16 icomoon-icon-arrow-right-3\"></span>ConfigServer Exploit Scanner</a></li>'\n";
	}

?>
		+'	</ul>'
		+'</li>';
		$(".mainnav > ul").append(newButtons);
	});
</script>
