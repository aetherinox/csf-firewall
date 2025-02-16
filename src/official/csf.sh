#!/bin/bash
#
###############################################################################
# lfd
# Copyright 2006-2018, Way to the Web Limited
# URL: http://www.configserver.com
# Email: sales@waytotheweb.com
###############################################################################
#
# chkconfig: 2345 15 80
# description: ConfigServer Firewall
#
### BEGIN INIT INFO
# Provides:          csf
# Required-Start:    $network
# Required-Stop:     $network
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# X-Start-Before:    $syslog
# Short-Description: ConfigServer Firewall (csf)
# Description:       ConfigServer Firewall (csf) init script
### END INIT INFO
#

[ -f /usr/sbin/csf ] || exit 0

# Source function library.
if [ -f /etc/init.d/functions ]; then
	. /etc/init.d/functions
fi

DAEMON=/usr/sbin/csf
LOCKFILE=/var/lock/subsys/csf

if [ -f /etc/SuSE-release ]; then
	. /etc/rc.status
	rc_reset
fi

case "$1" in
  start)
	echo -n "Starting csf:"
	$DAEMON --initup
	if [ -f /etc/SuSE-release ]; then
		rc_status -v
	elif [ -f /etc/debian_version ] || [ -f /etc/lsb-release ] || [ -f /etc/gentoo-release ]; then
		echo " Done"
	else
		success
		echo
	fi
	echo
	if [ -e /var/lock/subsys/ ]; then
		touch $LOCKFILE
	fi
	;;
  stop)
	echo "WARNING: This script should ONLY be used by the init process. To restart csf use the CLI command 'csf -r'"
	echo
	echo -n "Stopping csf:"
	$DAEMON --initdown
	$DAEMON --stop > /dev/null 2>&1
	if [ -f /etc/SuSE-release ]; then
		rc_status -v
	elif [ -f /etc/debian_version ] || [ -f /etc/lsb-release ] || [ -f /etc/gentoo-release ]; then
		echo " Done"
	else
		success
		echo
	fi
	echo
	if [ -e /var/lock/subsys/ ]; then
		rm -f $LOCKFILE
	fi
	;;
  status)
        echo -n "Status of csf:"
	$DAEMON --status
	echo
        ;;
  restart|force-reload|reload)
	$0 stop
	$0 start
	;;
  *)
	echo "Usage: /etc/init.d/csf start|stop|restart|force-reload|status"
	exit 1
esac

exit 0
