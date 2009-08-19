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
use Switch;

# add openslx stuff to @INC
use FindBin;
use lib "$FindBin::RealBin/../../../../lib";
use lib "$FindBin::RealBin";

# read default config
use OpenSLX::Basics;
openslxInit();

my $cgi = CGI->new;
my $mac = $cgi->param('user') || '';
my $action = $cgi->param('action');
my $data = $cgi->param('data');

# global requirements
die "must give 'mac' ($mac)!\n"
    unless $mac;

my $webPath = "$openslxConfig{'public-path'}/preboot-users";
my $userConfFile = "$webPath/$mac.conf";

# makes only sense if public path is writeable for www-data
# otherwise you have to create directory manualy
if ( ! -e $webPath ) {
    mkpath ($webPath) or die _tr("Can't create user config directory (%s). Reason: %s", $webPath, @_);
}

my $output = "";
my $error;

switch ($action) {
    case 'set' {
        if ($data) {
            open (MYFILE, ">$userConfFile");
            print MYFILE $data;
            close (MYFILE);
        } else {
            $error = "no data";
        }
    }
    case 'read' {
        if ( -e $userConfFile ) {
            open (MYFILE, $userConfFile);
            while (<MYFILE>) {
                chomp;
                $output .= "$_\n";
            }
            close (MYFILE); 
        } else {
            $error = "foobar";
        }

    }
    else {
        #default case check if we have a user config
        if ( -e $userConfFile ) { $output = "1";  }
        else { $output = "0"; };
    }
}

print $cgi->header('Content-type: text/plain');
if ($error) {
    print $error;
} else {
    print $output;
}

exit 0;
