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

die "must give 'system' ($system), 'client' ($client) and 'preboot_id' ($prebootID)!\n"
    unless $system && $client && $prebootID;

my $webPath = "$openslxConfig{'public-path'}/preboot";
my $src = "$webPath/client-config/$system/$prebootID.tgz";
my $destPath = "$webPath/$prebootID/client-config/$system";
mkpath($destPath."/".$client);
system(qq{tar -xz $src -C $destPath/$client/});

# from here on the modifications of client configuration should take place
# within $destPath/$client directory

system(qq{cd $destPath/$client; tar -czf $destPath/$client.tgz *});
unlink("$destPath/$client");

print
    $cgi->header(-charset => 'iso8859-1'),
    $cgi->start_html('Hey there ...'),
    $cgi->h1('Yo!'),
    $cgi->end_html();
