<?php
include('../standard_header.inc.php');

$rbscn = $_POST['rbscn']; $rbscn = htmlentities($rbscn);

$nodeDN = "cn=rbs,".$auDN;

$rbsoffer = $_POST['rbsoffer'];

$tftpserverip = $_POST['tftpserverip'];
$nfsserverip = $_POST['nfsserverip'];
$nbdserverip = $_POST['nbdserverip'];

$tftpserver = $_POST['tftpserver'];
$nfsserver = $_POST['nfsserver'];
$nbdserver = $_POST['nbdserver'];

$host_array = get_hosts($auDN,array("dn","hostname","ipaddress"));

$mnr = $_POST['mnr'];
$sbmnr = $_POST['sbmnr'];
$mcnr = $_POST['mcnr'];

# sosntige Attribute
$attribs = $_POST['attribs'];
if (count($attribs) != 0){
	foreach (array_keys($attribs) as $key){
		$atts[$key] = htmlentities($attribs[$key]);
	}
}
#print_r($atts); echo "<br><br>";


$get_rbscn = str_replace ( " ", "_", $rbscn );
$seconds = 300;
$url = "new_rbservice.php?&mnr=1";
 
echo "
<html>
<head>
	<title>Computers Management</title>
	<link rel='stylesheet' href='../styles.css' type='text/css'>
</head>
<body>
<table border='0' cellpadding='30' cellspacing='0'> 
<tr><td>";

if ( $rbscn != "" && $rbscn != "Hier_RBS_NAME_eintragen" ){

	$rbscn = "RBS_".$rbscn;

	# Formulareingaben anpassen
	$exprbs = explode(" ",$rbscn);
	foreach ($exprbs as $word){$expuc[] = ucfirst($word);}
	$rbscn = implode(" ",$expuc);
	$rbscn = preg_replace ( '/\s+([0-9A-Z])/', '$1', $rbscn);
	
	$rbsDN = "cn=".$rbscn.",".$nodeDN;
	print_r($rbsDN); echo "<br><br>";
	
	# Server_array zusammenstellen
	$server = array();
	# TFTP Server 
	if ($tftpserverip != ""){
		if ($syntax->check_ip_syntax($tftpserverip)){
			$tftpserverip = htmlentities($tftpserverip);
			$mesg .= "Suche nach dem Rechner mit IP ".$tftpserverip." :<br>";
			foreach ($host_array as $host){
				$hostipexp = explode('_',$host['ipaddress']);
				$hostip = $hostipexp[0];
				if ($tftpserverip == $hostip){
					$server ['tftp'] = $tftpserverip;
					break;
				}else{
					 $mesg .= "Rechner ".$host['hostname'].":  keine &Uuml;bereinstimmung mit eingegebener IP ".$tftpserverip."!<br>";
				}
			}
		}else{$mesg .= "Falsche IP Syntax!<br>";}
	}
	# NFS Server
	if ( $nfsserverip != "" ){
		if ($syntax->check_ip_syntax($nfsserverip)){
			$nfsserverip = htmlentities($nfsserverip);
			$mesg .= "Suche nach dem Rechner mit IP ".$nfsserverip." :<br>";
			foreach ($host_array as $host){
				$hostipexp = explode('_',$host['ipaddress']);
				$hostip = $hostipexp[0];
				if ($nfsserverip == $hostip){
					$server ['nfs'] = $nfsserverip;			
					break;
				}else{
					 $mesg .= "Rechner ".$host['hostname'].":  keine &Uuml;bereinstimmung mit eingegebener IP ".$nfsserverip."!<br>";
				}
			}
		}else{$mesg .= "Falsche IP Syntax!<br>";}
	}
	# NBD Server
	if ( $nbdserverip != "" ){
		if ($syntax->check_ip_syntax($nbdserverip)){
			$nbdserverip = htmlentities($nbdserverip);
			$mesg .= "Suche nach dem Rechner mit IP ".$nbdserverip." :<br>";
			foreach ($host_array as $host){
				$hostipexp = explode('_',$host['ipaddress']);
				$hostip = $hostipexp[0];
				if ($nbdserverip == $hostip){
					$server ['nbd'] = $nbdserverip;			
					break;
				}else{
					 $mesg .= "Rechner ".$host['hostname'].":  keine &Uuml;bereinstimmung mit eingegebener IP ".$nbdserverip."!<br>";
				}
			}
		}else{$mesg .= "Falsche IP Syntax!<br>";}
	}
	echo "Server Array: ";print_r($server); echo "<br>";
	
	if (add_rbs($rbsDN,$rbscn,$rbsoffer,$server,$atts)){			
		$mesg .= "<br>Remote Boot Service erfolgreich angelegt<br>";
		$url = "rbservice.php?mnr=1";
	}else{
		$mesg .= "<br>Fehler beim anlegen des Remote Boot Services!<br>";
	}
}

elseif ( $rbscn == "" || $rbscn == "Hier_RBS_NAME_eintragen" ){

	$mesg = "Sie haben den Namen des neuen Remote Boot Service nicht angegeben. Dieser ist 
				aber ein notwendiges Attribut.<br>
				Bitte geben Sie ihn an.<br><br>";
	$url = "new_rbservice.php?rbscn=Hier_RBS_NAME_eintragen&mnr=1";
}



$mesg .= "<br>Sie werden automatisch auf die vorherige Seite zur&uuml;ckgeleitet. <br>				
			Falls nicht, klicken Sie hier <a href=".$url." style='publink'>back</a>";
redirect($seconds, $url, $mesg, $addSessionId = TRUE);

echo "</td></tr></table></body>
</html>";
?>