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
# InitFile.pm
#    - configuration object for runlevel script
# -----------------------------------------------------------------------------
package OpenSLX::DistroUtils::InitFile;

use strict;
use warnings;

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
        'requiredStart' => "",
        'requiredStop' => "",
        'defaultStart' => "2 3 4 5",
        'defaultStop' => "1",
        'shortDesc' => "",
        
        'head'      => {
            'blockDesc' => "head: file existing checks, etc.",
            'content'   => {}
        },
        'functions' => {
            'blockDesc' => "functions: helper functions",
            'content'   => {}
        },
        'start'     => {
            'blockDesc' => "start: defines start function for initscript",
            'content'   => {}
        },
        'stop'      => {
            'blockDesc' => "stop: defines stop function for initscript",
            'content'   => {}
        },
        'reload'    => {
            'blockDesc' => "reload: defines reload function for initscript",
            'content'   => {}
        },
        'restart'   => {
            'blockDesc' => "restart: defines restart function for initscript",
            'content'   => {}
        },
        'status'    => {
            'blockDesc' => "status: defines status function for initscript",
            'content'   => {}
        },
        'usage'     => {
            'blockDesc' => "usage: defines usage function for initscript",
            'content'   => {}
        }
    };
}

sub addToBlock {
    my $self = shift;
    my $blockName = shift;
    my $content = shift;
    my $priority = shift || 5;
    
    #check if block is valid..
    
    push(@{$self->{'configHash'}->{$blockName}->{'content'}->{$priority}}, $content);
    
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



1;