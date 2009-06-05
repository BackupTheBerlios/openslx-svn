# Copyright (c) 2008, 2009 - OpenSLX GmbH
#
# This program is free software distributed under the GPL version 2.
# See http://openslx.org/COPYING
#
# If you have any feedback please consult http://openslx.org/feedback and
# send your suggestions, praise, or complaints to feedback@openslx.org
#
# General information about OpenSLX can be found at http://openslx.org/
# -----------------------------------------------------------------------------
# Engine.pm
#    - provides engine to distro based utils for OpenSLX
# -----------------------------------------------------------------------------
package OpenSLX::DistroUtils::Engine;

use OpenSLX::Basics;
use Data::Dumper;

use strict;
use warnings;

sub new
{
    my $class = shift;
    my $self = {};
    return bless $self, $class;
}


sub loadDistro {
    my $self = shift;
    my $distroName = shift;
       $distroName = ucfirst($distroName);
    
    my $distro;
    
    my $pathToClass = "$openslxConfig{'base-path'}/lib";
    my $flags = {};
    #$flags->{incPaths} = [ $pathToClass, "/mnt/$pathToClass" ];
    # for the case we call this function inside the chrooted environment of a plugin's
    # install method we add the corrected searchpath to INC
    # TODO: fix this problem via plugin engine
    
    print 'DUMP INC 2';
    print Dumper(@INC);
    my $loaded = eval {
            $distro = instantiateClass("OpenSLX::DistroUtils::${distroName}", $flags);
            return 0 if !$distro;   # module does not exist, try next
            1;
        };
        
    if (!$loaded) {
    	vlog(1, "can't find distro specific class, try base class..");
        $loaded = eval {
            $distro = instantiateClass("OpenSLX::DistroUtils::Base", $flags);
            return 0 if !$distro;   # module does not exist, try next
            1;
        };
    }
    
    if (!$loaded) {
        vlog(1, "failed to load DistroUtils!");
        vlog(1, $distroName);
    }

    return $distro;
}

1;
