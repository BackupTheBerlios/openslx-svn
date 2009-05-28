# Copyright (c) 2008 - OpenSLX GmbH
#
# This program is free software distributed under the GPL version 2.
# See http://openslx.org/COPYING
#
# If you have any feedback please consult http://openslx.org/feedback and
# send your suggestions, praise, or complaints to feedback@openslx.org
#
# General information about OpenSLX can be found at http://openslx.org/
# -----------------------------------------------------------------------------
# xserver/OpenSLX/Distro/Suse.pm
#    - provides SUSE-specific overrides of the Distro API for the xserver
#      plugin.
# -----------------------------------------------------------------------------
package xserver::OpenSLX::Distro::Suse;

use strict;
use warnings;

use base qw(xserver::OpenSLX::Distro::Base);

use File::Path;

use OpenSLX::Basics;
use OpenSLX::Utils;


################################################################################
### interface methods
################################################################################

sub setupXserverScript
{
    my $self     = shift;
    my $repoPath = shift;

    my $script = $self->SUPER::setupXserverScript($repoPath);

    $script .= unshiftHereDoc(<<'    End-of-Here');
        # SuSE specific extension to stage3 xserver.sh
        testmkd /mnt/var/lib/xkb/compiled
        testmkd /mnt/var/X11R6/bin
        testmkd /mnt/var/lib/xdm/authdir/authfiles 0700
        ln -s /usr/bin/Xorg /mnt/var/X11R6/bin/X
        rm /mnt/etc/X11/xdm/SuSEconfig.xdm
    End-of-Here

    return $script;
}


sub installNvidia
{
    my $self = shift;
    my $repopath = shift || "/opt/openslx/plugin-repo/xserver/";
    my $pkgpath = shift || "packages";

    my $tmpdir = "$repopath/nvidia/temp";
    if( !-d $tmpdir ) {
        mkdir( $tmpdir );
    }
#
#    my $ret = $self->SUPER::installNvidia(@_);
#
#    if($ret =~ /^error$/) {
#        print "Something went wrong installing NVIDIA files!\n";
#        return;
#    }
#
#    $self->SUPER::getdkms();
#
    my $kver = "2.6.25.20-0.1";
    my $ksuffix = "pae";
#
#    # here we have to compile the kernel modules for all kernels
#    my $grep = "grep -io DNV_VERSION_STRING=.* $ret/Makefile.nvidia |".
#        "cut -d'\\' -f2 | cut -d'\"' -f2";
#    my $nv_version = `$grep`;
#    chomp($nv_version);
#
#    system("mv $ret /usr/src/nvidia-$nv_version >/dev/null 2>&1");
#
#    open FH,">/usr/src/nvidia-$nv_version/dkms.conf";
#    print FH "DEST_MODULE_LOCATION=/updates\n";
#    print FH "PACKAGE_NAME=nvidia\n";
#    print FH "PACKAGE_VERSION=$nv_version\n";
#    close FH;
#
#    system("/sbin/dkms add -m nvidia -v $nv_version");
#    my $cmd = "#============= Executing following command =============\n".
#        "/sbin/dkms ".
#        " -m nvidia -v $nv_version ".
#        " -k $kver-$ksuffix ".
#        " --kernelsourcedir /usr/src/linux-$kver-obj/i586/$ksuffix ".
#        " --no-prepare-kernel ".
#        " --no-clean-kernel ".
#        " build \n".
#        "#==========================================================";
#
#    print $cmd;
#    system($cmd);


    my $srinfo = `head -n1 /etc/SuSE-release`;
    my @data = split (/ /, $srinfo);
    chomp(@data);

    my $version = $data[1];
    my $chost = substr($data[2],1,-1);

    my $url = "ftp://download.nvidia.com/opensuse/$version/$chost";
    system("wget -P $tmpdir $url/nvidia-gfxG01-kmp-$ksuffix* >/dev/null 2>&1");

    if($? > 0) {
        print "Could not download nvidia kernel module rpm!\n";
    }

    my @rpm = glob "$tmpdir/nvidia-gfxG01*.rpm";
    my $rpm = @rpm;

    if($rpm == 0) {
        print "Could not find nvidia kernel module rpm on filesystem!";
        return;
    }

    system("cd $tmpdir; rpm2cpio $rpm[0] | cpio -idv >/dev/null 2>&1");

    if(!-d "$repopath/nvidia/modules/")
    {
        mkdir("$repopath/nvidia/modules/");
    }
    copyFile("$tmpdir/lib/modules/$kver-$ksuffix/updates/nvidia.ko",
        "$repopath/nvidia/modules");

    
    my @versions = split(/-/, $rpm[0]);
    my @nv_versions = split('_',$versions[5]);
    my $nv_version = $nv_versions[0];

    system("wget -P $tmpdir $url/x11-video-nvidiaG01-$nv_version* >/dev/null 2>&1");

    @rpm = glob "$tmpdir/x11-video-nvidiaG01-$nv_version*";
    $rpm = @rpm;

    if($rpm == 0) 
    {
        print "Could not download x11-video-nvidia-$nv_version*.rpm!\n";
        print "Exiting nvidia driver installation!\n";
        return;
    }

    system("cd $tmpdir; rpm2cpio $rpm[0] | cpio -idv >/dev/null 2>&1");

    rmtree("$tmpdir/usr/share");
    system("mv $tmpdir/usr $repopath/nvidia/");

    rmtree($tmpdir);
   
}

sub installAti
{
    my $self = shift;
    my $repopath = shift || "/opt/openslx/plugin-repo/xserver/";
    my $pkgpath = shift || "packages";

    my $srinfo = `head -n1 /etc/SuSE-release`;
    my @data = split (/ /, $srinfo);
    chomp(@data);

    my $version = $data[1];
    my $chost = substr($data[2],1,-1);

    my $ret = $self->SUPER::installAti(@_);

    if($ret =~ /^error$/) {
        print "Something went wrong intalling ATI files!\n";
        return;
    }

    $self->SUPER::getdkms();

    my $kver = "2.6.25.20-0.1";
    my $ksuffix = "pae";

    # here we have to compile the kernel modules for all kernels
    #
    my $ati_version =  `head $repopath/$pkgpath/ati-driver-installer-9-1-x86.x86_64.run | grep -P -o '[0-9]+\.[0-9]{3}' | tail -n1`;
    chomp($ati_version);

    system("mv $ret /usr/src/fglrx-$ati_version >/dev/null 2>&1");

    open FH,">/usr/src/fglrx-$ati_version/dkms.conf";
    print FH "DEST_MODULE_LOCATION=/updates\n";
    print FH "PACKAGE_NAME=fglrx\n";
    print FH "PACKAGE_VERSION=$ati_version\n";
    close FH;

    my $cmd = "#============= Executing following command =============\n".
        "/sbin/dkms ".
        " -m fglrx -v $ati_version ".
        " -k $kver-$ksuffix ".
        " --kernelsourcedir /usr/src/linux-$kver-obj/i586/$ksuffix ".
        " --no-prepare-kernel ".
        " --no-clean-kernel ".
        " build \n".
        "#==========================================================";

#    print $cmd;
    if(!-f "/var/lib/dkms/fglrx/$ati_version/$kver-$ksuffix/$chost/module/fglrx.ko") {
        system("/sbin/dkms add -m fglrx -v $ati_version");
        system($cmd." >/dev/null 2>&1");
    }

    if(!-d  "$repopath/ati/modules/")
    {
        mkdir( "$repopath/ati/modules/" );
    }
    copyFile("/var/lib/dkms/fglrx/$ati_version/$kver-$ksuffix/$chost/module/fglrx.ko",
        "$repopath/ati/modules");
    #if ($? > 0) {
    #    print "\n\nCould not copy! Exit with Ctrl-D\n";
    #    system("/bin/bash");
    #}
    rmtree("$repopath/ati/temp");


}

1;
