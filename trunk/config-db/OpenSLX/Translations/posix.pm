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
	qq{config-file <%s> has incorrect syntax here:\n\t%s\n}
	=>
	qq{config-file <%s> has incorrect syntax here:\n\t%s\n},

	qq{copying kernel %s to %s/kernel}
	=>
	qq{copying kernel %s to %s/kernel},

	qq{Could not determine schema version of database}
	=>
	qq{Could not determine schema version of database},

	qq{Could not load module <%s> (Version <%s> required, but <%s> found)}
	=>
	qq{Could not load module <%s> (Version <%s> required, but <%s> found)},

	qq{creating tar %s}
	=>
	qq{creating tar %s},

	qq{DB matches current schema version %s}
	=>
	qq{DB matches current schema version %s},

	qq{executing %s}
	=>
	qq{executing %s},

	qq{exporting client %d:%s}
	=>
	qq{exporting client %d:%s},

	qq{exporting system %d:%s}
	=>
	qq{exporting system %d:%s},

	qq{generating initialramfs %s/initramfs}
	=>
	qq{generating initialramfs %s/initramfs},

	qq{ignoring unknown key <%s>}
	=>
	qq{ignoring unknown key <%s>},

	qq{merging %s (val=%s)}
	=>
	qq{merging %s (val=%s)},

	qq{merging from default client...}
	=>
	qq{merging from default client...},

	qq{merging from group %d:%s...}
	=>
	qq{merging from group %d:%s...},

	qq{no}
	=>
	qq{no},

	qq{Our schema-version is %s, DB is %s, upgrading DB...}
	=>
	qq{Our schema-version is %s, DB is %s, upgrading DB...},

	qq{PXE-system %s already exists!}
	=>
	qq{PXE-system %s already exists!},

	qq{removing %s}
	=>
	qq{removing %s},

	qq{setting %s to <%s>}
	=>
	qq{setting %s to <%s>},

	qq{system-error: illegal target-path <%s>!}
	=>
	qq{system-error: illegal target-path <%s>!},

	qq{translations module %s loaded successfully}
	=>
	qq{translations module %s loaded successfully},

	qq{Unable to access client-config-path '%s'!}
	=>
	qq{Unable to access client-config-path '%s'!},

	qq{Unable to create or access temp-path '%s'!}
	=>
	qq{Unable to create or access temp-path '%s'!},

	qq{Unable to create or access tftpboot-path '%s'!}
	=>
	qq{Unable to create or access tftpboot-path '%s'!},

	qq{unable to execute shell-command:\n\t%s \n\t(%s)}
	=>
	qq{unable to execute shell-command:\n\t%s \n\t(%s)},

	qq{Unable to load DB-module <%s> (%s)}
	=>
	qq{Unable to load DB-module <%s> (%s)},

	qq{Unable to load module <%s> (Version <%s> required)}
	=>
	qq{Unable to load module <%s> (Version <%s> required)},

	qq{Unable to load module <%s> (Version <%s> required, but <%s> found)}
	=>
	qq{Unable to load module <%s> (Version <%s> required, but <%s> found)},

	qq{Unable to write local settings file <%s> (%s)}
	=>
	qq{Unable to write local settings file <%s> (%s)},

	qq{UnknownDbSchemaColumnDescr}
	=>
	qq{Unknown DbSchema column description <%s> found},

	qq{UnknownDbSchemaCommand}
	=>
	qq{Unknown DbSchema command <%s> found},

	qq{UnknownDbSchemaTypeDescr}
	=>
	qq{Unknown DbSchema type description <%s> found},

	qq{upgrade done}
	=>
	qq{upgrade done},

	qq{writing PXE-file %s}
	=>
	qq{writing PXE-file %s},

	qq{yes}
	=>
	qq{yes},

);





1;





