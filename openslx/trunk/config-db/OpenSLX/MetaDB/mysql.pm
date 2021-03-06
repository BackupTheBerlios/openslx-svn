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
# mysql.pm
#    - provides mysql-specific overrides of the OpenSLX MetaDB API.
# -----------------------------------------------------------------------------
package OpenSLX::MetaDB::mysql;

use strict;
use warnings;

use base qw(OpenSLX::MetaDB::DBI);

################################################################################
### This class provides a MetaDB backend for mysql databases.
### - by default the db will be created inside a 'openslxdata-mysql' directory.
################################################################################
use DBD::mysql;
use OpenSLX::Basics;
use OpenSLX::Utils;

################################################################################
### implementation
################################################################################
sub new
{
    my $class = shift;
    my $self  = {};
    return bless $self, $class;
}

sub connect        ## no critic (ProhibitBuiltinHomonyms)
{
    my $self = shift;

    my $dbSpec = $openslxConfig{'db-spec'};
    if (!defined $dbSpec) {
        # build $dbSpec from individual parameters:
        $dbSpec = "database=$openslxConfig{'db-name'}";
    }
    my $dbUser
        = $openslxConfig{'db-user'}
            ? $openslxConfig{'db-user'}
            : (getpwuid($>))[0];
    my $dbPasswd = $openslxConfig{'db-passwd'};
    if (!defined $dbPasswd) {
        $dbPasswd = readPassword("db-password> ");
    }
    
    vlog(1, "trying to connect user '$dbUser' to mysql-database '$dbSpec'");
    $self->{'dbh'} = DBI->connect(
        "dbi:mysql:$dbSpec", $dbUser, $dbPasswd, {
            PrintError => 0,
            mysql_auto_reconnect => 1,
        }
    ) or die _tr("Cannot connect to database '%s' (%s)", $dbSpec, $DBI::errstr);
    return 1;
}

sub schemaConvertTypeDescrToNative
{
    my $self      = shift;
    my $typeDescr = lc(shift);

    if ($typeDescr eq 'b') {
        return 'integer';
    } elsif ($typeDescr eq 'i') {
        return 'integer';
    } elsif ($typeDescr eq 'pk') {
        return 'integer AUTO_INCREMENT primary key';
    } elsif ($typeDescr eq 'fk') {
        return 'integer';
    } elsif ($typeDescr =~ m[^s\.(\d+)$]i) {
        return "varchar($1)";
    } else {
        croak _tr('UnknownDbSchemaTypeDescr', $typeDescr);
    }
    return;
}

sub schemaRenameTable
{
    my $self      = shift;
    my $oldTable  = shift;
    my $newTable  = shift;
    my $colDescrs = shift;
    my $isSubCmd  = shift;

    my $dbh = $self->{'dbh'};
    vlog(1, "renaming table <$oldTable> to <$newTable>...") unless $isSubCmd;
    my $sql = "ALTER TABLE $oldTable RENAME TO $newTable";
    vlog(3, $sql);
    $dbh->do($sql)
      or croak _tr(q[Can't rename table <%s> (%s)], $oldTable, $dbh->errstr);
    return;
}

sub schemaAddColumns
{
    my $self              = shift;
    my $table             = shift;
    my $newColDescrs      = shift;
    my $newColDefaultVals = shift;
    my $colDescrs         = shift;
    my $isSubCmd          = shift;

    my $dbh         = $self->{'dbh'};
    my $newColNames = $self->_convertColDescrsToColNamesString($newColDescrs);
    vlog(1, "adding columns <$newColNames> to table <$table>") unless $isSubCmd;
    my $addClause = join ', ',
      map { "ADD COLUMN " . $self->_convertColDescrsToDBNativeString([$_]); }
      @$newColDescrs;
    my $sql = "ALTER TABLE $table $addClause";
    vlog(3, $sql);
    $dbh->do($sql)
      or croak _tr(q[Can't add columns to table <%s> (%s)], $table,
        $dbh->errstr);
    # if default values have been provided, we apply them now:
    if (defined $newColDefaultVals) {
        $self->_doUpdate($table, undef, $newColDefaultVals);
    }
    return;
}

sub schemaDropColumns
{
    my $self         = shift;
    my $table        = shift;
    my $dropColNames = shift;
    my $colDescrs    = shift;
    my $isSubCmd     = shift;

    my $dbh = $self->{'dbh'};
    my $dropColStr = join ', ', @$dropColNames;
    vlog(1,
        "dropping columns <$dropColStr> from table <$table>...")   
      unless $isSubCmd;
    my $dropClause = join ', ', map { "DROP COLUMN $_" } @$dropColNames;
    my $sql = "ALTER TABLE $table $dropClause";
    vlog(3, $sql);
    $dbh->do($sql)
      or croak _tr(q[Can't drop columns from table <%s> (%s)], $table,
        $dbh->errstr);
    return;
}

sub schemaChangeColumns
{
    my $self       = shift;
    my $table      = shift;
    my $colChanges = shift;
    my $colDescrs  = shift;
    my $isSubCmd   = shift;

    my $dbh = $self->{'dbh'};
    my $changeColStr = join ', ', keys %$colChanges;
    vlog(1, "changing columns <$changeColStr> in table <$table>...")
      unless $isSubCmd;
    my $changeClause = join ', ', map {
        "CHANGE COLUMN $_ "
          . $self->_convertColDescrsToDBNativeString([$colChanges->{$_}]);
      }
      keys %$colChanges;
    my $sql = "ALTER TABLE $table $changeClause";
    vlog(3, $sql);
    $dbh->do($sql)
      or croak _tr(q[Can't change columns in table <%s> (%s)], $table,
        $dbh->errstr);
    return;
}

1;
