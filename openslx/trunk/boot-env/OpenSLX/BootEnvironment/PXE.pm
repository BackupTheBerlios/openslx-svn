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
# for sha1 passwd encryption
use Digest::SHA1;
use MIME::Base64;

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
            my $menuMargin;
            while ($pxeConfig =~ m{^\s*MENU MARGIN (\S+?)\s*$}gims) {
                chomp($menuMargin = $1);
            }
            my $margin
                = defined $menuMargin
                    ? "$menuMargin"
                    : "0";
            my $marginAsText = ' ' x $margin;

            my $menuWidth;
            while ($pxeConfig =~ m{^\s*MENU WIDTH (\S+?)\s*$}gims) {
                chomp($menuWidth = $1);
            }
            my $width
                = defined $menuWidth
                    ? "$menuWidth"
                    : "80";
               $width = $width - 2* $margin + 2;

            my @atomicHelpText = split(/ /, $helpText);
            my $lineCounter = 0;

            $helpText = "";

            foreach my $word (@atomicHelpText){
                if ($lineCounter + length($word) + 1 < $width) {
                     $helpText .= "$word ";
                     $lineCounter += length($word) + 1;
                } else {
                     my $nobreak = 1;
                     while ($nobreak == 1) {
                        my $pos = index($word,"-");
                        $nobreak = 0;
                        if ($pos != -1) {
                            if ($lineCounter + $pos + 1 < $width) {
                                $helpText .= substr($word, 0, $pos+1);
                                $word = substr($word, $pos + 1, length($word));
                                $nobreak = 1;
                            }
                        }
                     }
                     $helpText .= "\n$word ";
                     $lineCounter = length($word);
                }
            } 

            $helpText =~ s{^}{$marginAsText}gms;
            $slxLabels .= "\tTEXT HELP\n";
            $slxLabels .= "$helpText\n";
            $slxLabels .= "\tENDTEXT\n";
        }
    }
    # now add the slx-labels (inline or appended) and write the config file
    if (!($pxeConfig =~ s{\@\@\@SLX_LABELS\@\@\@}{$slxLabels})) {
        $pxeConfig .= $slxLabels;
        # fetch PXE-bottom iclude, if exists (overwrite existing definitions)
        my $pxeBottomFile
            = "$openslxConfig{'config-path'}/boot-env/pxe/menu-bottom";
        if (-e $pxeBottomFile) {
            $pxeConfig .= "\n# configuration from include $pxeBottomFile\n";
            $pxeConfig .= slurpFile($pxeBottomFile);
        }
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

    my $basePath   = $openslxConfig{'base-path'};
    my $configPath = $openslxConfig{'config-path'};
    my $pxeTheme   = $openslxConfig{'pxe-theme'};

    my ($sec, $min, $hour, $day, $mon, $year) = (localtime);
    $mon++;
    $year += 1900;
    my $callDate = sprintf('%04d-%02d-%02d', $year, $mon, $day);
    my $callTime = sprintf('%02d:%02d:%02d', $hour, $min, $sec);
    
    # generate PXE-Menu
    my $pxeTemplate =
        "# generated by slxconfig-demuxer (on $callDate at $callTime)\n";
    $pxeTemplate .= "\nDEFAULT vesamenu.c32\n";
    # include static defaults
    $pxeTemplate .= "\n# static configuration (override with include file)\n";
    $pxeTemplate .= "NOESCAPE 0\n";
    $pxeTemplate .= "PROMPT 0\n";

    # first check for theme
    # let user stuff in config path win over our stuff in base path
    my $pxeThemePath;
    my $pxeThemeInConfig
        = "$configPath/boot-env/pxe/themes/${pxeTheme}";
    my $pxeThemeInBase
        = "$basePath/share/boot-env/pxe/themes/${pxeTheme}";
    if (-e "$pxeThemeInConfig/theme.conf") {
        $pxeThemePath = $pxeThemeInConfig;
    }
    else {
        if (-e "$pxeThemeInBase/theme.conf") {
            $pxeThemePath = $pxeThemeInBase;
        }
    }
    # include theme specific stuff
    if (defined $pxeThemePath) {
        $pxeTemplate .= "\n# theme specific configuration from $pxeThemePath\n";
        $pxeTemplate .= slurpFile("$pxeThemePath/theme.conf");
    }

    # copy background picture if exists
    my $pic;
    if (defined $pxeTheme) {
        while ($pxeTemplate =~ m{^\s*MENU BACKGROUND (\S+?)\s*$}gims) {
            chomp($pic = $1);
        }
    }
    if (defined $pic) {
        my $pxeBackground = "$pxeThemePath/$pic";
        if (-e $pxeBackground && !$self->{'dry-run'}) {
            slxsystem(qq[cp "$pxeBackground" $self->{'target-path'}/]);
        }
    }

    # include slxsettings
    $pxeTemplate .= "\n# slxsettings configuration\n";
    $pxeTemplate .= "TIMEOUT $openslxConfig{'pxe-timeout'}\n" || "";
    $pxeTemplate .= "TOTALTIMEOUT $openslxConfig{'pxe-totaltimeout'}\n" || "";
    my $sha1pass  = $self->_sha1pass($openslxConfig{'pxe-passwd'});
    $pxeTemplate .= "MENU MASTER PASSWD $sha1pass\n" || "";
    $pxeTemplate .= "MENU TITLE $openslxConfig{'pxe-title'}\n" || "";

    # fetch PXE-include, if exists (overwrite existing definitions)
    my $pxeIncludeFile
        = "$openslxConfig{'config-path'}/boot-env/pxe/menu-include";
    if (-e $pxeIncludeFile) {
        $pxeTemplate .= "\n# configuration from include $pxeIncludeFile\n";
        $pxeTemplate .= slurpFile($pxeIncludeFile);
    }

    $pxeTemplate .= "\n# slxsystems:\n";
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

        for my $file ('pxelinux.0', 'pxechain.com', 'vesamenu.c32',
            'mboot.c32', 'kernel-shutdown', 'initramfs-shutdown') {
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

# from syslinux 3.73: http://syslinux.zytor.co
sub _random_bytes
{
    my $self = shift;
    my $n = shift;
    my($v, $i);

    # using perl rand because of problems with encoding(cp850) and 'bytes'
    srand($$ ^ time);
    $v = '';
    for ( $i = 0 ; $i < $n ; $i++ ) {
        $v .= ord(int(rand() * 256));
    }
    
    return $v;
}

sub _sha1pass
{
    my $self = shift;
    my $pass = shift;
    my $salt = shift || MIME::Base64::encode($self->_random_bytes(6), '');
    $pass = Digest::SHA1::sha1_base64($salt, $pass);

    return sprintf('$4$%s$%s$', $salt, $pass);
}

1;
