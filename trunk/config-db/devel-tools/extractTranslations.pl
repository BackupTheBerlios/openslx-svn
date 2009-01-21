#! /usr/bin/perl
#
# extractTranslations.pl - OpenSLX-script to extract translatable strings from
#                          other scripts and modules.
#
# (c) 2006 - OpenSLX.com
#
# Oliver Tappe <ot@openslx.com>
#
use strict;

my $abstract = q[
extractTranslations.pl
    This script is a tool for OpenSLX developers as it allows to extract
    translatable strings from all OpenSLX perl-scripts and modules found
    in and below a given path.

    Optionally, all the translatable strings that were found can automatically
    be integrated into all existing translation modules. During this process,
    any translations already existing in these modules will be preserved.
];

use File::Find;
use Getopt::Long;
use Pod::Usage;

use Text::ParseWords;

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
	'update-path=s' => \$update,
	'show' => \$show,
	'verbose' => \$verbose,
	'version' => \$versionReq,
) or pod2usage(2);
pod2usage(-msg => $abstract, -verbose => 0, -exitval => 1) if $helpReq;
if ($versionReq) {
	system('slxversion');
	exit 1;
}
my $path = shift;
if (!defined $path) {
	print "You need to specify a path!\n";
	pod2usage(2);
}

chdir($path)
	or die "unable to chdir into target-path <$path> ($!)";

find(\&ExtractTrStrings, '.');

my $trCount = scalar keys %translatableStrings;
print "Found $trCount translatable strings in $fileCount files.\n";

if ($show) {
	foreach my $tr (sort {lc($a) cmp lc($b)} keys %translatableStrings) {
		print "\tqq{$tr}\n\t\t=> qq{$tr}\n";
	}
}

if ($update) {
	find(\&UpdateTrModule, 'OpenSLX/Translations');
}

sub ExtractTrStrings
{
	$File::Find::prune = 1 if ($_ eq '.svn' || $_ eq 'Translations'
								|| $_ eq 'devel-tools');
	return if -d;
	print "$File::Find::name...\n" if $verbose;
	open(F, "< $_")
		or die "could not open file $_ for reading!";
	$/ = undef;
	my $text = <F>;
	close(F);
	$fileCount++;
	while($text =~ m[_tr\s*\(\s*(.+?)\s*\)\s*;]gos) {
		# NOTE: that cheesy regex relies on the string ');' not being used
		#       inside of translatable strings... so SLX_DONT_DO_THAT!
		#		As an alternative, we could implement a real parser, but
		#		I'd like to postpone that until the current scheme proves
		#		simply not good enough.
		my $tr = $1;
		if (!($tr =~ m[^'([^']+)'\s*(,.+?)*\s*$]os
		|| $tr =~ m[^\"([^"]+)\"\s*(,.+?)*\s*$]os
		|| $tr =~ m{^qq?\[([^\]]+)\]\s*(,.+?)*\s*$}os)) {
			die "$File::Find::name: could not parse _tr()-argument: \n"
				."$tr\nPlease correct and retry.\n";
		}
		$tr = $1;
		$tr =~ s[\n][\\n]g;
		$tr =~ s[\t][\\t]g;
		$translatableStrings{$tr} = $tr;
		print "\t$tr\n" if $verbose;
	}
}

sub UpdateTrModule
{
	$File::Find::prune = 1 if ($_ eq '.svn');
	return if -d || ! /.pm$/;
	print "updating $File::Find::name...\n";
	my $trModule = $_;
	my $useKeyAsTranslation = ($trModule eq 'posix.pm');
	open(F, "< $trModule")
		or die "could not open file $trModule for reading!";
	$/ = undef;
	my $text = <F>;
	close(F);
	if ($text !~ m[%translations\s*=\s*\(\s*(.+)\s*\);]os) {
		print "\t*** No translations found (?!?) file will be skipped! ***\n";
		return;
	}
	my %translations;
	# evaluate the hash read from file into %translations:
	if (!eval "$&") {
		print "\t*** translations can't be evaluated (?!?) file will be skipped! ***\n";
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
		open(F, "> $trModule")
			or die "could not open file $trModule for writing!";
		print F "$text\n";
		close(F);
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

extractTranslations.pl [options] path

  Options:
      --help                   brief help message
      --update-path=<string>   update the OpenSLX locale modules in given
                               path
      --show                   show overview of all strings found
      --verbose                show for each file which strings are found
      --version                show version

=head1 OPTIONS

=over 8

=item B<--help>

Prints a brief help message and exits.

=item B<--show>

Prints sorted list of all translatable strings that were found.

=item B<--update-path=<string>>

Integrates the found translatable strings into all OpenSLX locale modules found
in path (which should end in 'Translations').
Every module will be updated with the found strings, existing
translations will not be changed (unless the corresponding key doesn't exist
anymore, in which case they will be removed).

=item B<--verbose>

Prints information about what's going on during execution of the script.

=item B<--version>

Prints the version and exits.

=back

=cut