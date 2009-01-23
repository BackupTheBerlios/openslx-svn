# Copyright (c) 2007, 2008 - OpenSLX GmbH
#
# This program is free software distributed under the GPL version 2.
# See http://openslx.org/COPYING
#
# If you have any feedback please consult http://openslx.org/feedback and
# send your suggestions, praise, or complaints to feedback@openslx.org
#
# General information about OpenSLX can be found at http://openslx.org/
# -----------------------------------------------------------------------------
# Engine.pm
#    - provides driver engine for the OSPlugin API.
# -----------------------------------------------------------------------------
package OpenSLX::OSPlugin::Engine;

use strict;
use warnings;

our $VERSION = 1.01;    # API-version . implementation-version

use File::Basename;
use File::Path;
use Storable;

use OpenSLX::Basics;
use OpenSLX::OSSetup::Engine;
use OpenSLX::ScopedResource;
use OpenSLX::Utils;

=head1 NAME

OpenSLX::OSPlugin::Engine - driver class for plugin handling.

=head1 DESCRIPTION

This class works as a driver for the installation/removal of plugins
into/from a vendor.

Additionally, it provides the OS-Plugin support interface.

=head1 PUBLIC METHODS

=over

=item new()

Trivial constructor

=cut

sub new
{
    my $class = shift;

    my $self = {};

    return bless $self, $class;
}

=item initialize($pluginName, $vendorOSName )

Sets up basic data (I<$pluginName> and I<$vendorOSName>) as well as paths and 
loads plugin.

=cut

sub initialize
{
    my $self         = shift;
    my $pluginName   = shift;
    my $vendorOSName = shift;
    my $givenAttrs   = shift || {};

    $self->{'vendor-os-name'} = $vendorOSName;

    $self->{'vendor-os-path'} 
        = "$openslxConfig{'private-path'}/stage1/$vendorOSName";
    vlog(1, "vendor-OS path is '$self->{'vendor-os-path'}'");

    if ($pluginName) {
        $self->{'plugin-name'} = $pluginName;
        $self->{'plugin-path'} 
            = "$openslxConfig{'base-path'}/lib/plugins/$pluginName";
        vlog(1, "plugin path is '$self->{'plugin-path'}'");

        # create ossetup-engine for given vendor-OS:
        my $osSetupEngine = OpenSLX::OSSetup::Engine->new;
        $osSetupEngine->initialize($self->{'vendor-os-name'}, 'plugin');
        $self->{'ossetup-engine'} = $osSetupEngine;

        $self->{'plugin'} = $self->_loadPlugin();
        return if !$self->{'plugin'};

        $self->{'chrooted-plugin-repo-path'}
            = "$openslxConfig{'base-path'}/plugin-repo/$self->{'plugin-name'}";
        $self->{'plugin-repo-path'}
            = "$self->{'vendor-os-path'}/$self->{'chrooted-plugin-repo-path'}";
        $self->{'chrooted-plugin-temp-path'}
            = "/tmp/slx-plugin/$self->{'plugin-name'}";
        $self->{'plugin-temp-path'}
            = "$self->{'vendor-os-path'}/$self->{'chrooted-plugin-temp-path'}";
        $self->{'chrooted-openslx-base-path'} = '/mnt/openslx';

        # check and store given attribute set
        my $knownAttrs = $self->{plugin}->getAttrInfo();
        my @unknownAttrs 
            = grep { !exists $knownAttrs->{$_} } keys %$givenAttrs;
        if (@unknownAttrs) {
            die _tr(
                "The plugin '%s' does not support these attributes:\n\t%s",
                $pluginName, join(',', @unknownAttrs)
            );
        }

        # merge attributes that were given on cmdline with the ones that
        # already exist in the DB and finally with the default values
        $self->{'plugin-attrs'} = { %$givenAttrs };
        my $defaultAttrs = $self->{plugin}->getDefaultAttrsForVendorOS(
            $vendorOSName
        );
        my $dbAttrs = $self->_fetchInstalledPluginAttrs($vendorOSName);
        for my $attrName (keys %$defaultAttrs) {
            next if exists $givenAttrs->{$attrName};
            $self->{'plugin-attrs'}->{$attrName}
                = exists $dbAttrs->{$attrName}
                    ? $dbAttrs->{$attrName}
                    : $defaultAttrs->{$attrName}->{default};
        }
        $self->{'vendorOS-attrs'} = $dbAttrs;
    }
    
    return 1;
}

=back

=head2 Driver Interface

The following methods are invoked by the slxos-plugin script in order to
install/remove a plugin into/from a vendor-OS:

=over

=item installPlugin()

Creates an ossetup-engine for the current vendor-OS and asks that to invoke
the plugin's installer method while chrooted into that vendor-OS.

=cut

sub installPlugin
{
    my $self = shift;

    if ($self->{'vendor-os-name'} ne '<<<default>>>') {

        # as the attrs may be changed by the plugin during installation, we
        # have to find a way to pass them back to this process (remember;
        # installation takes place in a forked process in order to do a chroot).
        # We simply serialize the attributes into a temp and deserialize it
        # in the calling process.
        my $serializedAttrsFile 
            = "$self->{'plugin-temp-path'}/serialized-attrs";
        my $chrootedSerializedAttrsFile 
            = "$self->{'chrooted-plugin-temp-path'}/serialized-attrs";
    
        mkpath([ $self->{'plugin-repo-path'}, $self->{'plugin-temp-path'} ]);
    
        # HACK: do a dummy serialization here in order to get Storable 
        # completely loaded (otherwise it will complain in the chroot about 
        # missing modules).
        store $self->{'plugin-attrs'}, $serializedAttrsFile;
    
        $self->_callChrootedFunctionForPlugin(
            sub {
                # invoke plugin and let it install itself into vendor-OS
                $self->{plugin}->installationPhase(
                    $self->{'chrooted-plugin-repo-path'}, 
                    $self->{'chrooted-plugin-temp-path'},
                    $self->{'chrooted-openslx-base-path'},
                    $self->{'plugin-attrs'},
                );

                # serialize possibly changed attributes (executed inside chroot)
                store $self->{'plugin-attrs'}, $chrootedSerializedAttrsFile;
            }
        );

        # now retrieve (deserialize) the current attributes and store them
        $self->{'plugin-attrs'} = retrieve $serializedAttrsFile;
        $self->_addInstalledPluginToDB();
    
        # cleanup temp path
        rmtree([ $self->{'plugin-temp-path'} ]);
    }
    
    return 1;
}

=item removePlugin()

Creates an ossetup-engine for the current vendor-OS and asks that to invoke
the plugin's removal method while chrooted into that vendor-OS.

=cut

sub removePlugin
{
    my $self = shift;

    if ($self->{'vendor-os-name'} ne '<<<default>>>') {

        mkpath([ $self->{'plugin-repo-path'}, $self->{'plugin-temp-path'} ]);

        $self->_callChrootedFunctionForPlugin(
            sub {
                $self->{plugin}->removalPhase(
                    $self->{'chrooted-plugin-repo-path'}, 
                    $self->{'chrooted-plugin-temp-path'},
                    $self->{'chrooted-openslx-base-path'},
                );
            }
        );

        rmtree([ $self->{'plugin-repo-path'}, $self->{'plugin-temp-path'} ]);
    }
    
    $self->_removeInstalledPluginFromDB();

    return 1;
}

=item getInstalledPlugins()

Returns the list of names of the plugins that are installed into the current
vendor-OS.

=cut

sub getInstalledPlugins
{
    my $self = shift;
    
    my $openslxDB = instantiateClass("OpenSLX::ConfigDB");
    $openslxDB->connect();
    my $vendorOS = $openslxDB->fetchVendorOSByFilter( { 
        name => $self->{'vendor-os-name'},
    } );
    if (!$vendorOS) {
        die _tr(
            'unable to find vendor-OS "%s" in DB!', $self->{'vendor-os-name'}
        );
    }
    my @installedPlugins = $openslxDB->fetchInstalledPlugins($vendorOS->{id});
    $openslxDB->disconnect();

    return @installedPlugins;
}

=back

=head2 Support Interface

This is the plugin support interface for OS-plugins, which represents the 
connection between a plugin's implementation and the rest of the OpenSLX system.

Plugin implementations are meant to use this interface in order to find
out details about the current vendor-OS or download files or install packages.

=over

=item vendorOSName()

Returns the name of the current vendor-OS.

=cut

sub vendorOSName
{
    my $self = shift;

    return $self->{'vendor-os-name'};
}

=item distroName()

Returns the name of the distro that the current vendor-OS is based on.

Each distro name always consists of the distro type, a dash and the
distro version, like 'suse-10.2' or 'ubuntu-7.04'.

=cut

sub distroName
{
    my $self = shift;

    return $self->{'ossetup-engine'}->distroName();
}

=item downloadFile($fileURL, $targetPath, $wgetOptions)

Invokes busybox's wget to download a file from the given URL.

=over

=item I<$fileURL>

The URL of the file to download.

=item I<$targetPath> [optional]

The directory where the file should be downloaded into. The default is the
current plugin's temp directory.

=item I<$wgetOptions> [optional]

Any other options you'd like to pass to wget.

=item I<Return Value>

If the downloaded was successful this method returns C<1>, otherwise it dies.

=back

=cut

sub downloadFile
{
    my $self        = shift;
    my $fileURL     = shift || return;
    my $targetPath  = shift || $self->{'chrooted-plugin-temp-path'};
    my $wgetOptions = shift || '';

    my $busybox = $self->{'ossetup-engine'}->busyboxBinary();
    
    if (slxsystem("$busybox wget -P $targetPath $wgetOptions $fileURL")) {
        die _tr('unable to download file "%s"! (%s)', $fileURL, $!);
    }

    return 1;
}

=item getInstalledPackages()

Returns the list of names of the packages (as an array) that are already 
installed in the vendor-OS. 
Useful if a plugin wants to find out whether or not it has to 
install additional packages.

=cut

sub getInstalledPackages
{
    my $self = shift;

    my $packager = $self->{'ossetup-engine'}->packager();
    return if !$packager;

    return $packager->getInstalledPackages();
}

=item getInstallablePackagesForSelection()

Looks at the selection with the given name and returns the list of names of the 
packages (as one string separated by spaces) that need to be installed in order 
to complete the selection.

=cut

sub getInstallablePackagesForSelection
{
    my $self      = shift;
    my $selection = shift;

    return $self->{'ossetup-engine'}->getInstallablePackagesForSelection(
        $selection
    );
}

=item installPackages($packages)

Installs the given packages into the vendor-OS.

N.B: Since this method uses the meta-packager of the vendor-OS, package 
dependencies will be determined and solved automatically.

=over

=item I<$packages>

Contains a list of package names (separated by spaces) that shall be installed.

=item I<Return Value>

If the packages have been installed successfully this method return 1,
otherwise it dies.

=back

=cut

sub installPackages
{
    my $self     = shift;
    my $packages = shift;

    return if !$packages;

    my $metaPackager = $self->{'ossetup-engine'}->metaPackager();
    return if !$metaPackager;

    return $metaPackager->installPackages($packages);
}

=item removePackages($packages)

Removes the given packages from the vendor-OS.

=over

=item I<$packages> [ARRAY-ref]

Contains a list of package names (separated by spaces) that shall be removed.

=item I<Return Value>

If the packages have been removed successfully this method return 1,
otherwise it dies.

=back

=cut

sub removePackages
{
    my $self     = shift;
    my $packages = shift;

    return if !$packages;

    my $metaPackager = $self->{'ossetup-engine'}->metaPackager();
    return if !$metaPackager;

    return $metaPackager->removePackages($packages);
}

=back

=head2 Driver Interface

The following methods are invoked by the slxos-plugin script in order to
install/remove a plugin into/from a vendor-OS:

=over

=item checkStage3AttrValues()

Checks if the stage3 values given in B<$stage3Attrs> are allowed and make sense.

If all values are ok, this method returns 1 - if not, it dies with an 
appropriate message.

This method chroots into the vendor-OS and then asks the plugin itself to check
the attributes.

=cut

sub checkStage3AttrValues
{
    my $self        = shift;
    my $stage3Attrs = shift;

    $self->_callChrootedFunctionForPlugin(
        sub {
            # let plugin check by itself
            $self->{plugin}->checkStage3AttrValues(
                $stage3Attrs, $self->{'vendorOS-attrs'}
            );
        }
    );

    return 1;
}

=back

=cut

sub _loadPlugin
{
    my $self = shift;
    
    my $pluginModule = "OpenSLX::OSPlugin::$self->{'plugin-name'}";
    my $plugin = instantiateClass(
        $pluginModule, { pathToClass => $self->{'plugin-path'} }
    );
    return if !$plugin;

    # if there's a distro folder, instantiate the most appropriate distro class
    my $distro;
    if (-d "$self->{'plugin-path'}/OpenSLX/Distro") {
        my $pluginBasePath = "$openslxConfig{'base-path'}/lib/plugins";
        my $distroScope = $plugin->{name} . '::OpenSLX::Distro';
        $distro = loadDistroModule({
            distroName  => $self->distroName(),
            distroScope => $distroScope,
            pathToClass => $pluginBasePath,
        });
        if (!$distro) {
            die _tr(
                'unable to load any distro module for vendor-OS %s in plugin %s',
                $self->{'vendor-os-name'}, $plugin->{name}
            );
        }
        $distro->initialize($self);
    }

    $plugin->initialize($self, $distro);

    return $plugin;
}

sub _callChrootedFunctionForPlugin
{
    my $self     = shift;
    my $function = shift;

    # bind-mount openslx basepath to /mnt/openslx of vendor-OS:
    my $basePath             = $openslxConfig{'base-path'};
    my $openslxPathInChroot = "$self->{'vendor-os-path'}/mnt/openslx";
    mkpath($openslxPathInChroot);

    my $pluginSession = OpenSLX::ScopedResource->new({
        name    => 'osplugin::session',
        acquire => sub { 
            # bind mount openslx base path into vendor-OS
            slxsystem("mount -o bind -o ro $basePath $openslxPathInChroot") == 0
                or die _tr(
                    "unable to bind mount '%s' to '%s'! (%s)", 
                    $basePath, $openslxPathInChroot, $!
                );
            1 
        },
        release => sub {
            slxsystem("umount $openslxPathInChroot") == 0
                or die _tr(
                    "unable to umount '%s'! (%s)", $openslxPathInChroot, $!
                );
            1
        },
    });

    # now let plugin install itself into vendor-OS
    $self->{'ossetup-engine'}->callChrootedFunctionForVendorOS($function);
    
    return;
}

sub _addInstalledPluginToDB
{
    my $self = shift;
    
    my $openslxDB = instantiateClass("OpenSLX::ConfigDB");
    $openslxDB->connect();
    my $vendorOS = $openslxDB->fetchVendorOSByFilter( { 
        name => $self->{'vendor-os-name'},
    } );
    if (!$vendorOS) {
        die _tr(
            'unable to find vendor-OS "%s" in DB!', $self->{'vendor-os-name'}
        );
    }
    $openslxDB->addInstalledPlugin(
        $vendorOS->{id}, $self->{'plugin-name'}, $self->{'plugin-attrs'}
    );
    $openslxDB->disconnect();

    return 1;
}

sub _fetchInstalledPluginAttrs
{
    my $self = shift;
    
    my $openslxDB = instantiateClass("OpenSLX::ConfigDB");
    $openslxDB->connect();
    my $vendorOS = $openslxDB->fetchVendorOSByFilter( { 
        name => $self->{'vendor-os-name'},
    } );
    if (!$vendorOS) {
        die _tr(
            'unable to find vendor-OS "%s" in DB!', $self->{'vendor-os-name'}
        );
    }
    my $installedPlugin = $openslxDB->fetchInstalledPlugins(
        $vendorOS->{id}, $self->{'plugin-name'}
    );
    $openslxDB->disconnect();

    return {} if !$installedPlugin;
    return $installedPlugin->{attrs};
}

sub _removeInstalledPluginFromDB
{
    my $self = shift;
    
    my $openslxDB = instantiateClass("OpenSLX::ConfigDB");
    $openslxDB->connect();
    my $vendorOS = $openslxDB->fetchVendorOSByFilter( { 
        name => $self->{'vendor-os-name'},
    } );
    if (!$vendorOS) {
        die _tr(
            'unable to find vendor-OS "%s" in DB!', $self->{'vendor-os-name'}
        );
    }
    $openslxDB->removeInstalledPlugin($vendorOS->{id}, $self->{'plugin-name'});
    $openslxDB->disconnect();

    return 1;
}

1;
