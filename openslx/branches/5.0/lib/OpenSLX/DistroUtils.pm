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
# DistroUtils.pm
#    - provides utility distro based functions for OpenSLX
# -----------------------------------------------------------------------------
package OpenSLX::DistroUtils;

use strict;
use warnings;

use OpenSLX::Utils;
use OpenSLX::Basics;

use OpenSLX::DistroUtils::Engine;
use OpenSLX::DistroUtils::InitFile;

use Exporter;

use vars qw(@ISA @EXPORT $VERSION);

use Exporter;
$VERSION = 1.01;
@ISA     = qw(Exporter);

@EXPORT = qw(
  newInitFile
  getInitFileForDistro
  simpleInitFile
);



sub newInitFile {
    return OpenSLX::DistroUtils::InitFile->new();
}


sub simpleInitFile {
    my $config = shift;
    my $initFile = OpenSLX::DistroUtils::InitFile->new();
    
    return $initFile->simpleSetup($config);
}


sub getInitFileForDistro {
    my $initFile = shift;
    my $distroName = shift;
    
    my $engine = OpenSLX::DistroUtils::Engine->new();
    my $distro = $engine->loadDistro($distroName);
    
    return $distro->generateInitFile($initFile);
}




1;
