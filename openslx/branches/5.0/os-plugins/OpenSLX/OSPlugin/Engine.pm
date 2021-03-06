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

use Config;
use File::Basename;
use File::Path;
use Storable;

use OpenSLX::Basics;
use OpenSLX::OSPlugin::Roster;
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
    vlog(2, "vendor-OS path is '$self->{'vendor-os-path'}'");

    if ($pluginName) {
        $self->{'plugin-name'} = $pluginName;
        $self->{'plugin-path'} 
            = "$openslxConfig{'base-path'}/lib/plugins/$pluginName";
        vlog(1, "plugin path is '$self->{'plugin-path'}'");

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
        $self->{'chrooted-openslx-base-path'}   = '/mnt/opt/openslx';
        $self->{'chrooted-openslx-config-path'} = '/mnt/etc/opt/openslx';

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

Invokes the plugin's installer method while chrooted into that vendor-OS.

=cut

sub installPlugin
{
    my $self = shift;
    
    $self->_checkIfRequiredPluginsAreInstalled();

    # look for unknown attributes
    my $attrs = $self->{'plugin-attrs'};
    my $attrInfos = $self->{plugin}->getAttrInfo();
    my @unknownAttrs = grep { !exists $attrInfos->{$_} } keys %$attrs;
    if (@unknownAttrs) {
        die _tr(
            "The plugin '%s' does not support these attributes:\n\t%s",
            $self->{'plugin-name'}, join(',', @unknownAttrs)
        );
    }

    # check all attr-values against the regex of the attribute (if any)
    my @attrProblems;
    foreach my $attr (keys %$attrs) {
        my $value = $attrs->{$attr};
        next if !defined $value;
        my $attrInfo = $attrInfos->{$attr};
        my $regex = $attrInfo->{content_regex};
        if ($regex && $value !~ $regex) {
            push @attrProblems, _tr(
                "the value '%s' for attribute %s is not allowed.\nAllowed values are: %s",
                $value, $attr, $attrInfo->{content_descr}
            );
        }
    }

    if (@attrProblems) {
        my $complaint = join "\n", @attrProblems;
        die $complaint;
    }

    if ($self->{'vendor-os-name'} ne '<<<default>>>') {

        # as the attrs may be changed by the plugin during installation, we
        # have to find a way to pass them back to this process (remember:
        # installation takes place in a forked process in order to do a chroot).
        # We simply serialize the attributes into a temp file and deserialize
        # it in the calling process.
        my $serializedAttrsFile 
            = "$self->{'plugin-temp-path'}/serialized-attrs";
        my $chrootedSerializedAttrsFile 
            = "$self->{'chrooted-plugin-temp-path'}/serialized-attrs";
    
        rmtree([ $self->{'plugin-repo-path'}, $self->{'plugin-temp-path'} ]);
        mkpath([ $self->{'plugin-repo-path'}, $self->{'plugin-temp-path'} ]);
    
        # invoke plugin and let it prepare the installation
        $self->{plugin}->preInstallationPhase( {
            'plugin-repo-path'    => $self->{'plugin-repo-path'},
            'plugin-temp-path'    => $self->{'plugin-temp-path'},
            'openslx-base-path'   => $openslxConfig{'base-path'},
            'openslx-config-path' => $openslxConfig{'config-path'},
            'plugin-attrs'        => $self->{'plugin-attrs'},
            'vendor-os-path'      => $self->{'vendor-os-path'},
        } );

        # HACK: do a dummy serialization here in order to get Storable 
        # completely loaded (otherwise it will complain in the chroot about 
        # missing modules).
        store $self->{'plugin-attrs'}, $serializedAttrsFile;
    
        $self->_callChrootedFunctionForPlugin(
            sub {
                # invoke plugin and let it install itself into vendor-OS
                $self->{plugin}->installationPhase( {
                    'plugin-repo-path' 
                        => $self->{'chrooted-plugin-repo-path'},
                    'plugin-temp-path' 
                        => $self->{'chrooted-plugin-temp-path'},
                    'openslx-base-path' 
                        => $self->{'chrooted-openslx-base-path'},
                    'openslx-config-path'
                        => $self->{'chrooted-openslx-config-path'},
                    'plugin-attrs'
                        => $self->{'plugin-attrs'},
                } );

                # serialize possibly changed attributes (executed inside chroot)
                store $self->{'plugin-attrs'}, $chrootedSerializedAttrsFile;
            }
        );

        # now retrieve (deserialize) the current attributes and store them
        $self->{'plugin-attrs'} = retrieve $serializedAttrsFile;

        # cleanup temp path
        rmtree([ $self->{'plugin-temp-path'} ]);

        # now update the vendorOS-attrs and let the plugin itself check the
        # stage3 attrs    
        $self->{'vendorOS-attrs'} = $self->{'plugin-attrs'};
        $self->checkStage3AttrValues(
            $self->{'plugin-attrs'}, \@attrProblems
        );
        if (@attrProblems) {
            my $complaint = join "\n", @attrProblems;
            die $complaint;
        }
    }

    $self->_addInstalledPluginToDB();

    return 1;
}

=item removePlugin()

Invokes the plugin's removal method while chrooted into that vendor-OS.

=cut

sub removePlugin
{
    my $self = shift;

    $self->_checkIfPluginIsRequiredByOthers();

    if ($self->{'vendor-os-name'} ne '<<<default>>>') {

        mkpath([ $self->{'plugin-repo-path'}, $self->{'plugin-temp-path'} ]);

        $self->_callChrootedFunctionForPlugin(
            sub {
                $self->{plugin}->removalPhase( {
                    'plugin-repo-path' 
                        => $self->{'chrooted-plugin-repo-path'},
                    'plugin-temp-path' 
                        => $self->{'chrooted-plugin-temp-path'},
                    'openslx-base-path' 
                        => $self->{'chrooted-openslx-base-path'},
                    'openslx-config-path'
                        => $self->{'chrooted-openslx-config-path'},
                    'plugin-attrs'
                        => $self->{'plugin-attrs'},
                } );
            }
        );

        # invoke plugin and let it prepare the installation
        $self->{plugin}->postRemovalPhase( {
            'plugin-repo-path'    => $self->{'plugin-repo-path'},
            'plugin-temp-path'    => $self->{'plugin-temp-path'},
            'openslx-base-path'   => $openslxConfig{'base-path'},
            'openslx-config-path' => $openslxConfig{'config-path'},
            'plugin-attrs'        => $self->{'plugin-attrs'},
            'vendor-os-path'      => $self->{'vendor-os-path'},
        } );

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
    my $vendorOSID = $self->_fetchVendorOSID($openslxDB);
    my @installedPlugins = $openslxDB->fetchInstalledPlugins($vendorOSID);
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

    return $self->_osSetupEngine()->distroName();
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

    my $busybox = $self->_osSetupEngine()->busyboxBinary();
    
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

    my $packager = $self->_osSetupEngine()->packager();
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

    return $self->_osSetupEngine()->getInstallablePackagesForSelection(
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

    my $metaPackager = $self->_osSetupEngine()->metaPackager();
    return if !$metaPackager;

    return $metaPackager->installPackages($packages, 1);
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

    my $metaPackager = $self->_osSetupEngine()->metaPackager();
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

This method gets also invoked whenever changes by slxconfig were made (passing
in only the stage3 attributes the user tried to change) and by the config 
demuxer (passing in all stage3 attributes for the system currently being 
demuxed).

If all values are ok, this method returns 1 - if not, it extends the given
problems array-ref with the problems that were found (and returns undef).

This method chroots into the vendor-OS and then asks the plugin itself to check
the attributes.

=cut

sub checkStage3AttrValues
{
    my $self        = shift;
    my $stage3Attrs = shift;
    my $problemsOut = shift;

    # we have to pass any problems back to this process (remember:
    # installation takes place in a forked process in order to do a chroot).
    # We simply serialize the problems into a temp file and deserialize
    # it in the calling process.
    my $serializedProblemsFile 
        = "$self->{'plugin-temp-path'}/serialized-problems";
    my $chrootedSerializedProblemsFile 
        = "$self->{'chrooted-plugin-temp-path'}/serialized-problems";

    mkpath([ $self->{'plugin-repo-path'}, $self->{'plugin-temp-path'} ]);

    # HACK: do a dummy serialization here in order to get Storable 
    # completely loaded (otherwise it will complain in the chroot about 
    # missing modules).
    store [], $serializedProblemsFile;
    
    $self->_callChrootedFunctionForPlugin(
        sub {
            # let plugin check by itself
            my $problems = $self->{plugin}->checkStage3AttrValues(
                $stage3Attrs, $self->{'vendorOS-attrs'}
            );

            # serialize list of problems (executed inside chroot)
            store($problems, $chrootedSerializedProblemsFile) if $problems;
        }
    );

    # now retrieve (deserialize) the found problems and pass them on
    my $problems = retrieve $serializedProblemsFile;
    rmtree([ $self->{'plugin-temp-path'} ]);
    if ($problems && ref($problems) eq 'ARRAY' && @$problems) {
        push @$problemsOut, @$problems;
        return;
    }

    return 1;
}

=back

=cut

sub _loadPlugin
{
    my $self = shift;
    
    my $pluginModule = "OpenSLX::OSPlugin::$self->{'plugin-name'}";
    my $plugin = instantiateClass(
        $pluginModule, { 
            acceptMissing => 1,
            pathToClass   => $self->{'plugin-path'},
        }
    );
    return if !$plugin;

    # if there's a distro folder, instantiate the most appropriate distro class
    my $distro;
    if ($self->{'vendor-os-name'} ne '<<<default>>>' 
    && -d "$self->{'plugin-path'}/OpenSLX/Distro") {
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

    # create os-setup engine here in order to block access to the vendor-OS
    # via other processes (which could cause problems)
    my $osSetupEngine = $self->_osSetupEngine();
    
    my @bindmounts;
    my @chrootPerlIncludes;
    
    # setup list of perl modules we want to bind into chroot
    push @chrootPerlIncludes, "/mnt/opt/openslx/lib";
    
    push @bindmounts, { 
        'source' => $Config{privlibexp}, 
        'target' => "$self->{'vendor-os-path'}/mnt/perl/privlibexp"
    };
    push @chrootPerlIncludes, "/mnt/perl/privlibexp";
    push @bindmounts, { 
        'source' => $Config{archlibexp}, 
        'target' => "$self->{'vendor-os-path'}/mnt/perl/archlibexp"
    };
    push @chrootPerlIncludes, "/mnt/perl/archlibexp";
    push @bindmounts, { 
        'source' => $Config{vendorlibexp}, 
        'target' => "$self->{'vendor-os-path'}/mnt/perl/vendorlibexp"
    };
    push @chrootPerlIncludes, "/mnt/perl/vendorlibexp";
    push @bindmounts, { 
        'source' => $Config{vendorarchexp}, 
        'target' => "$self->{'vendor-os-path'}/mnt/perl/vendorarchexp"
    };
    push @chrootPerlIncludes, "/mnt/perl/vendorarchexp";
    
    # prepare openslx bind mounts
    push @bindmounts, { 
        'source' => $openslxConfig{'base-path'}, 
        'target' => "$self->{'vendor-os-path'}/mnt/opt/openslx"
    };
    push @bindmounts, { 
        'source' => $openslxConfig{'config-path'}, 
        'target' => "$self->{'vendor-os-path'}/mnt/etc/opt/openslx"
    };
    
    # create mountpoints
    foreach (@bindmounts) {
    	mkpath($_->{'target'});
    }

    my $pluginSession = OpenSLX::ScopedResource->new({
        name    => 'osplugin::session',
        acquire => sub { 
            # bind mount perl includes, openslx base and config paths into vendor-OS
            foreach (@bindmounts) {
	            slxsystem("mount -o bind -o ro $_->{'source'} $_->{'target'}") == 0
	                or die _tr(
	                    "unable to bind mount '%s' to '%s'! (%s)", 
	                    $_->{'source'}, $_->{'target'}, $!
	                );
            }
            
            # add mounted perl includes to @INC
            foreach (@chrootPerlIncludes) {
            	unshift @INC, $_;
            }
            1 
        },
        release => sub {
        	# cleanup @INC again
            while (my $perlinc = pop(@chrootPerlIncludes)) {
	            if ($INC[0] eq $perlinc) {
	                shift @INC;
	            }
            }
            
            # unmount bindmounts
            foreach (@bindmounts) {
                slxsystem("umount $_->{'target'}") == 0
                    or die _tr(
                        "unable to umount '%s'! (%s)", 
                        $_->{'target'}, $!
                    );
            }
            1
        },
    });

    # now let plugin install itself into vendor-OS
    $osSetupEngine->callChrootedFunctionForVendorOS($function);
    
    return;
}

sub _addInstalledPluginToDB
{
    my $self = shift;
    
    my $openslxDB = instantiateClass("OpenSLX::ConfigDB");
    $openslxDB->connect();
    my $vendorOSID = $self->_fetchVendorOSID($openslxDB);
    $openslxDB->addInstalledPlugin(
        $vendorOSID, $self->{'plugin-name'}, $self->{'plugin-attrs'}
    );
    $openslxDB->disconnect();

    return 1;
}

sub _checkIfRequiredPluginsAreInstalled
{
    my $self = shift;
    
    my $requiredPlugins = $self->{plugin}->getInfo()->{required} || [];
    return 1 if !@$requiredPlugins;

    my $openslxDB = instantiateClass("OpenSLX::ConfigDB");
    $openslxDB->connect();
    my $vendorOSID = $self->_fetchVendorOSID($openslxDB);
    my @installedPlugins = $openslxDB->fetchInstalledPlugins($vendorOSID);
    $openslxDB->disconnect();
    
    my @missingPlugins 
        =   grep {
                my $required = $_;
                ! grep { $_->{plugin_name} eq $required } @installedPlugins;
            }
            @$requiredPlugins;

    if (@missingPlugins) {
        die _tr(
            'the plugin "%s" requires the following plugins to be installed first: "%s"!', 
            $self->{'plugin-name'}, join(',', @missingPlugins)
        );
    }        
    
    return 1;
}

sub _checkIfPluginIsRequiredByOthers
{
    my $self = shift;
    
    my $openslxDB = instantiateClass("OpenSLX::ConfigDB");
    $openslxDB->connect();
    my $vendorOSID = $self->_fetchVendorOSID($openslxDB);
    my @installedPlugins = $openslxDB->fetchInstalledPlugins($vendorOSID);
    $openslxDB->disconnect();
    
    my @lockingPlugins
        =   grep {
                my $installed 
                    = OpenSLX::OSPlugin::Roster->getPlugin($_->{plugin_name});
                my $requiredByInstalled 
                    = $installed
                        ? ($installed->getInfo()->{required} || [])
                        : [];
                grep { $_ eq $self->{'plugin-name'} } @$requiredByInstalled;
            }
            @installedPlugins;

    if (@lockingPlugins) {
        die _tr(
            'the plugin "%s" is required by the following plugins: "%s"!', 
            $self->{'plugin-name'}, 
            join(',', map { $_->{plugin_name} } @lockingPlugins)
        );
    }        
    
    return 1;
}

sub _fetchInstalledPluginAttrs
{
    my $self = shift;
    
    my $openslxDB = instantiateClass("OpenSLX::ConfigDB");
    $openslxDB->connect();
    my $vendorOSID = $self->_fetchVendorOSID($openslxDB);
    my $installedPlugin = $openslxDB->fetchInstalledPlugins(
        $vendorOSID, $self->{'plugin-name'}
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
    my $vendorOSID = $self->_fetchVendorOSID($openslxDB);
    $openslxDB->removeInstalledPlugin($vendorOSID, $self->{'plugin-name'});
    $openslxDB->disconnect();

    return 1;
}

sub _fetchVendorOSID
{
    my $self      = shift;
    my $openslxDB = shift;

    if ($self->{'vendor-os-name'} eq '<<<default>>>') {
        return 0;
    }

    my $vendorOS = $openslxDB->fetchVendorOSByFilter( { 
        name => $self->{'vendor-os-name'},
    } );
    if (!$vendorOS) {
        die _tr(
            'unable to find vendor-OS "%s" in DB!', $self->{'vendor-os-name'}
        );
    }

    return $vendorOS->{id};
}

sub _osSetupEngine
{
    my $self = shift;
    
    if (!$self->{'ossetup-engine'}) {
        # create ossetup-engine for given vendor-OS:
        my $osSetupEngine = OpenSLX::OSSetup::Engine->new;
        $osSetupEngine->initialize($self->{'vendor-os-name'}, 'plugin');
        $self->{'ossetup-engine'} = $osSetupEngine;
    }

    return $self->{'ossetup-engine'};
}

1;
