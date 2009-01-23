# Copyright (c) 2006-2008 - OpenSLX GmbH
#
# This program is free software distributed under the GPL version 2.
# See http://openslx.org/COPYING
#
# If you have any feedback please consult http://openslx.org/feedback and
# send your suggestions, praise, or complaints to feedback@openslx.org
#
# General information about OpenSLX can be found at http://openslx.org/
# -----------------------------------------------------------------------------
# LibScanner.pm
#    - module that recursively scans a given binary for library dependencies
# -----------------------------------------------------------------------------
package OpenSLX::LibScanner;

use strict;
use warnings;

use File::Find;
use File::Path;

use OpenSLX::Basics;
use OpenSLX::Utils;

################################################################################
### interface methods
################################################################################
sub new
{
    my $class  = shift;
    my $params = shift || {};

    checkParams($params, { 
        'root-path' => '!',
        'verbose'   => '?',
    } );

    my $self = {
        rootPath => $params->{'root-path'},
        verbose  => $params->{'verbose'} || 0,
    };

    return bless $self, $class;
}

sub determineRequiredLibs
{
    my $self     = shift;
    my @binaries = @_;

    $self->{filesToDo}  = [];
    $self->{libs}       = [];
    $self->{libInfo}    = {};

    $self->_fetchLoaderConfig();
    
    foreach my $binary (@binaries) {
        if (substr($binary, 0, 1) ne '/') {
            # force relative paths relative to $rootPath:
            $binary = "$self->{rootPath}/$binary";
        }
        if (!-e $binary) {
            warn _tr("$0: unable to find file '%s', skipping it\n", $binary);
            next;
        }
        push @{$self->{filesToDo}}, $binary;
    }
    
    foreach my $file (@{$self->{filesToDo}}) {
        $self->_addLibsForBinary($file);
    }

    return @{$self->{libs}};
}

sub _fetchLoaderConfig
{
    my $self = shift;

    my @libFolders;

    if (!-e "$self->{rootPath}/etc") {
        die _tr("'%s'-folder not found, maybe wrong root-path?\n",
            "$self->{rootPath}/etc");
    }
    $self->_fetchLoaderConfigFile("$self->{rootPath}/etc/ld.so.conf");

    # add "trusted" folders /lib and /usr/lib if not already in place:
    if (!grep { m[^$self->{rootPath}/lib$] } @libFolders) {
        push @libFolders, "$self->{rootPath}/lib";
    }
    if (!grep { m[^$self->{rootPath}/usr/lib$] } @libFolders) {
        push @libFolders, "$self->{rootPath}/usr/lib";
    }

    # add lib32-folders for 64-bit Debians, as they do not
    # refer those in ld.so.conf (which I find strange...)
    if (-e '/lib32' && !grep { m[^$self->{rootPath}/lib32$] } @libFolders) {
        push @libFolders, "$self->{rootPath}/lib32";
    }
    if (-e '/usr/lib32'
        && !grep { m[^$self->{rootPath}/usr/lib32$] } @libFolders)
    {
        push @libFolders, "$self->{rootPath}/usr/lib32";
    }

    push @{$self->{libFolders}}, @libFolders;

    return;
}

sub _fetchLoaderConfigFile
{
    my $self       = shift;
    my $ldConfFile = shift;

    return unless -e $ldConfFile;
    my $ldconfFH;
    if (!open($ldconfFH, '<', $ldConfFile)) {
        warn(_tr("unable to open file '%s' (%s)", $ldConfFile, $!));
        return;
    }
    while (<$ldconfFH>) {
        chomp;
        if (m{^\s*include\s+(.+?)\s*$}i) {
            my @incFiles = glob("$self->{rootPath}$1");
            foreach my $incFile (@incFiles) {
                if ($incFile) {
                    $self->_fetchLoaderConfigFile($incFile);
                }
            }
            next;
        }
        if (m{\S+}i) {
            s[=.+][];
            # remove any lib-type specifications (e.g. '=libc5')
            push @{$self->{libFolders}}, "$self->{rootPath}$_";
        }
    }
    close $ldconfFH
        or die(_tr("unable to close file '%s' (%s)", $ldConfFile, $!));
    return;
}

sub _addLibsForBinary
{
    my $self   = shift;
    my $binary = shift;

    # first do some checks:
    warn _tr("analyzing '%s'...\n", $binary) if $self->{verbose};
    my $fileInfo = `file --dereference --brief --mime $binary 2>/dev/null`;
    if ($?) {
        die _tr("unable to fetch file info for '%s', giving up!\n", $binary);
    }
    chomp $fileInfo;
    warn _tr("\tinfo is: '%s'...\n", $fileInfo) if $self->{verbose};
    if ($fileInfo !~ m[^application/(x-executable|x-shared)]i) {
        # ignore anything that's not an executable or a shared library
        warn _tr(
            "%s: ignored, as it isn't an executable or a shared library\n",
            $binary
        );
        next;
    }

    # fetch file info again, this time without '--mime' in order to get the architecture
    # bitwidth:
    $fileInfo = `file --dereference --brief $binary 2>/dev/null`;
    if ($?) {
        die _tr("unable to fetch file info for '%s', giving up!\n", $binary);
    }
    chomp $fileInfo;
    warn _tr("\tinfo is: '%s'...\n", $fileInfo) if $self->{verbose};
    my $bitwidth = ($fileInfo =~ m[64-bit]i) ? 64 : 32;
    # determine whether binary is 32- or 64-bit platform

    # now find out about needed libs, we first try objdump...
    warn _tr("\ttrying objdump...\n") if $self->{verbose};
    my $res = `objdump -p $binary 2>/dev/null`;
    if (!$?) {
        # find out if rpath is set for binary:
        my $rpath;
        if ($res =~ m[^\s*RPATH\s*(\S+)]im) {
            $rpath = $1;
            warn _tr("\trpath='%s'\n", $rpath) if $self->{verbose};
        }
        while ($res =~ m[^\s*NEEDED\s*(.+?)\s*$]gm) {
            $self->_addLib($1, $bitwidth, $rpath);
        }
    } else {
        # ...objdump failed, so we try readelf instead:
        warn _tr("\ttrying readelf...\n") if $self->{verbose};
        $res = `readelf -d $binary 2>/dev/null`;
        if ($?) {
            die _tr(
                "neither objdump nor readelf seems to be installed, giving up!\n"
            );
        }
        # find out if rpath is set for binary:
        my $rpath;
        if ($res =~ m{Library\s*rpath:\s*\[([^\]]+)}im) {
            $rpath = $1;
            warn _tr("\trpath='%s'\n", $rpath) if $self->{verbose};
        }
        while ($res =~ m{\(NEEDED\)[^\[]+\[(.+?)\]\s*$}gm) {
            $self->_addLib($1, $bitwidth, $rpath);
        }
    }
    return;
}

sub _addLib
{
    my $self     = shift;
    my $lib      = shift;
    my $bitwidth = shift;
    my $rpath    = shift;

    if (!exists $self->{libInfo}->{$lib}) {
        my $libPath;
        my @folders = @{$self->{libFolders}};
        if (defined $rpath) {
            # add rpath if given (explicit paths set during link stage)
            push @folders, split ':', $rpath;
        }
        foreach my $folder (@folders) {
            if (-e "$folder/$lib") {
                # have library matching name, now check if the platform is ok, too:
                my $libFileInfo =
                  `file --dereference --brief $folder/$lib 2>/dev/null`;
                if ($?) {
                    die _tr("unable to fetch file info for '%s', giving up!\n",
                        $folder / $lib);
                }
                my $libBitwidth = ($libFileInfo =~ m[64-bit]i) ? 64 : 32;
                if ($bitwidth != $libBitwidth) {
                    vlog(
                        0,
                        _tr(
                            '%s has wrong bitwidth (%s instead of %s)',
                            "$folder/$lib", $libBitwidth, $bitwidth
                        )
                    ) if $self->{verbose};
                    next;
                }
                $libPath = "$folder/$lib";
                last;
            }
        }
        if (!defined $libPath) {
            die _tr("unable to find lib %s!\n", $lib);
        }
        print "found $libPath\n" if $self->{verbose};
        push @{$self->{libs}}, $libPath;
        $self->{libInfo}->{$lib} = 1;
        push @{$self->{filesToDo}}, $libPath;
    }
    return;
}

1;
