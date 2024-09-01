#!/bin/sh
echo "Uninstalling csf and lfd..."
echo

/usr/sbin/csf -f

if test `cat /proc/1/comm` = "systemd"
then
    systemctl disable csf.service
    systemctl disable lfd.service
    systemctl stop csf.service
    systemctl stop lfd.service

    rm -fv /usr/lib/systemd/system/csf.service
    rm -fv /usr/lib/systemd/system/lfd.service
    systemctl daemon-reload
else
    if [ -f /etc/redhat-release ]; then
        /sbin/chkconfig csf off
        /sbin/chkconfig lfd off
        /sbin/chkconfig csf --del
        /sbin/chkconfig lfd --del
    elif [ -f /etc/debian_version ] || [ -f /etc/lsb-release ]; then
        update-rc.d -f lfd remove
        update-rc.d -f csf remove
    elif [ -f /etc/gentoo-release ]; then
        rc-update del lfd default
        rc-update del csf default
    elif [ -f /etc/slackware-version ]; then
        rm -vf /etc/rc.d/rc3.d/S80csf
        rm -vf /etc/rc.d/rc4.d/S80csf
        rm -vf /etc/rc.d/rc5.d/S80csf
        rm -vf /etc/rc.d/rc3.d/S85lfd
        rm -vf /etc/rc.d/rc4.d/S85lfd
        rm -vf /etc/rc.d/rc5.d/S85lfd
    else
        /sbin/chkconfig csf off
        /sbin/chkconfig lfd off
        /sbin/chkconfig csf --del
        /sbin/chkconfig lfd --del
    fi
    rm -fv /etc/init.d/csf
    rm -fv /etc/init.d/lfd
fi

if [ -e "/usr/local/cpanel/bin/unregister_appconfig" ]; then
    cd /
	/usr/local/cpanel/bin/unregister_appconfig csf
fi

rm -fv /etc/chkserv.d/lfd
rm -fv /usr/sbin/csf
rm -fv /usr/sbin/lfd
rm -fv /etc/cron.d/csf_update
rm -fv /etc/cron.d/lfd-cron
rm -fv /etc/cron.d/csf-cron
rm -fv /etc/logrotate.d/lfd
rm -fv /usr/local/man/man1/csf.man.1

/bin/rm -fv /usr/local/cpanel/whostmgr/docroot/cgi/addon_csf.cgi
/bin/rm -Rfv /usr/local/cpanel/whostmgr/docroot/cgi/csf

/bin/rm -fv /usr/local/cpanel/whostmgr/docroot/cgi/configserver/csf.cgi
/bin/rm -Rfv /usr/local/cpanel/whostmgr/docroot/cgi/configserver/csf

/bin/rm -fv /usr/local/cpanel/Cpanel/Config/ConfigObj/Driver/ConfigServercsf.pm
/bin/rm -Rfv /usr/local/cpanel/Cpanel/Config/ConfigObj/Driver/ConfigServercsf
/bin/touch /usr/local/cpanel/Cpanel/Config/ConfigObj/Driver

rm -fv /var/run/chkservd/lfd
sed -i 's/lfd:1//' /etc/chkserv.d/chkservd.conf
/scripts/restartsrv_chkservd

rm -Rfv /etc/csf /usr/local/csf /var/lib/csf

echo
echo "...Done"
