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
# Suse.pm
#    - provides suse specific functions for distro based utils for OpenSLX
# -----------------------------------------------------------------------------
package OpenSLX::DistroUtils::Suse;

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
                $initFile->addToBlock('start',
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
                $initFile->addToBlock('stop',
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
                $initFile->addToBlock('try-restart',
                    $tpl
                );

                $tpl  = "## Stop the service and regardless of whether it was \n";
                $tpl .= "## running or not, start it again.\n";
                $tpl .= "\$0 stop\n";
                $tpl .= "\$0 start\n\n";
                $tpl .= "# Remember status and be quiet\n";
                $tpl .= "rc_status";
                $initFile->addToBlock('restart',
                    $tpl
                );
                
                $tpl  = "echo -n \"Reload service %s\"\n";
                $tpl .= "killproc -p \$%s_PIDFILE -HUP \$%s_BIN\n";
                $tpl .= "rc_status -v";
                $initFile->addToBlock('reload',
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
                $initFile->addToBlock('status',
                    sprintf(
                        $tpl,
                        $element->{desc},
                        uc($element->{shortname}),
                        uc($element->{shortname})
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
    my $block;

    $self->_renderHighlevelConfig($initFile);
    
    my $config = $initFile->{'configHash'};
    my $output;
    
    $output = "#!/bin/sh\n\n";
    $output .= $self->_renderInfoBlock($config);
    $output .= ". /etc/rc.status \n\n";
    if (keys(%{$config->{'head'}->{'content'}}) > 0) {
        $output .= $self->_combineBlock($config->{'head'});
    }
    if (keys(%{$config->{'functions'}->{'content'}}) > 0) {
        $output .= $self->_combineBlock($config->{'functions'});
    }
    $output .= "rc.reset \n\n";
    $output .= "case \"\$1\" in \n";
    if (keys(%{$config->{'start'}->{'content'}}) > 0) {
        $output .= "  start)\n";
        $block .= $self->_combineBlock($config->{'start'});
        $block =~ s/^/    /mg;
        $output .= $block;
        $output .= "  ;;\n";
    } else {
        # trigger error
        # start is essential
    }
    if (keys(%{$config->{'stop'}->{'content'}}) > 0) {
        $output .= "  stop)\n";
        $block = $self->_combineBlock($config->{'stop'});
        $block =~ s/^/    /mg;
        $output .= $block;
        $output .= "  ;;\n";
    } else {
        # trigger error
        # stop is essential
    }
    if (keys(%{$config->{'reload'}->{'content'}}) > 0) {
        $output .= "  reload)\n";
        $block = $self->_combineBlock($config->{'reload'});
        $block =~ s/^/    /mg;
        $output .= $block;
        $output .= "  ;;\n";
    }
    if (keys(%{$config->{'restart'}->{'content'}}) > 0) {
        $output .= "  restart)\n";
        $block = $self->_combineBlock($config->{'restart'});
        $block =~ s/^/    /mg;
        $output .= $block;
        $output .= "  ;;\n";
    }
    if (keys(%{$config->{'try-restart'}->{'content'}}) > 0) {
        $output .= "  try-restart)\n";
        $block = $self->_combineBlock($config->{'try-restart'});
        $block =~ s/^/    /mg;
        $output .= $block;
        $output .= "  ;;\n";
    }
    if (keys(%{$config->{'status'}->{'content'}}) > 0) {
        $output .= "  status)\n";
        $block = $self->_combineBlock($config->{'status'});
        $block =~ s/^/    /mg;
        $output .= $block;
        $output .= "  ;;\n";
    }
    if (keys(%{$config->{'usage'}->{'content'}}) > 0) {
        $output .= "  *)\n";
        $block = $self->_combineBlock($config->{'usage'});
        $block =~ s/^/    /mg;
        $output .= $block;
        $output .= "  exit 1\n";
    } else {
        # try to generate usage
        # $this->_generateUsage();
    }
    $output .= "esac\n\n";
    $output .= "rc_exit\n";
    return $output;
    
}

1;