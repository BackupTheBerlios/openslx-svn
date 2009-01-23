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
# AttributeRoster.pm
#    - provides information about all available attributes
# -----------------------------------------------------------------------------
package OpenSLX::AttributeRoster;

use strict;
use warnings;

use OpenSLX::Basics;
use OpenSLX::OSPlugin::Engine;
use OpenSLX::OSPlugin::Roster;
use OpenSLX::Utils;

my %AttributeInfo;

#=item C<_init()>
#
#Integrates info about all known attributes (from core and from the plugins)
#into one big hash.
#Returns info about all attributes.
#
#=cut
#
sub _init
{
    my $class = shift;

    # set core attributes
    %AttributeInfo = (
        'automnt_dir' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                !!!descriptive text missing here!!!
            End-of-Here
            content_regex => undef,
            content_descr => undef,
            default => '',
        },
        'automnt_src' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                !!!descriptive text missing here!!!
            End-of-Here
            content_regex => undef,
            content_descr => undef,
            default => '',
        },
        'country' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                !!!descriptive text missing here!!!
            End-of-Here
            content_regex => undef,
            content_descr => undef,
            default => 'de',
        },
        'dm_allow_shutdown' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                !!!descriptive text missing here!!!
            End-of-Here
            content_regex => undef,
            content_descr => undef,
            default => 'user',
        },
        'hw_graphic' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                !!!descriptive text missing here!!!
            End-of-Here
            content_regex => undef,
            content_descr => undef,
            default => '',
        },
        'hw_monitor' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                !!!descriptive text missing here!!!
            End-of-Here
            content_regex => undef,
            content_descr => undef,
            default => '',
        },
        'hw_mouse' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                !!!descriptive text missing here!!!
            End-of-Here
            content_regex => undef,
            content_descr => undef,
            default => '',
        },
        'netbios_workgroup' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                !!!descriptive text missing here!!!
            End-of-Here
            content_regex => undef,
            content_descr => undef,
            default => 'slx-network',
        },
        'nis_domain' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                !!!descriptive text missing here!!!
            End-of-Here
            content_regex => undef,
            content_descr => undef,
            default => '',
        },
        'nis_servers' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                !!!descriptive text missing here!!!
            End-of-Here
            content_regex => undef,
            content_descr => undef,
            default => '',
        },
        'ramfs_fsmods' => {
            applies_to_systems => 1,
            applies_to_clients => 0,
            description => unshiftHereDoc(<<'            End-of-Here'),
                list of filesystem kernel modules to load
            End-of-Here
            content_regex => undef,
            content_descr => undef,
            default => '',
        },
        'ramfs_miscmods' => {
            applies_to_systems => 1,
            applies_to_clients => 0,
            description => unshiftHereDoc(<<'            End-of-Here'),
                list of miscellaneous kernel modules to load
            End-of-Here
            content_regex => undef,
            content_descr => undef,
            default => '',
        },
        'ramfs_nicmods' => {
            applies_to_systems => 1,
            applies_to_clients => 0,
            description => unshiftHereDoc(<<'            End-of-Here'),
                list of network card modules to load
            End-of-Here
            content_regex => qr{^\s*([-\w]+\s*)*$},
            content_descr => 'a space-separated list of NIC modules',
            default => 'forcedeth e1000 e100 tg3 via-rhine r8169 pcnet32',
        },
        'sane_scanner' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                !!!descriptive text missing here!!!
            End-of-Here
            content_regex => undef,
            content_descr => undef,
            default => '',
        },
        'scratch' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                !!!descriptive text missing here!!!
            End-of-Here
            content_regex => undef,
            content_descr => undef,
            default => '',
        },
        'slxgrp' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                !!!descriptive text missing here!!!
            End-of-Here
            content_regex => undef,
            content_descr => undef,
            default => '',
        },
        'start_alsasound' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                !!!descriptive text missing here!!!
            End-of-Here
            content_regex => undef,
            content_descr => undef,
            default => 'yes',
        },
        'start_atd' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                !!!descriptive text missing here!!!
            End-of-Here
            content_regex => undef,
            content_descr => undef,
            default => 'no',
        },
        'start_cron' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                !!!descriptive text missing here!!!
            End-of-Here
            content_regex => undef,
            content_descr => undef,
            default => 'no',
        },
        'start_dreshal' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                !!!descriptive text missing here!!!
            End-of-Here
            content_regex => undef,
            content_descr => undef,
            default => 'yes',
        },
        'start_ntp' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                !!!descriptive text missing here!!!
            End-of-Here
            content_regex => undef,
            content_descr => undef,
            default => 'initial',
        },
        'start_nfsv4' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                !!!descriptive text missing here!!!
            End-of-Here
            content_regex => undef,
            content_descr => undef,
            default => 'no',
        },
        'start_printer' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                !!!descriptive text missing here!!!
            End-of-Here
            content_regex => undef,
            content_descr => undef,
            default => 'no',
        },
        'start_samba' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                !!!descriptive text missing here!!!
            End-of-Here
            content_regex => undef,
            content_descr => undef,
            default => 'may',
        },
        'start_snmp' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                !!!descriptive text missing here!!!
            End-of-Here
            content_regex => undef,
            content_descr => undef,
            default => 'no',
        },
        'start_sshd' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                !!!descriptive text missing here!!!
            End-of-Here
            content_regex => undef,
            content_descr => undef,
            default => 'yes',
        },
        'start_syslogd' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                !!!descriptive text missing here!!!
            End-of-Here
            content_regex => undef,
            content_descr => undef,
            default => 'yes',
        },
        'start_x' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                !!!descriptive text missing here!!!
            End-of-Here
            content_regex => undef,
            content_descr => undef,
            default => 'yes',
        },
        'start_xdmcp' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                !!!descriptive text missing here!!!
            End-of-Here
            content_regex => undef,
            content_descr => undef,
            default => 'kdm',
        },
        'tex_enable' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                !!!descriptive text missing here!!!
            End-of-Here
            content_regex => undef,
            content_descr => undef,
            default => 'no',
        },
        'timezone' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                textual timezone (e.g. 'Europe/Berlin')
            End-of-Here
            content_regex => undef,
            content_descr => undef,
            default => 'Europe/Berlin',
        },
        'tvout' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                !!!descriptive text missing here!!!
            End-of-Here
            content_regex => undef,
            content_descr => undef,
            default => 'no',
        },
        'vmware' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                !!!descriptive text missing here!!!
            End-of-Here
            content_regex => undef,
            content_descr => undef,
            default => 'no',
        },
    );
    
    # and add all plugin attributes, too
    OpenSLX::OSPlugin::Roster->addAllStage3AttributesToHash(\%AttributeInfo);

    return 1;
}

=item C<getAttrInfo()>

Returns info about all attributes.

=over

=item Return Value

An hash-ref with info about all known attributes.

=back

=cut

sub getAttrInfo
{
    my $class  = shift;
    my $params = shift || {};

    $class->_init() if !%AttributeInfo;

    if (defined $params->{name}) {
        my $attrInfo = $AttributeInfo{$params->{name}};
        return if !defined $attrInfo;
        return { $params->{name} => $AttributeInfo{$params->{name}} };
    }
    elsif (defined $params->{scope}) {
        my %MatchingAttributeInfo;
        my $selectedScope = lc($params->{scope});
        foreach my $attr (keys %AttributeInfo) {
            my $attrScope = '';
            if ($attr =~ m{^(.+?)::}) {
                $attrScope = lc($1);
            }
            if ((!$attrScope && $selectedScope eq 'core') 
            || $attrScope eq $selectedScope) {
                $MatchingAttributeInfo{$attr} = $AttributeInfo{$attr};
            }
        }
        return \%MatchingAttributeInfo;
    }

    return \%AttributeInfo;
}

=item C<getStage3Attrs()>

Returns the stage3 attribute names (which apply to systems or clients).

=over

=item Return Value

An array of attribute names.

=back

=cut

sub getStage3Attrs
{
    my $class = shift;

    $class->_init() if !%AttributeInfo;

    return 
        grep { 
            $AttributeInfo{$_}->{applies_to_systems} 
            || $AttributeInfo{$_}->{applies_to_client} 
        }
        keys %AttributeInfo
}

=item C<getSystemAttrs()>

Returns the attribute names that apply to systems.

=over

=item Return Value

An array of attribute names.

=back

=cut

sub getSystemAttrs
{
    my $class = shift;

    $class->_init() if !%AttributeInfo;

    return 
        grep { $AttributeInfo{$_}->{"applies_to_systems"} }
        keys %AttributeInfo
}

=item C<getClientAttrs()>

Returns the attribute names that apply to clients.

=over

=item Return Value

An array of attribute names.

=back

=cut

sub getClientAttrs
{
    my $class = shift;

    $class->_init() if !%AttributeInfo;

    return 
        grep { $AttributeInfo{$_}->{"applies_to_clients"} }
        keys %AttributeInfo
}

=item C<findProblematicValues()>

Checks if the given stage3 attribute values are allowed (and make sense).

This method returns an array-ref of problems found. If there were no problems, 
this methods returns undef.

=cut

sub findProblematicValues
{
    my $class            = shift;
    my $stage3Attrs      = shift || {};
    my $vendorOSName     = shift;
    my $installedPlugins = shift;

    $class->_init() if !%AttributeInfo;

    my @problems;

    my %attrsByPlugin;
    foreach my $key (sort keys %{$stage3Attrs}) {
        my $value = $stage3Attrs->{$key};
        if ($key =~ m{^(.+)::.+?$}) {
            my $pluginName = $1;
            if ($installedPlugins 
            && !grep { $_->{plugin_name} eq $pluginName } @$installedPlugins) {
                # avoid checking attributes of plugins that are not installed
                next;
            }
            $attrsByPlugin{$pluginName} ||= {};
            $attrsByPlugin{$pluginName}->{$key} = $value;
        }

        # undefined values are always allowed
        next if !defined $value;

        # check the value against the regex of the attribute (if any)
        my $attrInfo = $AttributeInfo{$key}
            || die _tr('attribute "%s" is unknown!', $key);
        my $regex = $attrInfo->{content_regex};
        if ($regex && $value !~ $regex) {
            push @problems, _tr(
                "the value '%s' for attribute %s is not allowed.\nAllowed values are: %s",
                $value, $key, $attrInfo->{content_descr}
            );
        }
    }

    # if no vendorOS-name has been provided or there are no plugins installed, 
    # we can't do any further checks
    if ($vendorOSName && $installedPlugins) {
        # now give each installed plugin a chance to check it's own attributes
        # by itself
        foreach my $pluginInfo (sort @$installedPlugins) {
            my $pluginName = $pluginInfo->{plugin_name};
            vlog 2, "checking attrs of plugin: $pluginName\n";
            # create & start OSPlugin-engine for vendor-OS and current plugin
            my $engine = OpenSLX::OSPlugin::Engine->new;
            $engine->initialize($pluginName, $vendorOSName);
            if (!$engine->{'plugin-path'}) {
                warn _tr(
                    'unable to create engine for plugin "%s"!', $pluginName
                );
                next;
            }
            $engine->checkStage3AttrValues(
                $attrsByPlugin{$pluginName}, \@problems
            );
        }
    }
    
    return if !@problems;
    
    return \@problems;
}

1;
