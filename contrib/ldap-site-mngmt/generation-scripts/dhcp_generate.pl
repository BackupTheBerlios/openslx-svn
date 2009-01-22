#!/usr/bin/perl

# Generate ISC DHCP Configuration File
#
# Reads DHCP Config Data form LDAP Directory and generates an 
# include file "dhcp.master.inc" included in dhcpd.conf with: 
# - Definitions of User-defined DHCP Options
# - DHCP Service Global Options
# - DHCP Subnet Declarations, Options and Dynamic Pools
# - DHCP Host Declarations and Options


use strict;
use warnings;
#use diagnostics;

#use LSM::dhcpgen;
use Net::LDAP;
use Net::LDAP::LDIF;
use Getopt::Std;

#$Getopt::Std::STANDARD_HELP_VERSION;
our $VERSION = "1.10";


# Configuration Variables for Perl-Script
our ( $ldaphost, $basedn, $userdn, $passwd, $dhcpdn, $dhcpdconfpath, $dhcpdconffile, $opt_a, $opt_h, $opt_v );
# Read Configuration Variables ...
require "dhcpgen.conf.pl";

my ( $ldap, $mesg, $failoverpeer, @searchbases );

#use LSM::dhcpgen;
my $acteptime = time();
my $acttime = localtime();
getopts('ahv');


if ($opt_h){ print "HILFE Text\n"; exit (1); }
if ($opt_a){ print "Generate all Include Files:\n\n";}


# Bind with LDAP Server
$ldap = Net::LDAP->new( $ldaphost, debug => 0 ) or die "$@";
$mesg = $ldap->bind( $userdn, password => $passwd );
$mesg->code && die $mesg->error;

my @dhcpunits = get_dhcpunits();
@searchbases = searchbases($acteptime);
#print @searchbases;

mkdir "$dhcpdconfpath/includes";


#################################################
# DHCP MASTER INCLUDE FILE
my $writemaster;
my @dhcpdnarray = split /,/,$dhcpdn;
my $aurdn = $dhcpdnarray[2];
my @auarray = split /=/,$aurdn;
my $au = $auarray[1];
my $srvrdn = $dhcpdnarray[0];
my @srvarray = split /=/,$srvrdn;
my $srv = $srvarray[1];

# File Header
$writemaster .= "# DHCP Config Master Include File \"dhcp.master.inc\"\n# DHCP Service: $srv\n# AU: $au\n# (DN: $dhcpdn)\n# generated: $acttime\n# Unix: $acteptime\n\n";

# LDAP Search: DHCP Service Object
my $dhcpsrventry = get_dhcpservice_object($ldap,$dhcpdn);

# Definitions for user/self-defined DHCP Options
$writemaster .= "\n######################\n# Option Definitions\n######################\n\n";
if ($dhcpsrventry->exists('OptionDefinition')) {
	my @optdefinitions = $dhcpsrventry->get_value('OptionDefinition');
	foreach my $optdef (@optdefinitions) {
		$writemaster .= "$optdef\n";
	}
}

# Failover Information of DHCP Service, needed for DHCP Pool Declarations later 
#my $failoverpeer;
if ($dhcpsrventry->exists( 'dhcpFailoverPeer' )) {
	$failoverpeer = $dhcpsrventry->get_value( 'dhcpFailoverPeer' );
}

# Global DHCP Options (global Scope)
$writemaster .= "\n\n######################\n# Global Options\n######################\n\n";
my $indent = "";
$writemaster .= dhcpoptions( $dhcpsrventry, $indent );

# Include Directives (one for each DHCP Unit in LDAP Database)
$writemaster .= "\n\n######################\n# Includes\n######################\n\n";
foreach my $dhcpunit ( @dhcpunits ){
	$writemaster .= "include \"$dhcpdconfpath/includes/dhcp.".lc $dhcpunit->get_value('ou').".inc\";\n";
	#$writemaster .= "include \"includes/dhcp.".lc $dhcpunit->get_value('ou').".inc\";\n";
}

# Write File
print "Generate DHCP Master Include File\n";
open DATEI, "> $dhcpdconfpath/includes/dhcp.master.inc";
print DATEI $writemaster;
close DATEI;
# Writing DHCP MASTER INCLUDE FILE Completed 
#################################################


#################################################
# DHCP INCLUDE FILES, one for each AdministrativeUnit
foreach my $searchbase ( @searchbases ){
	
	my $writeinc;
	my $lastchange;
	my $includedatei = lc "dhcp.$searchbase->{ou}.inc";
	my $audn = $searchbase->{dn};
	my $dhcpmtime = $searchbase->{dhcpmtime};
	#print "$includedatei\n";
	#print "$audn\n";
	
	# Include File Header
	$writeinc .= "# DHCP Config Include File \"$includedatei\"\n# AU: $searchbase->{ou}\n# (DN: $audn)\n# generated: $acttime\n# Unix: $acteptime\n\n";

	###########################
	# DHCP SUBNETS (and POOLS)
	# LDAP Search: DHCP Subnet Objects referencing to DHCP Service Object
	my @subnets = get_dhcpsubnet_objects($ldap,$audn,$dhcpdn);
	# write Subnet declarations
	$writeinc .= "\n\n######################\n# DHCP Subnets\n######################\n\n";
	foreach my $subnetentry ( @subnets ) {	
		$writeinc .= dhcpsubnet($subnetentry);
	}
	
	###########################
	# DHCP HOSTS
	# LDAP Search: DHCP Host Objects referencing to DHCP Service Object
	my @hosts = get_dhcphost_objects($ldap,$audn,$dhcpdn);
	# write Host Declarations
	$writeinc .= "\n\n######################\n# DHCP Hosts\n######################\n";
	foreach my $hostentry ( @hosts ) {
		$writeinc .= dhcphost($hostentry);
	}
	
	# Write File
	if ($dhcpmtime == 0){ $lastchange = "not changed yet!"; }
		else{ $lastchange = "last change: ".localtime($dhcpmtime); }
	print "Generate Include-File $includedatei ($lastchange)\n";
	open DATEI, "> $dhcpdconfpath/includes/$includedatei";
	print DATEI $writeinc;
	close DATEI;
}
# Writing DHCP INCLUDE FILES Completed
#######################################


# LDAP unbind
$mesg = $ldap->unbind;


exit (0);



###################################################################################################
# Subroutines
###############

# write DHCP Options, Parameter: DHCP Object LDAP Entry
sub dhcpoptions {
	my $entry = shift;
	my $indent = shift;
	my @atts = $entry->attributes;
	my $output = "";
	
	# DHCP Option beginning with with 'option'
	my @options1 = grep /dhcpopt/, @atts;
	#printf "options: @options1\n";
	foreach my $option ( @options1 ){
		if ( $option ne "dhcpoptNetmask" ){
			my $value = $entry->get_value( $option );
			$option =~ s/dhcpopt//;
			if ( $option eq "Domain-name"){
				$output .= $indent."option ".lc($option)." \"$value\";\n";
			}else{
				$output .= $indent."option ".lc($option)." $value;\n";
			}
		}
	}
	# DHCP Options without 'option'
	my @options2 = grep /dhcpOpt/, @atts;
	#printf "Options: @options2\n";
	foreach my $option ( @options2 ){
		if ( $option ne "dhcpOptFixed-address" ){
			my $value = $entry->get_value( $option );
			$option =~ s/dhcpOpt//;
			if ( $option eq "Filename"){
				$output .= $indent.lc($option)." \"$value\";\n";
			}else{
				$output .= $indent.lc($option)." $value;\n";
			}
		}
	}
	
	return $output;
}


# write DHCP Pool declaration (+ specific Options), Parameter: DHCP Object LDAP Entry
sub dhcppool {
	my $entry = shift;
	my $indent = shift;
	my @atts = $entry->attributes;
	my $output = "";
	# open Pool Declaration
	$output .= $indent."pool {\n";
	# write DHCP Options in Pool Scope
	my $poolindent = $indent."  ";
	if ( $failoverpeer ){
		$output .= $poolindent."failover peer \"$failoverpeer\";\n";
		$output .= $poolindent."deny dynamic bootp clients;\n";
	}
	if ($entry->exists( 'dhcpRange' )) {
		#foreach my $ranges ( @) {
		my @range = split /_/,$entry->get_value( 'dhcpRange' );
		$output .= $poolindent."range $range[0] $range[1];\n";
	}
	$output .= dhcpoptions($entry,$poolindent);
	# close Pool Declaration
	$output .= "$indent}\n";
	
	return $output;
}


# write DHCP Subnet declaration (specific Options), Parameter: DHCP Object LDAP Entry
sub dhcpsubnet {
	my $entry = shift;
	my @atts = $entry->attributes;
	my $output = "";
	
	my $subnetdn = $entry->dn;
	my $subnet = $entry->get_value( 'cn' );
	my $netmask = $entry->get_value( 'dhcpoptnetmask' );
	# open Subnet Declaration
	$output .= "subnet $subnet netmask $netmask {\n";
	# write DHCP Options in Subnet Scope
	my $optindent = "  ";
	$output .= dhcpoptions($entry,$optindent);
	# write Pool Declarations in Subnet Declaration
	# ldapsearch on Pool Objects referencing to DHCP Subnet Object
	$mesg = $ldap->search(base=>$basedn,
				scope => 'sub',
				filter => '(&(objectclass=dhcpPool)(dhcphlpcont:dn:='.$subnetdn.'))');
	#Net::LDAP::LDIF->new( \*STDOUT,"w" )->write( $mesg->entries );
	$mesg->code && die $mesg->error;
	my @pools = $mesg->sorted('cn');
	foreach my $poolentry ( @pools ) {
		$output .= dhcppool($poolentry,$optindent);
	}
	# close Subnet Declaration
	$output .= "}\n\n";

	return $output;
}


# write DHCP Host declaration (specific Options), Parameter: DHCP Object LDAP Entry
sub dhcphost {
	my $entry = shift;
	my @atts = $entry->attributes;
	my $output = "";
	
	$output .= "\nhost ".lc $entry->get_value('hostname')." {\n";
	#printf DATEI "\nhost %s {\n", lc $entry->get_value( 'hostname' );
	# Host specific DHCP Options
	if ($entry->exists('hwaddress')) {
		$output .= "  hardware ethernet ".$entry->get_value('hwaddress').";\n";
	}
	if ($entry->exists('dhcpoptfixed-address')) {
		if ( $entry->get_value('dhcpoptfixed-address') eq "ip" ){
			my @ip = split /_/, $entry->get_value('ipaddress');
			$output .= "  fixed-address ".lc $ip[0].";\n";
		}
		if ( $entry->get_value('dhcpoptfixed-address') eq "hostname" ){
			$output .= "  fixed-address ".lc $entry->get_value('hostname').".".lc $entry->get_value('domainname').";\n";
		}
	}
	my @hwoptions = grep /Hw-/, @atts;
	foreach my $hwoption ( @hwoptions ){
		$output .= "  option ".lc($hwoption)." \"".$entry->get_value($hwoption)."\";\n";
	}
	# remaining DHCP Options
	my $optindent = "  ";
	$output .= dhcpoptions ($entry, $optindent);
	$output .= "}\n";
	
	return $output;
}

sub get_dhcpservice_object {
	my $ldap = shift;
	my $basedn = shift;
	# Ldapsearch on DHCP Service Object
	
	my $mesg = $ldap->search(base => $basedn,
					scope => 'base',
					filter => '(objectclass=dhcpService)');
	#Net::LDAP::LDIF->new( \*STDOUT,"w" )->write( $mesg->entries );
	$mesg->code && die $mesg->error;
	my $dhcpservice = $mesg->count or die "DHCP Service Object does not exist in the System";
	my $dhcpsrventry = $mesg->entry(0);
	
	return $dhcpsrventry;
}

# all Subnet Objects of one AU Container
sub get_dhcpsubnet_objects {
	my $ldap = shift;
	my $audn = shift;
	my $dhcpdn = shift;
	
	# ldapsearch on Subnet Objects referencing to DHCP Service Object
	$mesg = $ldap->search(base=>"cn=dhcp,".$audn,
				scope => 'sub',
				filter => '(&(objectclass=dhcpSubnet)(dhcphlpcont:dn:='.$dhcpdn.'))');
	#Net::LDAP::LDIF->new( \*STDOUT,"w" )->write( $mesg->entries );
	$mesg->code && die $mesg->error;
	my @dhcpsubnets = $mesg->sorted('cn');
	
	return @dhcpsubnets;
}

# all Host Objects of one AU Container
sub get_dhcphost_objects {
	my $ldap = shift;
	my $audn = shift;
	my $dhcpdn = shift;
	
	# ldapsearch on DHCP Host Objects referencing to DHCP Service Object
	$mesg = $ldap->search(base=>"cn=computers,".$audn,
			scope => 'sub',
			filter => '(&(objectclass=dhcpHost)(dhcphlpcont:dn:='.$dhcpdn.'))');
	#Net::LDAP::LDIF->new( \*STDOUT,"w" )->write( $mesg->entries );
	$mesg->code && die $mesg->error;
	my @dhcphosts = $mesg->sorted('dn');
	
	return @dhcphosts;
}

# all AU containers
sub get_dhcpunits {
	#my $ldap = shift;
	#my $basedn = shift;

	# ldapsearch on Subnet Objects referencing to DHCP Service Object
	$mesg = $ldap->search(base=>$basedn,
				scope => 'sub',
				filter => '(objectclass=administrativeUnit)',
				#filter => '(&(objectclass=administrativeUnit)(dhcpMTime>='.$yday.'))',
				attrs   =>  [ 'ou','dhcpMTime' ] );
	#Net::LDAP::LDIF->new( \*STDOUT,"w" )->write( $mesg->entries );
	$mesg->code && die $mesg->error;
	my @adminunits = $mesg->entries;
	
	return @adminunits;
}


# Generate Searchbases-Array for AdminUnit-specific LDAP Search on DHCP Objects 
sub searchbases {
	my $acteptime = shift;  ### falls noch plausibiltäts-test: acteptime > dhcpmtime
	my $opta = $opt_a;
	#print "opt_a: $opta \n";
	my @adunits = get_dhcpunits();
	if ( $opta ){
		# All Admin Units
		foreach my $adunit (@adunits){
			push @searchbases, { dn => $adunit->dn, ou => $adunit->get_value('ou'), dhcpmtime => $adunit->get_value('dhcpMTime') };
		}
	}else{
		# Only Admin Units which DHCP Data changed since last generation
		foreach my $adunit (@adunits){
			my $changetime = "1";
			my $dhandle = 1;
			open DAT, "< $dhcpdconfpath/includes/dhcp.".lc $adunit->get_value('ou').".inc"  #or open DAT and my $incgen = 1; #or die "Can't open/generate Include File";
			#print $incgen;
			or $dhandle = 0;
			if ($dhandle){
				while (<DAT>){
					chomp;
					if (/^# Unix: (\S+)/){ $changetime = $1; }
				}
				close DAT;
			}
			my $actualize = "";
			if ($adunit->exists( 'dhcpMTime' ) && $adunit->get_value('dhcpMTime') >= $changetime ) {
				#printf "%s - %s\n", $adunit->dn, $adunit->get_value('dhcpMTime');
				$actualize = "needs to be actualized\n";
				push @searchbases, { dn => $adunit->dn, ou => $adunit->get_value('ou'), dhcpmtime => $adunit->get_value('dhcpMTime') };
			}
			if ($opt_v){
				print $adunit->get_value('ou')."\n";
				print "dhcpmodify:  ".$adunit->get_value('dhcpMTime')."\n";
				print "lastchange:  $changetime\n";
				print $actualize;
				print "------------------------\n";
			}
		}
	}
	return @searchbases;
}