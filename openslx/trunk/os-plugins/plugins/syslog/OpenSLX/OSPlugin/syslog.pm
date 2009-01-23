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
# syslog.pm
#    - implementation of the 'syslog' plugin, which installs  
#     all needed information for a displaymanager and for the syslog. 
# -----------------------------------------------------------------------------
package OpenSLX::OSPlugin::syslog;

use strict;
use warnings;

use base qw(OpenSLX::OSPlugin::Base);

use File::Basename;
use File::Path;

use OpenSLX::Basics;
use OpenSLX::Utils;

sub new
{
    my $class = shift;

    my $self = {
        name => 'syslog',
    };

    return bless $self, $class;
}

sub getInfo
{
    my $self = shift;

    return {
        description => unshiftHereDoc(<<'        End-of-Here'),
            Sets up system log service for SLX-clients.
        End-of-Here
        precedence => 50,
    };
}

sub getAttrInfo
{
    my $self = shift;

    return {
        'syslog::active' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                should the 'syslog'-plugin be executed during boot?
            End-of-Here
            content_regex => qr{^(0|1)$},
            content_descr => '1 means active - 0 means inactive',
            default => '1',
        },
        'syslog::kind' => {
            applies_to_vendor_os => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                kind of syslog to use (syslogd-ng or old-style syslog)
            End-of-Here
            content_regex => undef,
            content_descr => 'allowed: syslogd-ng, syslog',
            default => syslog-ng,
        },
        'syslog::host' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                name or IP-address of host where syslog shall be sent to
            End-of-Here
            content_regex => undef,
            content_descr => 'a hostname or an IP address',
            default => undef,
        },
        'syslog::port' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                port number (UDP) where syslog shall be sent to
            End-of-Here
            content_regex => undef,
            content_descr => 'a port number',
            default => 514,
        },
        'syslog::file' => {
            applies_to_systems => 1,
            applies_to_clients => 1,
            description => unshiftHereDoc(<<'            End-of-Here'),
                name of file where all log messages shall be written
            End-of-Here
            content_regex => undef,
            content_descr => 'a complete file path',
            default => undef,
        },
    };
}

sub installationPhase
{
    my $self = shift;
    my $info = shift;
    
    $self->{pluginRepositoryPath} = $info->{'plugin-repo-path'};
    $self->{pluginTempPath}       = $info->{'plugin-temp-path'};
    $self->{openslxBasePath}      = $info->{'openslx-base-path'};
    $self->{openslxConfigPath}    = $info->{'openslx-config-path'};
    $self->{attrs}                = $info->{'plugin-attrs'};
    
    # We are going to change some of the stage1 attributes during installation
    # (basically we are filling the ones that are not defined). Since the result
    # of these changes might change between invocations, we do not want to store
    # the resulting values, but we want to store the original (undef).
    # In order to do so, we copy all stage1 attributes directly into the
    # object hash and change them there.
    $self->{kind}  = lc($self->{attrs}->{'syslog::kind'});
    
    my $engine = $self->{'os-plugin-engine'};
    
    if ($self->{kind} eq 'syslog-ng' && !qx{which syslog-ng}) {
        $engine->installPackages('syslog-ng');
    }
    if ($self->{kind} eq 'syslogd' && !qx{which syslogd}) {
        $engine->installPackages('syslogd');
    }

    if (!$self->{kind}) {
        if (qx{which syslog-ng}) {
            $self->{kind} = 'syslog-ng';
        }
        elsif (qx{which syslogd}) {
            $self->{kind} = 'syslogd';
        }
        else {
            die _tr(
                "no syslog daemon available, plugin 'syslog' wouldn't work!"
            );
        }
        print _tr("selecting %s as syslog kind\n", $self->{kind});
    }

    # start to actually do something - according to current stage1 attributes
    if ($self->{kind} eq 'syslog-ng') {
        $self->_setupSyslogNG();
    }
    elsif ($self->{kind} eq 'syslogd') {
        $self->_setupSyslogd();
    }
    else {
        die _tr(
            'unknown kind "%s" given, only "syslog-ng" and "syslogd" are supported!',
            $self->{kind}
        );
    }

    return;
}

sub removalPhase
{
    my $self = shift;
    my $info = shift;
    
    return;
}

sub _setupSyslogNG
{
    my $self  = shift;
    my $attrs = shift;
    
    my $repoPath = $self->{pluginRepositoryPath};

    my $rlInfo = $self->{distro}->runlevelInfo($attrs);

    my $conf = unshiftHereDoc(<<"    End-of-Here");
        #!/bin/ash
        # written by OpenSLX-plugin 'syslog'

        cat >/mnt/etc/syslog-ng/syslog-ng.conf <<END
        # written by OpenSLX-plugin 'syslog'
        source all {
            file("/proc/kmsg");
            unix-dgram("/dev/log");
            internal();
        };
        destination console_all {
            file("/dev/tty10");
        };        
        log {
            source(all);
            destination(console_all);
        };
        END
        
        if [ -n "\${syslog_host}" ]; then
        [ -z \${syslog_port} ] && syslog_port=514
        cat >>/mnt/etc/syslog-ng/syslog-ng.conf <<END
        destination loghost {
            udp( "\${syslog_host}" port(\${syslog_port}) );
        };
        log {
            source(all);
            destination(loghost);
        };
        END
        fi

        if [ -n "\${syslog_file}" ]; then
        cat >>/mnt/etc/syslog-ng/syslog-ng.conf <<END
        destination allmessages {
            file("\${syslog_file}");
        };
        log {
            source(all);
            destination(allmessages);
        };
        END
        fi

        rllinker $rlInfo->{scriptName} $rlInfo->{startAt} $rlInfo->{stopAt}

    End-of-Here
    spitFile("$repoPath/syslog.sh", $conf);
    
    return;    
}

sub _setupSyslogd
{
    my $self  = shift;
    my $attrs = shift;
    
    my $repoPath = $self->{pluginRepositoryPath};

    my $rlInfo = $self->{distro}->runlevelInfo($attrs);

    # TODO: implement!

    my $conf = unshiftHereDoc(<<'    End-of-Here');
        #!/bin/ash
        # written by OpenSLX-plugin 'syslog'

        cat >/mnt/etc/syslog.conf <<END
        # written by OpenSLX-plugin 'syslog'
         *.=debug;\
            auth,authpriv.none;\
            news.none;mail.none     -/var/log/debug
         *.=info;*.=notice;*.=warn;\
            auth,authpriv.none;\
            cron,daemon.none;\
            mail,news.none          -/var/log/messages

        END
        
        if [ -n "\${syslog_host}" ]; then
        [ -z \${syslog_port} ] && syslog_port=514
        cat >/mnt/etc/syslog.conf <<END
         *.*                        @${syslog_host}
        END
        fi

        if [ -n "\${syslog_file}" ]; then
        cat >/mnt/etc/syslog.conf <<END
         *.*                        ${syslog_file}
        };
        END
        fi

        rllinker $rlInfo->{scriptName} $rlInfo->{startAt} $rlInfo->{stopAt}

    End-of-Here
    spitFile("$repoPath/syslog.sh", $conf);
    
    return;    
}

1;
