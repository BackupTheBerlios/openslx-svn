# Copyright (c) 2006, 2007 - OpenSLX GmbH
#
# This program is free software distributed under the GPL version 2.
# See http://openslx.org/COPYING
#
# If you have any feedback please consult http://openslx.org/feedback and
# send your suggestions, praise, or complaints to feedback@openslx.org
#
# General information about OpenSLX can be found at http://openslx.org/
# -----------------------------------------------------------------------------
# OSSetup/Distro/Suse.pm
#    - provides SUSE-specific overrides of the OSSetup Distro API.
# -----------------------------------------------------------------------------
package OpenSLX::OSSetup::Distro::Suse;

use strict;
use warnings;

use base qw(OpenSLX::OSSetup::Distro::Base);

use OpenSLX::Basics;

################################################################################
### interface methods
################################################################################
sub new
{
    my $class = shift;
    my $self = {};
    return bless $self, $class;
}

sub initialize
{
    my $self   = shift;
    my $engine = shift;

    $self->SUPER::initialize($engine);
    $self->{'packager-type'}      = 'rpm';
    $self->{'meta-packager-type'} = $ENV{SLX_META_PACKAGER} || 'smart';

    if ($engine->{'action-type'} eq 'install') {
        # Inform SUSE RPMs that we're performing an installation - this is
        # only important for installations taking place in stage 1c:
        $ENV{YAST_IS_RUNNING} = "instsys";
    }

    return;
}

sub fixPrerequiredFiles
{
    my $self       = shift;
    my $stage1cDir = shift;

    chown(
        0, 0, "$stage1cDir/etc/group", "$stage1cDir/etc/passwd",
        "$stage1cDir/etc/shadow"
    );    
    return;
}

sub updateDistroConfig
{
    my $self = shift;

    # invoke SuSEconfig in order to allow it to update the configuration:
    if (slxsystem('SuSEconfig')) {
        die _tr("unable to run SuSEconfig (%s)", $!);
    }
    $self->SUPER::updateDistroConfig();
    return;
}

sub hashPassword
{
    my $self = shift;
    my $password = shift;
    
    my $busyboxBin = $self->{engine}->{'busybox-binary'};
    my $hashedPassword = qx{$busyboxBin cryptpw -a blowfish '$password'};
    chomp $hashedPassword;

    return $hashedPassword;
}

1;
