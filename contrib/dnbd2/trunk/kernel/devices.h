/*
 * kernel/devices.h
 */


/*
 * Initialize @dev and inform the kernel.
 */
int add_device(dnbd2_device_t *dev, int minor);

/*
 * Destroy @dev and inform the kernel.
 */
void del_device(dnbd2_device_t *dev);
