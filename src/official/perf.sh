#!/bin/bash
cd /etc/csf
rm -Rf /home/webumake/public_html/nytpro*
/usr/local/cpanel/3rdparty/bin/perl -d:NYTProf /etc/csf/csf.pl -r
/usr/local/cpanel/3rdparty/perl/522/bin/nytprofhtml --open
/bin/cp -avf nytprof /home/webumake/public_html/.
chmod -R 755 /home/webumake/public_html/nytprof

# browse to http://www.webumake.net/nytprof/etc-csf-csf-pl-1-line.html
