/*
 * kernel/sysfs.h
 */


/*
 * Setup the sysfs-interface for @dev:
 *
 * M = minor number
 * N = ALT_SERVERS_MAX - 1
 *
 * /sys/block/vnbdM/config    (from @dev->kobj)
 * /sys/block/vnbdM/server0   (from @dev->servers[0].kobj)
 *          .
 *          .
 * /sys/block/vnbdM/serverN   (from @dev->servers[N].kobj)
 *
 */
int start_sysfs(dnbd2_device_t *dev);

/*
 * Destroy the sysfs-interface for @dev.
 */
void stop_sysfs(dnbd2_device_t *dev);
