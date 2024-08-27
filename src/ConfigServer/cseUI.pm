###############################################################################
# Copyright 2006-2023, Way to the Web Limited
# URL: http://www.configserver.com
# Email: sales@waytotheweb.com
###############################################################################
## no critic (RequireUseWarnings, ProhibitExplicitReturnUndef, ProhibitMixedBooleanOperators, RequireBriefOpen)
package ConfigServer::cseUI;

use strict;
use Fcntl qw(:DEFAULT :flock);
use File::Find;
use File::Copy;
use IPC::Open3;

use Exporter qw(import);
our $VERSION     = 2.03;
our @ISA         = qw(Exporter);
our @EXPORT_OK   = qw();

umask(0177);

our ($chart, $ipscidr6, $ipv6reg, $ipv4reg, %config, %ips, $mobile,
	 %FORM, $script, $script_da, $images, $myv);

our ($act, $destpath, $element, $extramessage, $fieldname, $fileinc,
	$filetemp, $message, $name, $origpath, $storepath, $tgid, $thisdir,
	$tuid, $value, $webpath, %ele, %header, @bits, @dirs, @filebodies,
	@filenames, @files, @months, @parts, @passrecs, @thisdirs, @thisfiles,
	$files);
#
###############################################################################
# start main
sub main {
	my $FORM_ref = shift;
	%FORM = %{$FORM_ref};
	$fileinc = shift;
	$script = shift;
	$script_da = shift;
	$images = shift;
	$myv = shift;
	$| = 1;

	&loadconfig;

	$webpath = '/';

	if ($FORM{do} eq "view") {
		&view;
		exit;
	}

	print "Content-type: text/html\r\n\r\n";

	my $bootstrapcss = "<link rel='stylesheet' href='$images/bootstrap/css/bootstrap.min.css'>";
	my $jqueryjs = "<script src='$images/jquery.min.js'></script>";
	my $bootstrapjs = "<script src='$images/bootstrap/js/bootstrap.min.js'></script>";

	print <<EOF;
<!doctype html>
<html lang='en'>
<head>
	<title>ConfigServer Explorer</title>
	<meta charset='utf-8'>
	<meta name='viewport' content='width=device-width, initial-scale=1'>
	$bootstrapcss
	<link href='$images/configserver.css' rel='stylesheet' type='text/css'>
	$jqueryjs
	$bootstrapjs
</head>
<body>
<div id="loader"></div>
EOF

	unless ($FORM{do} eq "console") {
		print "<div class='container-fluid'>\n";
		print "<div class='pull-right' style='margin:8px'>\n";
		if ($config{UI_CXS} or $config{UI_CSE}) {
			print "<form action='$script' method='post'><select name='csfapp'><option>csf</option>";
			if ($config{UI_CXS}) {print "<option>cxs</option>"}
			if ($config{UI_CSE}) {print "<option selected>cse</option>"}
			print "<", "/select> <input class='btn btn-default' type='submit' value='Switch'></form>\n";
		}
		print " <a class='btn btn-default' href='$script?csfaction=csflogout'>cse Logout</a>\n";
		print "</div>\n";
		print <<EOF;
<div class='panel panel-default panel-body'>
<h4><span class="glyphicon glyphicon-folder-open icon-configserver"></span> ConfigServer Explorer - cse</h4>
</div>
EOF
	}

	$message = "";

	if ($fileinc) {&uploadfile}
	elsif ($FORM{do} eq "") {&browse}
	elsif ($FORM{quit} == 2) {&browse}
	elsif ($FORM{do} eq "b") {&browse}
	elsif ($FORM{do} eq "p") {&browse}
	elsif ($FORM{do} eq "o") {&browse}
	elsif ($FORM{do} eq "c") {&browse}
	elsif ($FORM{do} eq "m") {&browse}
	elsif ($FORM{do} eq "pw") {&browse}
	elsif ($FORM{do} eq "r") {&browse}
	elsif ($FORM{do} eq "newf") {&browse}
	elsif ($FORM{do} eq "newd") {&browse}
	elsif ($FORM{do} eq "cnewf") {&cnewf}
	elsif ($FORM{do} eq "cnewd") {&cnewd}
	elsif ($FORM{do} eq "ren") {&ren}
	elsif ($FORM{do} eq "del") {&del}
	elsif ($FORM{do} eq "setp") {&setp}
	elsif ($FORM{do} eq "seto") {&seto}
	elsif ($FORM{do} eq "cd") {&cd}
	elsif ($FORM{do} eq "console") {&console}
	elsif ($FORM{do} eq "edit") {&edit}
	elsif ($FORM{do} eq "Cancel") {&browse}
	elsif ($FORM{do} eq "Save") {&save}
	elsif ($FORM{do} eq "copyit") {&copyit}
	elsif ($FORM{do} eq "moveit") {&moveit}
	else {print "Invalid action"};

	unless ($FORM{do} eq "console") {
		print "<p>&copy;2006-2023, <a href='http://www.configserver.com' target='_blank'>ConfigServer Services</a> (Way to the Web Limited)</p>\n";
	}
	print <<EOF;
</div>
<script>
	\$("#loader").hide();
	\$(document).ready(function(){
		\$('[data-tooltip="tooltip"]').tooltip();
	});
</script>
</body>
</html>
EOF
	exit;
}
# end main
###############################################################################
# start browse
sub browse {
	my $extra;
	if ($FORM{c}) {
		if (-e "$webpath$FORM{c}") {
			$extra = "&c=$FORM{c}";
		} else {
			$FORM{c} = "";
		}
	}
	if ($FORM{m}) {
		if (-e "$webpath$FORM{m}") {
			$extra = "&m=$FORM{m}"
		} else {
			$FORM{m} = "";
		}
	}

	print "<script language='javascript'>\n";
	print "	function check(file) {return confirm('Click OK to '+file)}\n";
	print "</script>\n";

	$thisdir = $webpath;
	if ($thisdir !~ /\/$/) {$thisdir .= "/"}
	$thisdir .= $FORM{p};
	$thisdir =~ s/\/+/\//g;
	@months = ("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec");

	my $errordir = 0;
	opendir (DIR, "$thisdir") or $errordir = 1;
	while (my $file = readdir(DIR)) {
		if (-d "$thisdir/$file") {
			if ($file !~ /^\.$|^\.\.$/) {push (@thisdirs, $file)}
		} else {
			push (@thisfiles, $file);
		}

	}
	closedir (DIR);

	@thisdirs = sort @thisdirs;
	@thisfiles = sort @thisfiles;

	print "<div class='bs-callout bs-callout-danger'>\n";
	print "<span class='label label-danger'>WARNING!</span> While this utility can be very useful it is also very dangerous indeed. You can easily render your server inoperable and unrecoverable by performing ill advised actions. No warranty or guarantee is provided with the product that protects against system damage.\n";
	print "</div>\n";

	if ($message) {print "<div class='bs-callout bs-callout-success'><h3 class='text-center'>$message</h3></div>\n";}
	print "<table class='table table-bordered table-striped table-condensed'>\n";
	print "<tr><td colspan='7'>";
	print "[<a href=\"$script?do=b&p=$extra\">Home</a>]";
	my $path = "";
	my $cnt = 2;
	my @path = split(/\//,$FORM{p});
	foreach my $dir (@path) {
		if ($dir ne "" and ($dir ne "/")) {
			if ($cnt == @path) {
				print "<code>/$dir</code>";
			} else {
				print "<code>/</code><a href=\"$script?do=b&p=$path/$dir$extra\">$dir</a>";
			}
			$path .= "/$dir";
			$cnt++;
		}
	}
	if ($FORM{c}) {print "&nbsp;&nbsp;&nbsp;&nbsp;Copy buffer:<code>$FORM{c}</code> <a class='btn btn-default glyphicon glyphicon-paste' data-tooltip='tooltip' title='Paste Here' href='$script?do=c&p=$FORM{p}$extra\#new'></a>\n"}
	if ($FORM{m}) {print "&nbsp;&nbsp;&nbsp;&nbsp;Move buffer:<code>$FORM{m}</code> <a class='btn btn-default glyphicon glyphicon-paste' data-tooltip='tooltip' title='Move Here' href='$script?do=m&p=$FORM{p}$extra\#new'></a>\n"}
	print "</td></tr>\n";
	if ($errordir) {
		print "<tr><td colspan='10'>Permission Denied</td></tr>";
	} else {
		if (@thisdirs > 0) {
			print "<thead>\n";
			print "<tr>";
			print "<th>Directory Name</th>";
			print "<th>Size</th>";
			print "<th>Date</th>";
			print "<th>User(uid)/Group(gid)</th>";
			print "<th>Perms</th>";
			print "<th colspan='2'>Actions</th>";
			print "</tr></thead>\n";
		}
		my $class = "tdshade2";
		foreach my $dir (@thisdirs) {
			if ($dir =~/'|"|\||\`/) {
				print "<td colspan='7'>".quotemeta($dir)."Invalid directory name - ignored</td>";
				next;
			}
			my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat("$thisdir/$dir");
			if ($size < 1024) {
			}
			elsif ($size < (1024 * 1024)) {
				$size = sprintf("%.1f",($size/1024));
				$size .= "k";
			}
			else {
				$size = sprintf("%.1f",($size/(1024 * 1024)));
				$size .= "M";
			}
			$mode = sprintf "%04o", $mode & oct("07777");
			$tgid = getgrgid($gid);
			if ($tgid eq "") {$tgid = $gid}
			$tuid = getpwuid($uid);
			if ($tuid eq "") {$tuid = $uid}
			my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($mtime);
			$year += 1900;
			my $time = sprintf "%02d:%02d:%02d", $hour, $min, $sec;
			$mday = sprintf "%02d", $mday;
			$mtime = "$mday-$months[$mon]-$year $time";
			my $pp = "";
			my $passfile = "$FORM{p}/$dir";
			$passfile =~ s/\//\_/g;
			$passfile =~ s/\\/\_/g;
			$passfile =~ s/\:/\_/g;
			if (-e "$storepath/$passfile.htpasswd") {
				open (my $PASSFILE, "<","$storepath/$passfile.htpasswd") or die $!;
				flock ($PASSFILE, LOCK_SH);
				@passrecs = <$PASSFILE>;
				close ($PASSFILE);
				chomp @passrecs;
				if (@passrecs > 0) {$pp = "**"}
			}

			print "<tr>";
			if ($FORM{do} eq "r" and ($FORM{f} eq $dir)) {
				print "<form action='$script' method='post'>\n";
				print "<td>";
				print "<input type='hidden' name='do' value='ren'>\n";
				print "<input type='hidden' name='p' value='$FORM{p}'>\n";
				print "<input type='hidden' name='c' value='$FORM{c}'>\n";
				print "<input type='hidden' name='m' value='$FORM{m}'>\n";
				print "<input type='hidden' name='f' value='$dir'>\n";
				print "<input type='text' size='10' name='newf' value='$dir'>\n";
				print "<input type='submit' class='btn btn-default' value='OK'>\n";
				print "$pp<a name='new'></a></td>";
				print "</form>\n";
			}
			elsif (-r "$webpath$FORM{p}/$dir") {
				print "<td><a data-tooltip='tooltip' title='Enter Directory' href='$script?do=b&p=$FORM{p}/$dir$extra\#new'>$dir</a>$pp</td>";
			}
			else {
				print "<td>$dir</td>";
			}
			print "<td align='right'>$size</td>";
			print "<td align='right'>$mtime</td>";
			if ($FORM{do} eq "o" and ($FORM{f} eq $dir)) {
				print "<form action='$script' method='post'>\n";
				print "<td align='right'>";
				print "<input type='hidden' name='do' value='seto'>\n";
				print "<input type='hidden' name='p' value='$FORM{p}'>\n";
				print "<input type='hidden' name='c' value='$FORM{c}'>\n";
				print "<input type='hidden' name='m' value='$FORM{m}'>\n";
				print "<input type='hidden' name='f' value='$dir'>\n";
				print "<input type='text' size='20' name='newo' value='$tuid:$tgid'>\n";
				print "<input type='submit' class='btn btn-default' value='OK'>\n";
				print "<a name='new'></a></td>";
				print "</form>\n";
			}
			else {
				print "<td align='right'><a data-tooltip='tooltip' title='Directory Owner' href='$script?do=o&p=$FORM{p}&f=$dir$extra\#new'>$tuid($uid)/$tgid($gid)</a></td>";
			}
			if ($FORM{do} eq "p" and ($FORM{f} eq $dir)) {
				print "<form action='$script' method='post'>\n";
				print "<td align='right'>";
				print "<input type='hidden' name='do' value='setp'>\n";
				print "<input type='hidden' name='p' value='$FORM{p}'>\n";
				print "<input type='hidden' name='c' value='$FORM{c}'>\n";
				print "<input type='hidden' name='m' value='$FORM{m}'>\n";
				print "<input type='hidden' name='f' value='$dir'>\n";
				print "<input type='text' size='3' name='newp' value='$mode'>\n";
				print "<input type='submit' class='btn btn-default' value='OK'>\n";
				print "<a name='new'></a></td>";
				print "</form>\n";
			}
			else {
				print "<td align='right'><a data-tooltip='tooltip' title='Permissions (CHMOD)' href='$script?do=p&p=$FORM{p}&f=$dir$extra\#new'>$mode</a></td>";
			}
			print "<td>&nbsp;</td>";
			print "<td><a class='btn btn-danger glyphicon glyphicon-trash' data-tooltip='tooltip' title='Delete Directory' href='$script?do=del&p=$FORM{p}&f=$dir$extra' onClick='return check(\"DELETE $dir\")'></a>";
			print " <a class='btn btn-primary glyphicon glyphicon-wrench' data-tooltip='tooltip' title='Rename Directory' href='$script?do=r&p=$FORM{p}&f=$dir$extra\#new'></a>";
			print " <a class='btn btn-success glyphicon glyphicon-copy' data-tooltip='tooltip' title='Copy Directory' href='$script?do=b&p=$FORM{p}&c=$FORM{p}/$dir\#new'></a>";
			print " <a class='btn btn-warning glyphicon glyphicon-move' data-tooltip='tooltip' title='Move Directory' href='$script?do=b&p=$FORM{p}&m=$FORM{p}/$dir\#new'></a></td>";
			print "</tr>\n";
		}
		if ($FORM{do} eq "newd") {
			print "<tr>";
			print "<form action='$script' method='post'>\n";
			print "<td>";
			print "<input type='hidden' name='do' value='cnewd'>\n";
			print "<input type='hidden' name='p' value='$FORM{p}'>\n";
			print "<input type='hidden' name='c' value='$FORM{c}'>\n";
			print "<input type='hidden' name='m' value='$FORM{m}'>\n";
			print "<input type='text' size='10' name='newf' value=''>\n";
			print "<input type='submit' class='btn btn-default' value='OK'>\n";
			print "<a name='new'></a></td>";
			print "</form>\n";
			print "<td>&nbsp;</td>";
			print "<td>&nbsp;</td>";
			print "<td>&nbsp;</td>";
			print "<td>&nbsp;</td>";
			print "<td colspan='5'>&nbsp;</td>";
			print "</tr>\n";
		}
		if (($FORM{do} eq "c") and (-d "$webpath$FORM{c}")) {
			my $newf = (split(/\//,$FORM{c}))[-1];
			print "<tr>";
			print "<form action='$script' method='post'>\n";
			print "<td>";
			print "<input type='hidden' name='do' value='copyit'>\n";
			print "<input type='hidden' name='p' value='$FORM{p}'>\n";
			print "<input type='hidden' name='c' value='$FORM{c}'>\n";
			print "<input type='hidden' name='m' value='$FORM{m}'>\n";
			print "<input type='text' size='10' name='newf' value='$newf'>\n";
			print "<input type='submit' class='btn btn-default' value='OK'>\n";
			print "<a name='new'></a></td>";
			print "</form>\n";
			print "<td>&nbsp;</td>";
			print "<td>&nbsp;</td>";
			print "<td>&nbsp;</td>";
			print "<td>&nbsp;</td>";
			print "<td colspan='2'>&nbsp;</td>";
			print "</tr>\n";
		}
		if (($FORM{do} eq "m") and (-d "$webpath$FORM{m}")) {
			my $newf = (split(/\//,$FORM{m}))[-1];
			print "<tr>";
			print "<form action='$script' method='post'>\n";
			print "<td>";
			print "<input type='hidden' name='do' value='moveit'>\n";
			print "<input type='hidden' name='p' value='$FORM{p}'>\n";
			print "<input type='hidden' name='c' value='$FORM{c}'>\n";
			print "<input type='hidden' name='m' value='$FORM{m}'>\n";
			print "<input type='text' size='10' name='newf' value='$newf'>\n";
			print "<input type='submit' class='btn btn-default' value='OK'>\n";
			print "<a name='new'></a></td>";
			print "</form>\n";
			print "<td>&nbsp;</td>";
			print "<td>&nbsp;</td>";
			print "<td>&nbsp;</td>";
			print "<td>&nbsp;</td>";
			print "<td colspan='2'>&nbsp;</td>";
			print "</tr>\n";
		}

		if (@thisfiles > 0) {
			print "<tr><td colspan='7'>&nbsp;</td></tr>\n";
			print "<thead><tr>";
			print "<th>File Name</th>";
			print "<th>Size</th>";
			print "<th>Date</th>";
			print "<th>User(uid)/Group(gid)</th>";
			print "<th>Perms</th>";
			print "<th colspan='2'>Actions</th>";
			print "</tr></thead>\n";
		}
		$class = "tdshade2";
		foreach my $file (@thisfiles) {
			if ($file =~/'|"|\||\`/) {
				print "<td colspan='7'>".quotemeta($file)."Invalid file name - ignored</td>";
				next;
			}
			my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat("$thisdir/$file");
			if ($size < 1024) {
			}
			elsif ($size < (1024 * 1024)) {
				$size = sprintf("%.1f",($size/1024));
				$size .= "k";
			}
			else {
				$size = sprintf("%.1f",($size/(1024 * 1024)));
				$size .= "M";
			}
			$mode = sprintf "%03o", $mode & oct("00777");
			$tgid = getgrgid($gid);
			if ($tgid eq "") {$tgid = $gid}
			$tuid = getpwuid($uid);
			if ($tuid eq "") {$tuid = $uid}
			my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($mtime);
			$year += 1900;
			my $time = sprintf "%02d:%02d:%02d", $hour, $min, $sec;
			$mday = sprintf "%02d", $mday;
			$mtime = "$mday-$months[$mon]-$year $time";
			print "<tr>";
			if ($FORM{do} eq "r" and ($FORM{f} eq $file)) {
				print "<form action='$script' method='post'>\n";
				print "<td>";
				print "<input type='hidden' name='do' value='ren'>\n";
				print "<input type='hidden' name='p' value='$FORM{p}'>\n";
				print "<input type='hidden' name='c' value='$FORM{c}'>\n";
				print "<input type='hidden' name='m' value='$FORM{m}'>\n";
				print "<input type='hidden' name='f' value='$file'>\n";
				print "<input type='text' size='20' name='newf' value='$file'>\n";
				print "<input type='submit' class='btn btn-default' value='OK'>\n";
				print "<a name='new'></a></td>";
				print "</form>\n";
			}
			else {
				$act = "$script?do=view&p=$FORM{p}&f=$file$extra\#new";
				print "<td><a href='$act' data-tooltip='tooltip' title='Download File' target='_blank'>$file</a></td>";
			}
			print "<td align='right'>$size</td>";
			print "<td align='right'>$mtime</td>";
			if ($FORM{do} eq "o" and ($FORM{f} eq $file)) {
				print "<form action='$script' method='post'>\n";
				print "<td align='right'>";
				print "<input type='hidden' name='do' value='seto'>\n";
				print "<input type='hidden' name='p' value='$FORM{p}'>\n";
				print "<input type='hidden' name='c' value='$FORM{c}'>\n";
				print "<input type='hidden' name='m' value='$FORM{m}'>\n";
				print "<input type='hidden' name='f' value='$file'>\n";
				print "<input type='text' size='20' name='newo' value='$tuid:$tgid'>\n";
				print "<input type='submit' class='btn btn-default' value='OK'>\n";
				print "<a name='new'></a></td>";
				print "</form>\n";
			}
			else {
				print "<td align='right'><a data-tooltip='tooltip' title='File Owner' href='$script?do=o&p=$FORM{p}&f=$file$extra\#new'>$tuid($uid)/$tgid($gid)</a></td>";
			}
			if ($FORM{do} eq "p" and ($FORM{f} eq $file)) {
				print "<form action='$script' method='post'>\n";
				print "<td align='right'>";
				print "<input type='hidden' name='do' value='setp'>\n";
				print "<input type='hidden' name='p' value='$FORM{p}'>\n";
				print "<input type='hidden' name='c' value='$FORM{c}'>\n";
				print "<input type='hidden' name='m' value='$FORM{m}'>\n";
				print "<input type='hidden' name='f' value='$file'>\n";
				print "<input type='text' size='3' name='newp' value='$mode'>\n";
				print "<input type='submit' class='btn btn-default' value='OK'>\n";
				print "<a name='new'></a></td>";
				print "</form>\n";
			}
			else {
				print "<td align='right'><a data-tooltip='tooltip' title='Permissions (CHMOD)' href='$script?do=p&p=$FORM{p}&f=$file$extra\#new'>$mode</a></td>";
			}
			my $ext = (split(/\./,$file))[-1];
			if (-T "$webpath$FORM{p}/$file") {
				my $act = "";
				print "<td><a class='btn btn-info glyphicon glyphicon-edit' data-tooltip='tooltip' title='Edit File' href='$script?do=edit&p=$FORM{p}&f=$file$extra\#new'></a>$act</td>";
			} else {
				print "<td>&nbsp;</td>";
			}
			print "<td nowrap><a class='btn btn-danger glyphicon glyphicon-trash' data-tooltip='tooltip' title='Delete File' href='$script?do=del&p=$FORM{p}&f=$file$extra' onClick='return check(\"DELETE $file\")'></a>";
			print " <a class='btn btn-primary glyphicon glyphicon-wrench' data-tooltip='tooltip' title='Rename File' href='$script?do=r&p=$FORM{p}&f=$file$extra\#new'></a>";
			print " <a class='btn btn-success glyphicon glyphicon-copy' data-tooltip='tooltip' title='Copy File' href='$script?do=b&p=$FORM{p}&c=$FORM{p}/$file\#new'></a>";
			print " <a class='btn btn-warning glyphicon glyphicon-move' data-tooltip='tooltip' title='Move File' href='$script?do=b&p=$FORM{p}&m=$FORM{p}/$file\#new'></a></td>";
			print "</tr>\n";
		}
		if ($FORM{do} eq "newf") {
			print "<tr>";
			print "<form action='$script' method='post'>\n";
			print "<td>";
			print "<input type='hidden' name='do' value='cnewf'>\n";
			print "<input type='hidden' name='p' value='$FORM{p}'>\n";
			print "<input type='hidden' name='c' value='$FORM{c}'>\n";
			print "<input type='hidden' name='m' value='$FORM{m}'>\n";
			print "<input type='text' size='10' name='newf' value=''>\n";
			print "<input type='submit' class='btn btn-default' value='OK'>\n";
			print "<a name='new'></a></td>";
			print "</form>\n";
			print "<td>&nbsp;</td>";
			print "<td>&nbsp;</td>";
			print "<td>&nbsp;</td>";
			print "<td>&nbsp;</td>";
			print "<td colspan='2'>&nbsp;</td>";
			print "</tr>\n";
		}
		if (($FORM{do} eq "c") and (-f "$webpath$FORM{c}")) {
			my $newf = (split(/\//,$FORM{c}))[-1];
			print "<tr>";
			print "<form action='$script' method='post'>\n";
			print "<td>";
			print "<input type='hidden' name='do' value='copyit'>\n";
			print "<input type='hidden' name='p' value='$FORM{p}'>\n";
			print "<input type='hidden' name='c' value='$FORM{c}'>\n";
			print "<input type='hidden' name='m' value='$FORM{m}'>\n";
			print "<input type='text' size='10' name='newf' value='$newf'>\n";
			print "<input type='submit' class='btn btn-default' value='OK'>\n";
			print "<a name='new'></a></td>";
			print "</form>\n";
			print "<td>&nbsp;</td>";
			print "<td>&nbsp;</td>";
			print "<td>&nbsp;</td>";
			print "<td>&nbsp;</td>";
			print "<td colspan='2'>&nbsp;</td>";
			print "</tr>\n";
		}
		if (($FORM{do} eq "m") and (-f "$webpath$FORM{m}")) {
			my $newf = (split(/\//,$FORM{m}))[-1];
			print "<tr>";
			print "<form action='$script' method='post'>\n";
			print "<td>";
			print "<input type='hidden' name='do' value='moveit'>\n";
			print "<input type='hidden' name='p' value='$FORM{p}'>\n";
			print "<input type='hidden' name='c' value='$FORM{c}'>\n";
			print "<input type='hidden' name='m' value='$FORM{m}'>\n";
			print "<input type='text' size='10' name='newf' value='$newf'>\n";
			print "<input type='submit' class='btn btn-default' value='OK'>\n";
			print "<a name='new'></a></td>";
			print "</form>\n";
			print "<td>&nbsp;</td>";
			print "<td>&nbsp;</td>";
			print "<td>&nbsp;</td>";
			print "<td>&nbsp;</td>";
			print "<td colspan='2'>&nbsp;</td>";
			print "</tr>\n";
		}
	}
	print "</table>\n";

	print "<div class='bs-callout bs-callout-warning'>All the following actions apply to the current directory</div>\n";
	print "<form action='$script' method='post'>\n";
	print "<input type='hidden' name='p' value='$FORM{p}'>\n";
	print "<input type='hidden' name='c' value='$FORM{c}'>\n";
	print "<input type='hidden' name='m' value='$FORM{m}'>\n";
	print "<input type='hidden' name='do' value='search'>\n";
	print "<table class='table table-bordered table-striped table-condensed'>\n";
	print "<thead><tr><th colspan='2'>Search for filenames or directories</th></tr></thead>\n";
	print "<tr><td colspan='2'>";
	print "<input type='text' name='words' size='20'> <select name='type'>\n";
	print "<option value='and'>AND words</option>\n";
	print "<option value='or'>OR words</option>\n";
	print "<option value='match'>MATCH words</option></select>\n";
	print "<input type='submit' class='btn btn-default' value='Search'></td></tr>\n";
	print "</table>\n";
	print "</form>\n";
	print "<table class='table table-bordered table-striped table-condensed'>\n";
	print "<thead><tr><th colspan='2'>Create New...</th></tr></thead>\n";
	print "<tr><td><a class='btn btn-default' href='$script?do=newd&p=$FORM{p}$extra\#new'>Create New Directory</a></td>\n<td><a class='btn btn-default' href='$script?do=newf&p=$FORM{p}$extra\#new'>Create Empty File</a></td></tr>\n";
	print "</table>\n";
	print "<form action='$script' method='post' enctype='multipart/form-data'>\n";
	print "<input type='hidden' name='p' value='$FORM{p}'>\n";
	print "<input type='hidden' name='c' value='$FORM{c}'>\n";
	print "<input type='hidden' name='m' value='$FORM{m}'>\n";
	print "<table class='table table-bordered table-striped table-condensed'>\n";
	print "<thead><tr><th colspan='2'>Upload Files...</th></tr></thead>\n";
	print "<tr><td colspan='2'><input type='file' class='btn btn-default' size='15' name='file0'><br>\n";
	print "<tr><td colspan='2'>Mode: <label><input type='radio' name='type' value='ascii'><code>Ascii</code></label> <label><input type='radio' name='type' value='binary' checked><code>Binary</code></label> <input type='submit' class='btn btn-default' value='Upload'></td></tr>\n";
	print "</table>\n";
	print "</form>\n";
	print "<form action='$script' method='post'>\n";
	print "<input type='hidden' name='p' value='$FORM{p}'>\n";
	print "<input type='hidden' name='c' value='$FORM{c}'>\n";
	print "<input type='hidden' name='m' value='$FORM{m}'>\n";
	print "<input type='hidden' name='do' value='cd'>\n";
	print "<table class='table table-bordered table-striped table-condensed'>\n";
	print "<thead><tr><th colspan='2'>Change Directory...</th></tr></thead>\n";
	print "<tr><td colspan='2'>";
	print "<input type='text' name='directory' value='$thisdir' size='40'>\n";
	print " <input type='submit' class='btn btn-default' value='Change Directory'></td></tr>\n";
	print "</table><br>\n";
	print "</form>\n";

	print "<form action='$script' method='post' target='WHMConsole'>\n";
	print "<input type='hidden' name='p' value='$FORM{p}'>\n";
	print "<input type='hidden' name='c' value='$FORM{c}'>\n";
	print "<input type='hidden' name='m' value='$FORM{m}'>\n";
	print "<input type='hidden' name='do' value='console'>\n";
	print "<table class='table table-bordered table-striped table-condensed'>\n";
	print "<thead><tr><th colspan='2'>Virtual Console <code>$thisdir</code></th></tr></thead>\n";
	print "<tr><td colspan='2'>";
	print "<iframe width='100%' height='500' name='WHMConsole' style='border: 1px black solid' border='0' frameborder='0' src='$script?do=console&cmd=ls%20-la&p=$FORM{p}'></iframe>\n";
	print "<p>Command: <input type='text' name='cmd' value='' size='50' onFocus='this.value=\"\"'>\n";
	print " <input type='submit' class='btn btn-default' value='Send'></p>\n";
	print "<div class='bs-callout bs-callout-info'>Note: You cannot change directory within the console. Use the <em>Change Directory</em> feature above.</div>\n";
	print "</td></tr>\n";
	print "</table>\n";
	print "</form>\n";
	return;
}
# end browse
###############################################################################
# start setp
sub setp {
	my $status = 0;
	chmod (oct("0$FORM{newp}"),"$webpath$FORM{p}/$FORM{f}") or $status = $!;
	if ($status) {$message = "Operation Failed - $status"} else {$message = ""}
	&browse;
	return;
}
# end setp
###############################################################################
# start seto
sub seto {
	my $status = "";
	my ($uid,$gid) = split (/\:/,$FORM{newo});
	if ($uid !~ /^\d/) {$uid = (getpwnam($uid))[2]}
	if ($gid !~ /^\d/) {$gid = (getgrnam($gid))[2]}
	if ($uid eq "") {$message .= "No such user<br>\n"}
	if ($gid eq "") {$message .= "No such group<br>\n"}

	if ($message eq "") {
		chown ($uid,$gid,"$webpath$FORM{p}/$FORM{f}") or $status = $!;
		if ($status) {$message = "Operation Failed - $status"} else {$message = ""}
	}
	&browse;
	return;
}
# end seto
###############################################################################
# start ren
sub ren {
	my $status = 0;
	rename ("$webpath$FORM{p}/$FORM{f}","$webpath$FORM{p}/$FORM{newf}") or $status = $!;
	if ($status) {$message = "Operation Failed - $status"} else {$message = ""}
	&browse;
	return;
}
# end ren
###############################################################################
# start moveit
sub moveit {
	if ("$webpath$FORM{m}" eq "$webpath$FORM{p}/$FORM{newf}") {
		$message = "Move Failed - Cannot overwrite original";
	}
	elsif ((-d "$webpath$FORM{m}") and ("$webpath$FORM{p}/$FORM{newf}" =~ /^$webpath$FORM{m}\//)) {
		$message = "Move Failed - Cannot move inside original";
	}
	else {
		my $status = 0;
		rename ("$webpath$FORM{m}","$webpath$FORM{p}/$FORM{newf}") or $status = $!;
		if ($status) {$message = "Operation Failed - $status"} else {$message = ""}
	}
	if ($message eq "") {$FORM{m} = ""}
	&browse;
	return;
}
# end moveit
###############################################################################
# start copyit
sub copyit {
	if ("$webpath$FORM{c}" eq "$webpath$FORM{p}/$FORM{newf}") {
		$message = "Copy Failed - Cannot overwrite original";
	}
	elsif ((-d "$webpath$FORM{c}") and ("$webpath$FORM{p}/$FORM{newf}" =~ /^$webpath$FORM{c}\//)) {
		$message = "Copy Failed - Cannot copy inside original";
	}
	else {
		if (-d "$webpath$FORM{c}") {
			$origpath = "$webpath$FORM{c}";
			$destpath = "$webpath$FORM{p}/$FORM{newf}";
			find(\&mycopy, $origpath);
		} else {
			copy ("$webpath$FORM{c}","$webpath$FORM{p}/$FORM{newf}") or $message = "Copy Failed - $!";
			if ($message eq "") {
				my $mode = sprintf "%04o", (stat("$webpath$FORM{c}"))[2] & oct("00777");
				chmod (oct($mode),"$webpath$FORM{p}/$FORM{newf}") or $message = "Permission Change Failed - $!";
			}
		}
	}
	if ($message eq "") {$FORM{c} = ""}
	&browse;
	return;
}
# end copyit
###############################################################################
# start mycopy
sub mycopy {
	my $file  = $File::Find::name;
	(my $dest = $file) =~ s/^\Q$origpath/$destpath/;
	my $status = "";
	if (-d $file) {
		my $err = (split(/\//,$dest))[-1];
		mkpath ($dest) or $status = "Copy Failed Making New Dir [$err] - $!<br>\n";
	} elsif (-f $file) {
		my $err = (split(/\//,$file))[-1];
		copy ($file,$dest) or $status = "Copy Failed [$err] - $!<br>\n";
	}
	if ($status eq "") {
		my $err = (split(/\//,$file))[-1];
		my $mode = sprintf "%04o", (stat("$file"))[2] & oct("00777");
		chmod (oct($mode),"$dest") or $message .= "Copy Failed Setting Perms [$err] - $!<br>\n";
	} else {
		$message .= $status;
	}
	return;
}
# end mycopy
###############################################################################
# start cnewd
sub cnewd {
	my $status = 0;
	if ($FORM{newf} ne "") {
		mkdir ("$webpath$FORM{p}/$FORM{newf}",0777) or $status = $!;
	}
	if ($status) {$message = "Operation Failed - $status"} else {$message = ""}
	&browse;
	return;
}
# end cnewd
###############################################################################
# start cnewf
sub cnewf {
	my $status = 0;
	if ($FORM{newf} ne "") {
		if (-f "$webpath$FORM{p}/$FORM{newf}") {
			$status = "File exists";
		} else {
			open (my $OUT, ">","$webpath$FORM{p}/$FORM{newf}") or $status = $!;
			flock ($OUT, LOCK_EX);
			close ($OUT);
		}
	}
	if ($status) {$message = "Operation Failed - $status"} else {$message = ""}
	&browse;
	return;
}
# end cnewf
###############################################################################
# start del
sub del {
	my $status = 0;
	if (-d "$webpath$FORM{p}/$FORM{f}") {
		rmtree("$webpath$FORM{p}/$FORM{f}", 0, 0) or $status = $!;
	} else {
		unlink ("$webpath$FORM{p}/$FORM{f}") or $status = $!;
	}
	if ($status) {$message = "Operation Failed - $status"} else {$message = ""}
	&browse;
	return;
}
# end del
###############################################################################
# start view
sub view {
	if (-e "$webpath$FORM{p}/$FORM{f}" ) {
		if (-T "$webpath$FORM{p}/$FORM{f}") {
			print "content-type: text/plain\r\n";
		} else {
			print "content-type: application/octet-stream\r\n";
		}
		print "content-disposition: attachment; filename=$FORM{f}\r\n\r\n";

		open(my $IN,"<","$webpath$FORM{p}/$FORM{f}") or die $!;
		flock ($IN, LOCK_SH);
		while (<$IN>) {print}
		close($IN);
	}else{
		print "content-type: text/html\r\n\r\n";
		print "File [$webpath$FORM{p}/$FORM{f}] not found!";
	}
	return;
}
# end view
###############################################################################
# start console
sub console {
	my $thisdir = "$webpath$FORM{p}";
	$thisdir =~ s/\/+/\//g;

	print "<p><pre style='white-space:pre-wrap;'>\n";
	print "root [$thisdir]# $FORM{cmd}\n";
	chdir $thisdir;

	$| = 1;
	my ($childin, $childout);
	my $cmdpid = open3($childin, $childout, $childout, $FORM{cmd});
	while (my $line = <$childout>) {
		$line =~ s/\</\&lt\;/g;
		$line =~ s/\>/\&gt\;/g;
		print $line;
	}
	waitpid ($cmdpid, 0);
	print "root [$thisdir]# _</pre></p>\n";
	print "<script>window.scrollTo(0,10000000);</script>";
	return;
}
# end console
###############################################################################
# start cd
sub cd {
	if (-d $FORM{directory}) {
		$FORM{p} = $FORM{directory};
	} else {
		$message = "No such directory [$FORM{directory}]";
	}

	&browse;
	return;
}
# end cd
###############################################################################
# start edit
sub edit {
	open (my $IN, "<","$webpath$FORM{p}/$FORM{f}") or die $!;
	flock ($IN, LOCK_SH);
	my @data = <$IN>;
	close ($IN);

	my $filedata;
	foreach my $line (@data) {
		$line =~ s/\</&lt;/g;
		$line =~ s/\>/&gt;/g;
		$filedata .= $line;
	}

	my $lf = 0;
	if ($filedata =~ /\r/) {$lf = 1}

	print "<script language='javascript'>\n";
	print "	function check(file) {return confirm('Click OK to '+file)}\n";
	print "</script>\n";
	print "<form action='$script' method='post'>\n";
	print "<table class='table table-bordered table-striped'>\n";
	print "<tr><td align='center'>";
	print "<input type='hidden' name='p' value='$FORM{p}'>\n";
	print "<input type='hidden' name='f' value='$FORM{f}'>\n";
	print "<input type='hidden' name='lf' value='$lf'>\n";
	print "<textarea cols='100' rows='25' name='newf' style='width:100%'>$filedata</textarea>\n";
	print "</td></tr>\n";
	print "<tr><td align='center'>";
	print "<input type='submit' class='btn btn-default' name='do' value='Save'> \n";
	print "<input type='submit' class='btn btn-default' name='do' value='Cancel'>\n";
	print "</td>";
	print "</table>\n";
	print "</form>\n";
	return;
}
# end edit
###############################################################################
# start save
sub save {
	unless ($FORM{lf}) {$FORM{newf} =~ s/\r//g}
	my $status = 0;
	open (my $OUT, ">","$webpath$FORM{p}/$FORM{f}") or $status = $!;
	flock ($OUT, LOCK_EX);
	print $OUT $FORM{newf};
	close ($OUT);

	if ($status) {$message = "Operation Failed - $status"} else {$message = ""}
	&browse;
	return;
}
# end save
###############################################################################
# start uploadfile
sub uploadfile {
	my $crlf = "\r\n";
	my @data = split (/$crlf/,$fileinc);

	my $boundary = $data[0];

	$boundary =~ s/\"//g;
	$boundary =~ s/$crlf//g;

	my $start = 0;
	my $part_cnt=-1;
	undef @parts;
	my $fileno = 0;

	foreach my $line (@data) {
		if ($line =~ /^$boundary--/) {
			last;
		}
		if ($line =~ /^$boundary/) {
			$part_cnt++;
			$start = 1;
			next;
		}
		if ($start) { 
			$parts[$part_cnt] .= $line.$crlf;
		}
	}

	foreach my $part (@parts) {
		my @partdata = split(/$crlf/,$part);
		undef %header;
		my $body = "";
		my $dobody = 0;
		my $lastfieldname = "";

		foreach my $line (@partdata) {
			if (($line eq "") and !($dobody)) {
				$dobody = 1;
				next;
			}

			if ($dobody) {
				$body .= $line.$crlf;
			} else {
				if ($line =~ /^\s/) {
					$header{$lastfieldname} .= $line;
				} else {
					($fieldname, $value) = split (/\:\s/,$line,2);
					$fieldname = lc $fieldname;
					$fieldname =~ s/-/_/g;
					$header{$fieldname} = $value;
					$lastfieldname = $fieldname;
				}
			}
		}

		my @elements = split(/\;/,$header{content_disposition});
		foreach my $element (@elements) {
			$element =~ s/\s//g;
			$element =~ s/\"//g;
			($name,$value) = split(/\=/,$element);
			$FORM{$value} = $body;
			$ele{$name} = $value;
			$ele{$ele{name}} = $value;
			if ($value =~ /^file(.*)$/) {$files = $1}
		}
		
		my $filename = $ele{"file$files"};
		if ($filename ne "") {
			$fileno++;
			$filename =~ s/\"//g;
			$filename =~ s/\r//g;
			$filename =~ s/\n//g;
			@bits = split(/\\/,$filename);
			$filetemp=$bits[-1];
			@bits = split(/\//,$filetemp);
			$filetemp=$bits[-1];
			@bits = split(/\:/,$filetemp);
			$filetemp=$bits[-1];
			@bits = split(/\"/,$filetemp);
			$filename=$bits[0];
			push (@filenames, $filename);
			push (@filebodies, $body);
		}
	}

	$FORM{p} =~ s/\r//g;
	$FORM{p} =~ s/\n//g;
	$FORM{type} =~ s/\r//g;
	$FORM{type} =~ s/\n//g;
	$FORM{c} =~ s/\r//g;
	$FORM{c} =~ s/\n//g;
	$FORM{m} =~ s/\r//g;
	$FORM{m} =~ s/\n//g;
	$FORM{caller} =~ s/\r//g;
	$FORM{caller} =~ s/\n//g;

	for (my $x = 0;$x < @filenames ;$x++) {
		$filenames[$x] =~ s/\r//g;
		$filenames[$x] =~ s/\n//g;
		$filenames[$x] =~ s/^file-//g;
		$filenames[$x] = (split (/\\/,$filenames[$x]))[-1];
		$filenames[$x] = (split (/\//,$filenames[$x]))[-1];
		if ($FORM{type} eq "ascii") {$filebodies[$x] =~ s/\r//g}
		if (-e "$webpath$FORM{p}/$filenames[$x]") {
			$extramessage .= "<br>$filenames[$x] - Already exists, delete the original first";
			$fileno--;
			next;
		}
		sysopen (my $OUT,"$webpath$FORM{p}/$filenames[$x]", O_WRONLY | O_CREAT);
		flock ($OUT, LOCK_EX);
		print $OUT $filebodies[$x];
		close ($OUT);
		$extramessage .= "<br>$filenames[$x] - Uploaded";
	}

	$message = "$fileno File(s) Uploaded".$extramessage;

	&browse;
	return;
}
# end uploadfile
###############################################################################
# start countfiles
sub countfiles {
	if (-d $File::Find::name) {push (@dirs, $File::Find::name)} else {push (@files, $File::Find::name)}
	return;
}
# end countfiles
###############################################################################
# loadconfig
sub loadconfig {
	sysopen (my $IN, "/etc/csf/csf.conf", O_RDWR | O_CREAT) or die "Unable to open file: $!";
	flock ($IN, LOCK_SH);
	my @config = <$IN>;
	close ($IN);
	chomp @config;

	foreach my $line (@config) {
		if ($line =~ /^\#/) {next}
		if ($line !~ /=/) {next}
		my ($name,$value) = split (/=/,$line,2);
		$name =~ s/\s//g;
		if ($value =~ /\"(.*)\"/) {
			$value = $1;
		} else {
			&error(__LINE__,"Invalid configuration line");
		}
		$config{$name} = $value;
	}
	return;
}
# end loadconfig
###############################################################################

1;
