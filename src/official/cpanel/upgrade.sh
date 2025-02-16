#!/bin/sh

if [ -e "/usr/local/cpanel/bin/register_appconfig" ]; then
    if [ -e "/usr/local/cpanel/whostmgr/docroot/cgi/addon_csf.cgi" ]; then
        /bin/cp -af /usr/local/cpanel/whostmgr/docroot/cgi/configserver/csf/Driver/* /usr/local/cpanel/Cpanel/Config/ConfigObj/Driver/
        /bin/touch /usr/local/cpanel/Cpanel/Config/ConfigObj/Driver
        /usr/local/cpanel/bin/register_appconfig /usr/local/cpanel/whostmgr/docroot/cgi/configserver/csf/csf.conf

        /bin/rm -f /usr/local/cpanel/whostmgr/docroot/cgi/addon_csf.cgi
        /bin/rm -Rf /usr/local/cpanel/whostmgr/docroot/cgi/csf
    fi
fi
