#! /usr/bin/perl
# -----------------------------------------------------------------------------
# Copyright (c) 2006, 2007 - OpenSLX GmbH
#
# This program is free software distributed under the GPL version 2.
# See http://openslx.org/COPYING
#
# If you have any feedback please consult http://openslx.org/feedback and
# send your suggestions, praise, or complaints to feedback@openslx.org
#
# General information about OpenSLX can be found at http://openslx.org/
# -----------------------------------------------------------------------------
# parseSusePatterns.pl
#    - OpenSLX script to extract a package list from a given list of
#      SUSE-pattern-files (*.pat).
# -----------------------------------------------------------------------------
use strict;
use warnings;

my $abstract = q[
parseSusePatterns.pl
    This script is a tool for OpenSLX developers that allows to extract
    package lists from a given set of SUSE pattern files.
];

use Getopt::Long;
use Pod::Usage;

my (
    $helpReq,
    $versionReq,

    %patternNames,
    %packageNames,
);

GetOptions(
    'help|?' => \$helpReq,
    'version' => \$versionReq,
) or pod2usage(2);
pod2usage(-msg => $abstract, -verbose => 0, -exitval => 1) if $helpReq;
if ($versionReq) {
    system('slxversion');
    exit 1;
}

if ($ARGV[0] !~ m[^(\w+)-(.+)$]) {
    die "can't extract architecture from pattern file name '$ARGV[0]'";
}
my $arch = $2;

foreach my $patternFile (@ARGV) {
    parsePatternFile($patternFile, 1);
}

print join("\n", sort keys %packageNames)."\n";

exit;

sub parsePatternFile
{
    my $patternFile = shift;
    my $outmost = shift;

    my $patFH;
    if (!open($patFH, '<', $patternFile)) {
        return unless $outmost;
        die "unable to open $patternFile";
    }
    undef $/;
    my $content = <$patFH>;
    close($patFH);
    $patternNames{$patternFile} = 1;

    if ($content =~ m[^\=Sum.de:\s*(.+?)\s*$]ms) {
        print "+ $1\n";
    }
    if ($content =~ m[^\+Sug:\s*?$(.+?)^\-Sug:\s*?$]ms) {
        addSubPatterns($1);
    }
    if ($content =~ m[^\+Req:\s*?$(.+?)^\-Req:\s*?$]ms) {
        addSubPatterns($1);
    }
    if ($content =~ m[^\+Rec:\s*?$(.+?)^\-Rec:\s*?$]ms) {
        addSubPatterns($1);
    }
    if ($content =~ m[^\+Prq:\s*?$(.+?)^\-Prq:\s*?$]ms) {
        addPkgNames($1);
    }
    if ($content =~ m[^\+Prc:\s*?$(.+?)^\-Prc:\s*?$]ms) {
        addPkgNames($1);
    }
    return;
}

sub addSubPatterns
{
    my $patternNames = shift;

    my @subPatterns
        = grep { length($_) > 0 }
          map {
              my $pattern = $_;
              $pattern =~ s[^\s*(.+?)\s*$][$1];
              $pattern;
          }
          split "\n", $patternNames;

    foreach my $subPattern (@subPatterns) {
        my $subPatternFile = "$subPattern-$arch";
        if (!exists $patternNames{$subPatternFile}) {
            parsePatternFile($subPatternFile);
        }
    }
    return;
}

sub addPkgNames
{
    my $pkgs = shift;

    my @pkgNames
        = grep { length($_) > 0 }
          map {
              my $pkg = $_;
              $pkg =~ s[^\s*(.+?)\s*$][$1];
              $pkg;
          }
          split "\n", $pkgs;
    foreach my $pkgName (@pkgNames) {
        $packageNames{$pkgName} = 1;
    }
    return;
}

=head1 NAME

parseSusePatterns.pl - OpenSLX script to extract a package list from
a given list of SUSE-pattern-files (*.pat).

=head1 SYNOPSIS

parseSusePatterns.pl [options] <pattern-file> ...

  Options:
      --help                   brief help message
      --version                show version

=head1 OPTIONS

=over 8

=item B<--help>

Prints a brief help message and exits.

=item B<--version>

Prints the version and exits.

=back

=cut