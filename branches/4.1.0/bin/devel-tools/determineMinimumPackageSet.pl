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
use strict;

my $abstract = q[
determineMinimumPackageSet.pl
    This script is a tool for OpenSLX developers that allows to extract
    the minimal package-set from all the installed rpm packages.
    "Minimum" here means those packages only that are not
    required by other installed packages (a.k.a. the leaves of the RPM
    dependency graph).
    This minimal set is useful to simplify the commandline for yum when
    it is invoked to install a specific selection.
];

use Getopt::Long;
use Pod::Usage;

my (
	$helpReq,
	$verbose,
	$versionReq,

	%pkgs,
	@leafPkgs,
);

my $rpmOutFile = "/tmp/minpkgset.rpmout";
my $rpmErrFile = "/tmp/minpkgset.rpmerr";

GetOptions(
	'help|?' => \$helpReq,
	'verbose' => \$verbose,
	'version' => \$versionReq,
) or pod2usage(2);
pod2usage(-msg => $abstract, -verbose => 0, -exitval => 1) if $helpReq;
if ($versionReq) {
	system('slxversion');
	exit 1;
}

determineMinimumPackageSet();

print "THE MINIMUM PACKAGE LIST:\n";
print(('-' x 40)."\n");
print join("\n", sort @leafPkgs)."\n";

exit;

sub slurpFile
{
	my $file = shift;

	if (!open(F, "< $file")) {
		die _tr("could not open file '%s' for reading! (%s)", $file, $!);
	}
	local $/ = undef;
	my $text = <F>;
	close(F);
	return $text;
}

sub rpmDie
{
	my $rpmCmd = shift;

	print "\n*** An error occurred when executing the following rpm-command:\n";
	print "\t$rpmCmd\n";
	my $err = slurpFile($rpmErrFile);
	print "*** The error was:\n";
	print "\t$err\n";
	exit 5;
}

sub callRpm
{
	my $rpmCmd = shift;

	my $res	= system("$rpmCmd >$rpmOutFile 2>$rpmErrFile");
	exit 1 if ($res & 127);		# child caught a signal
	rpmDie($rpmCmd) if -s $rpmErrFile;
	my $out = slurpFile($rpmOutFile);
	return ($res, $out);
}

sub handlePackage
{
	my $pkgName = shift;

	# if any other package requires it, the current package is not a leaf!
	print "\tdirectly required..." 		if $verbose;
	my ($rpmRes, $rpmOut) = callRpm(qq[rpm -q --whatrequires "$pkgName"]);
	print $rpmRes ? "no\n" : "yes\n" 		if $verbose;
	return 0 unless $rpmRes;

	print "\tany of its provides required..." 		if $verbose;
	($rpmRes, $rpmOut) = callRpm(qq[rpm -q --provides "$pkgName"]);
	my $provides
		=	join ' ',
			map { s[^\s*(.+?)\s*$][$1]; qq["$_"]; }
			split "\n", $rpmOut;
	($rpmRes, $rpmOut) = callRpm(qq[rpm -q --whatrequires $provides]);
	if ($rpmRes == 0) {
		# ignore if rpm tells us that a provides is required by
		# the package that provides it:
		$rpmRes = 1;
		while($rpmOut =~ m[^\s*(.+?)\s*]gm) {
			if ($1 ne $pkgName) {
				$rpmRes = 0;
				last;
			}
		}
	}
	print $rpmRes ? "no\n" : "yes\n" 		if $verbose;
	return 0 unless $rpmRes;

	print "!!! adding $pkgName\n"		if $verbose;
	push @leafPkgs, $pkgName;
	return 1;
}

sub determineMinimumPackageSet
{
	my ($rpmRes, $allPkgs)
		= callRpm(qq[rpm -qa --queryformat "%{NAME}\n"]);
	foreach my $p (sort split "\n", $allPkgs) {
		print "$p...\n" 		if $verbose;
		print "."		unless $verbose;
		handlePackage($p);
	}
}

__END__

=head1 NAME

determineMinimumPackageSet.pl - OpenSLX script to extract the minimum package
set from all the installed rpm packages.

=head1 SYNOPSIS

determineMinimumPackageSet.pl [options]

  Options:
      --help                   brief help message
      --verbose                show files as they are being processed
      --version                show version

=head1 OPTIONS

=over 8

=item B<--help>

Prints a brief help message and exits.

=item B<--verbose>

Prints information about each installed package as it is being processed.

=item B<--version>

Prints the version and exits.

=back

=cut