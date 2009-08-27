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
use OpenSLX::DistroUtils;

use Data::Dumper;

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

# This function needs wget installed 
sub installNvidia
{
    my $self = shift;
    my $repopath = shift || "/opt/openslx/plugin-repo/xserver/";
    my $pkgpath = shift || "packages";

    my $tmpdir = "$repopath/nvidia/temp";
    if( !-d $tmpdir ) {
        mkdir( $tmpdir );
    }
    else {
        system("rm -rf $tmpdir/*");
    }

    my $mykernel = getKernelVersionForDistro("/boot");
    my $kver = $mykernel->{'version'};
    my $ksuffix = $mykernel->{'suffix'};

    my $srinfo = `head -n1 /etc/SuSE-release`;
    my @data = split (/ /, $srinfo);
    chomp(@data);

    my $version = $data[1];
    my $chost = substr($data[2],1,-1);

    my $url = "ftp://download.nvidia.com/opensuse/$version/$chost";

    print " * Downloading NVIDIA rpm from ftp://download.nvidia.com/opensuse/$version\n";

    system("wget -P $tmpdir -t2 -T2 $url/nvidia-gfxG01-kmp-$ksuffix* >/dev/null 2>&1");

    if($? > 0) {
        print "Could not download nvidia kernel module rpm!\n";
    }

    my @rpm = glob "$tmpdir/nvidia-gfxG01*.rpm";
    my $rpm = @rpm;
    $rpm[0] =~ /nvidia-gfxG01-kmp-$ksuffix-(.*?)_(.*?)-.*?\.$chost.rpm/;
    
    my $nv_kver = $2;
    $nv_kver =~ s/_/-/g;

    if($rpm == 0) {
        print "Could not download nvidia kernel module rpm!";
        return;
    }

    system("cd $tmpdir; rpm2cpio $rpm[0] | cpio -idv >/dev/null 2>&1");

    if(!-d "$repopath/nvidia/modules/")
    {
        mkdir("$repopath/nvidia/modules/");
    }


    # since kernel 2.6.25.20-0.1 there has to be a call to ld
    # ld -r -m elf_i386 -o ../modules/nvidia.ko  lib/modules/2.6.25.20-0.4-pae/updates/{nv-kernel,nv-linux}.o


    if ( -f "$tmpdir/lib/modules/$nv_kver-$ksuffix/updates/nv-kernel.o" ) {
        # we have to build our kernel module here
        system("ld -r -m elf_i386 -o $tmpdir/lib/modules/$nv_kver-$ksuffix/updates/nvidia.ko $tmpdir/lib/modules/$nv_kver-$ksuffix/updates/{nv-kernel,nv-linux}.o");
    }

    copyFile("$tmpdir/lib/modules/$nv_kver-$ksuffix/updates/nvidia.ko",
        "$repopath/nvidia/modules");

    
    my @versions = split(/-/, $rpm[0]);
    my @nv_versions = split('_',$versions[5]);
    my $nv_version = $nv_versions[0];

    system("wget -P $tmpdir -t2 -T2 $url/x11-video-nvidiaG01-$nv_version* >/dev/null 2>&1");

    @rpm = glob "$tmpdir/x11-video-nvidiaG01-$nv_version*";
    $rpm = @rpm;

    if($rpm == 0) 
    {
        print "Could not download x11-video-nvidiaG01-$nv_version*.rpm!\n";
        print "Exiting nvidia driver installation!\n";
        return;
    }

    system("cd $tmpdir; rpm2cpio $rpm[0] | cpio -idv >/dev/null 2>&1");

    rmtree("$tmpdir/usr/share");
    system("mv $tmpdir/usr $repopath/nvidia/");

    rmtree($tmpdir);
   
}


# this function needs wget
sub installAti
{
    my $self = shift;
    my $repopath = shift || "/opt/openslx/plugin-repo/xserver/";
    my $pkgpath = shift || "packages";

    my $tmpdir = "$repopath/ati/temp";
    if( !-d $tmpdir ) {
        mkdir( $tmpdir );
    }
    else {
        system("rm -rf $tmpdir/*");
    }

    my $mykernel = getKernelVersionForDistro("/boot");
    my $kver = $mykernel->{'version'};
    my $kver_ati = $kver;
    $kver_ati =~ s/-/_/;

    my $ksuffix = $mykernel->{'suffix'};

    my $srinfo = `head -n1 /etc/SuSE-release`;
    my @data = split (/ /, $srinfo);
    chomp(@data);

    my $version = $data[1];
    my $chost = substr($data[2],1,-1);

    my $url = "http://www2.ati.com/suse/$version/";
    
    print " * Downloading ATI rpm from http://www2.ati.com/suse/$version\n";

    system("wget -P $tmpdir -t2 -T2 $url/repodata/primary.xml.gz >/dev/null 2>&1");

    my $url2 = `zcat $tmpdir/primary.xml.gz | grep -P -o "$chost/ati-fglrxG01-kmp-$ksuffix.*?$kver_ati.*?$chost.rpm"`;
    chomp($url2);

    if($url2 eq '') {
        # Taking more general kernel version (minus local suse version)
        my $newkernvers = substr $kver_ati, 0, -4;
        $url2 = `zcat $tmpdir/primary.xml.gz | grep -P -o "$chost/ati-fglrxG01-kmp-$ksuffix.*?$newkernvers.*?$chost.rpm"`;
        chomp($url2);
        if(! $url2 eq '') {
            $kver = $newkernvers;
        }
        else {
            # Minus local Suse version number - hoping, there was no ABI change
            $newkernvers = substr $kver_ati, 0, -7;
            $url2 = `zcat $tmpdir/primary.xml.gz | grep -P -o "$chost/ati-fglrxG01-kmp-$ksuffix.*?$newkernvers.*?$chost.rpm"`;
            chomp($url2);
            if(! $url2 eq '') {
                $kver = $newkernvers;
            }

        }
    }

#    print "KVER = $kver; CHOST = $chost; ksuffix=$ksuffix\n";
#    system("bash");

    if($url2 eq '') {
        print "No ATI module rpm for the chosen kernel version ($kver) found! Exiting!\n";
	return;
    }
    system("wget -P $tmpdir -t2 -T2 $url/$url2 >/dev/null 2>&1");

    my @rpm = glob "$tmpdir/ati-fglrxG01-kmp-$ksuffix*$chost.rpm";
    my $rpm = @rpm;

    if($rpm == 0) {
        print "Could not download ATI kernel module rpm (for kernel $kver)!\n";
        print "Consider downgrading your Kernel! \nTrying package-install!\n";
        $self->installAtiOldStyle(@_);
        return;
    }

    system("cd $tmpdir; rpm2cpio $rpm[0] | cpio -idv >/dev/null 2>&1");

    if(!-d "$repopath/ati/modules/")
    {
        mkdir("$repopath/ati/modules/");
    }
    copyFile("$tmpdir/lib/modules/$kver*-$ksuffix/updates/fglrx.ko",
        "$repopath/ati/modules");

    my @versions = split(/-/, $rpm[0]);
    my @ati_versions = split('_',$versions[5]);
    my $ati_version = $ati_versions[0];

    $url2 = `zcat $tmpdir/primary.xml.gz | grep -P -o "$chost/x11-video-fglrxG01-$ati_version-.*?.$chost.rpm"`;
    chomp($url2);
    system("wget -P $tmpdir -t2 -T2 $url/$url2 >/dev/null 2>&1");

    @rpm = glob "$tmpdir/x11-video-fglrxG01-$ati_version*";
    $rpm = @rpm;

    if($rpm == 0) 
    {
        print " Could not download x11-video-fglrxG01-$ati_version*.rpm!\n";
        print " Exiting ATI driver installation!\n";
        return;
    }

    system("cd $tmpdir; rpm2cpio $rpm[0] | cpio -idv >/dev/null 2>&1");

    rmtree("$tmpdir/usr/share");
    system("mv $tmpdir/usr $repopath/ati/");
    system("mv $tmpdir/etc $repopath/ati/");
    if( ! -d "/usr/X11R6/lib/modules/dri/" ) {
        system("mkdir -p /usr/X11R6/lib/modules/dri/");
    }
    symlink("$repopath/ati/usr/lib/dri/fglrx_dri.so","/usr/X11R6/lib/modules/dri/fglrx_dri.so");

    rmtree($tmpdir);
}



sub installAtiOldStyle 
{
    my $self = shift;
    my $repopath = shift || "/opt/openslx/plugin-repo/xserver/";
    my $pkgpath = shift || "packages";

    
    my $ret = $self->SUPER::installAti(@_);

    if($ret =~ /^error$/) {
        print "Something went wrong installing ATI files!\n";
        return;
    }

    $self->SUPER::getdkms();
    my $mykernel = getKernelVersionForDistro("/boot");
    my $kver = $mykernel->{'version'};
    my $kver_ati = $kver;
    $kver_ati =~ s/-/_/;

    my $ksuffix = $mykernel->{'suffix'};

    my $srinfo = `head -n1 /etc/SuSE-release`;
    my @data = split (/ /, $srinfo);
    chomp(@data);

    my $version = $data[1];
    my $chost = substr($data[2],1,-1);

    # here we have to compile the kernel modules for all kernels
    #
    my $ati_version =  `head $repopath/$pkgpath/ati-driver-installer-*.run | grep -P -o '[0-9]+\.[0-9]{3}' | tail -n1`;
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
        " build >/dev/null 2>&1 \n".
        "#==========================================================";

#print $cmd;
    if(!-f "/var/lib/dkms/fglrx/$ati_version/$kver-$ksuffix/$chost/module/fglrx.ko") {
        system("/sbin/dkms add -m fglrx -v $ati_version >/dev/null 2>&1");
        system($cmd);
        #if ($? > 0) {
        #    print "\n\nCould not compile module! Exit with Ctrl-D\n";
        #    system("/bin/bash");
        #}
    }


    if(!-d  "$repopath/ati/modules/")
    {
        mkdir( "$repopath/ati/modules/" );
    }

    if( -e "/var/lib/dkms/fglrx/$ati_version/$kver-$ksuffix/$chost/module/fglrx.ko") {
        copyFile("/var/lib/dkms/fglrx/$ati_version/$kver-$ksuffix/$chost/module/fglrx.ko",
            "$repopath/ati/modules");
    }
    else {
       print "Could not install ati driver via pkg-installer!\n";
       rmtree($repopath."/ati");
       return;
    }
    rmtree("$repopath/ati/temp");


}

1;
