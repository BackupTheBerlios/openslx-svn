<?php
/**
 * -----------------------------------------------------------------------------
 * Copyright (c) 2008 - Rechenzentrum Uni FR, OpenSLX Project
 *
 * This program is free software distributed under the GPL version 2.
 * See http://openslx.org/COPYING
 *
 * If you have any feedback please consult http://openslx.org/feedback and
 * send your suggestions, praise, or complaints to feedback@openslx.org
 *
 * General information about OpenSLX can be found at http://openslx.org/
 * -----------------------------------------------------------------------------
 * printPreview.php
 *     - Give the user a chance to get an idea how the tag would look like. Not
 *       really wysiwyg :)
 * -----------------------------------------------------------------------------
 */

session_start();
?>

<script language="JavaScript" type="text/javascript">
function chkhost() {
    if (document.getElementById("hostname").value == 'false') {
        document.getElementById("hostname").checked = 'checked';
        document.getElementById("host").style.visibility = 'visible';
        document.getElementById("hostname").value = 'true';
    }
    else {
        document.getElementById("hostname").checked = '';
        document.getElementById("host").style.visibility = 'hidden';
        document.getElementById("hostname").value = 'false';
    }
}

function chkdomain() {
    if (document.getElementById("domainname").value == 'false') {
        document.getElementById("domainname").checked = 'checked';
        document.getElementById("domain").style.visibility = 'visible';
        document.getElementById("domainname").value = 'true';
    }
    else {
        document.getElementById("domainname").checked = '';
        document.getElementById("domain").style.visibility = 'hidden';
        document.getElementById("domainname").value = 'false';
    }
}

function chkip() {
    if (document.getElementById("ipaddress").value == 'false') {
        document.getElementById("ipaddress").checked = 'checked';
        document.getElementById("ip").style.visibility = 'visible';
        document.getElementById("ipaddress").value = 'true';
    }
    else {
        document.getElementById("ipaddress").checked = '';
        document.getElementById("ip").style.visibility = 'hidden';
        document.getElementById("ipaddress").value = 'false';
    }
}

function chkmac() {
    if (document.getElementById("hwaddress").value == 'false') {
        document.getElementById("hwaddress").checked = 'checked';
        document.getElementById("mac").style.visibility = 'visible';
        document.getElementById("hwaddress").value = 'true';
    }
    else {
        document.getElementById("hwaddress").checked = '';
        document.getElementById("mac").style.visibility = 'hidden';
        document.getElementById("hwaddress").value = 'false';
    }
}

function chkadd() {
    if (document.getElementById("additional").value == 'false') {
        document.getElementById("add").innerHTML = document.getElementById("addtext").value;
        document.getElementById("additional").checked = 'checked';
        document.getElementById("add").style.visibility = 'visible';
        document.getElementById("additional").value = 'true';
    }
    else {
        document.getElementById("add").innerHTML = document.getElementById("addtext").value;
        document.getElementById("additional").checked = '';
        document.getElementById("add").style.visibility = 'hidden';
        document.getElementById("additional").value = 'false';
    }
}
</script>

<div class="preview">
<table width="400" height="200">
<tr>
<td>
RZ-LOGO
</td>
</tr>
<tr>
<td align="center">
<b><span id="host">Host1</span></b>
</td>
<td rowspan="6" width="100">
<img src="sample-semacode.png"/>
</td>
</tr>
<tr>
<td align="center">
<span id="domain">host1.uni-freiburg.de</span>
</td>
</tr>
<tr>
<td align="center">
<b><i><span id="ip">132.230.200.200</span></i></b>
</td>
</tr>
<tr>
<td align="center">
<span id="mac">00:10:11:4E:2B:84</span>
</td>
</tr>
<tr>
<td align="center">
<span id="add">Zusatztext</span>
</td>
</tr>
</table>
</div>

<form method="POST" action="generatePDF.php">
<div class="options">
<input type="checkbox" id="hostname" name="hostname" onclick="chkhost()" value="true" checked="checked" />
Hostname
<br />
<input type="checkbox" id="domainname" name="domainname" onclick="chkdomain()" value="true" checked="checked" />
Domainname
<br />
<input type="checkbox" id="ipaddress" name="ipaddress" onclick="chkip()" value="true" checked="checked" />
IP-Adresse
<br />
<input type="checkbox" id="hwaddress" name="hwaddress" onclick="chkmac()" value="true" checked="checked" />
MAC-Adresse
<br />
<input type="checkbox" id="additional" name="additional" onclick="chkadd()" value="true" checked="checked" />
Zusatzinfo
<input type="text" id="addtext" name="addtext" />
Schriftgroesse Zusatztext:
<select name="addsize" size="1">
<option>6</option>
<option>7</option>
<option>8</option>
<option>9</option>
<option>10</option>
<option>11</option>
<option>12</option>
<option>13</option>
<option>14</option>
<option>15</option>
<option>16</option>
<option>17</option>
<option>18</option>
<option>19</option>
<option>20</option>
</select>
</div>

<div class="generate">
Positionen auf dem PDF:
<br />
<table width="200" bgcolor="#000000" cellpadding="1" cellspacing="1">
<tr>
<td bgcolor="#FFFFFF">Position 0</td>
<td bgcolor="#FFFFFF">Position 1</td>
</tr>
<tr>
<td bgcolor="#FFFFFF">Position 2</td>
<td bgcolor="#FFFFFF">Position 3</td>
</tr>
<tr>
<td bgcolor="#FFFFFF">Position 4</td>
<td bgcolor="#FFFFFF">Position 5</td>
</tr>
<tr>
<td bgcolor="#FFFFFF">Position 6</td>
<td bgcolor="#FFFFFF">Position 7</td>
</tr>
<tr>
<td bgcolor="#FFFFFF">Position 8</td>
<td bgcolor="#FFFFFF">Position 9</td>
</tr>
</table>
<br />
Ab Postition: 
<select name="position" size="1">
<option>0</option>
<option>1</option>
<option>2</option>
<option>3</option>
<option>4</option>
<option>5</option>
<option>6</option>
<option>7</option>
<option>8</option>
<option>9</option>
</select>
<br />
<input type="submit" name="submit" value="Generate">
</form>
</div>

