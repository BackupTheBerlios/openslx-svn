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
# Suse.pm
#    - provides suse specific functions for distro based utils for OpenSLX
# -----------------------------------------------------------------------------
package OpenSLX::DistroUtils::Suse;

use strict;
use warnings;
use Switch;

use base qw(OpenSLX::DistroUtils::Base);


sub _renderCasePrefix
{
    return "rc_reset\n";
}

sub _renderFooter
{
    return "rc_exit\n";
}


sub _renderHighlevelConfig {
    my $self = shift;
    my $initFile = shift;
    
    my $element;
    my $hlc = $initFile->{'configHash'}->{'highlevelConfig'};
    
    while ( $element = shift(@$hlc)){
        switch ($element->{type}) {
            case 'daemon' {
                my $tpl;
                $tpl  = "%s_BIN=%s \n";
                $tpl .= "[ -x %s_BIN ] || exit 5\n\n";
                $tpl .= "%s_OPTS=\"%s\" \n";
                $tpl .= "[ -f /etc/sysconfig/%s ] . /etc/sysconfig/%s \n\n";
                $tpl .= "%s_PIDFILE=\"/var/run/%s.init.pid\" \n\n";
                $initFile->addToBlock('head',
                    sprintf(
                        $tpl,
                        uc($element->{shortname}),
                        $element->{binary},
                        uc($element->{shortname}),
                        uc($element->{shortname}),
                        $element->{parameters},
                        $element->{shortname},
                        $element->{shortname},
                        uc($element->{shortname}),
                        $element->{shortname}
                    )
                );
                
                $tpl  = "echo -n \"Starting %s \"\n";
                $tpl .= "startproc -f -p \$%s_PIDFILE \$%s_BIN \$%s_OPTS\n";
                $tpl .= "rc_status -v";
                $initFile->addToCase('start',
                    sprintf(
                        $tpl,
                        $element->{desc},
                        uc($element->{shortname}),
                        uc($element->{shortname}),
                        uc($element->{shortname})
                    )
                );

                $tpl  = "echo -n \"Shutting down %s\" \n";
                $tpl .= "killproc -p \$%s_PIDFILE -TERM \$%s_BIN\n";
                $tpl .= "rc_status -v";
                $initFile->addToCase('stop',
                    sprintf(
                        $tpl,
                        $element->{desc},
                        uc($element->{shortname}),
                        uc($element->{shortname})
                    )
                );
                
                $tpl  = "## Stop the service and if this succeeds (i.e. the \n";
                $tpl .= "## service was running before), start it again.\n";
                $tpl .= "\$0 status >/dev/null &&  \$0 restart\n\n";
                $tpl .= "# Remember status and be quiet\n";
                $tpl .= "rc_status";
                $initFile->addToCase('try-restart',
                    $tpl
                );

                $tpl  = "## Stop the service and regardless of whether it was \n";
                $tpl .= "## running or not, start it again.\n";
                $tpl .= "\$0 stop\n";
                $tpl .= "\$0 start\n\n";
                $tpl .= "# Remember status and be quiet\n";
                $tpl .= "rc_status";
                $initFile->addToCase('restart',
                    $tpl
                );
                
                $tpl  = "echo -n \"Reload service %s\"\n";
                $tpl .= "killproc -p \$%s_PIDFILE -HUP \$%s_BIN\n";
                $tpl .= "rc_status -v";
                $initFile->addToCase('reload',
                    sprintf(
                        $tpl,
                        $element->{desc},
                        uc($element->{shortname}),
                        uc($element->{shortname}),
                        uc($element->{shortname})
                    )
                );

                $tpl  = "echo -n \"Checking for service %s\"\n";
                $tpl .= "checkproc -p \$%s_PIDFILE \$%s_BIN\n";
                $tpl .= "rc_status -v";
                $initFile->addToCase('status',
                    sprintf(
                        $tpl,
                        $element->{desc},
                        uc($element->{shortname}),
                        uc($element->{shortname})
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

sub _getInitsystemIncludes
{
	return ". /etc/rc.status\n\n";
}

1;