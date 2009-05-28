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
# posix.pm
#    - OpenSLX-translations for the posix locale (English language).
# -----------------------------------------------------------------------------
package OpenSLX::Translations::posix;

use strict;
use warnings;

our $VERSION = 0.02;

my %translations;

################################################################################
### Implementation
################################################################################
sub getAllTranslations
{
    my $class = shift;
    return \%translations;
}

################################################################################
### Translations
################################################################################

%translations = (
    q{%s doesn't seem to be installed,\nso there is no support for %s available, sorry!\n}
    =>
    qq{%s doesn't seem to be installed,\nso there is no support for %s available, sorry!\n},

    q{%s has wrong bitwidth (%s instead of %s)}
    =>
    qq{%s has wrong bitwidth (%s instead of %s)},

    q{%s: ignored, as it isn't an executable or a shared library\n}
    =>
    qq{%s: ignored, as it isn't an executable or a shared library\n},

    q{'%s' already exists!\n}
    =>
    qq{'%s' already exists!\n},

    q{'%s' not found, maybe wrong root-path?\n}
    =>
    qq{'%s' not found, maybe wrong root-path?\n},

    q{\trpath='%s'\n}
    =>
    qq{\trpath='%s'\n},

    q{\ttrying objdump...\n}
    =>
    qq{\ttrying objdump...\n},

    q{\ttrying readelf...\n}
    =>
    qq{\ttrying readelf...\n},

    q{analyzing '%s'...\n}
    =>
    qq{analyzing '%s'...\n},

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

    q{List of supported systems:\n\t}
    =>
    qq{List of supported systems:\n\t},

    q{Lock-file <%s> exists, script is already running.\nPlease remove the logfile and try again if you are sure that no one else\nis executing this script.\n}
    =>
    qq{Lock-file <%s> exists, script is already running.\nPlease remove the logfile and try again if you are sure that no one else\nis executing this script.\n},

    q{merging %s (val=%s)}
    =>
    qq{merging %s (val=%s)},

    q{merging from default client...}
    =>
    qq{merging from default client...},

    q{merging from group %d:%s...}
    =>
    qq{merging from group %d:%s...},

    q{neither objdump nor readelf seems to be installed, giving up!\n}
    =>
    qq{neither objdump nor readelf seems to be installed, giving up!\n},

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

    q{slxldd: unable to find file '%s', skipping it\n}
    =>
    qq{slxldd: unable to find file '%s', skipping it\n},

    q{Sorry, system '%s' is unsupported.\n}
    =>
    qq{Sorry, system '%s' is unsupported.\n},

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

    q{unable to create db-datadir %s! (%s)\n}
    =>
    qq{unable to create db-datadir %s! (%s)\n},

    q{Unable to create lock-file <%s>, exiting!\n}
    =>
    qq{Unable to create lock-file <%s>, exiting!\n},

    q{Unable to create or access temp-path '%s'!}
    =>
    qq{Unable to create or access temp-path '%s'!},

    q{Unable to create or access tftpboot-path '%s'!}
    =>
    qq{Unable to create or access tftpboot-path '%s'!},

    q{unable to execute shell-command:\n\t%s \n\t(%s)}
    =>
    qq{unable to execute shell-command:\n\t%s \n\t(%s)},

    q{unable to fetch file info for '%s', giving up!\n}
    =>
    qq{unable to fetch file info for '%s', giving up!\n},

    q{Unable to load DB-module <%s> (%s)\n}
    =>
    qq{Unable to load DB-module <%s> (%s)\n},

    q{Unable to load DB-module <%s>\nthat database type is not supported (yet?)\n}
    =>
    qq{Unable to load DB-module <%s>\nthat database type is not supported (yet?)\n},

    q{unable to load DHCP-Export backend '%s'! (%s)\n}
    =>
    qq{unable to load DHCP-Export backend '%s'! (%s)\n},

    q{Unable to load module <%s> (Version <%s> required)}
    =>
    qq{Unable to load module <%s> (Version <%s> required)},

    q{Unable to load module <%s> (Version <%s> required, but <%s> found)}
    =>
    qq{Unable to load module <%s> (Version <%s> required, but <%s> found)},

    q{Unable to load system-module <%s> (%s)\n}
    =>
    qq{Unable to load system-module <%s> (%s)\n},

    q{Unable to load system-module <%s>!\n}
    =>
    qq{Unable to load system-module <%s>!\n},

    q{Unable to write local settings file <%s> (%s)}
    =>
    qq{Unable to write local settings file <%s> (%s)},

    q{unknown settings key <%s>!\n}
    =>
    qq{unknown settings key <%s>!\n},

    q{UnknownDbSchemaColumnDescr}
    =>
    qq{UnknownDbSchemaColumnDescr},

    q{UnknownDbSchemaCommand}
    =>
    qq{UnknownDbSchemaCommand},

    q{UnknownDbSchemaTypeDescr}
    =>
    qq{UnknownDbSchemaTypeDescr},

    q{upgrade done}
    =>
    qq{upgrade done},

    q{writing dhcp-config for %s clients}
    =>
    qq{writing dhcp-config for %s clients},

    q{writing PXE-file %s}
    =>
    qq{writing PXE-file %s},

    q{yes}
    =>
    qq{yes},

    q{You need to specify at least one file!\n}
    =>
    qq{You need to specify at least one file!\n},

    q{You need to specify exactly one system name!\n}
    =>
    qq{You need to specify exactly one system name!\n},

    q{You need to specify the root-path!\n}
    =>
    qq{You need to specify the root-path!\n},

);

1;
