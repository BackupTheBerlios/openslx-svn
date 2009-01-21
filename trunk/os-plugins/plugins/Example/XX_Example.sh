#! /bin/sh
#
# stage3 part of 'Example' plugin - the runlevel script
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
#    /initramfs/plugin-conf/Example.conf)
#
# b) analyse the client (look at the available hardware) and decide what
#    needs to be done, taking into account the settings given in the config 
#    file
#
# c) activate the plugin by copying/linking appropriate plugin-specific files 
#    (in this case: from /mnt/opt/openslx/plugins/Example/), load required kernel
#    modules and whatever else might be necessary.
#
# if you have any questions regarding the use of this file, please drop a mail
# to: ot@openslx.com, or join the IRC-channel '#openslx' (on freenode).

if ! [ -e /initramfs/plugin-conf/Example.conf ]; then
	exit 1
fi

# for this example plugin, we simply take a filename from the configuration ...
. /initramfs/plugin-conf/Example.conf

if ! [ -n $active]; then
	exit 0
fi

echo "executing the 'Example' os-plugin ...";

# ... and cat that file (output the smiley):
cat /mnt/opt/openslx/plugin-repo/Example/$preferred_side

echo "done with 'Example' os-plugin ...";
