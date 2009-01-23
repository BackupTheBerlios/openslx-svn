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

use OpenSLX::Basics;

sub _loadPerlHeader
{
    my @phFiles = @_;

    for my $phFile (@phFiles) {
        if (!eval { require $phFile }) {
            # perl-header has not been provided by host-OS, so we create it
            # manually from C-header (via h2ph):
            (my $hFile = $phFile) =~ s{\.ph$}{.h};
            if (-e "/usr/include/$hFile") {
                my $libDir = "$openslxConfig{'base-path'}/lib";
                slxsystem("cd /usr/include && h2ph -d $libDir $hFile") == 0
                    or die _tr('unable to create %s! (%s)', $phFile, $!);
            }
        }
        return 1 if eval { require $phFile; 1 };
    }
    die _tr(
        'unable to load any of these perl headers: %s', join(',', @phFiles)
    );
}

sub enter32BitPersonality
{
    _loadPerlHeader('syscall.ph');
    _loadPerlHeader('linux/personality.ph', 'sys/personality.ph');

    syscall(&SYS_personality, PER_LINUX32()) != -1
        or warn _tr("unable to invoke syscall '%s'! ($!)", 'personality');

    return;
}

1;
