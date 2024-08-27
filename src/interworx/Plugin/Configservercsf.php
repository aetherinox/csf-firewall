<?php
/*
###############################################################################
# Copyright 2006-2023, Way to the Web Limited
# URL: http://www.configserver.com
# Email: sales@waytotheweb.com
###############################################################################
*/

class Plugin_Configservercsf extends Plugin
{

    public function preAction($ctrl_act, Ctrl_Abstract $Ctrl, $action, $params)
    {
        if ($ctrl_act === 'Ctrl_Nodeworx_Firewall:index') {
            throw new IWorx_Exception_ActionBlocked('ConfigServer Plugins > Security & Firewall, has replaced this item');
        }
		elseif (strpos($ctrl_act, 'Ctrl_Nodeworx_Firewall') === 0) {
			throw new IWorx_Exception_ActionBlocked('N/A');
		}
    }

	public function getCategory()
    {
        return Plugin_Category::ADVANCED;
    }

    public function getPriority()
    {
        return 40;
    }

    public function runReseller()
    {
        putenv('IWORX_SESSION_ID=' . session_id());
        session_write_close();

        $cmd = Ini::get(Ini::IWORX_BIN, 'runasuser');

        $user = 'root';
        $cmd .= " {$user} custom /usr/local/interworx/plugins/configservercsf/lib/reseller.pl 2>&1";

        $InterWorx   = IW::Env()->getActiveSession()->getInterWorx();
		$WorkingUser = $InterWorx->getWorkingUser();
		putenv('REMOTE_USER=' . $WorkingUser->getNickname());

		putenv('QUERY_STRING=' . http_build_query($_GET));
        putenv('REQUEST_METHOD=' . $_SERVER['REQUEST_METHOD']);

        putenv('REMOTE_ADDR=' . $_SERVER['REMOTE_ADDR']);
        putenv('HTTP_USER_AGENT=' . $_SERVER['HTTP_USER_AGENT']);

        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            putenv('CONTENT_LENGTH=' . $_SERVER['CONTENT_LENGTH']);
            putenv('POST=' . http_build_query($_POST));
            putenv('HTTP_RAW_POST_DATA=' . http_build_query($_POST));
        }

        IWorxExec::exec($cmd, $result, $retval, IWorxExec::STDERR_2_STDOUT);
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
    }

    public function runAdmin()
    {
        putenv('IWORX_SESSION_ID=' . session_id());
        session_write_close();

        $cmd = Ini::get(Ini::IWORX_BIN, 'runasuser');

        $user = 'root';
        $cmd .= " {$user} custom /usr/local/interworx/plugins/configservercsf/lib/index.pl 2>&1";

        putenv('QUERY_STRING=' . http_build_query($_GET));
        putenv('REQUEST_METHOD=' . $_SERVER['REQUEST_METHOD']);

        putenv('REMOTE_ADDR=' . $_SERVER['REMOTE_ADDR']);
        putenv('HTTP_USER_AGENT=' . $_SERVER['HTTP_USER_AGENT']);

        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            putenv('CONTENT_LENGTH=' . $_SERVER['CONTENT_LENGTH']);
            putenv('POST=' . http_build_query($_POST));
            putenv('HTTP_RAW_POST_DATA=' . http_build_query($_POST));
        }

        IWorxExec::exec($cmd, $result, $retval, IWorxExec::STDERR_2_STDOUT);
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
    }

    public function updateNodeworxMenu(IWorxMenuManager $MenuMan)
    {
        $new_data = array( 'text' => 'ConfigServer Plugins',
                       'class' => 'iw-i-plugin',
                       'disabled_for_reseller' => '0' );

        $MenuMan->addMenuItemAfter(
            'iw-menu-svc',
            'menu-configserver',
            $new_data
        );

		$new_data = array( 'text' => 'Security & Firewall',
                       'url' => '/nodeworx/configservercsf?action=launch',
                       'parent' => 'menu-configserver',
                       'class' => 'iw-i-plugin',
                       'disabled_for_reseller' => '0' );

        $MenuMan->addMenuItemAfter(
            'menu-configserver',
            'menu-configservercsf',
            $new_data
        );
    }

}
