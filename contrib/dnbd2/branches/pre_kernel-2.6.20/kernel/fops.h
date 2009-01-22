/*
 * kernel/fops.h
 */


extern struct block_device_operations dnbd2_fops;

int dnbd2_open(struct inode *inode, struct file *file);
int dnbd2_release(struct inode *inode, struct file *file);
