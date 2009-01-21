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

use Net::LDAP;
use Net::LDAP::LDIF;

# Configuration Variables for Perl-Script
our ( $ldaphost, $basedn, $userdn, $passwd, $dhcpdn, $dhcpdconfpath, $dhcpdconffile );
# Read Configuration Variables ...
require "dhcpgen.conf.pl";
#use dhcpgenconfig;

my ( $ldap, $mesg, $mesg2 );

# Bind with LDAP Server
$ldap = Net::LDAP->new( $ldaphost ) or die "$@";
$mesg = $ldap->bind( $userdn, password => $passwd );
$mesg->code && die $mesg->error;


mkdir "$dhcpdconfpath/includes";
open DATEI, "> $dhcpdconfpath/includes/dhcp.master.inc";

my @dhcpdnarray = split /,/,$dhcpdn;
my $aurdn = $dhcpdnarray[2];
my @auarray = split /=/,$aurdn;
my $au = $auarray[1];
my $srvrdn = $dhcpdnarray[0];
my @srvarray = split /=/,$srvrdn;
my $srv = $srvarray[1];

# File Header (general Informations)
printf DATEI "#####################  DHCP SERVICE CONFIG  ############################################ \n#\n";
printf DATEI "# DHCP Service: \t\t %s \n", $srv;
printf DATEI "# Administrative Unit: \t\t %s \n#\n", $au;
printf DATEI "# [ %s ]\n#\n", $dhcpdn;
printf DATEI "######################################################################################## \n\n\n";


# Ldapsearch on DHCP Service Object
$mesg = $ldap->search(base => $dhcpdn,
											scope => 'base',
											filter => '(objectclass=dhcpService)');
#Net::LDAP::LDIF->new( \*STDOUT,"w" )->write( $mesg->entries );
$mesg->code && die $mesg->error;
my $dhcpservice = $mesg->count or die "DHCP Service Object does not exist in the System";
my $dhcpsrventry = $mesg->entry(0);

printf DATEI "######################\n# Option Definitions\n######################\n\n";
# write Definitions of user/self-defined DHCP Options
if ($dhcpsrventry->exists( 'OptionDefinition' )) {
	my @optdefinitions = $dhcpsrventry->get_value( 'OptionDefinition' );
	foreach my $optdef ( @optdefinitions) {
		printf DATEI "%s\n", $optdef;
	}
}
# Failover Information of DHCP Service
my $failoverpeer;
if ($dhcpsrventry->exists( 'dhcpFailoverPeer' )) {
	$failoverpeer = $dhcpsrventry->get_value( 'dhcpFailoverPeer' );
}


my $indent = "";
printf DATEI "\n\n######################\n# Global Options\n######################\n\n";
# write DHCP Options in global Scope
dhcpoptions( $dhcpsrventry, $indent );
printf DATEI "\n";



####################################
# DHCP SUBNETS

# ldapsearch on Subnet Objects referencing to DHCP Service Object
$mesg = $ldap->search(base=>$basedn,
							scope => 'sub',
							filter => '(&(objectclass=dhcpSubnet)(dhcphlpcont:dn:='.$dhcpdn.'))');
#Net::LDAP::LDIF->new( \*STDOUT,"w" )->write( $mesg->entries );
$mesg->code && die $mesg->error;
my @subnets = $mesg->sorted('cn');

# write Subnet Declarations
printf DATEI "\n\n######################\n# DHCP Subnets\n######################\n\n";

foreach my $subnetentry ( @subnets ) {
	my $subnetdn = $subnetentry->dn;
	my $subnet = $subnetentry->get_value( 'cn' );
	my $netmask = $subnetentry->get_value( 'dhcpoptnetmask' );
	printf DATEI "subnet %s netmask %s {\n", $subnet, $netmask;
	# write DHCP Options in Subnet Scope
	my $optindent = "  ";
	dhcpoptions($subnetentry,$optindent);
	
	# write Pool Declarations in Subnet Declaration
	# ldapsearch on Pool Objects referencing to DHCP Subnet Object
	$mesg2 = $ldap->search(base=>$basedn,
								scope => 'sub',
								filter => '(&(objectclass=dhcpPool)(dhcphlpcont:dn:='.$subnetdn.'))');
	#Net::LDAP::LDIF->new( \*STDOUT,"w" )->write( $mesg->entries );
	$mesg2->code && die $mesg2->error;
	my @pools = $mesg2->sorted('cn');
	
	foreach my $poolentry ( @pools ) {
		printf DATEI "%spool {\n", $optindent;
		# write DHCP Options in Pool Scope
		my $poolindent = "    ";
		if ( $failoverpeer ){
			printf DATEI "%sfailover peer \"%s\";\n", $poolindent, $failoverpeer;
			printf DATEI "%sdeny dynamic bootp clients;\n", $poolindent;
		}
		if ($poolentry->exists( 'dhcpRange' )) {
			#foreach my $ranges ( @) {
			my @range = split /_/,$poolentry->get_value( 'dhcpRange' );
			printf DATEI "%srange %s %s;\n", $poolindent, $range[0], $range[1];
		}
		dhcpoptions($poolentry,$poolindent);
		printf DATEI "%s}\n", $optindent;
	}
	
	# close Subnet Declaration
	printf DATEI "}\n\n";
}


####################################
# DHCP HOSTS

# ldapsearch on DHCP Host Objects referencing to DHCP Service Object
$mesg = $ldap->search(base=>$basedn,
		scope => 'sub',
		filter => '(&(objectclass=dhcpHost)(dhcphlpcont:dn:='.$dhcpdn.'))');
		#Net::LDAP::LDIF->new( \*STDOUT,"w" )->write( $mesg->entries );
		$mesg->code && die $mesg->error;
my @hosts = $mesg->sorted('dn');

# write Host Declarations
printf DATEI "\n\n######################\n# DHCP Hosts\n######################\n";

# grouping Hosts by Administrative Units (AU)
my $hostau = "";
foreach my $hostentry ( @hosts ) {
	
	# für jede AU eigener Abschnitt (oder abzweigung in eigene includedatei ...)
	my $hostdn = $hostentry->dn();
	my @dnarray = split /,/,$hostdn;
	my @auarray = split /=/,$dnarray[2];
	my $hostauactual = $auarray[1];
	if ( $hostau ne $hostauactual) {
		# hier neues Datei Handle und neuer Pfad falls eigene includedatei ...
		printf DATEI "\n################################################\n# AU: %s \n", $hostauactual;
		$hostau = $hostauactual;
	}
	# DHCP Options in Host Scope
	dhcphost($hostentry);
}


close DATEI;

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
	
	# DHCP Optionen mit 'option' vorne dran
	my @options1 = grep /dhcpopt/, @atts;
	#printf "options: @options1\n";
	foreach my $option ( @options1 ){
		if ( $option ne "dhcpoptNetmask" ){
			my $value = $entry->get_value( $option );
			$option =~ s/dhcpopt//;
			if ( $option eq "Domain-name"){
				printf DATEI "%soption %s \"%s\";\n", $indent, lc($option), $value;
			}else{
				printf DATEI "%soption %s %s;\n", $indent, lc($option), $value;
			}
		}
	}
	# DHCP Optionen
	my @options2 = grep /dhcpOpt/, @atts;
	#printf "Options: @options2\n";
	foreach my $option ( @options2 ){
		if ( $option ne "dhcpOptFixed-address" ){
			my $value = $entry->get_value( $option );
			$option =~ s/dhcpOpt//;
			if ( $option eq "Filename"){
				printf DATEI "%s%s \"%s\";\n", $indent, lc($option), $value;
			}else{
				printf DATEI "%s%s %s;\n", $indent, lc($option), $value;
			}
		}
	}
}


# write DHCP Host specific Options, Parameter: DHCP Object LDAP Entry
sub dhcphost {
	my $entry = shift;
	my @atts = $entry->attributes;
	
	printf DATEI "\nhost %s {\n", lc $entry->get_value( 'hostname' );
	# Host specific DHCP Options
	if ($entry->exists( 'hwaddress' )) {
		printf DATEI "  hardware ethernet %s;\n", $entry->get_value( 'hwaddress' );
	}
	if ($entry->exists( 'dhcpoptfixed-address' )) {
		if ( $entry->get_value('dhcpoptfixed-address') eq "ip" ){
			my @ip = split /_/, $entry->get_value( 'ipaddress' );
			printf DATEI "  fixed-address %s;\n", lc $ip[0];
		}
		if ( $entry->get_value('dhcpoptfixed-address') eq "hostname" ){
			printf DATEI "  fixed-address %s.%s;\n", lc $entry->get_value( 'hostname' ), lc $entry->get_value( 'domainname' );
		}
	}
	my @hwoptions = grep /Hw-/, @atts;
	foreach my $hwoption ( @hwoptions ){
		printf DATEI "  option %s \"%s\";\n", lc($hwoption), $entry->get_value($hwoption);
	}
	# remaining DHCP Options
	my $optindent = "  ";
	dhcpoptions ($entry, $optindent);
	printf DATEI "}\n";
}