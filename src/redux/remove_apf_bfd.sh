#!/bin/sh
echo "Removing apf and/or bfd..."
echo

apf -f
rm -fv /etc/cron.daily/fw
rm -fv /etc/cron.daily/apf
rm -fv /etc/cron.d/refresh.apf
rm -fv /etc/logrotate.d/apf
rm -fv /var/log/apf*
/sbin/chkconfig apf off
/sbin/chkconfig apf --del
rm -fv /etc/init.d/apf
rm -Rfv /etc/apf

rm -fv /etc/cron.d/bfd
rm -fv /etc/logrotate.d/bfd
rm -fv /var/log/bfd*
rm -Rfv /usr/local/bfd

echo
echo "...Done"
