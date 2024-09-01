<?php
/*
###############################################################################
# Copyright 2006-2023, Way to the Web Limited
# URL: http://www.configserver.com
# Email: sales@waytotheweb.com
###############################################################################
*/

class Ctrl_Nodeworx_Configservercsf extends Ctrl_Nodeworx_Plugin
{

    protected function _init()
    {
        chmod('/usr/local/interworx/plugins/configservercsf', 0711);
        chmod('/usr/local/interworx/plugins/configservercsf/lib', 0711);
        chmod('/usr/local/interworx/plugins/configservercsf/lib/index.pl', 0711);
        chmod('/usr/local/interworx/plugins/configservercsf/lib/reseller.pl', 0711);
	}

    public function launchAction()
    {
        $this->getView()->assign('title', 'Configservercsf Services');
        $this->getView()->assign('template', 'admin');
    }

    public function indexAction()
    {
        if (IW::NW()->isReseller()) {
	        $this->_getPlugin()->runReseller();
		} else {
	        $this->_getPlugin()->runAdmin();
		}
        exit;
    }
}
