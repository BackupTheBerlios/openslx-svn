package ODLX::Translations::de_de_utf_8;

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
		=> 'Die Version des Datenbank-Schemas konnte nicht bestimmt werden',
	'Unable to load DB-module <%s> (%s)'
		=> 'Kann DB-Modul <%s> nicht laden (%s)',
	'UnknownDbSchemaCommand'
		=> 'Unbekannter DbSchema-Befehl <%s> wird übergangen',
);

1;