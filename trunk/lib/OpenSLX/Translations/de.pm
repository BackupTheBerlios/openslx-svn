# de.pm - OpenSLX-translations for the German language.
#
# (c) 2006 - OpenSLX.com
#
# Oliver Tappe <ot@openslx.com>
#
package OpenSLX::Translations::de;

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
	q{NEW:%s doesn't seem to be installed,\nso there is no support for %s available, sorry!\n}
	=>
	qq{},

	q{NEW:%s has wrong bitwidth (%s instead of %s)}
	=>
	qq{},

	q{NEW:%s: ignored, as it isn't an executable or a shared library\n}
	=>
	qq{},

	q{NEW:'%s' already exists!\n}
	=>
	qq{},

	q{NEW:'%s' not found, maybe wrong root-path?\n}
	=>
	qq{},

	q{NEW:\trpath='%s'\n}
	=>
	qq{},

	q{NEW:\ttrying objdump...\n}
	=>
	qq{},

	q{NEW:\ttrying readelf...\n}
	=>
	qq{},

	q{NEW:analyzing '%s'...\n}
	=>
	qq{},

	q{NEW:Can't add column to table <%s> (%s)}
	=>
	qq{},

	q{NEW:Can't add columns to table <%s> (%s)}
	=>
	qq{},

	q{NEW:Can't change columns in table <%s> (%s)}
	=>
	qq{},

	q{NEW:Can't create table <%s> (%s)}
	=>
	qq{},

	q{NEW:Can't delete from table <%s> (%s)}
	=>
	qq{},

	q{NEW:Can't drop columns from table <%s> (%s)}
	=>
	qq{},

	q{NEW:Can't drop table <%s> (%s)}
	=>
	qq{},

	q{NEW:Can't execute SQL-statement <%s> (%s)}
	=>
	qq{},

	q{NEW:Can't insert into table <%s> (%s)}
	=>
	qq{},

	q{NEW:Can't lock ID-file <%s> (%s)}
	=>
	qq{},

	q{NEW:Can't open ID-file <%s> (%s)}
	=>
	qq{},

	q{NEW:Can't prepare SQL-statement <%s> (%s)}
	=>
	qq{},

	q{NEW:Can't rename table <%s> (%s)}
	=>
	qq{},

	q{NEW:Can't to seek ID-file <%s> (%s)}
	=>
	qq{},

	q{NEW:Can't truncate ID-file <%s> (%s)}
	=>
	qq{},

	q{NEW:Can't update ID-file <%s> (%s)}
	=>
	qq{},

	q{NEW:Can't update table <%s> (%s)}
	=>
	qq{},

	q{NEW:Cannot connect to database <%s> (%s)}
	=>
	qq{},

	q{NEW:config-file <%s> has incorrect syntax here:\n\t%s\n}
	=>
	qq{},

	q{NEW:copying kernel %s to %s/kernel}
	=>
	qq{},

	q{Could not determine schema version of database}
	=>
	qq{Die Version des Datenbank-Schemas konnte nicht bestimmt werden},

	q{NEW:Could not load module <%s> (Version <%s> required, but <%s> found)}
	=>
	qq{},

	q{NEW:creating tar %s}
	=>
	qq{},

	q{NEW:DB matches current schema version %s}
	=>
	qq{},

	q{NEW:executing %s}
	=>
	qq{},

	q{NEW:exporting client %d:%s}
	=>
	qq{},

	q{NEW:exporting system %d:%s}
	=>
	qq{},

	q{NEW:generating initialramfs %s/initramfs}
	=>
	qq{},

	q{NEW:ignoring unknown key <%s>}
	=>
	qq{},

	q{NEW:List of supported systems:\n\t}
	=>
	qq{},

	q{NEW:Lock-file <%s> exists, script is already running.\nPlease remove the logfile and try again if you are sure that no one else\nis executing this script.\n}
	=>
	qq{},

	q{NEW:merging %s (val=%s)}
	=>
	qq{},

	q{NEW:merging from default client...}
	=>
	qq{},

	q{NEW:merging from group %d:%s...}
	=>
	qq{},

	q{NEW:neither objdump nor readelf seems to be installed, giving up!\n}
	=>
	qq{},

	q{no}
	=>
	qq{nein},

	q{NEW:Our schema-version is %s, DB is %s, upgrading DB...}
	=>
	qq{},

	q{NEW:PXE-system %s already exists!}
	=>
	qq{},

	q{NEW:removing %s}
	=>
	qq{},

	q{NEW:setting %s to <%s>}
	=>
	qq{},

	q{NEW:slxldd: unable to find file '%s', skipping it\n}
	=>
	qq{},

	q{NEW:Sorry, system '%s' is unsupported.\n}
	=>
	qq{},

	q{NEW:system-error: illegal target-path <%s>!}
	=>
	qq{},

	q{This will overwrite the current OpenSLX-database with an example dataset.\nAll your data (%s systems and %s clients) will be lost!\nDo you want to continue(%s/%s)? }
	=>
	qq{Die aktuelle OpenSLX-Datenbank wird mit einem Beispiel-Datensatz überschrieben.\nAlle Daten (%s Systeme und %s Clients) werden gelöscht!\nMöchten Sie den Vorgang fortsetzen(%s/%s)? },

	q{NEW:translations module %s loaded successfully}
	=>
	qq{},

	q{NEW:Unable to access client-config-path '%s'!}
	=>
	qq{},

	q{NEW:unable to create db-datadir %s! (%s)\n}
	=>
	qq{},

	q{NEW:Unable to create lock-file <%s>, exiting!\n}
	=>
	qq{},

	q{NEW:Unable to create or access temp-path '%s'!}
	=>
	qq{},

	q{NEW:Unable to create or access tftpboot-path '%s'!}
	=>
	qq{},

	q{NEW:unable to execute shell-command:\n\t%s \n\t(%s)}
	=>
	qq{},

	q{NEW:unable to fetch file info for '%s', giving up!\n}
	=>
	qq{},

	q{NEW:Unable to load DB-module <%s> (%s)\n}
	=>
	qq{},

	q{NEW:Unable to load DB-module <%s>\nthat database type is not supported (yet?)\n}
	=>
	qq{},

	q{NEW:unable to load DHCP-Export backend '%s'! (%s)\n}
	=>
	qq{},

	q{NEW:Unable to load module <%s> (Version <%s> required)}
	=>
	qq{},

	q{NEW:Unable to load module <%s> (Version <%s> required, but <%s> found)}
	=>
	qq{},

	q{NEW:Unable to load system-module <%s> (%s)\n}
	=>
	qq{},

	q{NEW:Unable to load system-module <%s>!\n}
	=>
	qq{},

	q{NEW:Unable to write local settings file <%s> (%s)}
	=>
	qq{},

	q{NEW:unknown settings key <%s>!\n}
	=>
	qq{},

	q{NEW:UnknownDbSchemaColumnDescr}
	=>
	qq{},

	q{UnknownDbSchemaCommand}
	=>
	qq{Unbekannter DbSchema-Befehl <%s> wird übergangen},

	q{NEW:UnknownDbSchemaTypeDescr}
	=>
	qq{},

	q{NEW:upgrade done}
	=>
	qq{},

	q{NEW:writing dhcp-config for %s clients}
	=>
	qq{},

	q{NEW:writing PXE-file %s}
	=>
	qq{},

	q{yes}
	=>
	qq{ja},

	q{NEW:You need to specify at least one file!\n}
	=>
	qq{},

	q{NEW:You need to specify exactly one system name!\n}
	=>
	qq{},

	q{NEW:You need to specify the root-path!\n}
	=>
	qq{},

);

1;









