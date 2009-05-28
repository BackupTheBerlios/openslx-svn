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
# xserver/OpenSLX/Distro/Base.pm
#    - provides base implementation of the Distro API for the xserver plugin.
# -----------------------------------------------------------------------------
package xserver::OpenSLX::Distro::Base;

use strict;
use warnings;

our $VERSION = 1.01;        # API-version . implementation-version

use File::Basename;
use File::Path;

use OpenSLX::Basics;
use OpenSLX::Utils;

################################################################################
### interface methods
################################################################################
sub new
{
    my $class = shift;
    my $self = {};
    return bless $self, $class;
}

sub initialize
{
    my $self        = shift;
    $self->{engine} = shift;
    
    return 1;
}

sub setupXserverScript
{
    my $self     = shift;
    my $repoPath = shift;

    my $pathInfo   = $self->XserverPathInfo();
    my $configFile = $pathInfo->{config};

    my $script = unshiftHereDoc(<<"    End-of-Here");
        # xserver.sh (base part)
        # written by OpenSLX-plugin 'xserver', repoPath is $repoPath

    End-of-Here
    
    return $script;
}

# not used yet, kept as example
sub XserverPathInfo
{
    my $self = shift;
    
    my $pathInfo = {
        config => '/etc/X11/xorg.conf',
        paths => [
            '/usr/bin',
        ],
    };

    return $pathInfo;
}


# looks for the NVIDIA-installer and extracts it
sub installNvidia
{
    my $self = shift;
    my $repopath = shift || "/opt/openslx/plugin-repo/xserver/";
    my $pkgpath = shift || "packages";
    
    my @paths = glob $repopath.$pkgpath."/NVIDIA-Linux-x86*\n";
    my $paths = @paths;
   
    if ($paths > 1)
    {
        print "Found more than one NVIDIA-Linux-x86 installer. Taking first one.\n";
    }
    if ($paths == 0)
    {
        print "Found no NVIDIA-Linux-x86 installer. Quitting NVIDIA installation!\n";
        return "error";
    }

    if ( ! -X $paths[0] )
    {
       system("chmod +x ".$paths[0]);
    }
    system($paths[0]." -x --target $repopath/nvidia/temp >/dev/null 2>&1");

    if($? == -1 ) 
    {
        print "Failed to execute ".$paths[0]."\n";
        return "error";
    }

    system("mv $repopath/nvidia/temp/usr/src $repopath/nvidia/temp/");
    system("mv $repopath/nvidia/temp/usr/ $repopath/nvidia/");
    rmtree("$repopath/nvidia/usr/share/");

    return "$repopath/nvidia/temp/src/nv";
}


sub installAti
{
    my $self = shift;
    my $repopath = shift || "/opt/openslx/plugin-repo/xserver/";
    my $pkgpath = shift || "packages";

    my @paths = glob $repopath."/".$pkgpath."/ati-driver-installer*";
    my $paths = @paths;

    if ($paths > 1)
    {
        print "Found more than one ati-driver-installer. Taking first one.\n";
    }
    if ($paths == 0)
    {
        print "Found no ati-driver-installer. Quitting ATI installation!\n";
        return "error";
    }

    if ( ! -X $paths[0] )
    {
       system("chmod +x ".$paths[0]);
    }
    system($paths[0]." --extract $repopath/ati/temp >/dev/null 2>&1");

    if($? == -1 ) 
    {
        print "Failed to execute ".$paths[0]."\n";
        return "error";
    }

    # TODO: allow x86_64 driver installation (libs)
    my $arch = "x86";

    rmtree("$repopath/ati/usr");
    system("mv $repopath/ati/temp/common/usr $repopath/ati/");
    if (!-d "$repopath/ati/usr/lib" ) {
        mkdir "$repopath/ati/usr/lib";
    }
    system("mv $repopath/ati/temp/arch/$arch/usr/X11R6/lib/* $repopath/ati/usr/lib/");
    system("mv $repopath/ati/temp/arch/$arch/usr/lib/* $repopath/ati/usr/lib/");
    rmtree("$repopath/ati/usr/share/");

    my $cmd='gcc --version | head -n 1 | sed -e "s/[^0-9. ]//g;s/^ *//;s/^\(.\)\..*$/\1/"';
    my $gcc_ver_maj =`$cmd`;
    chomp($gcc_ver_maj);

    system("mv $repopath/ati/temp/arch/$arch/lib/modules/fglrx/build_mod/libfglrx_ip.a.GCC$gcc_ver_maj $repopath/ati/temp/common/lib/modules/fglrx/build_mod/");


    return "$repopath/ati/temp/common/lib/modules/fglrx/build_mod";
}

# get dkms with wget/tar and put it into /sbin
sub getdkms
{
    if( !-f "/sbin/dkms") {
        if(!-f "dkms-2.0.21.1.tar.gz" ) {
            system("wget http://linux.dell.com/dkms/permalink/dkms-2.0.21.1.tar.gz");
            die("Could not download dkms tarball! Exiting!") if($? > 0 );
        }
        if(!-f "dkms-2.0.21.1/dkms" ) {
            system("tar -zxvf dkms-2.0.21.1.tar.gz dkms-2.0.21.1/dkms");
            die("Could not extract dkms script from tarball! Exiting!") if($? > 0 ); 
        }
        copy("dkms-2.0.21.1/dkms","/sbin/dkms");
        chmod 0755, "/sbin/dkms";
    }
}

1;
