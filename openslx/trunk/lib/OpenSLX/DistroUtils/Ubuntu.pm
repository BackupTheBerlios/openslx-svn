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
# Ubuntu.pm
#    - provides ubuntu specific functions for distro based utils for OpenSLX
# -----------------------------------------------------------------------------
package OpenSLX::DistroUtils::Ubuntu;

use strict;
use warnings;
use Switch;
    
use base qw(OpenSLX::DistroUtils::Base);

sub _renderHighlevelConfig {
    my $self = shift;
    my $initFile = shift;
    
    my $element;
    my $hlc = $initFile->{'configHash'}->{'highlevelConfig'};
    
    while ( $element = shift(@$hlc)){
        switch ($element->{type}) {
            case 'daemon' {
                $element->{binary} =~ m/\/([^\/]*)$/;
                my $shortname = $1;
                my $tpl  = "export %s_PARAMS=\"%s\" \n";
                $tpl .= "[ -f /etc/default/%s ] . /etc/default/%s \n";
                $initFile->addToBlock('head',
                    sprintf(
                        $tpl,
                        uc($shortname),
                        $element->{parameters},
                        $shortname,
                        $shortname
                    )
                );
                
                
                $tpl  = "start-stop-daemon --start --quiet --oknodo ";
                $tpl .= "--pidfile /var/run/%s.pid --exec %s -- \$%s_PARAMS \n";
                $tpl .= "log_end_msg \$?";
                $initFile->addToBlock('start',
                    sprintf(
                        $tpl,
                        $shortname,
                        $element->{binary},
                        uc($shortname)
                    )
                );
                
                $tpl  = "start-stop-daemon --stop --quiet --oknodo ";
                $tpl .= "--pidfile /var/run/%s.pid \n";
                $tpl .= "log_end_msg \$?";
                $initFile->addToBlock('stop',
                    sprintf(
                        $tpl,
                        $shortname
                    )
                );
                
                
            }
        }
    }
    
}

sub generateInitFile
{
    my $self = shift;
    my $initFile = shift;
    
    $initFile->addToBlock('head', '#ubuntu test');
    
    $self->_renderHighlevelConfig($initFile);

    return $self->SUPER::generateInitFile($initFile);
}

1;