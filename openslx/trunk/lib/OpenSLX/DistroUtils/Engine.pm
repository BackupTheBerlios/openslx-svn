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
    if ($pathToClass) {
        $flags->{incPaths} = [ $pathToClass ];
        # if you call this function inside a plugin's install method we have to add /mnt
        # in front of the include path!
        $flags->{incPaths} = [ "/mnt/$pathToClass" ];
    }
    
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
    }

    return $distro;
}

1;