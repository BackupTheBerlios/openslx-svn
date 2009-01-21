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

use File::Find;
use Getopt::Long;
use Pod::Usage;

my (
	$helpReq,
	$update,
	$verbose,
	$versionReq,

	%translatableStrings,
);

GetOptions(
	'help|?' => \$helpReq,
	'update' => \$update,
	'verbose' => \$verbose,
	'version' => \$versionReq,
) or pod2usage(2);
pod2usage(1) if $helpReq;
if ($versionReq) {
	system('slxversion');
	exit 1;
}

use FindBin;
chdir("$FindBin::RealBin/../../config-db")
	or die "unable to find 'config-db'-folder (should be '..' from script)";
		# always start in 'config-db' - folder

find(\&ExtractTrStrings, '.');

if ($update) {
	find(\&UpdateTrModule, 'OpenSLX/Translations');
} else {
	foreach my $tr (sort {lc($a) cmp lc($b)} keys %translatableStrings) {
		print "\tqq{$tr}\n\t\t=> qq{$tr}\n";
	}
}

sub ExtractTrStrings
{
	$File::Find::prune = 1 if ($_ eq '.svn' || $_ eq 'Translations');
	return if -d;
	print "$File::Find::name...\n" if $verbose;
	open(F, "< $_")
		or die "could not open file $_ for reading!";
	$/ = undef;
	my $text = <F>;
	close(F);
	while($text =~ m[_tr\s*\(\s*('[^']+'|\"[^"]+\")\s*(?:,.+?)?\)\s*;]gos) {
		my $tr = substr($1, 1, -1);
		$translatableStrings{$tr} = $tr;
		print "\t$tr\n" if $verbose;
	}
}

sub UpdateTrModule
{
	$File::Find::prune = 1 if ($_ eq '.svn');
	return if -d;
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
	if (!eval "$&") {
		print "\t*** Something No translations found (?!?) file will be skipped! ***\n";
	my $updatedTranslations = "%translations = (\n";
	foreach my $tr (sort {lc($a) cmp lc($b)} keys %translatableStrings) {
		if (!exists $translations{$tr} && $useKeyAsTranslation) {
			# POSIX language: use key as translation:
			$updatedTranslations
				.= "\tqq{$tr}\n\t\t => qq{$tr},\n\n";
		} else {
			# use existing translation for key:
			$updatedTranslations
				.= "\tqq{$tr}\n\t\t => qq{$translations{$tr}},\n\n";
		}
	}
	$text =~ s[%translations\s*=\s*\(\s*(.+)\s*\);]
			  [$updatedTranslations);\n]os;
	chomp $text;
	open(F, "> $trModule")
		or die "could not open file $trModule for writing!";
	print F "$text\n";
	close(F);
}

__END__

=head1 NAME

extractTranslations.pl - OpenSLX-script to extract translatable strings from
other scripts and modules.

=head1 SYNOPSIS

extractTranslations.pl [options] [path]

  Options:
      --help              brief help message
      --update            update the OpenSLX locale modules
      --verbose           show what's going on
      --version           show version

=head1 OPTIONS

=over 8

=item B<--help>

Prints a brief help message and exits.

=item B<--update>

Integrates the found translatable strings into all OpenSLX locale modules, i.e.
every module will be updated with the found strings, existing translations
will not be changed (unless the corresponding key doesn't exist anymore, in
which case they will be removed).

=item B<--verbose>

Prints information about what's going on during execution of the script.

=item B<--version>

Prints the version and exits.

=back

=head1 DESCRIPTION

B<extractTranslations.pl> can be used to