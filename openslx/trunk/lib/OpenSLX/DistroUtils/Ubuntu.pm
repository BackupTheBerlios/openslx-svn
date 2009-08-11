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

                $tpl  = "log_daemon_msg \"Restarting %s\" \"%s\"\n";
                $tpl .= "\$0 stop\n";
                $tpl .= "case \"\$?\" in\n";
                $tpl .= "   0|1)\n";
                $tpl .= "   \$0 start\n";
                $tpl .= "   case \"\$?\" in\n";
                $tpl .= "       0) log_end_msg 0 ;;\n";
                $tpl .= "       1) log_end_msg 1 ;; # Old process is still running\n";
                $tpl .= "       *) log_end_msg 1 ;; # Failed to start\n";
                $tpl .= "   esac\n";
                $tpl .= "   ;;\n";
                $tpl .= "   *)\n";
                $tpl .= "       # Failed to stop\n";
                $tpl .= "       log_end_msg 1\n";
                $tpl .= "       ;;\n";
                $tpl .= "esac\n";
                $tpl .= ";;\n";
                
                $initFile->addToCase('restart',
                    sprintf(
                        $tpl,
                        $shortname
                    )
                );
   
                
                $tpl  = "start-stop-daemon --stop --signal 1 --quiet ";
                $tpl .= "--pidfile /var/run/%s.pid --name \$s\n";
                $tpl .= "return 0\n";
                $initFile->addToCase('reload',
                    sprintf(
                        $tpl,
                        $shortname,
                        $element->{binary}
                    )
                );

                $tpl  = "status_of_proc -p /var/run/%s.pid %s_BIN %s && exit 0 || exit \$?";
                $initFile->addToCase('status',
                    sprintf(
                        $tpl,
                        $element->{shortname},
                        $element->{binary},
                        $element->{shortname}
                    )
                );
                
                
            }
            case 'function' {
                my $tpl;
                $tpl  = "%s () { \n";
                $tpl .= "%s";
                $tpl .= "\n}\n";
                $initFile->addToBlock('functions',
                    sprintf(
                        $tpl,
                        $element->{name},
                        $element->{script}
                    )
                );
                    
            }
            case 'functionCall' {
                my $tpl;
                $tpl  = "%s %s\n";
                #$tpl .= "%s\n ";
                $initFile->addToCase($element->{block},
                    sprintf(
                        $tpl,
                        $element->{function},
                        $element->{parameters},
                        ""
                    ),
                    $element->{priority}
                );
                    
            }
            
        }
    }
    
}

1;