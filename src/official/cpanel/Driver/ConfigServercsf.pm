package Cpanel::Config::ConfigObj::Driver::ConfigServercsf;

use strict;
use Cpanel::Config::ConfigObj::Driver::ConfigServercsf::META ();
*VERSION = \$Cpanel::Config::ConfigObj::Driver::ConfigServercsf::META::VERSION;

#use parent qw(Cpanel::Config::ConfigObj::Interface::Config::v1);
our @ISA = qw(Cpanel::Config::ConfigObj::Interface::Config::v1);    

sub init {
    my ( $class, $software_obj ) = @_;

    my $ConfigServercsf_defaults = {
        'thirdparty_ns' => "ConfigServercsf",
        'meta'          => {},
    };
    my $self = $class->SUPER::base( $ConfigServercsf_defaults, $software_obj );

    return $self;
}

sub enable {
    my ( $self, $input ) = @_;
    return 1;
}

sub disable {
    my ( $self, $input ) = @_;
    return 1;
}

sub info {
    my ($self)   = @_;
    my $meta_obj = $self->meta();
    my $abstract = $meta_obj->abstract();
    return $abstract;
}

sub acl_desc {
    return [
        {
            'acl'              => 'software-ConfigServer-csf',       #this should be "software-$key"
            'default_value'    => 0,
            'default_ui_value' => 0,                        # NOTE: this is for ui; first time setting reseller privs
            'name'             => 'ConfigServer Security & Firewall (Reseller UI)',
            'acl_subcat'       => 'Third Party Services',
        },
    ];
}

1;
