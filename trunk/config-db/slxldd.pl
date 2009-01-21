#! /usr/bin/perl
#
# slxldd.pl - OpenSLX-rewrite of ldd that works on multiple architectures.
#
# (c) 2006 - OpenSLX.com
#
# Oliver Tappe <ot@openslx.com>
#
use strict;

my $abstract = q[
slxldd.pl
    This script reimplements ldd in a way that should work for all
    binary formats supported by the binutils installed on the host system.

    An example: if you have a folder containing an ia64 system, you can
    invoke this script on a ia32-host in order to determine all the libraries
    required by a binary of the ia64 target system.
];

use File::Glob ':globally';
use Getopt::Long;
use Pod::Usage;

use OpenSLX::Basics;

my (
	$helpReq,
	$rootPath,
	$versionReq,

	@libFolders,
	@libs,
	%libInfo,
);

GetOptions(
	'help|?' => \$helpReq,
	'root-path=s' => \$rootPath,
	'version' => \$versionReq,
) or pod2usage(2);
pod2usage(-msg => $abstract, -verbose => 0, -exitval => 1) if $helpReq;
if ($versionReq) {
	system('slxversion');
	exit 1;
}

openslxInit();

if (!$rootPath) {
	print _tr("You need to specify the root-path!\n");
	pod2usage(2);
}

$rootPath =~ s[/+$][];
	# remove trailing slashes

if (!@ARGV) {
	print _tr("You need to specify at least one file!\n");
	pod2usage(2);
}

fetchLoaderConfig();

foreach my $file (@ARGV) {
	if ($file =~ m[^/]) {
		# force absolute path relative to $rootPath:
		$file = "$rootPath$file";
	} else {
		# relative paths are relative to $rootPath:
		$file = "$rootPath/$file";
	}

	next if `file $file` =~ m[shell\s+script];
		# silently ignore shell scripts

	addLibsForBinary($file);
}

sub fetchLoaderConfigFile
{
	my $ldConfFile = shift;

	open(LDCONF, "< $ldConfFile");
	while(<LDCONF>) {
		chomp;
		if (/^\s*include\s+(.+?)\s*$/i) {
			foreach my $incFile (<$rootPath$1>) {
				fetchLoaderConfigFile($incFile);
			}
			next;
		}
		if (/\S+/i) {
			s[=.+][];
				# remove any lib-type specifications (e.g. '=libc5')
			push @libFolders, "$rootPath$_";
		}
	}
	close LDCONF;
}

sub fetchLoaderConfig
{
	if (!-e "$rootPath/etc/ld.so.conf") {
		die _tr("$rootPath/etc/ld.so.conf not found, maybe wrong root-path?\n");
	}
	fetchLoaderConfigFile("$rootPath/etc/ld.so.conf");

	# add "trusted" folders /lib and /usr/lib if not already in place:
	if (!grep { m[^$rootPath/lib$]}  @libFolders) {
		push @libFolders, "$rootPath/lib";
	}
	if (!grep { m[^$rootPath/usr/lib$] } @libFolders) {
		push @libFolders, "$rootPath/usr/lib";
	}
}

sub addLib
{
	my $lib = shift;

	if (!exists $libInfo{$lib}) {
		push @libs, $lib;
		my $libPath;
		foreach my $folder (@libFolders) {
			if (-e "$folder/$lib") {
				$libPath = "$folder/$lib";
				last;
			}
		}
		if (!defined $libPath) {
			die _tr("*** unable to find lib %s! ***\n", $lib);
		}
		print "$libPath\n";
		$libInfo{$lib} = $libPath;
		addLibsForBinary($libPath);
	}
}

sub addLibsForBinary
{
	my $binary = shift;

	# we try objdump...
	my $res = `objdump -p $binary 2>/dev/null`;
	if (!$?) {
		while($res =~ m[^\s*NEEDED\s*(.+?)\s*$]gm) {
			addLib($1);
		}
	} else {
		# ...objdump failed, so we try readelf instead:
		$res = `readelf -d $binary 2>/dev/null`;
		if ($?) {
			die _tr("neither objdump nor readelf seems to be installed, giving up!\n");
		}
		while($res =~ m{\(NEEDED\)[^\[]+\[(.+?)\]\s*$}gm) {
			addLib($1);
		}
	}
}


__END__

=head1 NAME

slxldd.pl - OpenSLX-script to determine the libraries required by any given
binary file.

=head1 SYNOPSIS

slxldd.pl [options] file [...more files]

  Options:
      --help                   brief help message
      --root-path=<string>     path to the root folder for library search
      --version                show version

=head1 OPTIONS

=over 8

=item B<--help>

Prints a brief help message and exits.

=item B<--root-path=<string>>

Sets the root folder that is used when searching for libraries. In order to
collect the loader-settings, etc/ld.so.conf is read relative to this path and
all libraries are sought relative to this path, too (a.k.a. a virtual chroot).

=item B<--version>

Prints the version and exits.

=back

=cut