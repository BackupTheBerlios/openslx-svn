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
package OpenSLX::ConfigFolder;

use strict;
use warnings;

our (@ISA, @EXPORT, $VERSION);

use Exporter;
$VERSION = 1.01;
@ISA = qw(Exporter);

@EXPORT = qw(
    &createConfigFolderForDefaultSystem
    &createConfigFolderForSystem
);

=head1 NAME

OpenSLX::ConfigFolder - implements configuration folder related functionality 
for OpenSLX.

=head1 DESCRIPTION

This module exports functions that create configuration folders for specific
system, which will be used by the slxconfig-demuxer when building an initramfs
for each system.

=cut

use OpenSLX::Basics;
use OpenSLX::Utils;

=head1 PUBLIC FUNCTIONS

=over

=item B<createConfigFolderForDefaultSystem()>

Creates the configuration folder for the default system.

The resulting folder will be named C<default> and will be created
in the I<OpenSLX-private-path>C</config>-folder (usually 
C</var/opt/openslx/config>).

Within that folder, two subfolders, C<initramfs> and C<rootfs> will be created.

In the C<initramfs>-subfolder, two files will be created: C<preinit.local>
and C<postinit.local>, who are empty stub-scripts meant to be edited by the 
OpenSLX admin.

The functions returns 1 if any folder or file had to be created and 0 if all the
required folders & files already existed.

=cut

sub createConfigFolderForDefaultSystem
{
    my $result = 0;
    my $defaultConfigPath = "$openslxConfig{'private-path'}/config/default";
    if (!-e "$defaultConfigPath/initramfs") {
        slxsystem("mkdir -p $defaultConfigPath/initramfs");
        $result = 1;
    }
    if (!-e "$defaultConfigPath/rootfs") {
        slxsystem("mkdir -p $defaultConfigPath/rootfs");
        $result = 1;
    }

    # create default pre-/postinit scripts for us in initramfs:
    my $preInitFile = "$defaultConfigPath/initramfs/preinit.local";
    if (!-e $preInitFile) {
        my $preInit = unshiftHereDoc(<<'            END-of-HERE');
            #!/bin/sh
            #
            # This script allows the local admin to extend the
            # capabilities at the beginning of the initramfs (stage3).
            # The toolset is rather limited and you have to keep in mind 
            # that stage4 rootfs has the prefix '/mnt'.
            END-of-HERE
        spitFile($preInitFile, $preInit);
        slxsystem("chmod u+x $preInitFile");
        $result = 1;
    }

    my $postInitFile = "$defaultConfigPath/initramfs/postinit.local";
    if (!-e $postInitFile) {
        my $postInit = unshiftHereDoc(<<'            END-of-HERE');
            #!/bin/sh
            #
            # This script allows the local admin to extend the
            # capabilities at the end of the initramfs (stage3).
            # The toolset is rather limited and you have to keep in mind 
            # that stage4 rootfs has the prefix '/mnt'.
            # But you may use some special slx-functions available via
            # inclusion: '. /etc/functions' ...
            END-of-HERE
        spitFile($postInitFile, $postInit);
        slxsystem("chmod u+x $postInitFile");
        $result = 1;
    }
    return $result;
}

=item B<createConfigFolderForSystem($systemName)>

Creates the configuration folder for the system whose name has been given in
I<$systemName>.

The resulting folder will be named just like the system and will be created
in the I<OpenSLX-private-path>C</config>-folder (usually 
C</var/opt/openslx/config>).

In that folder, a single subfolder C<default> will be created (representing
the default setup for all clients of that system). Within that folder, two
subfolders, C<initramfs> and C<rootfs> will be created.

The functions returns 1 if any folder had to be created and 0 if all the
required folders already existed.

=cut

sub createConfigFolderForSystem
{
    my $systemName = shift || confess "need to pass in system-name!";

    my $result = 0;
    my $systemConfigPath 
        = "$openslxConfig{'private-path'}/config/$systemName/default";
    if (!-e "$systemConfigPath/initramfs") {
        slxsystem("mkdir -p $systemConfigPath/initramfs");
        $result = 1;
    }
    if (!-e "$systemConfigPath/rootfs") {
        slxsystem("mkdir -p $systemConfigPath/rootfs");
        $result = 1;
    }
    return $result;
}

=back

=cut

1;
