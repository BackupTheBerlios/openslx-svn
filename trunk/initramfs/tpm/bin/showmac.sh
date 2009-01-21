#!/bin/sh
#

DEV="$1"
[ -z "$DEV" ] && DEV="eth0"

ip link show $DEV | \
	sed -n 's,.*\(..:..:..:..:..:..\) br.*,\1,p' | \
	sed 's,:,-,g'
