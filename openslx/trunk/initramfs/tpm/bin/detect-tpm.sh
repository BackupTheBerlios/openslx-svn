#!/bin/sh
#

SYS_PATH="/sys/class/misc/tpm0/device/"
MODULES="atmel tis nsc infineon"
MODULES_FORCE="tis"
FLAGS=""
FLAGS_FORCE="force=1"

test_tpm() {
	if [ ! -d "$SYS_PATH" ] ; then
		return 1
	fi

# tpm_tis creates "active" and "enabled" files
# _atmel and _nsc only create the "caps"
	ACTIVE="$(cat $SYS_PATH/active 2>/dev/null)"
	ENABLED="$(cat $SYS_PATH/enabled 2>/dev/null)"
	CAPS="$(cat $SYS_PATH/caps 2>/dev/null)"
	if [ -n "$ACTIVE" -o -n "$ENABLED" -o -n "$CAPS" ] ; then
		echo
		echo "successfully detected TPM chip!"
		echo
		echo "$CAPS"
		echo
	else
		return 2
	fi
}

try_modules() {
	if [ "$1" == "force" ] ; then
		MODULES=$MODULES_FORCE
		FLAGS=$FLAGS_FORCE
		echo "using flags '$FLAGS'"
	fi
	echo -n "trying modules:"
	for module in $MODULES ; do
		echo -n " $module"
		modprobe tpm_${module} $FLAGS 2>/dev/null
		if test_tpm ; then
			return 0
		fi
		# clean up since e.g. infineon always loads w/o error...
		modprobe -r tpm_${module} 2>/dev/null
	done
	echo
	return 1
}

# create device-node
test -c /dev/tpm0 || mknod /dev/tpm0 c 10 224

if try_modules ; then
	exit 0  # success
fi
if ! try_modules force ; then
	echo "Warning: no TPM chip found!"
	exit 1
fi
