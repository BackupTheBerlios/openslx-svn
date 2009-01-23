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
# PerlHeaders.pm
#    - provides automatic generation of required perl headers (for syscalls)
# -----------------------------------------------------------------------------
package OpenSLX::Syscall;

use strict;
use warnings;

our $VERSION = 1.01;

=head1 NAME

OpenSLX::Syscall - provides wrapper functions for syscalls.

=head1 DESCRIPTION

This module exports one wrapper function for each syscall that OpenSLX is
using. Each of these functions takes care to load all required Perl-headers
before trying to invoke the respective syscall.

=cut

use Config;
use File::Path;

use OpenSLX::Basics;

=head1 PUBLIC FUNCTIONS

=over

=item B<enter32BitPersonality()>

Invokes the I<personality()> syscall in order to enter the 32-bit personality
(C<PER_LINUX32>).

=cut

sub enter32BitPersonality
{
    _loadPerlHeader('syscall.ph');
    _loadPerlHeader('linux/personality.ph', 'sys/personality.ph');

    syscall(&SYS_personality, PER_LINUX32()) != -1
        or warn _tr("unable to invoke syscall '%s'! ($!)", 'personality');

    return;
}

sub _loadPerlHeader
{
    my @phFiles = @_;

    my @alreadyLoaded = grep { exists $INC{$_} } @phFiles;
    return if @alreadyLoaded;

    my $phLibDir = $Config{installsitearch};
    local @INC = @INC;
    push @INC, "$phLibDir/asm";

    # Unability to load an existing Perl header may be caused by missing 
    # asm-(kernel-)headers, since for instance openSUSE 11 does not provide 
    # any of these).
    # If they are missing, we just have a go at creating all of them:
    mkpath($phLibDir) unless -e $phLibDir;
    if (-l "/usr/include/asm" && !-e "$phLibDir/asm") {
        my $asmFolder = readlink("/usr/include/asm");
        slxsystem("cd /usr/include && h2ph -rQ -d $phLibDir $asmFolder") == 0
            or die _tr('unable to create Perl-header from "asm" folder! (%s)', $!);
        slxsystem("mv $phLibDir/$asmFolder $phLibDir/asm") == 0
            or die _tr('unable to cleanup "asm" folder for Perl headers! (%s)', $!);
    }
    elsif (-d "/usr/include/asm") {
        slxsystem("cd /usr/include && h2ph -rQ -d $phLibDir asm") == 0
            or die _tr('unable to create Perl-header from "asm" folder! (%s)', $!);
    }
    else {
        die _tr(
            'the folder "/usr/include/asm" is required - please install kernel headers!'
        );
    }
    if (-e "usr/include/asm-generic" && !-e "$phLibDir/asm-generic") {
        slxsystem("cd /usr/include && h2ph -rQ -d $phLibDir asm-generic") == 0
            or die _tr('unable to create Perl-header from "asm-generic" folder! (%s)', $!);
    }

    for my $phFile (@phFiles) {
        return 1 if eval { require $phFile };

        warn(_tr(
            'unable to load Perl-header "%s", trying to create it ...', 
            $phFile
        ));

        # perl-header has not been provided by host-OS, so we create it
        # manually from C-header (via h2ph):
        (my $hFile = $phFile) =~ s{\.ph$}{.h};
        if (-e "/usr/include/$hFile") {
            slxsystem("cd /usr/include && h2ph -aQ -d $phLibDir $hFile") == 0
                or die _tr('unable to create %s! (%s)', $phFile, $!);
        }

        return 1 if eval { require $phFile };
    }

    die _tr(
        'unable to load any of these perl headers: %s (%s)', 
        join(',', @phFiles), $@
    );
}

=back

=cut

1;
