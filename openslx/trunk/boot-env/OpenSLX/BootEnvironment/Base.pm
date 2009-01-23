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
# BootEnvironment::Base.pm
#    - provides empty base of the BootEnvironment API.
# -----------------------------------------------------------------------------
package OpenSLX::BootEnvironment::Base;

use strict;
use warnings;

our $VERSION = 1.01;        # API-version . implementation-version

use File::Path;

use OpenSLX::Basics;
use OpenSLX::ConfigDB;

sub new
{
    my $class  = shift;

    my $self = {};

    return bless $self, $class;
}

sub initialize
{
    my $self   = shift;
    my $params = shift;

    $self->{'dry-run'} = $params->{'dry-run'};

    return 1;
}

sub finalize
{
    my $self   = shift;
    my $delete = shift;

    return 1 if $self->{'dry-run'};
    
    my $rsyncDeleteClause = $delete ? '--delete' : '';
    my $rsyncCmd 
        = "rsync -a $rsyncDeleteClause --delay-updates $self->{'target-path'}/ $self->{'original-path'}/";
    slxsystem($rsyncCmd) == 0
        or die _tr(
            "unable to rsync files from '%s' to '%s'! (%s)", 
            $self->{'target-path'}, $self->{'original-path'}, $!
        );
    rmtree([$self->{'target-path'}]);

    return 1;
}

sub targetPath
{
    my $self = shift;
    
    return $self->{'target-path'};
}

sub writeBootloaderMenuFor
{
    my $self             = shift;
    my $client           = shift;
    my $externalClientID = shift;
    my $systemInfos      = shift;

    return;
}

sub writeFilesRequiredForBooting
{
    my $self          = shift;
    my $info          = shift;
    my $tftpbuildPath = shift;
    my $slxVersion    = shift;

    return;
}

1;
