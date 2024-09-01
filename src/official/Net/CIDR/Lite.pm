package Net::CIDR::Lite;

use strict;
use vars qw($VERSION);
use Carp qw(confess);

$VERSION = '0.21';

my %masks;
my @fields = qw(PACK UNPACK NBITS MASKS);

# Preloaded methods go here.

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = bless {}, $class;
    $self->add_any($_) for @_;
    $self;
}

sub add_any {
    my $self = shift;
    for (@_) {
        tr|/|| && do { $self->add($_); next };
        tr|-|| && do { $self->add_range($_); next };
        UNIVERSAL::isa($_, 'Net::CIDR::Lite') && do {
            $self->add_cidr($_); next
        };
        $self->add_ip($_), next;
    }
    $self;
}

sub add {
    my $self = shift;
    my ($ip, $mask) = split "/", shift;
    $self->_init($ip) || confess "Can't determine ip format" unless %$self;
    confess "Bad mask $mask"
        unless $mask =~ /^\d+$/ and $mask <= $self->{NBITS}-8;
    $mask += 8;
    my $start = $self->{PACK}->($ip) & $self->{MASKS}[$mask]
        or confess "Bad ip address: $ip";
    my $end = $self->_add_bit($start, $mask);
    ++$$self{RANGES}{$start} || delete $$self{RANGES}{$start};
    --$$self{RANGES}{$end}   || delete $$self{RANGES}{$end};
    $self;
}

sub clean {
    my $self = shift;
    return $self unless $self->{RANGES};
    my $ranges = $$self{RANGES};
    my $total;
    $$self{RANGES} = {
      map { $total ? ($total+=$$ranges{$_})? () : ($_=>-1)
                   : do { $total+=$$ranges{$_}; ($_=>1) }
          } sort keys %$ranges
    };
    $self;
}

sub list {
    my $self = shift;
    return unless $self->{NBITS};
    my $nbits = $$self{NBITS};
    my ($start, $total);
    my @results;
    for my $ip (sort keys %{$$self{RANGES}}) {
        $start = $ip unless $total;
        $total += $$self{RANGES}{$ip};
        unless ($total) {
            while ($start lt $ip) {
                my ($end, $bits);
                my $sbit = $nbits-1;
                # Find the position of the last 1 bit
                $sbit-- while !vec($start, $sbit^7, 1) and $sbit>0;
                for my $pos ($sbit+1..$nbits) {
                    $end = $self->_add_bit($start, $pos);
                    $bits = $pos-8, last if $end le $ip;
                }
                push @results, $self->{UNPACK}->($start) . "/$bits";
                $start = $end;
            }
        }
    }
    wantarray ? @results : \@results;
}

sub list_range {
    my $self = shift;
    my ($start, $total);
    my @results;
    for my $ip (sort keys %{$$self{RANGES}}) {
        $start = $ip unless $total;
        $total += $$self{RANGES}{$ip};
        unless ($total) {
            $ip = $self->_minus_one($ip);
            push @results,
                $self->{UNPACK}->($start) . "-" . $self->{UNPACK}->($ip);
        }
    }
    wantarray ? @results : \@results;
}

sub list_short_range {
    my $self = shift;
    
    my $start;
    my $total;
    my @results;
    
    for my $ip (sort keys %{$$self{RANGES}}) {
    	# we begin new range when $total is zero
        $start = $ip if not $total;
        
        # add to total (1 for start of the range or -1 for end of the range)
        $total += $$self{RANGES}{$ip};
        
        # in case of end of range
        if (not $total) {
        	while ($ip gt $start) {
	            $ip = $self->_minus_one($ip);
	            
	            # in case of single ip not a range
				if ($ip eq $start) {
	            	push @results,
	                	$self->{UNPACK}->($start);
	                next;					
				}
	            
	            # get the last ip octet number
	            my $to_octet = ( unpack('C5', $ip) )[4];

				# next ip end will be current end masked by c subnet mask 255.255.255.0 - /24
	            $ip = $ip & $self->{MASKS}[32];

	            # if the ip range is in the same c subnet
	            if ($ip eq ($start & $self->{MASKS}[32])) {
	            	push @results,
	                	$self->{UNPACK}->($start) . "-" . $to_octet;
	            }
	            # otherwise the range start is .0 (end of range masked by c subnet mask)
	            else {
	            	push @results,
	                	$self->{UNPACK}->($ip & $self->{MASKS}[32]) . "-" . $to_octet;	            	
	            }
	        };
        }
    }
    wantarray ? @results : \@results;
}

sub _init {
    my $self = shift;
    my $ip = shift;
    my ($nbits, $pack, $unpack);
    if (_pack_ipv4($ip)) {
        $nbits = 40;
        $pack = \&_pack_ipv4;
        $unpack = \&_unpack_ipv4;
    } elsif (_pack_ipv6($ip)) {
        $nbits = 136;
        $pack = \&_pack_ipv6;
        $unpack = \&_unpack_ipv6;
    } else {
        return;
    }
    $$self{PACK}  = $pack;
    $$self{UNPACK}  = $unpack;
    $$self{NBITS} = $nbits;
    $$self{MASKS} = $masks{$nbits} ||= [
      map { pack("B*", substr("1" x $_ . "0" x $nbits, 0, $nbits))
          } 0..$nbits
    ];
    $$self{RANGES} = {};
    $self;
}

sub _pack_ipv4 {
    my @nums = split /\./, shift(), -1;
    return unless @nums == 4;
    for (@nums) {
        return unless /^\d{1,3}$/ and $_ <= 255;
    }
    pack("CC*", 0, @nums);
}

sub _unpack_ipv4 {
    join(".", unpack("xC*", shift));
}

sub _pack_ipv6 {
    my $ip = shift;
    $ip =~ s/^::$/::0/;
    return if $ip =~ /^:/ and $ip !~ s/^::/:/;
    return if $ip =~ /:$/ and $ip !~ s/::$/:/;
    my @nums = split /:/, $ip, -1;
    return unless @nums <= 8;
    my ($empty, $ipv4, $str) = (0,'','');
    for (@nums) {
        return if $ipv4;
        $str .= "0" x (4-length) . $_, next if /^[a-fA-F\d]{1,4}$/;
        do { return if $empty++ }, $str .= "X", next if $_ eq '';
        next if $ipv4 = _pack_ipv4($_);
        return;
    }
    return if $ipv4 and @nums > 6;
    $str =~ s/X/"0" x (($ipv4 ? 25 : 33)-length($str))/e if $empty;
    pack("H*", "00" . $str).$ipv4;
}

sub _unpack_ipv6 {
    _compress_ipv6(join(":", unpack("xH*", shift) =~ /..../g)),
}

# Replace longest run of null blocks with a double colon
sub _compress_ipv6 {
    my $ip = shift;
    if (my @runs = $ip =~ /((?:(?:^|:)(?:0000))+:?)/g ) {
        my $max = $runs[0];
        for (@runs[1..$#runs]) {
            $max = $_ if length($max) < length;
        }
        $ip =~ s/$max/::/;
    }
    $ip =~ s/:0{1,3}/:/g;
    $ip;
}

# Add a single IP address
sub add_ip {
    my $self = shift;
    my $ip = shift;
    $self->_init($ip) || confess "Can't determine ip format" unless %$self;
    my $start = $self->{PACK}->($ip) or confess "Bad ip address: $ip";
    my $end = $self->_add_bit($start, $self->{NBITS});
    ++$$self{RANGES}{$start} || delete $$self{RANGES}{$start};
    --$$self{RANGES}{$end}   || delete $$self{RANGES}{$end};
    $self;
}

# Add a hyphenated range of IP addresses
sub add_range {
    my $self = shift;
    local $_ = shift;
    my ($ip_start, $ip_end, $crud) = split /\s*-\s*/;
    confess "Only one hyphen allowed in range" if defined $crud;
    $self->_init($ip_start) || confess "Can't determine ip format"
      unless %$self;
    my $start = $self->{PACK}->($ip_start)
      or confess "Bad ip address: $ip_start";
    my $end = $self->{PACK}->($ip_end)
      or confess "Bad ip address: $ip_end";
    confess "Start IP is greater than end IP" if $start gt $end;
    $end = $self->_add_bit($end, $$self{NBITS});
    ++$$self{RANGES}{$start} || delete $$self{RANGES}{$start};
    --$$self{RANGES}{$end}   || delete $$self{RANGES}{$end};
    $self;
}

# Add ranges from another Net::CIDR::Lite object
sub add_cidr {
    my $self = shift;
    my $cidr = shift;
    confess "Not a CIDR object" unless UNIVERSAL::isa($cidr, 'Net::CIDR::Lite');
    unless (%$self) {
        @$self{@fields} = @$cidr{@fields};
    }
    $$self{RANGES}{$_} += $$cidr{RANGES}{$_} for keys %{$$cidr{RANGES}};
    $self;
}

# Increment the ip address at the given bit position
# bit position is in range 1 to # of bits in ip
# where 1 is high order bit, # of bits is low order bit
sub _add_bit {
    my $self= shift;
    my $base= shift();
    my $bits= shift()-1;
    while (vec($base, $bits^7, 1)) {
        vec($base, $bits^7, 1) = 0;
        $bits--;
        return $base if  $bits < 0;
    }
    vec($base, $bits^7, 1) = 1;
    return $base;
}

# Subtract one from an ip address
sub _minus_one {
  my $self = shift;
  my $nbits = $self->{NBITS};
  my $ip = shift;
  $ip = ~$ip;
  $ip = $self->_add_bit($ip, $nbits);
  $ip = $self->_add_bit($ip, $nbits);
  $self->_add_bit(~$ip, $nbits);
}

sub find {
    my $self = shift;
    $self->prep_find unless $self->{FIND};
    return $self->bin_find(@_) unless @{$self->{FIND}} < $self->{PCT};
    return 0 unless $self->{PACK};
    my $this_ip = $self->{PACK}->(shift);
    my $ranges = $self->{RANGES};
    my $last = -1;
    for my $ip (@{$self->{FIND}}) {
        last if $this_ip lt $ip;
        $last = $ranges->{$ip};
    }
    $last > 0;
}

sub bin_find {
    my $self = shift;
    my $ip = $self->{PACK}->(shift);
    $self->prep_find unless $self->{FIND};
    my $find = $self->{FIND};
    my ($start, $end) = (0, $#$find);
    return unless $ip ge $find->[$start] and $ip lt $find->[$end];
    while ($end - $start > 0) {
        my $mid = int(($start+$end)/2);
        if ($start == $mid) {
            if ($find->[$end] eq $ip) {
                $start = $end;
            } else { $end = $start }
        } else {
            ($find->[$mid] lt $ip ? $start : $end) = $mid;
        }
    }
    $self->{RANGES}{$find->[$start]} > 0;
}

sub prep_find {
    my $self = shift;
    $self->clean;
    $self->{PCT} = shift || 20;
    my $aref = $self->{FIND} = [];
    push @$aref, $_ for sort keys %{$self->{RANGES}};
    $self;
}

sub spanner {
    Net::CIDR::Lite::Span->new(@_);
}

sub _ranges {
    sort keys %{shift->{RANGES}};
}

sub _packer { shift->{PACK} }
sub _unpacker { shift->{UNPACK} }

package Net::CIDR::Lite::Span;
use Carp qw(confess);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = bless {RANGES=>{}}, $class;
    $self->add(@_);
}

sub add {
    my $self = shift;
    my $ranges = $self->{RANGES};
    if (@_ && !$self->{PACK}) {
        my $cidr = $_[0];
        $cidr = Net::CIDR::Lite->new($cidr) unless ref($cidr);
        $self->{PACK} = $cidr->_packer;
        $self->{UNPACK} = $cidr->_unpacker;
    }
    while (@_) {
        my ($cidr, $label) = (shift, shift);
        $cidr = Net::CIDR::Lite->new($cidr) unless ref($cidr);
        $cidr->clean;
        for my $ip ($cidr->_ranges) {
            push @{$ranges->{$ip}}, $label;
        }
    }
    $self;
}

sub find {
    my $self = shift;
    my $pack   = $self->{PACK};
    my $unpack = $self->{UNPACK};
    my %results;
    my $in_range;
    $self->prep_find unless $self->{FIND};
    return {} unless @_;
    return { map { $_ => {} } @_ } unless @{$self->{FIND}};
    return $self->bin_find(@_) if @_/@{$self->{FIND}} < $self->{PCT};
    my @ips = sort map { $pack->($_) || confess "Bad IP: $_" } @_;
    my $last;
    for my $ip (@{$self->{FIND}}) {
        if ($ips[0] lt $ip) {
            $results{$unpack->(shift @ips)} = $self->_in_range($last)
              while @ips and $ips[0] lt $ip;
        }
        last unless @ips;
        $last = $ip;
    }
    if (@ips) {
        my $no_range = $self->_in_range({});
        $results{$unpack->(shift @ips)} = $no_range while @ips;
    }
    \%results;
}

sub bin_find {
    my $self = shift;
    return {} unless @_;
    $self->prep_find unless $self->{FIND};
    return { map { $_ => {} } @_ } unless @{$self->{FIND}};
    my $pack   = $self->{PACK};
    my $unpack = $self->{UNPACK};
    my $find   = $self->{FIND};
    my %results;
    for my $ip ( map { $pack->($_) || confess "Bad IP: $_" } @_) {
        my ($start, $end) = (0, $#$find);
        $results{$unpack->($ip)} = $self->_in_range, next
          unless $ip ge $find->[$start] and $ip lt $find->[$end];
        while ($start < $end) {
            my $mid = int(($start+$end)/2);
            if ($start == $mid) {
                if ($find->[$end] eq $ip) {
                    $start = $end;
                } else { $end = $start }
            } else {
                ($find->[$mid] lt $ip ? $start : $end) = $mid;
            }
        }
        $results{$unpack->($ip)} = $self->_in_range($find->[$start]);
    }
    \%results;
}

sub _in_range {
    my $self = shift;
    my $ip = shift || '';
    my $aref = $self->{PREPPED}{$ip} || [];
    my $key = join "|", sort @$aref;
    $self->{CACHE}{$key} ||= { map { $_ => 1 } @$aref };
}

sub prep_find {
    my $self = shift;
    my $pct = shift || 4;
    $self->{PCT} = $pct/100;
    $self->{FIND} = [ sort keys %{$self->{RANGES}} ];
    $self->{PREPPED} = {};
    $self->{CACHE} = {};
    my %cache;
    my %in_range;
    for my $ip (@{$self->{FIND}}) {
        my $keys = $self->{RANGES}{$ip};
        $_ = !$_ for @in_range{@$keys};
        my @keys = grep $in_range{$_}, keys %in_range;
        my $key_str = join "|", @keys;
        $self->{PREPPED}{$ip} = $cache{$key_str} ||= \@keys;
    }
    $self;
}

sub clean {
    my $self = shift;
    unless ($self->{PACK}) {
      my $ip = shift;
      my $cidr = Net::CIDR::Lite->new($ip);
      return $cidr->clean($ip);
    }
    my $ip = $self->{PACK}->(shift) || return;
    $self->{UNPACK}->($ip);
}

1;
__END__

=head1 NAME

Net::CIDR::Lite - Perl extension for merging IPv4 or IPv6 CIDR addresses

=head1 SYNOPSIS

  use Net::CIDR::Lite;

  my $cidr = Net::CIDR::Lite->new;
  $cidr->add($cidr_address);
  @cidr_list = $cidr->list;
  @ip_ranges = $cidr->list_range;

=head1 DESCRIPTION

Faster alternative to Net::CIDR when merging a large number
of CIDR address ranges. Works for IPv4 and IPv6 addresses.

=head1 METHODS

=over 4

=item new() 

 $cidr = Net::CIDR::Lite->new
 $cidr = Net::CIDR::Lite->new(@args)

Creates an object to represent a list of CIDR address ranges.
No particular format is set yet; once an add method is called
with a IPv4 or IPv6 format, only that format may be added for this
cidr object. Any arguments supplied are passed to add_any() (see below).

=item add()

 $cidr->add($cidr_address)

Adds a CIDR address range to the list.

=item add_range()

 $cidr->add_range($ip_range)

Adds a hyphenated IP address range to the list.

=item add_cidr()

 $cidr1->add_cidr($cidr2)

Adds address ranges from one object to another object.

=item add_ip()

 $cidr->add_ip($ip_address)

Adds a single IP address to the list.

=item add_any()

 $cidr->add_any($cidr_or_range_or_address);

Determines format of range or single ip address and calls add(),
add_range(), add_cidr(), or add_ip() as appropriate.

=item $cidr->clean()

 $cidr->clean;

If you are going to call the list method more than once on the
same data, then for optimal performance, you can call this to
purge null nodes in overlapping ranges from the list. Boundary
nodes in contiguous ranges are automatically purged during add().
Only useful when ranges overlap or when contiguous ranges are added
out of order.

=item $cidr->list()

 @cidr_list = $cidr->list;
 $list_ref  = $cidr->list;

Returns a list of the merged CIDR addresses. Returns an array if called
in list context, an array reference if not.

=item $cidr->list_range()

 @cidr_list = $cidr->list_range;
 $list_ref  = $cidr->list_range;

Returns a list of the merged addresses, but in hyphenated range
format. Returns an array if called in list context, an array reference
if not.

=item $cidr->list_short_range()

 @cidr_list = $cidr->list_short_range;
 $list_ref  = $cidr->list_short_range;

Returns a list of the C subnet merged addresses, in short hyphenated range
format. Returns an array if called in list context, an array reference
if not.

Example:

	1.1.1.1-2
	1.1.1.5-7
	1.1.1.254-255
	1.1.2.0-2
	1.1.3.5
	1.1.3.7

=item $cidr->find()

 $found = $cidr->find($ip);

Returns true if the ip address is found in the CIDR range. False if not.
Not extremely efficient, is O(n*log(n)) to sort the ranges in the
cidr object O(n) to search through the ranges in the cidr object.
The sort is cached on the first call and used in subsequent calls,
but if more addresses are added to the cidr object, prep_find() must
be called on the cidr object.

=item $cidr->bin_find()

Same as find(), but forces a binary search. See also prep_find.

=item $cidr->prep_find()

 $cidr->prep_find($num);

Caches the result of sorting the ip addresses. Implicitly called on the first
find call, but must be explicitly called if more addresses are added to
the cidr object. find() will do a binary search if the number of ranges is
greater than or equal to $num (default 20);

=item $cidr->spanner()

 $spanner = $cidr1->spanner($label1, $cidr2, $label2, ...);

Creates a spanner object to find out if multiple ip addresses are within
multiple labeled address ranges. May also be called as (with or without
any arguments):

 Net::CIDR::Lite::Span->new($cidr1, $label1, $cidr2, $label2, ...);

=item $spanner->add()

 $spanner->add($cidr1, $label1, $cidr2, $label2,...);

Adds labeled address ranges to the spanner object. The 'address range' may
be a Net::CIDR::Lite object, a single CIDR address range, a single
hyphenated IP address range, or a single IP address.

=item $spanner->find()

 $href = $spanner->find(@ip_addresses);

Look up which range(s) ip addresses are in, and return a lookup table
of the results, with the keys being the ip addresses, and the value a
hash reference of which address ranges the ip address is in.

=item $spanner->bin_find()

Same as find(), but forces a binary search. See also prep_find.

=item $spanner->prep_find()

 $spanner->prep_find($num);

Called implicitly the first time $spanner->find(..) is called, must be called
again if more cidr objects are added to the spanner object. Will do a
binary search if ratio of the number of ip addresses to the number of ranges
is less than $num percent (default 4).

=item $spanner->clean()

 $clean_address = $spanner->clean($ip_address);

Validates and returns a cleaned up version of an ip address (which is
what you will find as the key in the result from the $spanner->find(..),
not necessarily what the original argument looked like). E.g. removes
unnecessary leading zeros, removes null blocks from IPv6
addresses, etc.

=back

=head1 CAVEATS

Garbage in/garbage out. This module does do validation, but maybe
not enough to suit your needs.

=head1 AUTHOR

Douglas Wilson, E<lt>dougw@cpan.orgE<gt>
w/numerous hints and ideas borrowed from Tye McQueen.

=head1 COPYRIGHT

 This module is free software; you can redistribute it and/or
 modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Net::CIDR>.

=cut
