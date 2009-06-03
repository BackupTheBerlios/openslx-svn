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
# Base.pm
#    - provides empty base of the OpenSLX OSPlugin API.
# -----------------------------------------------------------------------------
package OpenSLX::OSPlugin::Base;

use strict;
use warnings;

our $VERSION = 1.01;        # API-version . implementation-version

=head1 NAME

OpenSLX::OSPlugin::Base - the base class for all OpenSLX OS-plugins.

=head1 DESCRIPTION

This class defines the OpenSLX API for OS-plugins.

The general idea behind OS-plugins is to extend any installed vendor-OS with
a specific features. Each feature is implemented as a separate, small software 
component in order to make them easy to understand and maintain. 

Since all of these software components are plugged into the OpenSLX system by 
means of a common API, we call them B<OS-plugin>s.

This API can be separated into different parts:

=over

=item - L</Declarative Interface> (provide info about a plugin)

=item - L</Vendor-OS Interface> (installing or removing a plugin into/from a 
vendor-OS)

=item - L</Initramfs Interface> (integrating a plugin into an initramfs)

=back

=head1 MORE INFO

Please read the user-level introduction on plugins in the OpenSLX-wiki:
L<http://openslx.org/trac/de/openslx/wiki/PluginKonzept> (in German).

If you'd like to know how a plugin is implemented, please have a look at the
'example' plugin, which contains some explainations and useful hints.

If you have any questions regarding the concept of OS-plugins and their
implementation, please drop a mail to: ot@openslx.com, or join the IRC-channel
'#openslx' (on freenode).

=cut

use OpenSLX::Basics;
use OpenSLX::OSPlugin::Roster;

=head1 PLUGIN API

=head2 Declarative Interface

=over

=item new()

Every plugin should provide a new-method and provide it's own name in the
'name' entry of $self. 

Please note that by convention, plugin names are all lowercase!

=cut

sub new
{
    confess "Creating OpenSLX::OSPlugin::Base-objects directly makes no sense!";
}

=item initialize()

Initializes basic context for this plugin (esp. a reference to the OSPlugin
engine that drives this plugin.

=cut

sub initialize
{
    my $self = shift;

    $self->{'os-plugin-engine'} = shift;
    $self->{'distro'}           = shift;
    
    return;
}

=item getInfo()

Returns a hash-ref with administrative information about this plugin (what does 
it do and how does it relate to other plugins). Every plugin needs to provide
this method and return the information about itself.

The returned hash-ref must include at least the following entries:

=over

=item B<description>

Explains the purpose of this plugins.

=item B<precedence>

Specifies the execution precedence of this plugin with respect to all other
plugins (plugins with lower precedences will be started before the ones with
a higher precedence).

Valid values range from 0-99. If your plugin does not have any requirements
in this context, just specify the default value '50'.

=item B<required>

Specifies the list of plugins that are required by this plugin.

Before any plugin can be installed, all other plugins that are required by it
must have been installed.

=back
    
=cut

sub getInfo
{
    my $self = shift;

    return {
        # a short (one-liner) description of this plugin
        description => '',
    };
}

=item getAttrInfo()

Returns a hash-ref with information about all attributes supported by this 
specific plugin. 

This default configuration will be added as attributes to the default system, 
such that it can be overruled for any specific system by means of B<slxconfig>.

The returned hash-ref must include at least the following entries:

=over

=item B<I<plugin-name>::active>

Indicates whether or not this plugin is active (1 for active, 0 for inactive).

=back

=cut

sub getAttrInfo
{
    my $self = shift;

    # This default configuration will be added as attributes to the default
    # system, such that it can be overruled for any specific system by means 
    # of slxconfig.
    return {
        # attribute 'active' is mandatory for all plugins
    };
}

=item getDefaultAttrsForVendorOS()

Returns a hash-ref with the default attribute values for the given vendor-OS.

=cut

sub getDefaultAttrsForVendorOS
{
    my $self = shift;

    # the default implementation does not change the default values at all:
    return $self->getAttrInfo();
}

=item checkStage3AttrValues()

Checks if the stage3 values given in B<$stage3Attrs> are allowed and make sense.

This method returns an array-ref of problems found. If there were no problems, 
this methods returns undef.

Plugins may override this implementation to do checks that for instance look
at the stage1 vendor-OS-attributes given in B<$vendorOSAttrs>.

N.B.: this method is called while being chrooted into the vendor-OS, so it
      may invoke all distro methods that expect to be run in this environment,
      too

=cut

sub checkStage3AttrValues
{
    my $self          = shift;
    my $stage3Attrs   = shift;
    my $vendorOSAttrs = shift;

    # this default implementation does no further checks (thus relying on the
    # attributte regex check that is done in the AttributeRoster)
    return;
}

=item dependsOnPlugin()

=cut

sub dependsOnPlugin
{
    my $self      = shift;
    my $otherName = shift;
    
    if (!defined $self->{dependsOn}) {
        my @dependsOn = $self->_determineAllPluginsWeDependOn();
        $self->{dependsOn} = \@dependsOn;
    }
    
    return grep { $_ eq $otherName } @{$self->{dependsOn}};
}

=back

=head2 Vendor-OS Interface

=over

=item installationPhase()

In this method, the plugin should install itself into the given vendor-OS.

What "installation" means is up to the plugin. Some plugins may just copy
a file from the OpenSLX host installation into the vendor-OS, while others may 
need to download files from the internet and/or install packages through the
vendor-OS' meta packager.

N.B.: This method is invoked while chrooted into the vendor-OS root.

The hash-ref given in B<$info> contains vital information for the installation
process:

=over

=item C<plugin-repo-path>

The folder where the stage1-plugin should store all files required by the 
corresponding stage3 runlevel script.

=item C<plugin-temp-path>

A temporary playground that will be cleaned up automatically.

=item C<openslx-base-path>

In order to make the OpenSLX files from the host available, the OpenSLX base 
folder (normally /opt/openslx) will be mounted into the chroot. 
So if you have to copy any files from the host, fetch them from this path.

=item C<openslx-config-path>

In order to make the OpenSLX config files from the host available, the OpenSLX 
config folder (normally /etc/opt/openslx) will be mounted into the chroot. 
So if you have to copy any config files from the host, fetch them from this 
path.

=item C<plugin-attrs>

Contains the attributes in effect for the installation of this plugin.

=back

=cut

sub installationPhase
{
    my $self = shift;
    my $info = shift;
    
    return;
}

=item removalPhase()

In this method, the plugin should remove itself from the given vendor-OS.

What "removal" means is up to the plugin. Some plugins may just delete
a file from the vendor-OS, while others may need to uninstall packages through 
the vendor-OS' meta packager.

N.B.: This method is invoked while chrooted into the vendor-OS root.

The hash-ref given in B<$info> contains vital information for the installation
process:

=over

=item C<plugin-repo-path>

The folder where the stage1-plugin should store all files required by the 
corresponding stage3 runlevel script.

=item C<plugin-temp-path>

A temporary playground that will be cleaned up automatically.

=item C<openslx-base-path>

In order to make the OpenSLX files from the host available, the OpenSLX base 
folder (normally /opt/openslx) will be mounted into the chroot. 
So if you have to copy any files from the host, fetch them from this path.

=item C<openslx-config-path>

In order to make the OpenSLX config files from the host available, the OpenSLX 
config folder (normally /etc/opt/openslx) will be mounted into the chroot. 
So if you have to copy any config files from the host, fetch them from this 
path.

=item C<plugin-attrs>

Contains the attributes in effect for the installation of this plugin.

=back

=cut

sub removalPhase
{
    my $self = shift;
    my $info = shift;
    
    return;
}

=item preInstallationPhase()

In this method, any preparations for installation of the plugin into a vendor-OS
should be executed. As this method is being called immediately before the chroot
is entered, this is the last/only chance to copy any files into the chroot that
are required from within (in installationPhase()).

The given parameters are similar to the ones for installationPhase(), except 
that all paths are now relative to the root-fs instead of being relative to the 
chroot (i.e. the paths are ready to be used from outside the chroot):

A "exit 1;" will result in a not installed plugin.

=over

=item C<plugin-repo-path>

The folder where the stage1-plugin should store all files required by the 
corresponding stage3 runlevel script.

=item C<plugin-temp-path>

A temporary playground that will be cleaned up automatically. 

If a plugin needs to unpack any archives, these archives should be copied to
this folder (as it will be cleaned automatically).

=item C<openslx-base-path>

In order to make the OpenSLX files from the host available, the OpenSLX base 
folder (normally /opt/openslx) will be mounted into the chroot. 
So if you have to copy any files from the host, fetch them from this path.

=item C<openslx-config-path>

In order to make the OpenSLX config files from the host available, the OpenSLX 
config folder (normally /etc/opt/openslx) will be mounted into the chroot. 
So if you have to copy any config files from the host, fetch them from this 
path.

=item C<plugin-attrs>

Contains the attributes in effect for the installation of this plugin.

=item C<vendor-os-path>

Contains the path to the vendor-OS into which the plugin will be installed.

=back

=cut

sub preInstallationPhase
{
    my $self = shift;
    my $info = shift;
    
    return;
}

=item postRemovalPhase()

In this method, any plugin has the chance to do any necessary cleanup that
must be executed outside of the chroot.

This method is invoked immediately after leaving the chroot into the vendor-OS 
root, but before the plugin-temp-path has been cleaned up. So if required, any
files could be copied out of the temp-path somewhere into the root-fs.

The given parameters are similar to the ones for removalPhase(), except that all
paths are now relative to the root-fs instead of being relative to the chroot
(i.e. the paths are ready to be used from outside the chroot):

=over

=item C<plugin-repo-path>

The folder where the stage1-plugin should store all files required by the 
corresponding stage3 runlevel script.

=item C<plugin-temp-path>

A temporary playground that will be cleaned up automatically.

=item C<openslx-base-path>

In order to make the OpenSLX files from the host available, the OpenSLX base 
folder (normally /opt/openslx) will be mounted into the chroot. 
So if you have to copy any files from the host, fetch them from this path.

=item C<openslx-config-path>

In order to make the OpenSLX config files from the host available, the OpenSLX 
config folder (normally /etc/opt/openslx) will be mounted into the chroot. 
So if you have to copy any config files from the host, fetch them from this 
path.

=item C<plugin-attrs>

Contains the attributes in effect for the installation of this plugin.

=item C<vendor-os-path>

Contains the path to the vendor-OS from which the plugin has been removed.

=back

=cut

sub postRemovalPhase
{
    my $self = shift;
    my $info = shift;
    
    return;
}

=back

=head2 Initramfs Interface

All of the following methods are invoked by the config demuxer when it makes an 
initramfs for a system that has this plugin activated. Through these methods,
each plugin can integrate itself into that initramfs.

=over

=item suggestAdditionalKernelParams()

Called in order to give the plugin a chance to add any kernel params it 
requires.

In order to do so, the plugin should return a list of additional kernel params 
that it would like to see added.

=cut

sub suggestAdditionalKernelParams
{
    my $self                = shift;
    my $makeInitRamFSEngine = shift;
    
    return;
}

=item suggestAdditionalKernelModules()

Called in order to give the plugin a chance to add any kernel modules it 
requires.

In order to do so, the plugin should return the names of additional kernel
modules that it would like to see added.
    
=cut

sub suggestAdditionalKernelModules
{
    my $self                = shift;
    my $makeInitRamFSEngine = shift;
    my $attrs               = shift;
    
    return;
}

=item copyRequiredFilesIntoInitramfs()

Called in order to give the plugin a chance to copy all required files from the 
vendor-OS into the initramfs.

N.B.: Only files that are indeed required by the initramfs should be copied 
here, i.e. files that are needed *before* the root-fs has been mounted. 
All other files should be taken from the root-fs instead!

=cut

sub copyRequiredFilesIntoInitramfs
{
    my $self                = shift;
    my $targetPath          = shift;
    my $attrs               = shift;
    my $makeInitRamFSEngine = shift;
    
    return;
}

=item setupPluginInInitramfs()

Called in order to let the plugin setup all the files it requires in the 
initramfs.

Normally, you don't need to override this method in your own plugin,
as it is usually enough to override suggestAdditionalKernelParams(),
suggestAdditionalKernelModules() and maybe copyRequiredFilesIntoInitramfs().

=cut

sub setupPluginInInitramfs
{
    my $self                = shift;
    my $attrs               = shift;
    my $makeInitRamFSEngine = shift;

    my $pluginName      = $self->{name};
    my $pluginSrcPath   = "$openslxConfig{'base-path'}/lib/plugins";
    my $buildPath       = $makeInitRamFSEngine->{'build-path'};
    my $pluginInitdPath = "$buildPath/etc/plugin-init.d";
    my $initHooksPath   = "$buildPath/etc/init-hooks";

    # copy runlevel script
    my $precedence = sprintf('%02d', $self->getInfo()->{precedence});
    my $scriptName = "$pluginSrcPath/$pluginName/XX_${pluginName}.sh";
    my $targetName = "$pluginInitdPath/${precedence}_${pluginName}.sh";
    if (-e $scriptName) {
        $makeInitRamFSEngine->addCMD("cp $scriptName $targetName");
        $makeInitRamFSEngine->addCMD("chmod a+x $targetName");
    }

    # copy init hook scripts, if any
    if (-d "$pluginSrcPath/$pluginName/init-hooks") {
        my $hookSrcPath = "$pluginSrcPath/$pluginName/init-hooks";
        $makeInitRamFSEngine->addCMD(
            "cp -r $hookSrcPath/* $buildPath/etc/init-hooks/"
        );
    }

    # invoke hook methods to suggest additional kernel params ...
    my @suggestedParams 
        = $self->suggestAdditionalKernelParams($makeInitRamFSEngine);
    if (@suggestedParams) {
        my $params = join ' ', @suggestedParams;
        vlog(1, "plugin $pluginName suggests these kernel params: $params");
        $makeInitRamFSEngine->addKernelParams(@suggestedParams);
    }

    # ... and kernel modules
    my @suggestedModules 
        = $self->suggestAdditionalKernelModules($makeInitRamFSEngine, $attrs);
    if (@suggestedModules) {
        my $modules = join(',', @suggestedModules);
        vlog(1, "plugin $pluginName suggests these kernel modules: $modules");
        $makeInitRamFSEngine->addKernelModules(@suggestedModules);
    }

    # invoke hook method to copy any further files that are required in stage3
    # before the root-fs has been mounted
    $self->copyRequiredFilesIntoInitramfs(
        $buildPath, $attrs, $makeInitRamFSEngine
    );

    return 1;
}

sub _determineAllPluginsWeDependOn
{
    my $self = shift;
    my $seen = shift || {};

    return if $seen->{$self->{name}};
    $seen->{$self->{name}} = 1;

    my %dependsOn;
    if ($self->getInfo()->{required}) {
        @dependsOn{@{$self->getInfo()->{required}}} = ();
    }

    foreach my $depName (keys %dependsOn) {
        my $depPlugin = OpenSLX::OSPlugin::Roster->getPlugin($depName);
        my @subDeps = $depPlugin->_determineAllPluginsWeDependOn($seen);
        @dependsOn{@subDeps} = ();
    }

    return keys %dependsOn;
}

=back

1;
