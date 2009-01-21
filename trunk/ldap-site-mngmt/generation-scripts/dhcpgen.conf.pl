# Beispiel einer Konfiguration der dhcp_generator.pl
# Zentraler DHCP Dienst DHCP_UniFR des Rechenzentrums
# verantwortlicher Administrator ist admin01

$ldaphost = "ldap://foo.ruf.uni-freiburg.de"; # aus config.php
$basedn = "ou=UniFreiburg,ou=RIPM,dc=uni-freiburg,dc=de"; 
$userdn = "uid=admin01,ou=people,dc=uni-freiburg,dc=de"; # aus Session
$passwd = "dipman02"; # aus Session
$dhcpdn = "cn=DHCP_RZ01,cn=dhcp,ou=Rechenzentrum,ou=UniFreiburg,ou=RIPM,dc=uni-freiburg,dc=de";
$dhcpdconfpath = "/home/lsm/new_dhcpconfigs";
#$dhcpdconffile = "dhcpd.conf.new";
