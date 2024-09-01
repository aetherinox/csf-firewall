###############################################################################
# Copyright 2006-2023, Way to the Web Limited
# URL: http://www.configserver.com
# Email: sales@waytotheweb.com
###############################################################################
## no critic (RequireUseWarnings, ProhibitExplicitReturnUndef, ProhibitMixedBooleanOperators, RequireBriefOpen)
# start main
package ConfigServer::Slurp;

use strict;
use lib '/usr/local/csf/lib';
use Fcntl qw(:DEFAULT :flock);
use Carp;

use Exporter qw(import);
our $VERSION     = 1.02;
our @ISA         = qw(Exporter);
our @EXPORT_OK   = qw(slurp);

our $slurpreg = qr/(?>\x0D\x0A?|[\x0A-\x0C\x85\x{2028}\x{2029}])/;
our $cleanreg = qr/(\r)|(\n)|(^\s+)|(\s+$)/;

# end main
###############################################################################
# start slurp
sub slurp {
	my $file = shift;
	if (-e $file) {
		sysopen (my $FILE, $file, O_RDONLY) or carp "*Error* Unable to open [$file]: $!";
		flock ($FILE, LOCK_SH) or carp "*Error* Unable to lock [$file]: $!";
		my $text = do {local $/; <$FILE>};
		close ($FILE);
		return split(/$slurpreg/,$text);
	} else {
		carp "*Error* File does not exist: [$file]";
	}

	return;
}
# end slurp
###############################################################################
# start slurpreg
sub slurpreg {
	return $slurpreg;
}
# end slurpreg
###############################################################################
# start cleanreg
sub cleanreg {
	return $cleanreg;
}
# end cleanreg
###############################################################################

1;