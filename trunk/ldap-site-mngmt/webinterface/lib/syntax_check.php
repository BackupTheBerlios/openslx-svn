<?php
/*
	Syntaxcheck 1.2  2006/08/08

	A class for checking syntax of forms data
	Copyright (c) Tarik Gasmi, All Rights Reserved
*/


class Syntaxcheck
{

	var $ERROR	=	"";
	var $CLEAR	=	false;

	function Syntaxcheck ()
	{
		return;
	}

	function clear_error ()
	{
		$this->ERROR = "";
	}
	




# Ist "dotted quad IPAddress" in gueltigem Bereich? true or false
# Ueberprueft Format, fuehrende Nullen, und Werte > 255
# 
# Ueberprueft nicht nach reservierten oder nicht-route-baren IPs.
# 
function check_ip_syntax($IP)
{
	if($this->CLEAR) { $this->clear_error();}
	
	$len = strlen($IP);
	if( $len > 15 ){
		$this->ERROR = "check_ip_syntax: too long [$IP][$len]";
		return false;
		}
		
	$badcharacter = eregi_replace("([0-9\.]+)","",$IP);
	if(!empty($badcharacter)){
		$this->ERROR = "check_ip_syntax: Bad data in IP address [$badcharacter]";
		return false;
	}
	
	$chunks = explode(".",$IP);
	$count = count($chunks);
	if ($count != 4){
		$this->ERROR = "check_ip_syntax: not a dotted quad [$IP]";
		return false;
	}
	
	while ( list ($key,$val) = each ($chunks) ){
		if(ereg("^0",$val)){
			$this->ERROR = "check_ip_syntax: Invalid IP segment [$val]";
			return false;
		}
		$Num = $val;
		settype($Num,"integer");
		if($Num > 255){
			$this->ERROR = "check_ip_syntax: Segment out of range [$Num]";
			return false;
		}
	}
	
	return true;
	
}	

# Netzwerkaddresse
function check_netip_syntax($IP)
{
	if($this->CLEAR) { $this->clear_error();}
	
	if ( !($this->check_ip_syntax($IP)) ){
	   return false;
	}
	$chunks = explode(".",$IP);
	if ( $chunks[3] != "0" ){
	   return false;
	}
	return true;
}	

# MAC Adresse

# Domainname

# Hostname
function is_hostname ($hostname = ""){

	if($this->CLEAR) { $this->clear_error(); }

	$web = false;

	if(empty($hostname))
	{
		$this->ERROR = "is_hostname: No hostname submitted";
		return false;
	}

	// Only a-z, 0-9, and "-" or "." are permitted in a hostname

	// Patch for POSIX regex lib by Sascha Schumann sas@schell.de
	$Bad = eregi_replace("[-A-Z0-9\.]","",$hostname);

	if(!empty($Bad))
	{
		$this->ERROR = "is_hostname: invalid chars [$Bad]";
		return false;
	}

	// See if we're doing www.hostname.tld or hostname.tld
	if(eregi("^www\.",$hostname))
	{
		$web = true;
	}

	// double "." is a not permitted
	if(ereg("\.\.",$hostname))
	{
		$this->ERROR = "is_hostname: Double dot in [$hostname]";
		return false;
	}
	if(ereg("^\.",$hostname))
	{
		$this->ERROR = "is_hostname: leading dot in [$hostname]";
		return false;
	}

	$chunks = explode(".",$hostname);

	if( (gettype($chunks)) != "array")
	{
		$this->ERROR = "is_hostname: Invalid hostname, no dot seperator [$hostname]";
		return false;
	}

	$count = ( (count($chunks)) - 1);

	if($count < 1)
	{
		$this->ERROR = "is_hostname: Invalid hostname [$count] [$hostname]\n";
		return false;
	}

	// Bug that can't be killed without doing an is_host,
	// something.something will return TRUE, even if it's something
	// stupid like NS.SOMETHING (with no tld), because SOMETHING is
	// construed to BE the tld.  The is_bigfour and is_country
	// checks should help eliminate this inconsistancy. To really
	// be sure you've got a valid hostname, do an is_host() on it.

	if( ($web) and ($count < 2) )
	{
		$this->ERROR = "is_hostname: Invalid hostname [$count] [$hostname]\n";
		return false;
	}

	$tld = $chunks[$count];

	if(empty($tld))
	{
		$this->ERROR = "is_hostname: No TLD found in [$hostname]";
		return false;
	}

	if(!$this->is_bigfour($tld))
	{
		if(!$this->is_country($tld))
		{
			$this->ERROR = "is_hostname: Unrecognized TLD [$tld]";
			return false;
		}
	}
	

	return true;
}


# Syntax Check für die Eingaben: Uhrzeit, Wochentag, Monatstag, Monatstag.Monat
function check_timerange_syntax($mcday,$mcbeg,$mcend){
	
	if($this->CLEAR) { $this->clear_error();}

	$badcharacter = eregi_replace("([a-z0-9\.]+)","",$mcday);
	if(!empty($badcharacter)){
		$this->ERROR = "check_ip_syntax: Bad data in MC Day [$badcharacter]";
		return false;
	}
	$badcharacter = eregi_replace("([x0-9]+)","",$mcbeg);
	if(!empty($badcharacter)){
		$this->ERROR = "check_ip_syntax: Bad data in MC Begin [$badcharacter]";
		return false;
	}
	$badcharacter = eregi_replace("([x0-9]+)","",$mcend);
	if(!empty($badcharacter)){
		$this->ERROR = "check_ip_syntax: Bad data in MC End [$badcharacter]";
		return false;
	}
	
	$lenmcday = strlen($mcday);
	if (eregi("([a-z]+)",$mcday)){
		if ($lenmcday > 2){$this->ERROR = "WOTAG > 2"; return false;}
		if (eregi("([0-9\.]+)",$mcday)){$this->ERROR = "WOTAG enthaelt (0-9.)"; return false;}
		#if (!(eregi("[mdsfx][aiorx]",$mcday))){return false;}
		if (!(eregi("(m[io]|d[io]|s[ao]|fr|x)",$mcday))){$this->ERROR = "WOTAG falscher String"; return false;}
	}
	if (eregi("([0-9]+)",$mcday)){
		if (eregi("[\.]",$mcday)){
			preg_match("/[\.]/",$mcday,$treffer);
			if (count($treffer) > 1){$this->ERROR = "mehr als 2 Punkte"; return false;};
			$exp = explode('.',$mcday);
			$day = $exp[0]; 
			$lenday = strlen($day);
			if ($lenday > 2){$this->ERROR = "TAG > 2"; return false;}
			if (!(eregi("(0[1-9]|[0-2][0-9]|3[01])",$day))){$this->ERROR = "TAG nicht korrekt"; return false;}
			$month = $exp[1];
			$lenmonth = strlen($month);
			if ($lenmonth > 2){$this->ERROR = "MONAT > 2"; return false;}
			if (!(eregi("(0[0-9]|0[0-9]|1[0-2])",$month))){$this->ERROR = "Monat nicht korrekt"; return false;}
			
		}
		else{
			if ($lenmcday > 2){$this->ERROR = "TAG > 2"; return false;}
			if (!(eregi("(0[0-9]|[0-2][0-9]|3[01])",$mcday))){$this->ERROR = "Tag nicht korrekt"; return false;}
		}
	}
	
	$lenmcbeg = strlen($mcbeg);
	if ($lenmcbeg == 2){
		if (!(eregi("(0[0-9]|1[0-9]|2[0-3]|x)",$mcbeg))){$this->ERROR = "Uhrzeit nicht korrekt"; return false;}
	}
	if ($lenmcbeg == 1){
		if (!(eregi("([0-9]|x)",$mcbeg))){$this->ERROR = "Uhrzeit nicht korrekt"; return false;}
	}
	$lenmcend = strlen($mcend);
	if ($lenmcend == 2){
		if (!(eregi("(0[0-9]|1[0-9]|2[0-3]|x)",$mcend))){$this->ERROR = "Uhrzeit nicht korrekt"; return false;}
	}
	if ($lenmcend == 1){
		if (!(eregi("([0-9]|x)",$mcend))){$this->ERROR = "Uhrzeit nicht korrekt"; return false;}
	}
	
	return true;
}


# Überprüft ob Menuposition ein Zahl ist
function check_menuposition($menpos){
	
	if($this->CLEAR) { $this->clear_error();}

	$badcharacter = eregi_replace("([0-9]+)","",$menpos);
	if(!empty($badcharacter)){
		$this->ERROR = "check_menupostion: Bad data in Menu Position [$badcharacter]";
		return false;
	}
}

}
?>