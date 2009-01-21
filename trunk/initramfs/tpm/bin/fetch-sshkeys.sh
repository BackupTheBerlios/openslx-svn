#!/bin/sh
#

SHOWMAC="/bin/showmac.sh"
KEYTRG="/root/.ssh"

# FIXME: remote-host could be determined from kernel-cmdline, should we?
RHOST="132.230.4.180"

if [ ! -x "$SHOWMAC" ] ; then
	echo "Can't find $SHOWMAC, exiting."
	exit 1
fi
MAC_ETH0="$($SHOWMAC eth0)"

mkdir -p "$KEYTRG"

PRIVKEY="id_rsa.tpm-${MAC_ETH0}.sealed"

echo -n "trying to fetch private key (via tftp):"
tftp -r tpm/$PRIVKEY -l $KEYTRG/id_rsa -g $RHOST
if [ "$?" -gt 0 ] ; then
	echo "  FAILED!"
	echo "ERROR: can't find private key for this MAC-address: $MAC_ETH0."
	exit 2
fi
echo " $PRIVKEY"
chmod 600 $KEYTRG/id_rsa
