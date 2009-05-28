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
# DistroUtils.pm
#    - provides base for distro based utils for OpenSLX
# -----------------------------------------------------------------------------
package OpenSLX::DistroUtils::Base;

use Data::Dumper;
use OpenSLX::Utils;
use Clone qw(clone);
use Switch;

use strict;
use warnings;

sub new
{
    my $class = shift;
    my $self = {};
    return bless $self, $class;
}

sub dumpInit
{
    my $self = shift;
    my $initFile = shift;
    
    print  Dumper($initFile->{'configHash'});
    
    print $self->generateInitFile($initFile);
}

sub _concatContent
{
    my $self = shift;
    my $block = shift;
    
    my $output;
    
    $output = "#";
    $output .= $block->{'blockDesc'};
    $output .= "\n";
    
    my $content = $block->{'content'};
    while ( my ($priority, $contentArray) = each %$content )
    {
        $output .= join("\n", @$contentArray);
        $output .= "\n";
    }
    
    return $output;
}

sub _renderInfoBlock
{
    my $self = shift;
    my $config = shift;
    
    my $tpl = unshiftHereDoc(<<'    End-of-Here');
    ### BEGIN INIT INFO
    # Provides:             %s
    # Required-Start:       %s
    # Required-Stop:        %s
    # Default-Start:        %s
    # Default-Stop:         %s
    # Short-Description:    %s
    ### END INIT INFO
    
    End-of-Here
    
    return sprintf(
      $tpl,
      $config->{'name'},
      $config->{'requiredStart'},
      $config->{'requiredStop'},
      $config->{'defaultStart'},
      $config->{'defaultStop'},
      $config->{'shortDesc'}
    );
}

sub _insertSystemHelperFunctions
{
    my $self = shift;
    my $content = shift;
    
    # do some regex
    
    # ubuntu:
    # log_end_msg
    # log_progress_msg
    # log_daemon_msg
    # log_action_msg
    
    # start-stop-daemon
    
    # suse http://de.opensuse.org/Paketbau/SUSE-Paketkonventionen/Init-Skripte
    
    return $content;
}

sub _renderHighlevelConfig
{
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
                $tpl .= "[ -f /etc/default/%s ] . /etc/default/%s \n\n";
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
        }
    }
    
}


sub _getInitsystemIncludes
{
    return "\n";
}

sub _renderCasePrefix
{
    return "\n";
}

sub _renderFooter
{
    return "exit 0\n";
}

sub _generateUsage
{
	my $self = shift;
	my $usage = shift;
	my $tpl;
	
    $tpl  = "## print out usage \n";
    $tpl .= "echo \"Usage: \$0 {%s}\" >&2 \n";
    $tpl .= "exit 1";
	
	return sprintf(
	   $tpl,
	   $usage
	);
}

sub _getAuthorBlock
{
	my $tpl;
	
	$tpl  = "# Copyright (c) 2009 - OpenSLX GmbH \n";
    $tpl .= "# \n";
    $tpl .= "# This program is free software distributed under the GPL version 2. \n";
    $tpl .= "# See http://openslx.org/COPYING \n";
    $tpl .= "# \n";
    $tpl .= "# If you have any feedback please consult http://openslx.org/feedback and \n";
    $tpl .= "# send your suggestions, praise, or complaints to feedback\@openslx.org \n";
    $tpl .= "# \n";
    $tpl .= "# General information about OpenSLX can be found at http://openslx.org/ \n";
    $tpl .= "# -----------------------------------------------------------------------------\n";
    $tpl .= "# §filename§ \n";
    $tpl .= "#    - §desc§ \n";
    $tpl .= "# §generated§ \n";
    $tpl .= "# -----------------------------------------------------------------------------\n\n";
	
	return sprintf(
	   $tpl
	);
}

sub generateInitFile
{
    my $self = shift;
    my $initFile = shift;
    my $content;
    my @usage;
    
    # get a copy of initFile object before modifying it..
    my $initFileCopy = clone($initFile);

    $self->_renderHighlevelConfig($initFileCopy);
    
    my $config = $initFileCopy->{'configHash'};
    my $output;
    
    # head
    $output = "#!/bin/sh\n";
    $output .= $self->_getAuthorBlock();
    $output .= $self->_renderInfoBlock($config);
    $output .= $self->_getInitsystemIncludes();
    
    if (keys(%{$config->{'blocks'}->{'head'}->{'content'}}) > 0) {
        $output .= $self->_concatContent($config->{'blocks'}->{'head'});
    }
    
    # functions
    if (keys(%{$config->{'blocks'}->{'functions'}->{'content'}}) > 0) {
        $output .= $self->_concatContent($config->{'blocks'}->{'functions'});
    }
    
    # case block
    $output .= $self->_renderCasePrefix();
    $output .= "\ncase \"\$1\" in \n";  
    
    # get caseBlocks in defined order
    my @blocks = sort{
    	   $config->{'caseBlocks'}->{$a}->{'order'} <=> 
    	   $config->{'caseBlocks'}->{$b}->{'order'}
        } 
    	keys(%{$config->{'caseBlocks'}});
    
    # case block
    while (@blocks)
    {
    	my $block= shift(@blocks);
	    if (keys(%{$config->{'caseBlocks'}->{$block}->{'content'}}) > 0) {
	    	push(@usage, $block);
	        $output .= "  $block)\n";
	        $content = $self->_concatContent($config->{'caseBlocks'}->{$block});
	        $content =~ s/^/    /mg;
	        $output .= $content;
	        $output .= "  ;;\n";
	    } else {
	    	if ($config->{'caseBlocks'}->{$block}->{'required'}) {
	    		print "required block $block undefined";
	    	}
	    }    	
    }
    
    # autogenerate usage
    if (scalar(grep(/usage/, @usage)) == 0) {
    	$initFileCopy->addToCase(
    	       'usage',
    	       $self->_generateUsage(join(', ',@usage))
    	);

 	    $output .= "  *)\n";
        $content = $self->_concatContent($config->{'caseBlocks'}->{'usage'});
        $content =~ s/^/    /mg;
        $output .= $content;
        $output .= "  ;;\n";
    	
    }
    
    # footer
    $output .= "esac\n\n";
    $output .= $self->_renderFooter();
    
    return $output;
    
}


1;