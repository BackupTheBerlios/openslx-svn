#! /bin/sh
#
# stage3 part of 'example' plugin - the runlevel script
#
# This basically is a runlevel script (just like you know them from 'init'),
# whose purpose is to activate the plugin in stage3. The 'XX' at the beginning 
# of the filename will be replaced with a runlevel precedence number taken 
# from the configuration of the respective plugin. All plugin runlevel scripts 
# will be executed in the order of those precedence numbers.
#
# In order to activate the corresponding plugin, each runlevel script should:
#
# a) read the corresponding configuration file (in this case: 
#    /initramfs/plugin-conf/example.conf)
#
# b) analyse the client (look at the available hardware) and decide what
#    needs to be done, taking into account the settings given in the config 
#    file
#
# c) activate the plugin by copying/linking appropriate plugin-specific files 
#    (in this case: from /mnt/opt/openslx/plugins/example/), load required kernel
#    modules and whatever else might be necessary.
#
# if you have any questions regarding the use of this file, please drop a mail
# to: ot@openslx.com, or join the IRC-channel '#openslx' (on freenode).

if [ -e /initramfs/plugin-conf/example.conf ]; then
	. /initramfs/plugin-conf/example.conf
	if [ $example_active -ne 0 ]; then
		[ $DEBUGLEVEL -gt 0 ] && echo "executing the 'bindrivers' os-plugin ...";

		# for this example plugin, we simply take a filename from the 
		# configuration and cat that file (output the smiley):
		cat /mnt/opt/openslx/plugin-repo/example/$preferred_side

		[ $DEBUGLEVEL -gt 0 ] && echo "done with 'bindrivers' os-plugin ...";
	fi
fi
