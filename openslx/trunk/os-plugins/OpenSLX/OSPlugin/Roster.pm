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
# OSPlugin::Roster.pm
#    - provides information about all available plugins
# -----------------------------------------------------------------------------
package OpenSLX::OSPlugin::Roster;

use strict;
use warnings;

use OpenSLX::Basics;
use Clone qw(clone);

my %plugins;

=item C<getAvailablePlugins()>

Returns a hash that keys the names of available plugins to their info hash.

=cut

sub getAvailablePlugins
{
    my $class = shift;

    $class->_init() if !%plugins;

    my %pluginInfo;
    foreach my $pluginName (keys %plugins) {
        $pluginInfo{$pluginName} = $plugins{$pluginName}->getInfo();
    }
    return \%pluginInfo;
}

=item C<getPlugin()>

Returns an instance of the plugin with the given name

=cut

sub getPlugin
{
    my $class      = shift;
    my $pluginName = shift;

    $class->_init() if !%plugins;

    my $plugin = $plugins{$pluginName};
    return if !$plugin;

    return clone($plugin);
}

=item C<getPluginAttrInfo()>

Returns a hash that contains info about the attributes support by the 
given plugin

=cut

sub getPluginAttrInfo
{
    my $class      = shift;
    my $pluginName = shift;

    $class->_init() if !%plugins;

    return if !$plugins{$pluginName};

    return $plugins{$pluginName}->getAttrInfo();
}

=item C<addAllAttributesToHash()>

Fetches attribute info from all available plugins and adds it to the given 
hash-ref.

If a plugin name has been given, only the attributes of that plugin will be
added.

=over

=item Return Value

1

=back

=cut

sub addAllAttributesToHash
{
    my $class      = shift;
    my $attrInfo   = shift;
    my $pluginName = shift;

    return $class->_addAttributesToHash($attrInfo, $pluginName, sub { 1 } );
}

=item C<addAllStage1AttributesToHash()>

Fetches attribute info relevant for stage1 (i.e. vendor-OS-attributes) 
from all available plugins and adds it to the given hash-ref.

If a plugin name has been given, only the attributes of that plugin will be
added.

=over

=item Return Value

1

=back

=cut

sub addAllStage1AttributesToHash
{
    my $class      = shift;
    my $attrInfo   = shift;
    my $pluginName = shift;

    return $class->_addAttributesToHash($attrInfo, $pluginName, sub {
        my $attr = shift;
        return $attr->{applies_to_vendor_os};
    } );
}

=item C<addAllStage3AttributesToHash()>

Fetches attribute info relevant for stage3 (i.e. system- or client-attributes) 
from all available plugins and adds it to the given hash-ref.

If a plugin name has been given, only the attributes of that plugin will be
added.

=over

=item Return Value

1

=back

=cut

sub addAllStage3AttributesToHash
{
    my $class      = shift;
    my $attrInfo   = shift;
    my $pluginName = shift;

    return $class->_addAttributesToHash($attrInfo, $pluginName, sub {
        my $attr = shift;
        return $attr->{applies_to_systems} || $attr->{applies_to_clients};
    } );
}

sub _addAttributesToHash
{
    my $class      = shift;
    my $attrInfo   = shift;
    my $pluginName = shift;
    my $testFunc   = shift;

    $class->_init() if !%plugins;

    foreach my $plugin (values %plugins) {
        next if $pluginName && $plugin->{name} ne $pluginName;
        my $pluginAttrInfo = $plugin->getAttrInfo();
        foreach my $attr (keys %$pluginAttrInfo) {
            next if !$testFunc->($pluginAttrInfo->{$attr});
            $attrInfo->{$attr} = clone($pluginAttrInfo->{$attr});
        }
    }
    return 1;
}

sub _init
{
    my $class = shift;

    %plugins = ();
    my $pluginPath = "$openslxConfig{'base-path'}/lib/plugins";
    foreach my $modulePath (glob("$pluginPath/*")) {
        next if $modulePath !~ m{/([^/]+)$};
        my $pluginName = $1;
        if (!-e "$modulePath/OpenSLX/OSPlugin/$pluginName.pm") {
            vlog(
                1, 
                "skipped plugin-folder $modulePath as no corresponding perl "
                    . "module could be found."
            );
            next;
        }
        my $class = "OpenSLX::OSPlugin::$pluginName";
        vlog(2, "loading plugin $class from path '$modulePath'");
        my $plugin = instantiateClass($class, { pathToClass => $modulePath });
        $plugins{$pluginName} = $plugin;
    }
    return;
}

1;
