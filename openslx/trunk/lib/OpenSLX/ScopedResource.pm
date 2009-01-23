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
package OpenSLX::ScopedResource;

use strict;
use warnings;

our $VERSION = 1.01;        # API-version . implementation-version

=head1 NAME

OpenSLX::ScopedResource - provides a helper class that implements the 
'resource-acquisition-by-definition' pattern.

=head1 SYNOPSIS

{   # some scope

    my $distroSession = OpenSLX::ScopedResource->new({
        name    => 'distro::session',
        acquire => sub { $distro->startSession(); 1 },
        release => sub { $distro->finishSession(); 1 },
    });
    
    die $@ if ! eval {
        # do something dangerous and unpredictable here:
        doRandomStuff();
        1;
    };
        
} 
# the distro-session will be cleanly finished, no matter if we died or not

=head1 DESCRIPTION

The class C<ScopedResource> wraps any resource such that the resource will be
acquired when an object of this class is created. Whenever the ScopedResource
object is being destroyed (e.g. by leaving scope) the wrapped resource will
automatically be released.

The main purpose of this class is to make it simple to implement reliable 
resource acquisition and release management even if the structure of the code
that refers to that resource is rather complex. 

Furthermore, this class handles cases where the script handling those resources 
is spread across different process and/or makes us of signal handlers.

=cut

# make sure that we catch any signals in order to properly release scoped
# resources
use sigtrap qw( die normal-signals error-signals );

use OpenSLX::Basics;

=head1 PUBLIC METHODS

=over

=item B<new($params)>

Creates a ScopedResource object for the resource specified by the given 
I<$params>.

As part of creation of the object, the resource will be acquired.

The I<$params>-hashref requires the following entries:

=over

=item C<name>

Gives a name for the wrapped resource. This is just used in log messages
concerning the acquisition and release of that resource.

=item C<acuire>

Gives the code that is going to be executed in order to acquire the resource.

=item C<release>

Gives the code that is going to be executed in order to release the resource.

=back

=cut

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
    
    $self->_acquire();
    
    return $self;
}

=item B<DESTROY()>

Releases the resource (if it had been acquired by this process) and cleans up.

=cut

sub DESTROY
{
    my $self = shift;
    
    $self->_release();
    
    # remove references to functions, in order to release any closures
    $self->{acquire} = undef;
    $self->{release} = undef;
    
    return;
}

sub _acquire
{
    my $self = shift;

    # acquire the resource and set ourselves as owner
    if ($self->{acquire}->()) {
        vlog(1, "process $$ acquired resource $self->{name}");
        $self->{owner} = $$;
    }
}

sub _release
{
    my $self = shift;

    # ignore ctrl-c while we are trying to release the resource, as otherwise
    # the resource would be leaked
    local $SIG{INT} = 'IGNORE';

    # only release the resource if invoked by the owning process
    vlog(3, "process $$ tries to release resource $self->{name}");
    return if $self->{owner} != $$;
    
    # release the resource and unset owner
    if ($self->{release}->()) {
        vlog(1, "process $$ released resource $self->{name}");
        $self->{owner} = 0;
    }
}

=back

=cut

1;
