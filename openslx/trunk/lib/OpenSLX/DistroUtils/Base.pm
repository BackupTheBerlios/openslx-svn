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
    $output .= "\n  ";
    
    my $content = $block->{'content'};
    while ( ($priority, $contentArray) = each %$content )
    {
        $output .= join("\n  ", @$contentArray);
        $output .= "\n  ";
    }
    
    $output .= "\n";
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

sub generateInitFile
{
    my $self = shift;
    my $initFile = shift;
    
    my $config = $initFile->{'configHash'};
    
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
        $output .= $self->_combineBlock($config->{'start'});
        $output .= "  ;;\n";
    } else {
        # trigger error
        # start is essential
    }
    if (keys(%{$config->{'stop'}->{'content'}}) > 0) {
        $output .= "  stop)\n";
        $output .= $self->_combineBlock($config->{'stop'});
        $output .= "  ;;\n";
    } else {
        # trigger error
        # stop is essential
    }
    if (keys(%{$config->{'reload'}->{'content'}}) > 0) {
        $output .= "  reload)\n";
        $output .= $self->_combineBlock($config->{'relaod'});
        $output .= "  ;;\n";
    }
    if (keys(%{$config->{'restart'}->{'content'}}) > 0) {
        $output .= "  restart)\n";
        $output .= $self->_combineBlock($config->{'restart'});
        $output .= "  ;;\n";
    }
    if (keys(%{$config->{'status'}->{'content'}}) > 0) {
        $output .= "  status)\n";
        $output .= $self->_combineBlock($config->{'status'});
        $output .= "  ;;\n";
    }
    if (keys(%{$config->{'usage'}->{'content'}}) > 0) {
        $output .= "  *)\n";
        $output .= $self->_combineBlock($config->{'usage'});
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