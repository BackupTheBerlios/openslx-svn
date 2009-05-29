#!/usr/bin/perl -w
# Copyright (c) 2009 - OpenSLX GmbH
#
# This program is free software distributed under the GPL version 2.
# See http://openslx.org/COPYING
#
# If you have any feedback please consult http://openslx.org/feedback and
# send your feedback to feedback@openslx.org
#
# General information about OpenSLX can be found at http://openslx.org
#
# cgi-bin script that accepts user settings and stores them in a special
# folder on the openslx server

use strict;
use warnings;

use CGI;
use CGI::Carp qw(fatalsToBrowser);
use File::Path;

# add openslx stuff to @INC
use FindBin;
use lib "$FindBin::RealBin/../../../../lib";
use lib "$FindBin::RealBin";

# read default config
use OpenSLX::Basics;
openslxInit();

#    die "*** Taint mode must be active! ***" unless ${^TAINT};

my $cgi = CGI->new;

my $system = $cgi->param('system') || '';
my $client = $cgi->param('client') || '';
my $prebootID = $cgi->param('preboot_id') || '';
my $type = $cgi->param('type') || 'directkiosk';
my $errormsg = 'None';

die "must give 'system' ($system), 'client' ($client) and 'preboot_id' ($prebootID)!\n"
    unless $system && $client && $prebootID;

my $webPath = "$openslxConfig{'public-path'}/preboot";
my $src = "$webPath/client-config/$system/$prebootID.tgz";
my $destPath = "$webPath/$prebootID/client-config/$system";

# if fastboot (default) is selected and a ConfTGZ exist just proceed ...
if ($type eq "fastboot" && !-e "$destPath/$client.tgz") { $type = "slxconfig"; }
# directkiosk/cfgkiosk/slxconfig
if ($type ne "fastboot") { 
    mkpath($destPath."/".$client);
    system(qq{tar -xzf $src -C $destPath/$client/});


    # from here on the modifications of client configuration should take place
    # within $destPath/$client directory
    if ($type eq "slxconfig") {
        # configuration of a WAN boot SLX client
        print STDERR "slxconfig sub";
    }
    elsif ($type eq "cfgkiosk") {
        # configuration of a WAN boot SLX kiosk
    }
    elsif (!$type || $type eq "directkiosk") {
        # deactivate the desktop plugin for the kiosk mode
        open (CFGFILE, ">>$destPath/$client/initramfs/plugin-conf/desktop.conf");
        print CFGFILE 'desktop_active="0"';
        close (CFGFILE);
        # activate the kiosk plugin
        if (!-e "$destPath/$client/initramfs/plugin-conf/kiosk.conf") {
            $errormsg = "The kiosk plugin seems not to be installed";
            print STDERR $errormsg;
        } else {
            open (CFGFILE, ">>$destPath/$client/initramfs/plugin-conf/kiosk.conf");
            print CFGFILE 'kiosk_active="1"';
            close (CFGFILE);
        }
    }
    else {
        # unknown type
        $errormsg = "You have passed an unknown boot type $type";
        print STDERR $errormsg;
    }
    system(qq{cd $destPath/$client; tar -czf $destPath/$client.tgz *});
    rmtree($destPath."/".$client);
}

print
    $cgi->header(-charset => 'iso8859-1'),
    $cgi->start_html('Hey there ...'),
    $cgi->h1('Yo!'),
    $cgi->p("Error: $errormsg"),
    $cgi->end_html();
