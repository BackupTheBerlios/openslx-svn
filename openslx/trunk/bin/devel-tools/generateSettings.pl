#! /usr/bin/perl
# -----------------------------------------------------------------------------
# Copyright (c) 2006 - 2009 - OpenSLX GmbH
#
# This program is free software distributed under the GPL version 2.
# See http://openslx.org/COPYING
#
# If you have any feedback please consult http://openslx.org/feedback and
# send your suggestions, praise, or complaints to feedback@openslx.org
#
# General information about OpenSLX can be found at http://openslx.org/
# -----------------------------------------------------------------------------
use strict;
use warnings;
use Data::Dumper;
my $abstract = q[
determineMinimumPackageSet.pl
    This script is a tool for OpenSLX developers that is meant to generate a
    packageset for settings.default. It can be used to generate
    bootstrap-packages for example.
];

use Getopt::Long;
use Pod::Usage;

my (
    $helpReq,
    $verbose,
    $versionReq,
    $inputfile,
    $outputfile,
    $url,
    $errorfile,

    @Pkgs,
    @files,
    @GivenNames,
    @filelisting,
    @errors,
);

$errorfile="/tmp/genSettings.err";
GetOptions(
    'help|?' => \$helpReq,
    'verbose' => \$verbose,
    'version' => \$versionReq,
    'if=s' => \$inputfile,
    'of=s' => \$outputfile,
    'url=s' => \$url,
) or pod2usage(2);
pod2usage(-msg => $abstract, -verbose => 0, -exitval => 1) if $helpReq;
if ($versionReq) {
    system('slxversion');
    exit 1;
}
	
open(INPUTFILE,$inputfile) || die("Can't open input-file $inputfile!");
    while (my $zeile=<INPUTFILE>){
        if ($zeile ne "") {
            push (@GivenNames,$zeile);
        }
    }
close(INPUTFILE);
	
print "getting filelisting:\n" if $verbose;
if (substr($url,0,3) eq "ftp") {
    print "\trecognized mirror as ftp - $url\n" if $verbose;
    @filelisting=_getPackageListingFtp($url);
} elsif (substr($url,0,4) eq "http") {
    print "\trecognized mirror as http - $url\n" if $verbose;
    @filelisting=_getPackageListingHttp($url);
} else {
    die "Unable to get mirror type (ftp or http)";
}
print "\tgot file listing from $url\n" if $verbose;
print "resolving names:\n" if $verbose;
foreach my $name (@GivenNames) {
    $name=~ s/^[\s\t]+//;  #removes whitespaces
    $name=~ s/[\n\t\r]$//; #removes new lines
    my @possiblepackages = grep(/^\Q$name\E*/i,@filelisting);
    my $res;
    if ($possiblepackages[0]) {
        $res = $possiblepackages[0];
    } else {
        push (@errors,$name);
    }
    print "\t$name->$res\n" if $verbose;
    push (@Pkgs,$res) if $res;
}
open (OUTPUTFILE,">>$outputfile") || die("Can't open output-file $outputfile!");
foreach my $package (@Pkgs) {
    print OUTPUTFILE "$package\n";		
}
close (OUTPUTFILE);
open (ERRORFILE,">>$errorfile") || die("Can't open output-file $errorfile!");
    foreach my $error (@errors) {
    print ERRORFILE "$error\n";		
}
close (ERRORFILE);
print "\n";

if ($verbose) {
    print "THE PACKAGE LIST:\n";
    print(('=' x 40)."\n");
    print join("\n", sort @Pkgs)."\n";
}

exit;


sub _getPackageListingFtp {
	my $url = shift;
    use Net::FTP;
    use URI;
    require URI::_generic;
    
    my $urlObject = URI->new($url);
    my $path = shift;
	my $ftp = Net::FTP->new($urlObject->host( ), Timeout => 240)
	  or die _tr("Unable to connect to FTP-Server");
    $ftp->login("anonymous", "mailaddress@");
    $ftp->cwd($urlObject->path( ));
    return $ftp->ls();    
}

sub _getPackageListingHttp {
    my $url = shift;
    use URI;
    use URI::http;
    use URI::_foreign;
    use HTTP::Request;
    use LWP::UserAgent;
    use LWP::Protocol::http;
    
    my @filelisting;
    my $ua = LWP::UserAgent->new;
    $ua->agent("Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.8) Gecko/20051111 Firefox/1.5");
    my $req;
    $req = HTTP::Request->new(GET => $url);
    $req->header('Accept' => 'text/html');

    # send request
    my $res = $ua->request($req);
    # check the outcome
    if ($res->is_success) {
	print "\tThe given URL is : $url\n"       	if $verbose;
        @filelisting = ($res->decoded_content =~ m/<a href=\"([^\"]*.rpm)/g);
        foreach my $i (@filelisting){
        	print $i."\n"				if $verbose;
        }
	print "\tgot list of files from mirror.\n"	if $verbose;
        return @filelisting;
    }
    die("Error: " . $res->status_line . "\n");
}


__END__

=head1 NAME

generateSettings.pl - OpenSLX script to extract full package names
from a given mirror.

=head1 SYNOPSIS

generateSettings.pl [options]

  Options:
      --if                     inputfile
      --of                     outputfile
      --url                    url of the mirror
      --help                   brief help message
      --verbose                show files as they are being processed
      --version                show version

=head1 OPTIONS

=over 8

=item B<--if>

Select input file with package names in each line.

=item B<--of>

Select output file for complete package names to append.

=item B<--url>

Select a mirror directory for the desired distribution

=item B<--help>

Prints a brief help message and exits.

=item B<--verbose>

Prints information about each installed package as it is being processed.

=item B<--version>

Prints the version and exits.

=back

=cut
