# posix.pm - OpenSLX-translations for the posix locale (English language).
#
# (c) 2006 - OpenSLX.com
#
# Oliver Tappe <ot@openslx.com>
#
package ODLX::Translations::posix;

use strict;
use vars qw(@ISA @EXPORT $VERSION);

use Exporter;
$VERSION = 0.02;
@ISA = qw(Exporter);

@EXPORT = qw(%translations);

use vars qw(%translations);

################################################################################
### Translations
################################################################################

%translations = (
	'Could not determine schema version of database'
		=> 'Could not determine schema version of database',
	'Unable to load DB-module <%s> (%s)'
		=> 'Unable to load DB-module <%s> (%s)',
	'Unable to load module <%s> (Version <%s> required, but <%s> found)'
		=> 'Unable to load module <%s> (Version <%s> required, but <%s> found)',
	'UnknownDbSchemaCommand'
		=> 'Unknown DbSchema command <%s> found',
	'UnknownDbSchemaColumnDescr'
		=> 'Unknown DbSchema column description <%s> found',
	'UnknownDbSchemaTypeDescr'
		=> 'Unknown DbSchema type description <%s> found',
);

1;