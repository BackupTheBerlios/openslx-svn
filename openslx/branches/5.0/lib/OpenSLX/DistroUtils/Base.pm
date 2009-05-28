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
#    - provides base for distro based utils for OpenSLX
# -----------------------------------------------------------------------------
package OpenSLX::DistroUtils::Base;

use Data::Dumper;
use OpenSLX::Utils;


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

sub _combineBlock
{
    my $self = shift;
    my $block = shift;
    
    my $output;
    
    $output = "#";
    $output .= $block->{'blockDesc'};
    $output .= "\n";
    
    my $content = $block->{'content'};
    while ( ($priority, $contentArray) = each %$content )
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

sub generateInitFile
{
    my $self = shift;
    my $initFile = shift;
    my $block;
    
    my $config = $initFile->{'configHash'};
    
        print  Dumper($initFile->{'configHash'});
    
    
    $output = "#!/bin/sh\n\n";
    $output .= $self->_renderInfoBlock($config);
    $output .= "set -e \n\n";
    if (keys(%{$config->{'head'}->{'content'}}) > 0) {
        $output .= $self->_combineBlock($config->{'head'});
    }
    if (keys(%{$config->{'functions'}->{'content'}}) > 0) {
        $output .= $self->_combineBlock($config->{'functions'});
    }
    $output .= "case \"\$1\" in \n";
    if (keys(%{$config->{'start'}->{'content'}}) > 0) {
        $output .= "  start)\n";
        $block = $self->_combineBlock($config->{'start'});
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
    $output .= "exit 0\n";
    return $output;
    
}

1;