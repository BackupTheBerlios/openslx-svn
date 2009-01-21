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
# OSPlugin::Roster.pm
#	- provides information about all available plugins
# -----------------------------------------------------------------------------
package OpenSLX::OSPlugin::Roster;

use strict;
use warnings;

use OpenSLX::Basics;

=item C<addAllDefaultAttributesToHash()>

Fetches attribute info from all available plugins and adds it to the given
hash-ref.

=over

=item Return Value

1

=back

=cut

sub addAllDefaultAttributesToHash
{
	my $class    = shift;
	my $attrInfo = shift;

	my $pluginPath = "$openslxConfig{'base-path'}/lib/plugins";
	foreach my $modulePath (glob("$pluginPath/*")) {
		next if $modulePath !~ m{/([^/]+)$};
		my $pluginName = $1;
		my $class = "OpenSLX::OSPlugin::$pluginName";
		vlog(2, "loading plugin $class from path '$modulePath'");
		my $plugin = instantiateClass($class, { pathToClass => $modulePath });
		my $pluginAttrInfo = $plugin->getAttrInfo();
		foreach my $attr (keys %$pluginAttrInfo) {
			$attrInfo->{$attr} = $pluginAttrInfo->{$attr};
		}
	}
	return 1;
}

1;
