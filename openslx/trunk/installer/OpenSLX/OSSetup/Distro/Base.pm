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
# OSSetup/Distro/Base.pm
#    - provides base implementation of the OSSetup Distro API.
# -----------------------------------------------------------------------------
package OpenSLX::OSSetup::Distro::Base;

use strict;
use warnings;

our $VERSION = 1.01;        # API-version . implementation-version

use Fcntl qw(:DEFAULT :flock);
use File::Basename;
use File::Path;
use Scalar::Util qw( weaken );

use OpenSLX::Basics;
use OpenSLX::Utils;

################################################################################
### interface methods
################################################################################
sub new
{
    confess "Creating OpenSLX::OSSetup::System::Base-objects directly makes no sense!";
}

sub initialize
{
    my $self = shift;
    my $engine = shift;

    $self->{'engine'} = $engine;
    weaken($self->{'engine'});
        # avoid circular reference between distro and its engine

    if ($engine->{'distro-name'} =~ m[x86_64]) {
        # be careful to only try installing 64-bit systems if actually
        # running on a 64-bit host, as otherwise we are going to fail later,
        # anyway:
        my $arch = `uname -m`;
        if ($?) {
            die _tr("unable to determine architecture of host system (%s)\n", $!);
        }
        if ($arch !~ m[x86_64]) {
            die _tr("you can't install a 64-bit system on a 32-bit host, sorry!\n");
        }
    }

    $self->{'stage1a-binaries'} = {
        "$openslxConfig{'base-path'}/share/busybox/busybox" => 'bin',
    };

    $self->{'stage1b-faked-files'} = [
        '/etc/mtab',
    ];

    $self->{'stage1c-faked-files'} = [
    ];

    $self->{'clone-filter'} = "
        - /var/cache/apt/archives/*
        - /var/tmp/*
        - /var/opt/openslx
        - /var/lib/vmware
        - /var/lib/ntp/*
        - /var/run/*
        - /var/log/*
        + /var
        - /usr/lib/vmware/modules/*
        + /usr
        - /tmp/*
        + /tmp
        - /sys/*
        + /sys
        + /sbin
        - /root/*
        + /root
        - /proc/*
        + /proc
        - /opt/openslx
        + /opt
        - /media/*
        + /media
        - /mnt/*
        + /mnt
        + /lib64
        - /lib/ld-uClibc*
        + /lib
        - /home/*
        + /home
        - /etc/vmware/installer.sh
        - /etc/shadow*
        - /etc/samba/secrets.tdb
        - /etc/resolv.conf.*
        - /etc/opt/openslx
        - /etc/exports*
        - /etc/X11/xorg.c*
	- /etc/X11/XF86*
        + /etc
        - /dev/*
        + /dev
        + /boot
        + /bin
        - /*
        - .svn
        - .*.cmd
        - *~
        - *lost+found*
        - *.old
        - *.bak
    ";

    return;
}

sub fixPrerequiredFiles
{
}

sub startSession
{
    my $self  = shift;
    my $osDir = shift;
    
    # setup a fixed locale environment to avoid warnings about unset locales
    # (like for instance shown by apt-get)
    $ENV{LC_ALL} = 'POSIX';

    # ensure that a couple of important devices exist
    my %devInfo = (
        mem     => { type => 'c', major => '1', minor =>  '1' },
        null    => { type => 'c', major => '1', minor =>  '3' },
        zero    => { type => 'c', major => '1', minor =>  '5' },
        random  => { type => 'c', major => '1', minor =>  '8' },
        urandom => { type => 'c', major => '1', minor =>  '9' },
        kmsg    => { type => 'c', major => '1', minor => '11' },
        tty     => { type => 'c', major => '5', minor =>  '0' },
        console => { type => 'c', major => '5', minor =>  '1' },
        ptmx    => { type => 'c', major => '5', minor =>  '2' },
    );
    if (!-e "$osDir/dev" && !mkpath("$osDir/dev")) {
        die _tr("unable to create folder '%s' (%s)\n", "$osDir/dev", $!);
    }
    foreach my $dev (keys %devInfo) {
        my $info = $devInfo{$dev};
        if (!-e "$osDir//dev/$dev") {
            if (slxsystem(
                "mknod $osDir//dev/$dev $info->{type} $info->{major} $info->{minor}"
            )) {
                croak(_tr("unable to create dev-node '%s'! (%s)", $dev, $!));
            }
        }
    }

    # enter chroot jail
    chrootInto($osDir);
    $ENV{PATH} = join(':', @{$self->getDefaultPathList()});

    # mount /proc (if we have 'mount' available)
    if (qx{which mount 2>/dev/null}) {
        if (!-e '/proc' && !mkpath('/proc')) {
            die _tr("unable to create folder '%s' (%s)\n", "$osDir/proc", $!);
        }
        if (slxsystem("mount -t proc proc '/proc'")) {
            warn _tr("unable to mount '%s' (%s)\n", "$osDir/proc", $!);
        }
        if (!-e '/dev/pts' && !mkpath('/dev/pts')) {
            die _tr("unable to create folder '%s' (%s)\n", "$osDir/dev/pts", $!);
        }
        if (slxsystem("mount -t devpts devpts '/dev/pts'")) {
            warn _tr("unable to mount '%s' (%s)\n", "$osDir/dev/pts", $!);
        }
    }

    return 1;
}

sub finishSession
{
    my $self = shift;
    
    # umount /proc, /dev/pts (if we have 'umount' available)
    if (qx{which umount 2>/dev/null}) {
        if (slxsystem("umount /proc")) {
            warn _tr("unable to umount '%s' (%s)\n", "/proc", $!);
        }
        if (slxsystem("umount /dev/pts")) {
            warn _tr("unable to umount '%s' (%s)\n", "/dev/pts", $!);
        }
    }

    return 1;
}

sub getDefaultPathList
{
    my $self = shift;
    
    return [ qw(
        /sbin
        /usr/sbin
        /usr/local/sbin
        /usr/local/bin
        /usr/bin
        /bin
        /usr/bin/X11
        /usr/X11R6/bin
        /opt/kde3/bin
        /opt/gnome/bin
    ) ];
}

sub updateDistroConfig
{
    if (slxsystem("ldconfig")) {
        die _tr("unable to run ldconfig (%s)", $!);
    }
}

sub pickKernelFile
{
    my $self       = shift;
    my $kernelPath = shift;

    my $newestKernelFile;
    my $newestKernelFileSortKey = '';
    my $kernelPattern = '{vmlinuz,kernel-genkernel-x86}-*';
    foreach my $kernelFile (glob("$kernelPath/$kernelPattern")) {
        next unless $kernelFile =~ m{
            (?:vmlinuz|x86)-(\d+)\.(\d+)\.(\d+)(?:\.(\d+))?-(\d+(?:\.\d+)?)
        }x;
        my $sortKey 
            = sprintf("%02d.%02d.%02d.%02d-%2.1f", $1, $2, $3, $4||0, $5);
        if ($newestKernelFileSortKey lt $sortKey) {
            $newestKernelFile        = $kernelFile;
            $newestKernelFileSortKey = $sortKey;
        }
    }

    if (!defined $newestKernelFile) {
        die _tr("unable to pick a kernel-file from path '%s'!", $kernelPath);
    }
    return $newestKernelFile;
}

sub preSystemInstallationHook
{
}

sub postSystemInstallationHook
{
}

sub setPasswordForUser
{
    my $self = shift;
    my $username = shift;
    my $password = shift;
    
    my $hashedPassword = $self->hashPassword($password);

    my $writePasswordFunction = sub {
        # now read, change and write shadow-file in atomic manner:
        my $shadowFile = '/etc/shadow';
        if (!-e $shadowFile) {
            spitFile( $shadowFile, '');
        }
        slxsystem("cp -r $shadowFile $shadowFile~");
        my $shadowFH;
        open($shadowFH, '+<', $shadowFile)
            or croak _tr("could not open file '%s'! (%s)", $shadowFile, $!);
        flock($shadowFH, LOCK_EX)
            or croak _tr("could not lock file '%s'! (%s)", $shadowFile, $!);
        my $lastChanged = int(time()/24/60/60);
        my $newEntry 
            = "$username:$hashedPassword:$lastChanged:0:99999:7:::";
        my $content = do { local $/; <$shadowFH> };
        if ($content =~ m{^$username:}ims) {
            $content =~ s{^$username:.+?$}{$newEntry}ms;
        } else {
            $content .= "$newEntry\n";
        }
        seek($shadowFH, 0, 0)
            or croak _tr("could not seek file '%s'! (%s)", $shadowFile, $!);
        print $shadowFH $content
            or croak _tr("could not write to file '%s'! (%s)", $shadowFile, $!);
        close($shadowFH)
            or croak _tr("could not close file '%s'! (%s)", $shadowFile, $!);
        unlink "$shadowFile~";
    };
    $self->{engine}->callChrootedFunctionForVendorOS($writePasswordFunction);
}

sub hashPassword
{
    my $self = shift;
    my $password = shift;
    
    my $busyboxBin = $self->{engine}->busyboxBinary();
    my $hashedPassword = qx{$busyboxBin cryptpw -a md5 $password};
    chomp $hashedPassword;

    return $hashedPassword;
}

1;
################################################################################

=pod

=head1 NAME

OpenSLX::OSSetup::System::Base - the base class for all OSSetup backends

=head1 SYNOPSIS

  package OpenSLX::OSSetup::coolnewOS;

  use vars qw(@ISA $VERSION);
  @ISA = ('OpenSLX::OSSetup::Base');
  $VERSION = 1.01;

  use coolnewOS;

  sub new
  {
      my $class = shift;
      my $self = {};
      return bless $self, $class;
  }

  # override all methods of OpenSLX::OSSetup::Base in order to implement
  # a full OS-setup backend
  ...

I<The synopsis above outlines a class that implements a
OSSetup backend for the (imaginary) operating system B<coolnewOS>>

=head1 DESCRIPTION

This class defines the OSSetup interface for the OpenSLX.

Aim of the OSSetup abstraction is to make it possible to install a large set
of different operating systems transparently.

...

=cut
