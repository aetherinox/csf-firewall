#!/bin/sh
###############################################################################
# Copyright 2006-2018, Way to the Web Limited
# URL: http://www.configserver.com
# Email: sales@waytotheweb.com
###############################################################################

umask 0177

touch /etc/csf/csf.disable
/etc/init.d/lfd stop

# temp data:

cp -avf /etc/csf/csf.4.saved /var/lib/csf/
cp -avf /etc/csf/csf.6.saved /var/lib/csf/
cp -avf /etc/csf/csf.block.AUTOSHUN /var/lib/csf/
cp -avf /etc/csf/csf.block.BFB /var/lib/csf/
cp -avf /etc/csf/csf.block.BOGON /var/lib/csf/
cp -avf /etc/csf/csf.block.CIARMY /var/lib/csf/
cp -avf /etc/csf/csf.block.DSHIELD /var/lib/csf/
cp -avf /etc/csf/csf.block.HONEYPOT /var/lib/csf/
cp -avf /etc/csf/csf.block.MAXMIND /var/lib/csf/
cp -avf /etc/csf/csf.block.OPENBL /var/lib/csf/
cp -avf /etc/csf/csf.block.RBN /var/lib/csf/
cp -avf /etc/csf/csf.block.SPAMDROP /var/lib/csf/
cp -avf /etc/csf/csf.block.SPAMEDROP /var/lib/csf/
cp -avf /etc/csf/csf.block.TOR /var/lib/csf/
cp -avf /etc/csf/csf.ccignore /var/lib/csf/
cp -avf /etc/csf/csf.cclookup /var/lib/csf/
cp -avf /etc/csf/csf.div /usr/local/csf/lib/
cp -avf /etc/csf/csf.dnscache /var/lib/csf/
cp -avf /etc/csf/csf.dwdisable /var/lib/csf/
cp -avf /etc/csf/csf.gallow /var/lib/csf/
cp -avf /etc/csf/csf.gdeny /var/lib/csf/
cp -avf /etc/csf/csf.gdyndns /var/lib/csf/
cp -avf /etc/csf/csf.gignore /var/lib/csf/
cp -avf /etc/csf/csf.load /var/lib/csf/
cp -avf /etc/csf/csf.lock /var/lib/csf/
cp -avf /etc/csf/csf.logmax /var/lib/csf/
cp -avf /etc/csf/csf.logrun /var/lib/csf/
cp -avf /etc/csf/csf.logtemp /var/lib/csf/
cp -avf /etc/csf/csf.queue /var/lib/csf/
cp -avf /etc/csf/csf.restart /var/lib/csf/
cp -avf /etc/csf/csf.tempallow /var/lib/csf/
cp -avf /etc/csf/csf.tempban /var/lib/csf/
cp -avf /etc/csf/csf.tempconf /var/lib/csf/
cp -avf /etc/csf/csf.tempdisk /var/lib/csf/
cp -avf /etc/csf/csf.tempdyn /var/lib/csf/
cp -avf /etc/csf/csf.tempexp /var/lib/csf/
cp -avf /etc/csf/csf.tempexploit /var/lib/csf/
cp -avf /etc/csf/csf.tempfiles /var/lib/csf/
cp -avf /etc/csf/csf.tempgdyn /var/lib/csf/
cp -avf /etc/csf/csf.tempint /var/lib/csf/
cp -avf /etc/csf/csf.tempip /var/lib/csf/
cp -avf /etc/csf/csf.temppids /var/lib/csf/
cp -avf /etc/csf/csf.tempusers /var/lib/csf/
cp -avf /etc/csf/csf.tempwatch /var/lib/csf/
cp -avf /etc/csf/Geo/GeoIP.dat /var/lib/csf/Geo/
cp -avf /etc/csf/Geo/GeoLiteCity.dat /var/lib/csf/Geo/
cp -avf /etc/csf/lfd.enable /var/lib/csf/
cp -avf /etc/csf/lfd.restart /var/lib/csf/
cp -avf /etc/csf/lfd.start /var/lib/csf/
cp -avf /etc/csf/lock/ /var/lib/csf/
cp -avf /etc/csf/nocheck /var/lib/csf/
cp -avf /etc/csf/sanity.txt /usr/local/csf/lib/
cp -avf /etc/csf/stats/ /var/lib/csf/
cp -avf /etc/csf/suspicious.tar /var/lib/csf/
cp -avf /etc/csf/ui/ui.session /var/lib/csf/ui/
cp -avf /etc/csf/webmin/ /usr/local/csf/lib/
cp -avf /etc/csf/zone/ /var/lib/csf/

rm -fv /etc/csf/csf.4.saved
rm -fv /etc/csf/csf.6.saved
rm -fv /etc/csf/csf.block.AUTOSHUN
rm -fv /etc/csf/csf.block.BFB
rm -fv /etc/csf/csf.block.BOGON
rm -fv /etc/csf/csf.block.CIARMY
rm -fv /etc/csf/csf.block.DSHIELD
rm -fv /etc/csf/csf.block.HONEYPOT
rm -fv /etc/csf/csf.block.MAXMIND
rm -fv /etc/csf/csf.block.OPENBL
rm -fv /etc/csf/csf.block.RBN
rm -fv /etc/csf/csf.block.SPAMDROP
rm -fv /etc/csf/csf.block.SPAMEDROP
rm -fv /etc/csf/csf.block.TOR
rm -fv /etc/csf/csf.ccignore
rm -fv /etc/csf/csf.cclookup
rm -fv /etc/csf/csf.div
rm -fv /etc/csf/csf.dnscache
rm -fv /etc/csf/csf.dwdisable
rm -fv /etc/csf/csf.gallow
rm -fv /etc/csf/csf.gdeny
rm -fv /etc/csf/csf.gdyndns
rm -fv /etc/csf/csf.gignore
rm -fv /etc/csf/csf.load
rm -fv /etc/csf/csf.lock
rm -fv /etc/csf/csf.logmax
rm -fv /etc/csf/csf.logrun
rm -fv /etc/csf/csf.logtemp
rm -fv /etc/csf/csf.queue
rm -fv /etc/csf/csf.restart
rm -fv /etc/csf/csf.tempallow
rm -fv /etc/csf/csf.tempban
rm -fv /etc/csf/csf.tempconf
rm -fv /etc/csf/csf.tempdisk
rm -fv /etc/csf/csf.tempdyn
rm -fv /etc/csf/csf.tempexp
rm -fv /etc/csf/csf.tempexploit
rm -fv /etc/csf/csf.tempfiles
rm -fv /etc/csf/csf.tempgdyn
rm -fv /etc/csf/csf.tempint
rm -fv /etc/csf/csf.tempip
rm -fv /etc/csf/csf.temppids
rm -fv /etc/csf/csf.tempusers
rm -fv /etc/csf/csf.tempwatch
rm -fv /etc/csf/Geo/GeoIP.dat
rm -fv /etc/csf/Geo/GeoLiteCity.dat
rm -fv /etc/csf/lfd.enable
rm -fv /etc/csf/lfd.restart
rm -fv /etc/csf/lfd.start
rm -Rfv /etc/csf/lock/
rm -fv /etc/csf/nocheck
rm -fv /etc/csf/sanity.txt
rm -Rfv /etc/csf/stats/
rm -fv /etc/csf/suspicious.tar
rm -fv /etc/csf/ui/ui.session
rm -Rfv /etc/csf/webmin/
rm -Rfv /etc/csf/zone/

# email alert templates:

cp -avf /etc/csf/accounttracking.txt /usr/local/csf/tpl/
cp -avf /etc/csf/alert.txt /usr/local/csf/tpl/
cp -avf /etc/csf/connectiontracking.txt /usr/local/csf/tpl/
cp -avf /etc/csf/consolealert.txt /usr/local/csf/tpl/
cp -avf /etc/csf/cpanelalert.txt /usr/local/csf/tpl/
cp -avf /etc/csf/exploitalert.txt /usr/local/csf/tpl/
cp -avf /etc/csf/filealert.txt /usr/local/csf/tpl/
cp -avf /etc/csf/forkbombalert.txt /usr/local/csf/tpl/
cp -avf /etc/csf/integrityalert.txt /usr/local/csf/tpl/
cp -avf /etc/csf/loadalert.txt /usr/local/csf/tpl/
cp -avf /etc/csf/logalert.txt /usr/local/csf/tpl/
cp -avf /etc/csf/logfloodalert.txt /usr/local/csf/tpl/
cp -avf /etc/csf/netblock.txt /usr/local/csf/tpl/
cp -avf /etc/csf/permblock.txt /usr/local/csf/tpl/
cp -avf /etc/csf/portknocking.txt /usr/local/csf/tpl/
cp -avf /etc/csf/portscan.txt /usr/local/csf/tpl/
cp -avf /etc/csf/processtracking.txt /usr/local/csf/tpl/
cp -avf /etc/csf/queuealert.txt /usr/local/csf/tpl/
cp -avf /etc/csf/relayalert.txt /usr/local/csf/tpl/
cp -avf /etc/csf/resalert.txt /usr/local/csf/tpl/
cp -avf /etc/csf/reselleralert.txt /usr/local/csf/tpl/
cp -avf /etc/csf/scriptalert.txt /usr/local/csf/tpl/
cp -avf /etc/csf/sshalert.txt /usr/local/csf/tpl/
cp -avf /etc/csf/sualert.txt /usr/local/csf/tpl/
cp -avf /etc/csf/syslogalert.txt /usr/local/csf/tpl/
cp -avf /etc/csf/tracking.txt /usr/local/csf/tpl/
cp -avf /etc/csf/uialert.txt /usr/local/csf/tpl/
cp -avf /etc/csf/uidscan.txt /usr/local/csf/tpl/
cp -avf /etc/csf/usertracking.txt /usr/local/csf/tpl/
cp -avf /etc/csf/watchalert.txt /usr/local/csf/tpl/
cp -avf /etc/csf/webminalert.txt /usr/local/csf/tpl/
cp -avf /etc/csf/x-arf.txt /usr/local/csf/tpl/

rm -fv /etc/csf/accounttracking.txt
rm -fv /etc/csf/alert.txt
rm -fv /etc/csf/connectiontracking.txt
rm -fv /etc/csf/consolealert.txt
rm -fv /etc/csf/cpanelalert.txt
rm -fv /etc/csf/exploitalert.txt
rm -fv /etc/csf/filealert.txt
rm -fv /etc/csf/forkbombalert.txt
rm -fv /etc/csf/integrityalert.txt
rm -fv /etc/csf/loadalert.txt
rm -fv /etc/csf/logalert.txt
rm -fv /etc/csf/logfloodalert.txt
rm -fv /etc/csf/netblock.txt
rm -fv /etc/csf/permblock.txt
rm -fv /etc/csf/portknocking.txt
rm -fv /etc/csf/portscan.txt
rm -fv /etc/csf/processtracking.txt
rm -fv /etc/csf/queuealert.txt
rm -fv /etc/csf/relayalert.txt
rm -fv /etc/csf/resalert.txt
rm -fv /etc/csf/reselleralert.txt
rm -fv /etc/csf/scriptalert.txt
rm -fv /etc/csf/sshalert.txt
rm -fv /etc/csf/sualert.txt
rm -fv /etc/csf/syslogalert.txt
rm -fv /etc/csf/tracking.txt
rm -fv /etc/csf/uialert.txt
rm -fv /etc/csf/uidscan.txt
rm -fv /etc/csf/usertracking.txt
rm -fv /etc/csf/watchalert.txt
rm -fv /etc/csf/webminalert.txt
rm -fv /etc/csf/x-arf.txt

# perl modules:

rm -Rfv /etc/csf/Crypt
rm -Rfv /etc/csf/Geo
rm -Rfv /etc/csf/HTTP
rm -Rfv /etc/csf/Net

# scripts:

cp -avf /etc/csf/cseui.pl /usr/local/csf/bin/
cp -avf /etc/csf/csftest.pl /usr/local/csf/bin/
cp -avf /etc/csf/csfui.pl /usr/local/csf/bin/
cp -avf /etc/csf/csfuir.pl /usr/local/csf/bin/
cp -avf /etc/csf/migratedata.pl /usr/local/csf/bin/
cp -avf /etc/csf/pt_deleted_action.pl /usr/local/csf/bin/
cp -avf /etc/csf/regex.custom.pm /usr/local/csf/bin/
cp -avf /etc/csf/regex.pm /usr/local/csf/bin/
cp -avf /etc/csf/remove_apf_bfd.sh /usr/local/csf/bin/
cp -avf /etc/csf/servercheck.pm /usr/local/csf/bin/
cp -avf /etc/csf/uninstall.sh /usr/local/csf/bin/

rm -fv /etc/csf/cseui.pl
rm -fv /etc/csf/csftest.pl
rm -fv /etc/csf/csfui.pl
rm -fv /etc/csf/csfuir.pl
rm -fv /etc/csf/migratedata.pl
rm -fv /etc/csf/pt_deleted_action.pl
rm -fv /etc/csf/regex.custom.pm
rm -fv /etc/csf/regex.pm
rm -fv /etc/csf/remove_apf_bfd.sh
rm -fv /etc/csf/servercheck.pm
rm -fv /etc/csf/uninstall.sh

# other:

rm -fv /etc/csf/*.new
rm -fv /etc/csf/dd_test
rm -fv /etc/csf/csfwebmin.tgz
rm -fv /etc/csf/csf.spamhaus /etc/csf/csf.dshield /etc/csf/csf.tor /etc/csf/csf.bogon
rm -Rfv /etc/csf/File
rm -Rfv /etc/csf/Geography
rm -Rfv /etc/csf/IP
rm -Rfv /etc/csf/Math
rm -Rfv /etc/csf/Sys

rm -fv /etc/csf/csf.disable
