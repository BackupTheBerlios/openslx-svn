# Copyright (c) 2008..2009 - OpenSLX GmbH
#
# This program is free software distributed under the GPL version 2.
# See http://openslx.org/COPYING
#
# If you have any feedback please consult http://openslx.org/feedback and
# send your suggestions, praise, or complaints to feedback@openslx.org
#
# General information about OpenSLX can be found at http://openslx.org/
# -----------------------------------------------------------------------------
# BootEnvironment::PXE.pm
#    - provides PXE-specific implementation of the BootEnvironment API.
# -----------------------------------------------------------------------------
package OpenSLX::BootEnvironment::PXE;

use strict;
use warnings;

use base qw(OpenSLX::BootEnvironment::Base);

use File::Basename;
use File::Path;

use OpenSLX::Basics;
use OpenSLX::Utils;

sub initialize
{
    my $self   = shift;
    my $params = shift;
    
    return if !$self->SUPER::initialize($params);

    $self->{'original-path'} = "$openslxConfig{'public-path'}/tftpboot";
    $self->{'target-path'}   = "$openslxConfig{'public-path'}/tftpboot.new";

    $self->{'requires-default-client-config'} = 1;

    if (!$self->{'dry-run'}) {
        mkpath([$self->{'original-path'}]);
        rmtree($self->{'target-path'});
        mkpath("$self->{'target-path'}/client-config");
    }

    return 1;
}

sub writeBootloaderMenuFor
{
    my $self             = shift;
    my $client           = shift;
    my $externalClientID = shift;
    my $systemInfos      = shift;

    $self->_prepareBootloaderConfigFolder() 
        unless $self->{preparedBootloaderConfigFolder};

    my $pxePath       = $self->{'target-path'};
    my $pxeConfigPath = "$pxePath/pxelinux.cfg";

    my $pxeConfig    = $self->_getTemplate();
    my $pxeFile      = "$pxeConfigPath/$externalClientID";
    my $clientAppend = $client->{attrs}->{kernel_params_client} || '';
    my $bootURI      = $client->{attrs}->{boot_uri} || '';
    vlog(1, _tr("writing PXE-file %s", $pxeFile));

    # set label for each system
    foreach my $info (@$systemInfos) {
        my $label = $info->{label} || '';
        if (!length($label) || $label eq $info->{name}) {
            if ($info->{name} =~ m{^(.+)::(.+)$}) {
                my $system = $1;
                my $exportType = $2;
                $label = $system . ' ' x (40-length($system)) . $exportType;
            } else {
                $label = $info->{name};
            }
        }
        $info->{pxeLabel} = $label;
    }
    my $slxLabels = '';
    foreach my $info (sort { $a->{label} cmp $b->{label} } @$systemInfos) {
        my $vendorOSName = $info->{'vendor-os'}->{name};
        my $kernelName   = basename($info->{'kernel-file'});
        my $append       = $info->{attrs}->{kernel_params};
        my $pxePrefix    = '';
        my $tftpPrefix   = '';
        $info->{'pxe_prefix_ip'} ||= '';
        
        # pxe_prefix_ip set and looks like a ip
        if ($info->{'pxe_prefix_ip'} =~ m/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/) {
        	$pxePrefix = "$info->{'pxe_prefix_ip'}::";
        	$tftpPrefix = "tftp://$info->{'pxe_prefix_ip'}" if ! length($bootURI);
        }
        
        $append .= " initrd=$pxePrefix$vendorOSName/$info->{'initramfs-name'}";
        $append .= " file=$bootURI"     if length($bootURI);
        $append .= " file=$tftpPrefix"  if length($tftpPrefix);
        $append .= " $clientAppend";
        $slxLabels .= "LABEL openslx-$info->{'external-id'}\n";
        $slxLabels .= "\tMENU LABEL ^$info->{pxeLabel}\n";
        $slxLabels .= "\tKERNEL $pxePrefix$vendorOSName/$kernelName\n";
        $slxLabels .= "\tAPPEND $append\n";
        $slxLabels .= "\tIPAPPEND 3\n";
        my $helpText = $info->{description} || '';
        if (length($helpText)) {
            # make sure that text matches the given margin
            my $margin = $openslxConfig{'pxe-theme-menu-margin'} || 0;
            my $marginAsText = ' ' x $margin;
            $helpText =~ s{^}{$marginAsText}gms;
            $slxLabels .= "\tTEXT HELP\n$helpText\n\tENDTEXT\n";
        }
    }
    # now add the slx-labels (inline or appended) and write the config file
    if (!($pxeConfig =~ s{\@\@\@SLX_LABELS\@\@\@}{$slxLabels})) {
        $pxeConfig .= $slxLabels;
    }

    # PXE uses 'cp850' (codepage 850) but our string is in utf-8, we have
    # to convert in order to avoid showing gibberish on the client side...
    spitFile($pxeFile, $pxeConfig, { 'io-layer' => 'encoding(cp850)' } )
        unless $self->{'dry-run'};

    return 1;
}

sub _getTemplate
{
    my $self = shift;
    
    return $self->{'pxe-template'} if $self->{'pxe-template'};
    
    my $pxeDefaultTemplate = unshiftHereDoc(<<'    End-of-Here');
        NOESCAPE 0
        PROMPT 0
        TIMEOUT 100
        DEFAULT menu.c32
        IMPLICIT 1
        ALLOWOPTIONS 1
        MENU TITLE Was möchten Sie tun (Auswahl mittels Cursortasten)?
        MENU MASTER PASSWD secret
    End-of-Here
    utf8::decode($pxeDefaultTemplate);
    
    my ($sec, $min, $hour, $day, $mon, $year) = (localtime);
    $mon++;
    $year += 1900;
    my $callDate = sprintf('%04d-%02d-%02d', $year, $mon, $day);
    my $callTime = sprintf('%02d:%02d:%02d', $hour, $min, $sec);
    
    # fetch PXE-template, if any
    my $pxeTemplate =
        "# generated by slxconfig-demuxer (on $callDate at $callTime)\n";
    my $pxeTemplateFile 
        = "$openslxConfig{'config-path'}/boot-env/pxe/menu-template";
    if (-e $pxeTemplateFile) {
        $pxeTemplate .= slurpFile($pxeTemplateFile);
    } else {
        $pxeTemplate .= $pxeDefaultTemplate;
    }

    # now append (and thus override) the PXE-template with the settings of the 
    # selected PXE-theme, if any
    my $basePath   = $openslxConfig{'base-path'};
    my $configPath = $openslxConfig{'config-path'};
    my $pxeTheme   = $openslxConfig{'pxe-theme'};
    if (defined $pxeTheme) {
        # let user stuff in config path win over our stuff in base path
        my $pxeThemeInConfig
            = "$configPath/boot-env/pxe/themes/${pxeTheme}/theme.conf";
        if (-e $pxeThemeInConfig) {
            $pxeTemplate .= slurpFile($pxeThemeInConfig);
        }
        else {
            my $pxeThemeInBase
                = "$basePath/share/boot-env/pxe/themes/${pxeTheme}/theme.conf";
            if (-e $pxeThemeInBase) {
                $pxeTemplate .= slurpFile($pxeThemeInBase);
            }
        }
    }

    # fetch info about margin and replace the corresponding placeholders
    my $margin = $openslxConfig{'pxe-theme-menu-margin'} || 0;
    my $marginAsText = ' ' x $margin;
    $pxeTemplate =~ s{\@\@\@MENU_MARGIN\@\@\@}{$margin}g;
    my $separatorLine = '-' x (78 - 4 - 2 * $margin);
    $pxeTemplate =~ s{\@\@\@SEPARATOR_LINE\@\@\@}{$separatorLine}g;

    # pick out the last background picture and copy it over
    my $pic;
    while ($pxeTemplate =~ m{^\s*MENU BACKGROUND (\S+?)\s*$}gims) {
        chomp($pic = $1);
    }
    if (defined $pic) {
        my $pxeBackground 
            = defined $pxeTheme
                ? "$basePath/share/themes/${pxeTheme}/pxe/$pic"
                : $pic;
        if (-e $pxeBackground && !$self->{'dry-run'}) {
            slxsystem(qq[cp "$pxeBackground" $self->{'target-path'}/]);
        }
    }
    
    $self->{'pxe-template'} = $pxeTemplate;
    
    return $pxeTemplate;
}
   
sub _prepareBootloaderConfigFolder
{
    my $self = shift;
    
    my $basePath      = $openslxConfig{'base-path'};
    my $pxePath       = $self->{'target-path'};
    my $pxeConfigPath = "$pxePath/pxelinux.cfg";

    if (!$self->{'dry-run'}) {
        rmtree($pxeConfigPath);
        mkpath($pxeConfigPath);

        for my $file ('pxelinux.0', 'menu.c32', 'vesamenu.c32') {
            if (!-e "$pxePath/$file") {
                slxsystem(
                    qq[cp -p "$basePath/share/boot-env/pxe/$file" $pxePath/]
                );
            }
        }
    }
    
    $self->{preparedBootloaderConfigFolder} = 1;

    return 1;
}

1;
