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
# AttributeRoster.pm
#	- provides information about all available attributes
# -----------------------------------------------------------------------------
package OpenSLX::AttributeRoster;

use strict;
use warnings;

our (@ISA, @EXPORT, $VERSION);

use Exporter;
$VERSION = 0.2;
@ISA = qw(Exporter);

@EXPORT = qw(
	$%AttributeInfo
);

use OpenSLX::Basics;

################################################################################
###
### Load the available AttrInfo-modules and build a hash containing info about
### all known attributes from the data contained in those modules.
###
################################################################################

my %AttributeInfo = ();

my $libPath = "$openslxConfig{'base-path'}/lib";
foreach my $module (glob("$libPath/OpenSLX/AttrInfo/*.pm")) {
	next if $module !~ m{/([^/]+)\.pm$};
	my $class = "OpenSLX::AttrInfo::$1";
	vlog(2, "loading attr-info from module '$module'");
	my $instance = instantiateClass($class);
	my $attrInfo = $instance->AttrInfo();
	foreach my $attr (keys %$attrInfo) {
		$AttributeInfo{$attr} = $attrInfo->{$attr};
	}
}

=item C<getAttrInfo()>

Returns info about all attributes.

=over

=item Return Value

An hash-ref with info about all known attributes.

=back

=cut

sub getAttrInfo
{
	my $class = shift;
	my $name  = shift;

	if (defined $name) {
		my $attrInfo = $AttributeInfo{$name};
		return if !defined $attrInfo;
		return { $name => $AttributeInfo{$name} };
	}

	return \%AttributeInfo;
}

=item C<getSystemAttrs()>

Returns the attribute names that apply to systems.

=over

=item Return Value

An array of attribute names.

=back

=cut

sub getSystemAttrs
{
	my $class = shift;

	return 
		grep { $AttributeInfo{$_}->{"applies_to_systems"} }
		keys %AttributeInfo
}

=item C<getClientAttrs()>

Returns the attribute names that apply to clients.

=over

=item Return Value

An array of attribute names.

=back

=cut

sub getClientAttrs
{
	my $class = shift;

	return 
		grep { $AttributeInfo{$_}->{"applies_to_clients"} }
		keys %AttributeInfo
}

1;
