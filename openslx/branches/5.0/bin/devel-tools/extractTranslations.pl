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
# extractTranslations.pl
#    - OpenSLX-script to extract translatable strings from other scripts
#      and modules.
# -----------------------------------------------------------------------------
use strict;
use warnings;

my $abstract = q[
extractTranslations.pl
    This script is a tool for OpenSLX developers that allows to extract
    translatable strings from all OpenSLX perl-scripts and modules found
    in and below a given path.

    Optionally, all the translatable strings that were found can automatically
    be integrated into all existing translation modules. During this process,
    any translations already existing in these modules will be preserved.
];

use Cwd;
use File::Find;
use Getopt::Long;
use Pod::Usage;

use OpenSLX::Utils;

my (
    $helpReq,
    $show,
    $update,
    $verbose,
    $versionReq,

    %translatableStrings,
    $fileCount,
);

GetOptions(
    'help|?' => \$helpReq,
    'update' => \$update,
    'show' => \$show,
    'verbose' => \$verbose,
    'version' => \$versionReq,
) or pod2usage(2);
pod2usage(-msg => $abstract, -verbose => 0, -exitval => 1) if $helpReq;
if ($versionReq) {
    system('slxversion');
    exit 1;
}

# chdir to the repository's root folder:
use FindBin;
my $path = "$FindBin::RealBin/../..";
chdir($path)
    or die "can't chdir to repository-root <$path> ($!)";
print "searching in ".cwd()."\n";

find(\&ExtractTrStrings, '.');

my $trCount = scalar keys %translatableStrings;
print "Found $trCount translatable strings in $fileCount files.\n";

if ($show) {
    foreach my $tr (sort {lc($a) cmp lc($b)} keys %translatableStrings) {
        print "\tqq{$tr}\n\t\t=> qq{$tr}\n";
    }
}

if ($update) {
    find(\&UpdateTrModule, 'lib/OpenSLX/Translations');
}

exit;

sub ExtractTrStrings
{
    $File::Find::prune = 1 if ($_ eq '.svn'
                            || $_ eq 'Translations'
                            || $_ eq 'devel-tools');
    return if -d;
    my $text = slurpFile($_);
    if ($File::Find::name !~ m[\.pm$] && $text !~ m[^#!.+/perl]im) {
        # ignore anything other than perl-modules and -scripts
        return;
    }
    print "$File::Find::name...\n";
    $fileCount++;
    while($text =~ m[_tr\s*\(\s*(.+?)\s*\);]gos) {
        # NOTE: that cheesy regex relies on the string ');' not being used
        #       inside of translatable strings... so SLX_DONT_DO_THAT!
        #        As an alternative, we could implement a real parser, but
        #        I'd like to postpone that until the current scheme proves
        #        simply not good enough.
        my $tr = $1;
        if (!($tr =~ m[^'([^']+)'\s*(,.+?)*\s*$]os
        || $tr =~ m[^\"([^"]+)\"\s*(,.+?)*\s*$]os
        || $tr =~ m{^qq?\[([^\]]+)\]\s*(,.+?)*\s*$}os)) {
            die "$File::Find::name: could not parse _tr()-argument \n"
                ."\t$tr\nPlease correct and retry.\n";
        }
        $tr = $1;
        if ($tr =~ m[(\$\w+)]) {
            die "$File::Find::name: _tr()-argument\n\t$tr\n"
                ."contains variable '$1'.\nPlease correct and retry.\n";
        }
        $tr =~ s[\n][\\n]g;
        $tr =~ s[\t][\\t]g;
        $translatableStrings{$tr} = $tr;
        print "\t$tr\n" if $verbose;
    }
}

sub UpdateTrModule
{
    $File::Find::prune = 1 if ($_ eq '.svn');
    return if -d || !/.pm$/;
    print "updating $File::Find::name...\n";
    my $trModule = $_;
    my $useKeyAsTranslation = ($trModule eq 'posix.pm');
    my $text = slurpFile($trModule);
    if ($text !~ m[%translations\s*=\s*\(\s*(.+)\s*\);]os) {
        print "\t*** No translations found - file will be skipped! ***\n";
        return;
    }
    my %translations;
    # evaluate the hash read from file into %translations:
    if (!eval "$&") {
        print "\t*** translations can't be evaluated - file will be skipped! ***\n";
        return;
    }
    my $updatedTranslations = "%translations = (\n";
    my $keepCount = 0;
    my $newCount = 0;
    foreach my $tr (sort {lc($a) cmp lc($b)} keys %translatableStrings) {
        if (!length($translations{$tr})) {
            if ($useKeyAsTranslation) {
                # POSIX language (English): use key as translation:
                $updatedTranslations
                    .= "\tq{$tr}\n\t=>\n\tqq{$tr},\n\n";
                $newCount++;
            } else {
                # no translation available, we mark the key, such that a
                # search for this key will fall back to the english message:
                my $trMark = "NEW:$tr";
                if (exists $translations{$trMark}) {
                    # the marked string already exists, we keep the translation
                    # if any (usually, of course, there is none):
                    my $trValue = $translations{$trMark};
                    $trValue =~ s[\n][\\n]g;
                    $trValue =~ s[\t][\\t]g;
                    $updatedTranslations
                        .= "\tq{$trMark}\n\t=>\n\tqq{$trValue},\n\n";
                    $keepCount++;
                } else {
                    $updatedTranslations
                        .= "\tq{$trMark}\n\t=>\n\tqq{},\n\n";
                    $newCount++;
                }
            }
        } else {
            # use existing translation for key:
            my $trValue = $translations{$tr};
            $trValue =~ s[\n][\\n]g;
            $trValue =~ s[\t][\\t]g;
            $updatedTranslations
                .= "\tq{$tr}\n\t=>\n\tqq{$trValue},\n\n";
            $keepCount++;
        }
    }
    my $delCount = scalar(keys %translations) - $keepCount;
    $text =~ s[%translations\s*=\s*\(\s*(.+)\s*\);]
              [$updatedTranslations);]os;
    if ($newCount + $delCount) {
        chomp $text;
        spitFile($trModule, $text."\n");
        print "\tadded $newCount strings, kept $keepCount and removed $delCount.\n";
    } else {
        print "\tnothing changed\n";
    }
}

__END__

=head1 NAME

extractTranslations.pl - OpenSLX-script to extract translatable strings from
all scripts and modules found in and below the given path.

=head1 SYNOPSIS

extractTranslations.pl [options]

  Options:
      --help                   brief help message
      --update                 update the OpenSLX locale modules
                               (in lib/OpenSLX/Translations)
      --show                   show overview of all strings found
      --verbose                show for each file which strings are found
      --version                show version

=head1 OPTIONS

=over 8

=item B<--help>

Prints a brief help message and exits.

=item B<--show>

Prints sorted list of all translatable strings that were found.

=item B<--update>

Integrates the found translatable strings into all OpenSLX locale modules found
under lib/OpenSLX/Translations.
Every module will be updated with the found strings, existing
translations will not be changed (unless the corresponding key doesn't exist
anymore, in which case they will be removed).

=item B<--verbose>

Prints information about what's going on during execution of the script.

=item B<--version>

Prints the version and exits.

=back

=cut