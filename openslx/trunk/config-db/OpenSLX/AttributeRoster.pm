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

use Digest::MD5 qw(md5_hex);

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
        'boot_type' => {
            applies_to_systems => 0,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                Selects the boot technology for this client.
                Currently the following boot types are supported:
                    pxe    (is the default)
                        uses PXE to boot client over LAN
                    preboot
                        generates a set of images (see preboot_media) that can
                        be used to remotely boot the systems referred to by 
                        this client
            End-of-Here
            content_regex => qr{^(pxe|preboot)$},
            content_descr => '"pxe" or "preboot"',
            default => 'pxe',
        },
        'boot_uri' => {
            applies_to_systems => 0,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                specifies the wget(able) address of the remote bootloader 
                archive that shall be loaded from the preboot environment
            End-of-Here
            content_regex => undef,
            content_descr => 'an uri supported by wget',
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
        'hidden' => {
            applies_to_systems => 1,
            applies_to_clients => 0,
            description => unshiftHereDoc(<<'            End-of-Here'),
                specifies whether or not this system is offered for booting
            End-of-Here
            content_regex => qr{^(0|1)$},
            content_descr => '0: system is bootable - 1: system is hidden',
            default => '0',
        },
        'kernel_params' => {
            applies_to_systems => 1,
            applies_to_clients => 0,
            description => unshiftHereDoc(<<'            End-of-Here'),
                params to build kernel cmdline for this system
            End-of-Here
            content_regex => undef,
            content_descr => 'kernel cmdline fragment',
            default => 'quiet',
        },
        'kernel_params_client' => {
            applies_to_systems => 0,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                client-specific params for kernel cmdline
            End-of-Here
            content_regex => undef,
            content_descr => 'kernel cmdline fragment',
            default => '',
        },
        'preboot_media' => {
            applies_to_systems => 0,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                List of preboot media supported by this client.
                Currently the following preboot media are supported:
                    cd
                        generates a bootable CD-image that can be used to
                        remotely boot the systems referred to by this client
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
        'hw_local_disk' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                how to handle local disk deploament - no/slxonly/all
            End-of-Here
            content_regex => undef,
            content_descr => 'how to handle local disk (no/slxonly/all)',
            default => 'all',
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
        'unbootable' => {
            applies_to_systems => 0,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                specifies whether or not this client is allowed to boot
            End-of-Here
            content_regex => qr{^(0|1)$},
            content_descr => '0: client can boot - 1: client is blocked',
            default => '0',
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
        my $attrInfo = $AttributeInfo{$key};
        if (!$attrInfo) {
            push @problems, _tr('attribute "%s" is unknown!', $key);
            next;
        }
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
        foreach my $pluginInfo (
            sort { $a->{plugin_name} cmp $b->{plugin_name} } @$installedPlugins
        ) {
            my $pluginName = $pluginInfo->{plugin_name};
            vlog 2, "checking attrs of plugin: $pluginName\n";
            # create & start OSPlugin-engine for vendor-OS and current plugin
            my $engine = OpenSLX::OSPlugin::Engine->new;
            if (!$engine->initialize($pluginName, $vendorOSName)) {
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

=item C<computeMD5HashOverAllAttrs()>

Returns a MD5 hash representing the list of all attributes (including plugins).

=cut

sub computeMD5HashOverAllAttrs
{
    my $class = shift;

    $class->_init() if !%AttributeInfo;

    my %attrNames;
    @attrNames{keys %AttributeInfo} = ();
    
    my $pluginInfo = OpenSLX::OSPlugin::Roster->getAvailablePlugins();
    if ($pluginInfo) {
        foreach my $pluginName (sort keys %$pluginInfo) {
            my $attrInfo 
                = OpenSLX::OSPlugin::Roster->getPluginAttrInfo($pluginName);
            @attrNames{keys %$attrInfo} = ();
        }
    }
    
    my $attrNamesAsString = join ',', sort keys %attrNames;

    return md5_hex($attrNamesAsString);
}

1;
