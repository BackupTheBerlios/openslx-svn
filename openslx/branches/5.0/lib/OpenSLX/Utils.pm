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
# Utils.pm
#    - provides utility functions for OpenSLX
# -----------------------------------------------------------------------------
package OpenSLX::Utils;

use strict;
use warnings;

use vars qw(@ISA @EXPORT $VERSION);

use Exporter;
$VERSION = 1.01;
@ISA     = qw(Exporter);

@EXPORT = qw(
    copyFile fakeFile linkFile 
    copyBinaryWithRequiredLibs
    slurpFile spitFile appendFile
    followLink 
    unshiftHereDoc
    string2Array
    chrootInto
    mergeHash
    getFQDN
    readPassword
    hostIs64Bit
    getAvailableBusyboxApplets
    grabLock
    pathOf
    isInPath
);

=head1 NAME

OpenSLX::Utils - provides utility functions for OpenSLX.

=head1 DESCRIPTION

This module exports utility functions, which are expected to be used all across
OpenSLX.

=cut

use Fcntl qw(:DEFAULT :flock);
use File::Basename;
use File::Path;
use Socket;
use Sys::Hostname;
use Term::ReadLine;

use OpenSLX::Basics;
use OpenSLX::ScopedResource;

=head1 PUBLIC FUNCTIONS

=over

=item B<copyFile($fileName, $targetDir, $targetFileName)>

Copies the file specified by I<$fileName> to the folder I<$targetDir>,
preserving the permissions and optionally renaming it to I<$targetFileName> 
during the process.

If I<$targetDir> does not exist yet, it will be created.

=cut

sub copyFile
{
    my $fileName       = shift || croak 'need to pass in a fileName!';
    my $targetDir      = shift || croak 'need to pass in target dir!';
    my $targetFileName = shift || '';

    mkpath($targetDir) unless -d $targetDir;
    my $target = "$targetDir/$targetFileName";
    vlog(2, _tr("copying '%s' to '%s'", $fileName, $target));
    if (system("cp -p $fileName $target")) {
        croak(
            _tr(
                "unable to copy file '%s' to dir '%s' (%s)",
                $fileName, $target, $!
            )
        );
    }
    return;
}

=item B<fakeFile($fullPath)>

Creates the (empty) file I<$fullPath> unless it already exists.

If the parent directory of I<$fullPath> does not exist yet, it will be created.

=cut

sub fakeFile
{
    my $fullPath = shift || croak 'need to pass in full path!';

    return if -e $fullPath;

    my $targetDir = dirname($fullPath);
    mkpath($targetDir) unless -d $targetDir;

    if (system("touch", $fullPath)) {
        croak(_tr("unable to create file '%s' (%s)", $fullPath, $!));
    }
    return;
}

=item B<linkFile($linkTarget, $linkName)>

Creates the link I<$linkName> that points to I<$linkTarget>. 

If the directory where the new link shall live does not exist yet, it will be 
created.

=cut

sub linkFile
{
    my $linkTarget = shift || croak 'need to pass in link target!';
    my $linkName   = shift || croak 'need to pass in link name!';

    my $targetDir = dirname($linkName);
    mkpath($targetDir) unless -d $targetDir;
    if (system("ln -sfn $linkTarget $linkName")) {
        croak(
            _tr(
                "unable to create link '%s' to '%s' (%s)",
                $linkName, $linkTarget, $!
            )
        );
    }
    return;
}

=item B<slurpFile($fileName, $flags)>

Reads the file specified by <$fileName> and returns the contents.

The optional hash-ref I<$flags> supports the following entries:

=over

=item failIfMissing

Specifies what shall happen if the file does not exist: die (failIfMissing == 1)
or return an empty string (failIfMissing == 0). Defaults to 1.

=item io-layer

Specifies the Perl-IO-layer that shall be applied to the file (defaults to 
'utf8').

=back

=cut

sub slurpFile
{
    my $fileName = shift || confess 'need to pass in fileName!';
    my $flags    = shift || {};

    checkParams($flags, { 
        'failIfMissing' => '?',
        'io-layer' => '?',
    });
    my $failIfMissing 
        = exists $flags->{failIfMissing} ? $flags->{failIfMissing} : 1;
    my $ioLayer = $flags->{'io-layer'} || 'utf8';

    my $fh;
    if (!open($fh, "<:$ioLayer", $fileName)) {
        return '' unless $failIfMissing;
        croak _tr("could not open file '%s' for reading! (%s)", $fileName, $!);
    }
    if (wantarray()) {
        my @content = <$fh>;
        close($fh)
          or croak _tr("unable to close file '%s' (%s)\n", $fileName, $!);
        return @content;
    }
    else  {
        local $/;
        my $content = <$fh>;
        close($fh)
          or croak _tr("unable to close file '%s' (%s)\n", $fileName, $!);
        return $content;
    }
}

=item B<spitFile($fileName, $content, $flags)>

Writes the given I<$content> to the file specified by <$fileName>, creating
the file (and any missing directories) if it does not exist yet.

The optional hash-ref I<$flags> supports the following entries:

=over

=item io-layer

Specifies the Perl-IO-layer that shall be applied to the file (defaults to 
'utf8').

=item mode

Specifies the file mode that shall be applied to the file (via chmod).

=back

=cut

sub spitFile
{
    my $fileName = shift || croak 'need to pass in a fileName!';
    my $content  = shift || '';
    my $flags    = shift || {};

    checkParams($flags, { 
        'io-layer' => '?',
        'mode'     => '?',
    });
    my $ioLayer = $flags->{'io-layer'} || 'utf8';

    my $targetDir = dirname($fileName);
    mkpath($targetDir) unless -d $targetDir;

    my $fh;
    open($fh, ">:$ioLayer", $fileName)
        or croak _tr("unable to create file '%s' (%s)\n", $fileName, $!);
    print $fh $content
        or croak _tr("unable to print to file '%s' (%s)\n", $fileName, $!);
    close($fh)
        or croak _tr("unable to close file '%s' (%s)\n", $fileName, $!);
    if (defined $flags->{mode}) {
        chmod $flags->{mode}, $fileName;
    }
    return;
}

=item B<appendFile($fileName, $content, $flags)>

Appends the given I<$content> to the file specified by <$fileName>, creating
the file (and any missing directories) if it does not exist yet.

The optional hash-ref I<$flags> supports the following entries:

=over

=item io-layer

Specifies the Perl-IO-layer that shall be applied to the file (defaults to 
'utf8').

=back

=cut

sub appendFile
{
    my $fileName = shift || croak 'need to pass in a fileName!';
    my $content  = shift;
    my $flags    = shift || {};

    checkParams($flags, { 
        'io-layer' => '?',
    });
    my $ioLayer = $flags->{'io-layer'} || 'utf8';

    my $targetDir = dirname($fileName);
    mkpath($targetDir) unless -d $targetDir;

    my $fh;
    open($fh, ">>:$ioLayer", $fileName)
      or croak _tr("unable to create file '%s' (%s)\n", $fileName, $!);
    print $fh $content
      or croak _tr("unable to print to file '%s' (%s)\n", $fileName, $!);
    close($fh)
      or croak _tr("unable to close file '%s' (%s)\n", $fileName, $!);
    return;
}

=item B<followLink($path, $prefixedPath)>

Deeply traverses the given I<$path> until it no longer contains a link and
returns the resulting file or directory.

If you pass in a I<$prefixedPath>, each link will be resolved relatively to
that path (useful for example with respect to chroot-environments).

=cut

sub followLink
{
    my $path         = shift || croak 'need to pass in a path!';
    my $prefixedPath = shift || '';

    my $target;
    while (-l "$path") {
        $target = readlink "$path";
        if (substr($target, 0, 1) eq '/') {
            $path = "$prefixedPath$target";
        }
        else {
            $path = $prefixedPath . dirname($path) . '/' . $target;
        }
    }
    return $path;
}

=item B<copyBinaryWithRequiredLibs($params)>

Copies a binary to a specified folder, taking along all the libraries that
are required by this binary.

The hash-ref I<$params> supports the following entries:

=over

=item binary

The full path to the binary that shall be copied.

=item targetFolder

The full path to the folder where the binary shall be copied to.

=item libTargetFolder

Defines a path relatively to which all required libs will be copied to. 

An example: during execution of 

    copyBinaryWithRequiredLibs({
        binary          => '/bin/ls',
        targetFolder    => '/tmp/slx-initramfs/bin',
        libTargetFolder => '/tmp/slx-initramfs',
    });

the library C<lib/libc-2.6.1.so> will be copied to 
C</tmp/slx-initramfs/lib/libc-2.6.1.so>.

=item targetName   [optional]

If you'd like to rename the binary while copying, you can specify the new name
in this entry.

=back

=cut

sub copyBinaryWithRequiredLibs {
    my $params = shift;
    
    checkParams($params, {
        'binary'             => '!', # file to copy
        'targetFolder'    => '!',    # where file shall be copied to
        'libTargetFolder' => '!',    # base target folder for libs
        'targetName'      => '?',    # name of binary in target folder
    });
    copyFile($params->{binary}, $params->{targetFolder}, $params->{targetName});

    # determine all required libraries and copy those, too:
    vlog(1, _tr("calling slxldd for $params->{binary}"));
    my $slxlddCmd = "slxldd $params->{binary}";
    vlog(2, "executing: $slxlddCmd");
    my $requiredLibsStr = qx{$slxlddCmd};
    if ($?) {
        die _tr(
            "slxldd couldn't determine the libs required by '%s'! (%s)", 
            $params->{binary}, $?
        );
    }
    chomp $requiredLibsStr;
    vlog(2, "slxldd results:\n$requiredLibsStr");
    
    foreach my $lib (split "\n", $requiredLibsStr) {
        my $libDir = dirname($lib);
        my $targetLib = "$params->{libTargetFolder}$libDir";
        next if -e "$targetLib/$lib";
        vlog(3, "copying lib '$lib'");
        copyFile($lib, $targetLib);
    }
    return $requiredLibsStr;
}

=item B<unshiftHereDoc($content)>

Returns the here-doc (or string) given in I<$content> such that the leading
whitespace found on the first line will be removed from all lines.

As an example: if you pass in the string

        #!/bin/sh
        if [ -n "$be_nice" ]; then
          echo "bummer!" >/etc/passwd
        fi
        
you will get this:

#!/bin/sh
if [ -n "$be_nice" ]; then
  echo "bummer!" >/etc/passwd
fi

=cut

sub unshiftHereDoc
{
    my $content = shift;
    return $content unless $content =~ m{^(\s+)};
    my $shiftStr = $1;
    $content =~ s[^$shiftStr][]gms;
    return $content;
}

=item B<string2Array($string)>

Returns the given string split into an array, using newlines as separator.

In the resulting array, empty entries will have been removed and each entry
will be trimmed of leading or trailing whitespace and comments (lines starting
with a #).

=cut

sub string2Array
{
    my $string = shift || '';

    my @lines = split m[\n], $string;
    for my $line (@lines) {
        # remove leading and trailing whitespace:
        $line =~ s{^\s*(.*?)\s*$}{$1};
    }

    # drop empty lines and comments:
    return grep { length($_) > 0 && $_ !~ m[^\s*#]; } @lines;
}

=item B<chrootInto($osDir)>

Does a chroot() into the given directory (which is supposed to contain at
least the fragments of an operating system).

=cut

sub chrootInto
{
    my $osDir = shift;

    vlog(2, "chrooting into $osDir...");
    chdir $osDir
        or die _tr("unable to chdir into '%s' (%s)\n", $osDir, $!);

    # ...do chroot
    chroot "."
        or die _tr("unable to chroot into '%s' (%s)\n", $osDir, $!);
    return;
}

=item B<mergeHash($targetHash, $sourceHash, $fillOnly)>

Deeply copies values from I<$sourceHash> into I<$targetHash>. 

If you pass in 1 for I<$fillOnly>, only hash entries that do not exist in 
I<$targetHash> will be copied (C<Merge>-mode), otherwise all values from 
I<$sourceHash> will be copied over (C<Push>-mode).

Returns the resulting I<$targetHash> for convenience.

=cut

sub mergeHash
{
    my $targetHash = shift;
    my $sourceHash = shift;
    my $fillOnly   = shift || 0;
    
    foreach my $key (keys %{$sourceHash}) {
        my $sourceVal = $sourceHash->{$key};
        if (ref($sourceVal) eq 'HASH') {
            if (!exists $targetHash->{$key}) {
                $targetHash->{$key} = {};
            }
            mergeHash($targetHash->{$key}, $sourceVal);
        }
        elsif (ref($sourceVal) eq 'ARRAY') {
            if (!exists $targetHash->{$key}) {
                $targetHash->{$key} = [];
            }
            foreach my $val (@{$sourceHash->{$key}}) {
                my $targetVal = {};
                push @{$targetHash->{$key}}, $targetVal;
                mergeHash($targetVal, $sourceVal);
            }
        }
        else {
            next if $fillOnly && exists $targetHash->{$key};
            $targetHash->{$key} = $sourceVal;
        }
    }
    return $targetHash;
}

=item B<getFQDN()>

Determines the fully-qualified-domain-name (FQDN) of the computer executing
this function and returns it.

=cut

sub getFQDN
{
    my $hostName = hostname();
    
    my $hostAddr = gethostbyname($hostName)
        or die(_tr("unable to get address of host '%s'", $hostName));
    my $FQDN = gethostbyaddr($hostAddr, AF_INET)
        or die(_tr("unable to get dns-name of address '%s'", $hostAddr));
    return $FQDN;
}

=item B<readPassword($prompt)>

Outputs the given I<$prompt> and then reads a password from the terminal
(trying to make sure that the characters are not echoed in a readable form).

=cut

sub readPassword
{
    my $prompt = shift;
    
    my $term = Term::ReadLine->new('slx');
    my $attribs = $term->Attribs;
    $attribs->{redisplay_function} = $attribs->{shadow_redisplay};

    return $term->readline($prompt);
}

=item B<hostIs64Bit()>

Returns 1 if the host (the computer executing this function) is running a
64-bit OS, 0 if not (i.e. 32-bit).

=cut

sub hostIs64Bit
{
    my $arch = qx{uname -m};
    return $arch =~ m[64];
}

=item B<getAvailableBusyboxApplets()>

Returns the list of the applets that is provided by the given busybox binary.

=cut

sub getAvailableBusyboxApplets
{
    my $busyboxBinary = shift;

    my $busyboxHelp = qx{$busyboxBinary --help};
    if ($busyboxHelp !~ m{defined functions:(.+)\z}ims) {
        die "unable to parse busybox --help output:\n$busyboxHelp";
    }
    my $rawAppletList = $1;
    my @busyboxApplets 
        =    map {
                $_ =~ s{\s+}{}igms;
                $_;
            }
            split m{,}, $rawAppletList;
            
    return @busyboxApplets;
}

=item grabLock()

=cut

sub grabLock
{
    my $lockName = shift || die 'you need to pass a lock-name to grabLock()!';

    my $lockPath = "$openslxConfig{'private-path'}/locks";
    mkpath($lockPath) unless -e $lockPath;

    # drop any trailing slashes from lock name:
    $lockName =~ s{/+$}{};
    my $lockFile = "$lockPath/$lockName";

    my $lockFH;

    my $lock = OpenSLX::ScopedResource->new({
        name    => "lock::$lockName",
        acquire => sub { 
            # use a lock-file to implement the actual locking:
            if (-e $lockFile) {
                my $ctime = (stat($lockFile))[10];
                my $now   = time();
                if ($now - $ctime > 15 * 60) {
                    # existing lock file is older than 15 minutes, we consider
                    # that to be a leftover (which shouldn't happen of course)
                    # and wipe it:
                    unlink $lockFile;
                }
            }
            
            local $| = 1;
            my $waiting;
            while(!(sysopen($lockFH, $lockFile, O_RDWR | O_CREAT | O_EXCL)
                && syswrite($lockFH, getpgrp() . "\n"))) {
                if ($! == 13) {
                    die _tr(
                        qq[Unable to create lock "%s", giving up!], $lockFile
                    );
                } else {
                    # check if the lock is owned by our own process group
                    # and only block if it isn't (this allows recursive locking)
                    my $pgrpOfLock 
                        = slurpFile($lockFile, { failIfMissing => 0});
                    last if $pgrpOfLock && $pgrpOfLock == getpgrp();

                    # wait for lock to become available
                    if (!$waiting) {
                        print _tr('waiting for "%s"-lock ', $lockName);
                        $waiting = 1;
                    }
                    else {
                        print '.';
                    }
                    sleep(1);
                }
            }
            print "ok\n" if $waiting;
            1
        },
        release => sub {
            close($lockFH);
            unlink $lockFile;
            1
        },
    });
    
    return $lock;
}

=item B<pathOf()>

Returns the path of a binary it is installed in.

=cut

sub pathOf
{
    my $binary = shift;
    return qx{which $binary 2>/dev/null};
}

=item B<isInpath()>

Returns whether a binary is found.

=cut

sub isInPath
{
    my $binary = shift;
    my $path = pathOf($binary);

    return $path ? 1 : 0;
}


1;
