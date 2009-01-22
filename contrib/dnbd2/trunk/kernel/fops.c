/*
 * kernel/fops.c
 */


#include "dnbd2.h"
#include "fops.h"


struct block_device_operations dnbd2_fops = {
	.owner   = THIS_MODULE,
	.open    = dnbd2_open,
	.release = dnbd2_release,
};


int dnbd2_open(struct inode *inode, struct file *file)
{
	dnbd2_device_t *dev = inode->i_bdev->bd_disk->private_data;
	if (down_interruptible(&dev->config_mutex))
		return -EBUSY;

	/* FIXME: How do we put this add/start_device? */
	if (set_blocksize(inode->i_bdev, DNBD2_BLOCK_SIZE)) {
		up(&dev->config_mutex);
		return -EBUSY;
	}

	atomic_inc(&dev->refcnt);
	up(&dev->config_mutex);
	return 0;
}


int dnbd2_release(struct inode *inode, struct file *file)
{
	dnbd2_device_t *dev = inode->i_bdev->bd_disk->private_data;
	if (down_interruptible(&dev->config_mutex))
		return -EBUSY;
	atomic_dec(&dev->refcnt);
	up(&dev->config_mutex);
	return 0;
}
