#!/bin/bash
#
###############################################################################
# lfd
# Copyright 2006-2018, Way to the Web Limited
# URL: http://www.configserver.com
# Email: sales@waytotheweb.com
###############################################################################
#
# chkconfig: 2345 20 75
# description: Login Failure Daemon
#
### BEGIN INIT INFO
# Provides:          lfd
# Required-Start:    $network $syslog
# Required-Stop:     $network $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: csf Login Failure Daemon (lfd)
# Description:       csf Login Failure Daemon (lfd) init script
### END INIT INFO
#

[ -f /usr/sbin/lfd ] || exit 0

# Source function library.
if [ -f /etc/init.d/functions ]; then
	. /etc/init.d/functions
fi

RETVAL=0
PID=/var/run/lfd.pid
DAEMON=/usr/sbin/lfd
PIDOF=pidof

if [ -f /etc/SuSE-release ]; then
	. /etc/rc.status
	rc_reset
fi

# See how we were called.
case "$1" in
  start)
	echo -n "Starting lfd:"
    ulimit -n 4096
	$DAEMON
	if [ -f /etc/SuSE-release ]; then
		rc_status -v
	elif [ -f /etc/debian_version ] || [ -f /etc/lsb-release ] || [ -f /etc/gentoo-release ]; then
		echo " Done"
	else
		success
		echo
	fi
	;;
  stop)
	echo -n "Stopping lfd:"
	if [ -f /etc/SuSE-release ]; then
		killproc lfd
		rc_status -v
	elif [ -f /etc/debian_version ] || [ -f /etc/lsb-release ] || [ -f /etc/gentoo-release ]; then
		lfd=`cat /var/run/lfd.pid 2>/dev/null`
		if [ -n "${lfd}" ] && [ -e /proc/"${lfd}" ]; then
			kill "$lfd";
		fi
		echo " Done"
	else
		killproc lfd
		success
		echo
	fi
	;;
  status)
        echo -n "Status of lfd:"
	if [ -f /etc/SuSE-release ]; then
	        checkproc lfd
	        rc_status -v
		RETVAL=$?
	elif [ -f /etc/debian_version ] || [ -f /etc/lsb-release ] || [ -f /etc/gentoo-release ]; then
		lfd=`cat /var/run/lfd.pid 2>/dev/null`
		if [ -n "${lfd}" ] && [ -e /proc/"${lfd}" ]; then
			echo " Running"
		else
			echo " Stopped"
			RETVAL=3
		fi
	else
		status lfd
		RETVAL=$?
		echo
	fi
        ;;
  restart|force-reload)
	$0 stop
	$0 start
	;;
  *)
	echo "Usage: /etc/init.d/lfd start|stop|restart|force-reload|status"
	exit 1
esac

exit $RETVAL
