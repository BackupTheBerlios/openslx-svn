# de_de_utf_8.pm - OpenSLX-translations for the German language.
#
# (c) 2006 - OpenSLX.com
#
# Oliver Tappe <ot@openslx.com>
#
package OpenSLX::Translations::de_de_utf_8;

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
	qq{NEW:config-file <%s> has incorrect syntax here:\n\t%s\n}
	=>
	qq{},

	qq{NEW:copying kernel %s to %s/kernel}
	=>
	qq{},

	qq{Could not determine schema version of database}
	=>
	qq{Die Version des Datenbank-Schemas konnte nicht bestimmt werden},

	qq{NEW:Could not load module <%s> (Version <%s> required, but <%s> found)}
	=>
	qq{},

	qq{NEW:creating tar %s}
	=>
	qq{},

	qq{NEW:DB matches current schema version %s}
	=>
	qq{},

	qq{NEW:executing %s}
	=>
	qq{},

	qq{NEW:exporting client %d:%s}
	=>
	qq{},

	qq{NEW:exporting system %d:%s}
	=>
	qq{},

	qq{NEW:generating initialramfs %s/initramfs}
	=>
	qq{},

	qq{NEW:ignoring unknown key <%s>}
	=>
	qq{},

	qq{NEW:merging %s (val=%s)}
	=>
	qq{},

	qq{NEW:merging from default client...}
	=>
	qq{},

	qq{NEW:merging from group %d:%s...}
	=>
	qq{},

	qq{NEW:no}
	=>
	qq{},

	qq{NEW:Our schema-version is %s, DB is %s, upgrading DB...}
	=>
	qq{},

	qq{NEW:PXE-system %s already exists!}
	=>
	qq{},

	qq{NEW:removing %s}
	=>
	qq{},

	qq{NEW:setting %s to <%s>}
	=>
	qq{},

	qq{NEW:system-error: illegal target-path <%s>!}
	=>
	qq{},

	qq{NEW:translations module %s loaded successfully}
	=>
	qq{},

	qq{NEW:Unable to access client-config-path '%s'!}
	=>
	qq{},

	qq{NEW:Unable to create or access temp-path '%s'!}
	=>
	qq{},

	qq{NEW:Unable to create or access tftpboot-path '%s'!}
	=>
	qq{},

	qq{unable to execute shell-command:\n\t%s \n\t(%s)}
	=>
	qq{Konnte Shell-Kommando nicht ausführen:\n\t%s\n\t(%s)},

	qq{Unable to load DB-module <%s> (%s)}
	=>
	qq{Kann DB-Modul <%s> nicht laden (%s)},

	qq{NEW:Unable to load module <%s> (Version <%s> required)}
	=>
	qq{},

	qq{NEW:Unable to load module <%s> (Version <%s> required, but <%s> found)}
	=>
	qq{},

	qq{NEW:Unable to write local settings file <%s> (%s)}
	=>
	qq{},

	qq{NEW:UnknownDbSchemaColumnDescr}
	=>
	qq{},

	qq{UnknownDbSchemaCommand}
	=>
	qq{Unbekannter DbSchema-Befehl <%s> wird übergangen},

	qq{NEW:UnknownDbSchemaTypeDescr}
	=>
	qq{},

	qq{NEW:upgrade done}
	=>
	qq{},

	qq{NEW:writing PXE-file %s}
	=>
	qq{},

	qq{NEW:yes}
	=>
	qq{},

);

1;





