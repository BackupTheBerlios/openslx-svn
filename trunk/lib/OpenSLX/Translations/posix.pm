# posix.pm - OpenSLX-translations for the posix locale (English language).
#
# (c) 2006 - OpenSLX.com
#
# Oliver Tappe <ot@openslx.com>
#
package OpenSLX::Translations::posix;

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
	q{%s doesn't seem to be installed,\nso there is no support for %s available, sorry!\n}
	=>
	qq{%s doesn't seem to be installed,\nso there is no support for %s available, sorry!\n},

	q{Can't add column to table <%s> (%s)}
	=>
	qq{Can't add column to table <%s> (%s)},

	q{Can't add columns to table <%s> (%s)}
	=>
	qq{Can't add columns to table <%s> (%s)},

	q{Can't change columns in table <%s> (%s)}
	=>
	qq{Can't change columns in table <%s> (%s)},

	q{Can't create table <%s> (%s)}
	=>
	qq{Can't create table <%s> (%s)},

	q{Can't delete from table <%s> (%s)}
	=>
	qq{Can't delete from table <%s> (%s)},

	q{Can't drop columns from table <%s> (%s)}
	=>
	qq{Can't drop columns from table <%s> (%s)},

	q{Can't drop table <%s> (%s)}
	=>
	qq{Can't drop table <%s> (%s)},

	q{Can't execute SQL-statement <%s> (%s)}
	=>
	qq{Can't execute SQL-statement <%s> (%s)},

	q{Can't insert into table <%s> (%s)}
	=>
	qq{Can't insert into table <%s> (%s)},

	q{Can't lock ID-file <%s> (%s)}
	=>
	qq{Can't lock ID-file <%s> (%s)},

	q{Can't open ID-file <%s> (%s)}
	=>
	qq{Can't open ID-file <%s> (%s)},

	q{Can't prepare SQL-statement <%s> (%s)}
	=>
	qq{Can't prepare SQL-statement <%s> (%s)},

	q{Can't rename table <%s> (%s)}
	=>
	qq{Can't rename table <%s> (%s)},

	q{Can't to seek ID-file <%s> (%s)}
	=>
	qq{Can't to seek ID-file <%s> (%s)},

	q{Can't truncate ID-file <%s> (%s)}
	=>
	qq{Can't truncate ID-file <%s> (%s)},

	q{Can't update ID-file <%s> (%s)}
	=>
	qq{Can't update ID-file <%s> (%s)},

	q{Can't update table <%s> (%s)}
	=>
	qq{Can't update table <%s> (%s)},

	q{Cannot connect to database <%s> (%s)}
	=>
	qq{Cannot connect to database <%s> (%s)},

	q{config-file <%s> has incorrect syntax here:\n\t%s\n}
	=>
	qq{config-file <%s> has incorrect syntax here:\n\t%s\n},

	q{copying kernel %s to %s/kernel}
	=>
	qq{copying kernel %s to %s/kernel},

	q{Could not determine schema version of database}
	=>
	qq{Could not determine schema version of database},

	q{Could not load module <%s> (Version <%s> required, but <%s> found)}
	=>
	qq{Could not load module <%s> (Version <%s> required, but <%s> found)},

	q{creating tar %s}
	=>
	qq{creating tar %s},

	q{DB matches current schema version %s}
	=>
	qq{DB matches current schema version %s},

	q{executing %s}
	=>
	qq{executing %s},

	q{exporting client %d:%s}
	=>
	qq{exporting client %d:%s},

	q{exporting system %d:%s}
	=>
	qq{exporting system %d:%s},

	q{generating initialramfs %s/initramfs}
	=>
	qq{generating initialramfs %s/initramfs},

	q{ignoring unknown key <%s>}
	=>
	qq{ignoring unknown key <%s>},

	q{Lock-file <%s> exists, script is already running.\nPlease remove the logfile and try again if you are sure that no one else is executing this script.}
	=>
	qq{Lock-file <%s> exists, script is already running.\nPlease remove the logfile and try again if you are sure that no one else is executing this script.},

	q{merging %s (val=%s)}
	=>
	qq{merging %s (val=%s)},

	q{merging from default client...}
	=>
	qq{merging from default client...},

	q{merging from group %d:%s...}
	=>
	qq{merging from group %d:%s...},

	q{no}
	=>
	qq{no},

	q{Our schema-version is %s, DB is %s, upgrading DB...}
	=>
	qq{Our schema-version is %s, DB is %s, upgrading DB...},

	q{PXE-system %s already exists!}
	=>
	qq{PXE-system %s already exists!},

	q{removing %s}
	=>
	qq{removing %s},

	q{setting %s to <%s>}
	=>
	qq{setting %s to <%s>},

	q{system-error: illegal target-path <%s>!}
	=>
	qq{system-error: illegal target-path <%s>!},

	q{This will overwrite the current OpenSLX-database with an example dataset.\nAll your data (%s systems and %s clients) will be lost!\nDo you want to continue(%s/%s)? }
	=>
	qq{This will overwrite the current OpenSLX-database with an example dataset.\nAll your data (%s systems and %s clients) will be lost!\nDo you want to continue(%s/%s)? },

	q{translations module %s loaded successfully}
	=>
	qq{translations module %s loaded successfully},

	q{Unable to access client-config-path '%s'!}
	=>
	qq{Unable to access client-config-path '%s'!},

	q{Unable to create or access temp-path '%s'!}
	=>
	qq{Unable to create or access temp-path '%s'!},

	q{Unable to create or access tftpboot-path '%s'!}
	=>
	qq{Unable to create or access tftpboot-path '%s'!},

	q{unable to execute shell-command:\n\t%s \n\t(%s)}
	=>
	qq{unable to execute shell-command:\n\t%s \n\t(%s)},

	q{Unable to load DB-module <%s> (%s)}
	=>
	qq{Unable to load DB-module <%s> (%s)},

	q{Unable to load module <%s> (Version <%s> required)}
	=>
	qq{Unable to load module <%s> (Version <%s> required)},

	q{Unable to load module <%s> (Version <%s> required, but <%s> found)}
	=>
	qq{Unable to load module <%s> (Version <%s> required, but <%s> found)},

	q{Unable to write local settings file <%s> (%s)}
	=>
	qq{Unable to write local settings file <%s> (%s)},

	q{UnknownDbSchemaColumnDescr}
	=>
	qq{Unknown DbSchema column description <%s> found},

	q{UnknownDbSchemaCommand}
	=>
	qq{Unknown DbSchema command <%s> found},

	q{UnknownDbSchemaTypeDescr}
	=>
	qq{Unknown DbSchema type description <%s> found},

	q{upgrade done}
	=>
	qq{upgrade done},

	q{writing PXE-file %s}
	=>
	qq{writing PXE-file %s},

	q{yes}
	=>
	qq{yes},

);





1;








