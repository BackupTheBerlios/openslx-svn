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
# Ubuntu.pm
#    - provides ubuntu specific functions for distro based utils for OpenSLX
# -----------------------------------------------------------------------------
package OpenSLX::DistroUtils::Ubuntu;

use strict;
use warnings;
use Switch;
    
use base qw(OpenSLX::DistroUtils::Base);

sub _getInitsystemIncludes
{
    return ". /lib/lsb/init-functions\n\n";
}

sub _renderCasePrefix
{
    return "";
}

sub _renderFooter
{
    return "exit 0\n";
}


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
                $tpl .= "if [ -f /etc/default/%s ]; then . /etc/default/%s; fi \n";
                $initFile->addToBlock('head',
                    sprintf(
                        $tpl,
                        uc($shortname),
                        $element->{parameters},
                        $shortname,
                        $shortname
                    )
                );
                
                
                $tpl  = "log_daemon_msg \"Starting %s\" \"%s\" \n";
                $tpl .= "start-stop-daemon --start --quiet --oknodo ";
                $tpl .= "--pidfile /var/run/%s.pid --exec %s -- \$%s_PARAMS \n";
                $tpl .= "log_end_msg \$?";
                $initFile->addToCase('start',
                    sprintf(
                        $tpl,
                        $element->{description},
                        $shortname,
                        $shortname,
                        $element->{binary},
                        uc($shortname)
                    )
                );
                
                $tpl  = "start-stop-daemon --stop --quiet --oknodo ";
                $tpl .= "--pidfile /var/run/%s.pid \n";
                $tpl .= "log_end_msg \$?";
                $initFile->addToCase('stop',
                    sprintf(
                        $tpl,
                        $shortname
                    )
                );
                
                
            }
        }
    }
    
}

1;