package Cpanel::Config::ConfigObj::Driver::ConfigServercsf::META;

use strict;

our $VERSION = 1.1;

#use parent qw(Cpanel::Config::ConfigObj::Interface::Config::Version::v1);
sub spec_version {
	return 1;
}

sub meta_version {
    return 1;
}

sub get_driver_name {
    return 'ConfigServercsf_driver';
}

sub content {
    my ($locale_handle) = @_;

    my $content = {
        'vendor' => 'Way to the Web Limited',
        'url'    => 'www.configserver.com',
        'name'   => {
            'short'  => 'ConfigServercsf Driver',
            'long'   => 'ConfigServercsf Driver',
            'driver' => get_driver_name(),
        },
        'since'    => 'cPanel 11.38.1',
        'abstract' => "A ConfigServercsf driver",
        'version'  => $VERSION,
    };

    if ($locale_handle) {
        $content->{'abstract'} = $locale_handle->maketext("ConfigServer csf driver");
    }

    return $content;
}

sub showcase {
    return;
}
1;
