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
# ScopedResource.pm
#    - a helper class that releases resources if the object leaves scope
# -----------------------------------------------------------------------------
package OpenSLX::ScopedResource;

use strict;
use warnings;

our $VERSION = 1.01;        # API-version . implementation-version

# make sure that we catch any signals in order to properly released scoped
# resources
use sigtrap qw( die normal-signals error-signals );

use OpenSLX::Basics;

sub new
{
    my $class = shift;
    my $params = shift;
    
    checkParams($params, {
        name    => '!',
        acquire => '!',
        release => '!',
    });

    my $self = {
        name    => $params->{name},
        owner   => 0,
        acquire => $params->{acquire},
        release => $params->{release},
    };
    
    bless $self, $class;
    
    $self->acquire();
    
    return $self;
}

sub acquire
{
    my $self = shift;

    # acquire the resource and set ourselves as owner
    if ($self->{acquire}->()) {
        vlog(1, "process $$ acquired resource $self->{name}");
        $self->{owner} = $$;
    }
}

sub release
{
    my $self = shift;

    # only release the resource if invoked by the owning process
    vlog(3, "process $$ tries to release resource $self->{name}");
    return if $self->{owner} != $$;
    
    # release the resource and unset owner
    if ($self->{release}->()) {
        vlog(1, "process $$ released resource $self->{name}");
        $self->{owner} = 0;
    }
}

sub DESTROY
{
    my $self = shift;
    
    $self->release();
    
    # remove references to functions, in order to release any closures
    $self->{acquire} = undef;
    $self->{release} = undef;
    
    return;
}

1;
