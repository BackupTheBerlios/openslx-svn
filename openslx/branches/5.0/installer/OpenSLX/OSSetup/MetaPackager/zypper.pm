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
# zypper.pm
#    - provides zypper-specific overrides of the OpenSLX::OSSetup::MetaPackager API.
# -----------------------------------------------------------------------------
package OpenSLX::OSSetup::MetaPackager::zypper;

use strict;
use warnings;

use base qw(OpenSLX::OSSetup::MetaPackager::Base);

use OpenSLX::Basics;
use OpenSLX::Utils;

################################################################################
### implementation
################################################################################
sub new
{
    my $class = shift;
    my $self = {
        'name' => 'zypper',
    };
    return bless $self, $class;
}

sub initPackageSources
{
    my $self = shift;

    $ENV{LC_ALL} = 'POSIX';

    # remove any existing channels
    slxsystem("rm -f /etc/zypp/repos.d/*");

    return 1;
}

sub setupPackageSource
{
    my $self        = shift;
    my $repoName    = shift;
    my $repoInfo    = shift;
    my $excludeList = shift;
    my $repoURLs    = shift;

    my $repoSubdir = '';
    if (length($repoInfo->{'repo-subdir'})) {
        $repoSubdir = "/$repoInfo->{'repo-subdir'}";
    }
    my $baseURL = shift @$repoURLs;
    if (slxsystem("zypper addrepo $baseURL$repoSubdir $repoName")) {
        die _tr("unable to add repo '%s' (%s)\n", $repoName, $!);
    }

    return 1;
}

sub installPackages
{
    my $self      = shift;
    my $packages  = shift;
    my $doRefresh = shift || 0;

    $packages =~ tr{\n}{ };

    if ($doRefresh && slxsystem("zypper --non-interactive refresh")) {
        die _tr("unable to update repo info (%s)\n", $!);
    }
    if (slxsystem("zypper --non-interactive install $packages")) {
        die _tr("unable to install selection (%s)\n", $!);
    }

    return 1;
}

sub removePackages
{
    my $self         = shift;
    my $pkgSelection = shift;

    if (slxsystem("zypper --non-interactive remove $pkgSelection")) {
        die _tr("unable to remove selection (%s)\n", $!);
    }

    return 1;
}

sub updateBasicVendorOS
{
    my $self = shift;

    if (slxsystem("zypper --non-interactive update")) {
        if ($! == 2) {
            # file not found => zypper isn't installed
            die _tr("unable to update this vendor-os, as it seems to lack an installation of zypper!\n");
        }
        die _tr("unable to update this vendor-os (%s)\n", $!);
    }

    return 1;
}

1;
