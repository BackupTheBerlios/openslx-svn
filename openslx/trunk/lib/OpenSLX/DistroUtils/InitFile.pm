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
# InitFile.pm
#    - configuration object for runlevel script
# -----------------------------------------------------------------------------
package OpenSLX::DistroUtils::InitFile;

use strict;
use warnings;

use OpenSLX::Basics;
use OpenSLX::Utils;

sub new {
    my $class  = shift;
    my $params = shift || {};
    my $self = {
    };
    
    $self->{'configHash'} = _initialConfigHash();
    
    return bless $self, $class;
}

sub _initialConfigHash() {
    return {
        'name'  =>  "",
        'requiredStart' => "\$remote_fs",
        'requiredStop' => "\$remote_fs",
        'defaultStart' => "2 3 4 5",
        'defaultStop' => "1",
        'shortDesc' => "",
        'blocks' => {
            'head'      => {
                'blockDesc' => "head: file existing checks, etc.",
                'content'   => {}
            },
            'functions' => {
                'blockDesc' => "functions: helper functions",
                'content'   => {}
            }
        },
        'caseBlocks' => {
	        'start'     => {
	            'blockDesc' => "start: defines start function for initscript",
	            'content'   => {},
	            'order'     => 1,
	            'required'  => 1
	        },
	        'stop'      => {
	            'blockDesc' => "stop: defines stop function for initscript",
	            'content'   => {},
                'order'     => 2,
                'required'  => 1
	        },
	        'reload'    => {
	            'blockDesc' => "reload: defines reload function for initscript",
	            'content'   => {},
                'order'     => 3,
                'required'  => 0
	        },
	        'force-reload'    => {
	            'blockDesc' => "force-reload: defines force-reload function for initscript",
	            'content'   => {},
                'order'     => 4,
                'required'  => 0
	        },
	        'restart'   => {
	            'blockDesc' => "restart: defines restart function for initscript",
	            'content'   => {},
                'order'     => 5,
                'required'  => 1
	        },
	        'try-restart'   => {
	            'blockDesc' => "restart: defines restart function for initscript",
	            'content'   => {},
                'order'     => 6,
                'required'  => 0
	        },
	        'status'    => {
	            'blockDesc' => "status: defines status function for initscript",
	            'content'   => {},
                'order'     => 7,
                'required'  => 0
	        },
	        'usage'     => {
	            'blockDesc' => "usage: defines usage function for initscript",
	            'content'   => {},
                'order'     => 8,
                'required'  => 0
	        }
        }
    };
}

sub addToCase {
    my $self = shift;
    my $blockName = shift;
    my $content = shift;
    my $priority = shift || 5;
    
    #check if block is valid..
    
    push(@{$self->{'configHash'}->{'caseBlocks'}->{$blockName}->{'content'}->{$priority}}, $content);
    
    return $self;
}

sub addToBlock {
    my $self = shift;
    my $blockName = shift;
    my $content = shift;
    my $priority = shift || 5;
    
    #check if block is valid..
    
    push(@{$self->{'configHash'}->{'blocks'}->{$blockName}->{'content'}->{$priority}}, $content);
    
    return $self;
}

sub setName {
    my $self = shift;
    my $name = shift;
    
    $self->{'configHash'}->{'name'} = $name;
    return $self;
}

sub setDesc {
    my $self = shift;
    my $desc = shift;
    
    $self->{'configHash'}->{'shortDesc'} = $desc;
    return $self;
}

sub addFunction {
	my $self   = shift;
	my $name   = shift;
	my $script = shift;
	my $flags  = shift || {};
    my $priority    = $flags->{priority} || 5;

    push(@{$self->{'configHash'}->{'highlevelConfig'}},
    {
        name => $name,
        script => $script,
        priority => $priority,
        type => 'function'
    });
    return 1;
}

sub addFunctionCall {
	my $self       = shift;
	my $function   = shift;
	my $block      = shift;
	my $flags      = shift;
	my $priority   = $flags->{priority} || 5;
	my $parameters = $flags->{parameters} || "";

    push(@{$self->{'configHash'}->{'highlevelConfig'}},
    {
        function => $function,
        block => $block,
        parameters => $parameters,
        priority => $priority,
        type => 'functionCall'
    });
    return 1;
}

sub addScript {
    my $self    = shift;
    my $name    = shift;
    my $script  = shift;
    my $flags   = shift || {};
    my $block       = $flags->{block} || 'start';
    my $required    = $flags->{required} || 1;
    my $errormsg    = $flags->{errormsg} || "$name failed!";
    my $priority    = $flags->{priority} || 5;
    
    push(@{$self->{'configHash'}->{'highlevelConfig'}},
    {
        name => $name,
        script => $script,
        block => $block,
        required => $required,
        priority => $priority,
        errormsg => $errormsg,
        type => 'script'
    });
    return 1;
}

sub addDaemon {
    my $self = shift;
    my $binary = shift;
       $binary =~ m/\/([^\/]*)$/;
    my $shortname = $1;
    my $parameters = shift || "";
    my $flags = shift || {};
    my $required    = $flags->{required} || 1;
    my $desc        = $flags->{desc} || "$shortname";
    my $errormsg    = $flags->{errormsg} || "$desc failed!";
    my $priority    = $flags->{priority} || 5;
    
    push(@{$self->{'configHash'}->{'highlevelConfig'}},
    {
        binary => $binary,
        shortname => $shortname,
        parameters => $parameters,
        desc => $desc,
        errormsg => $errormsg,
        required => $required,
        priority => $priority,
        type => 'daemon'
    });
    return 1;
}


1;
