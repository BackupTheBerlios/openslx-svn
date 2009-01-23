# Copyright (c) 2008 - OpenSLX GmbH
#
# This program is free software distributed under the GPL version 2.
# See http://openslx.org/COPYING
#
# If you have any feedback please consult http://openslx.org/feedback and
# send your suggestions, praise, or complaints to feedback@openslx.org
#
# General information about OpenSLX can be found at http://openslx.org/
# -----------------------------------------------------------------------------
# BootEnvironment::Base.pm
#    - provides empty base of the BootEnvironment API.
# -----------------------------------------------------------------------------
package OpenSLX::BootEnvironment::Base;

use strict;
use warnings;

our $VERSION = 1.01;        # API-version . implementation-version

use OpenSLX::Basics;
use OpenSLX::ConfigDB;

sub new
{
    my $class  = shift;

    my $self = {};

    return bless $self, $class;
}

sub initialize
{
    my $self   = shift;
    my $params = shift;

    $self->{'build-path'} = $params->{'build-path'};
    $self->{'dry-run'}    = $params->{'dry-run'};

    return 1;
}

sub prepareBootloaderConfigFolder
{
    my $self = shift;

    return;
}

1;
