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
# qemukvm/OpenSLX/Distro/Base.pm
#    - provides base implementation of the Distro API for the qemukvm plugin.
# -----------------------------------------------------------------------------
package qemukvm::OpenSLX::Distro::Base;

use strict;
use warnings;

our $VERSION = 1.01;        # API-version . implementation-version

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
    my $self = shift;
    my $engine = shift;

    return 1;
}

sub fillRunlevelScript
{
    my $self     = shift;
    my $location = shift;
    my $kind     = shift;

    my $script = unshiftHereDoc(<<'    End-of-Here');

    # cpuvirt=$(grep -e "vmx|svm" /proc/cpuinfo)
    # modprobe $cpuvirt

    End-of-Here

    return $script;
}

1;
