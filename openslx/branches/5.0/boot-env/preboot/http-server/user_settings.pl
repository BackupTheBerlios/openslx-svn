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

#    die "*** Taint mode must be active! ***" unless ${^TAINT};

my $cgi = CGI->new;

my $system = $cgi->param('system') || '';
my $client = $cgi->param('client') || '';
my $prebootID = $cgi->param('preboot_id') || '';

die "must give 'system' ($system), 'client' ($client) and 'preboot_id' ($prebootID)!\n"
    unless $system && $client && $prebootID;

my $src = "/srv/openslx/preboot/client-config/$system/default.tgz";
my $destPath = "/srv/www/openslx/preboot/$prebootID/client-config/$system";
mkpath($destPath);
system(qq{cp $src $destPath/$client.tgz});

print
    $cgi->header(-charset => 'iso8859-1'),
    $cgi->start_html('Hey there ...'),
    $cgi->h1('Yo!'),
    $cgi->end_html();
