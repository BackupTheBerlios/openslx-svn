/*
 * kernel/devices.c
 */


#include "dnbd2.h"
#include "core.h"
#include "fops.h"
#include "sysfs.h"
#include "devices.h"
#include "servers.h"


#define TO_PERCENT 50
#define TO_JIFFIES 10


/*
 * Activate the request-processing mechanism for @dev: dnbd2_requeue
 * (timer) and dnbd2_tx_loop (thread). dnbd2_rx_loop is started
 * afterwards by add_server on a per-server basis.
 */
int start_device(dnbd2_device_t *dev)
{
	/* Start requeue timer. */
	init_timer(&dev->requeue_timer);
	dev->requeue_timer.data = (unsigned long)dev;
	dev->requeue_timer.function = dnbd2_requeue_timer;
	dev->requeue_timer.expires = jiffies + REQUEUE_INTERVAL;
	add_timer(&dev->requeue_timer);

	/* Start heartbeat timer. */
	init_timer(&dev->hb_timer);
	dev->hb_timer.data = (unsigned long)dev;
	dev->hb_timer.function = dnbd2_hb_timer;
	dev->hb_timer.expires = jiffies + HB_NORMAL_INTERVAL;
	add_timer(&dev->hb_timer);

	/* Start takeover timer. */
	init_timer(&dev->to_timer);
	dev->to_timer.data = (unsigned long)dev;
	dev->to_timer.function = dnbd2_to_timer;
	dev->to_timer.expires = jiffies + TO_INTERVAL;
	add_timer(&dev->to_timer);

	/* Start sending thread. */
	dev->tx_signal = 0;
	dev->tx_id = kernel_thread(dnbd2_tx_loop, dev, CLONE_KERNEL);
	if (dev->tx_id < 0) {
		del_timer(&dev->hb_timer);
		del_timer(&dev->to_timer);
		del_timer(&dev->requeue_timer);
		return -1;
	}
	wait_for_completion(&dev->tx_start);

	return 0;
}


/*
 * Deactivate the request-processing mechanism for @dev. All
 * dnbd2_rx_loop threads must be stopped beforehand by del_server.
 */
void stop_device(dnbd2_device_t *dev)
{
	struct list_head *cur, *next;
	struct request *req;

	/* Stop heartbeat timer. */
	del_timer(&dev->hb_timer);

	/* Stop takeover timer. */
	del_timer(&dev->to_timer);

	/* Stop request processing. */
	del_timer(&dev->requeue_timer);
	dev->tx_signal = 1;
	kill_proc(dev->tx_id, SIGKILL, 1);
	wait_for_completion(&dev->tx_stop);

	/* Empty pending-queue. */
	list_for_each_safe(cur, next, &dev->pending_queue) {
		req = blkdev_entry_to_request(cur);
		list_del_init(&req->queuelist);
		dnbd2_end_request(req, 0);
	}

	/* Empty send-queue. */
	list_for_each_safe(cur, next, &dev->send_queue) {
		req = blkdev_entry_to_request(cur);
		list_del_init(&req->queuelist);
		dnbd2_end_request(req, 0);
	}
}


int add_device(dnbd2_device_t *dev, int minor)
{
	struct request_queue *queue;
	struct srv_info *srv_info;
	struct gendisk *disk;
	int i;

	/*
	 * Prepare dnbd2_device_t. Please use the
	 * same order as in dnbd2.h.
	 */

	#if (LINUX_VERSION_CODE < KERNEL_VERSION(2,6,20))
		INIT_WORK(&dev->work, NULL, NULL);
	#else
		INIT_WORK(&dev->work, NULL); 
	#endif

	spin_lock_init(&dev->kmap_lock);
	for (i=0 ; i<POOL_SIZE ; i++)
		dev->info_pool[i].cnt = -1;

	dev->emergency = 0;
	dev->running = 0;

	dev->vid = 0;
	dev->rid = 0;

	atomic_set(&dev->refcnt, 0);
	init_MUTEX(&dev->config_mutex);

	spin_lock_init(&dev->blk_lock);

	init_waitqueue_head(&dev->sender_wq);
	spin_lock_init(&dev->send_queue_lock);
	INIT_LIST_HEAD(&dev->send_queue);

	dev->pending_reqs = 0;
	spin_lock_init(&dev->pending_queue_lock);
	INIT_LIST_HEAD(&dev->pending_queue);

	dev->hb_interval = HB_NORMAL_INTERVAL;

	init_completion(&dev->tx_start);
	init_completion(&dev->tx_stop);

	init_MUTEX(&dev->servers_mutex);
	for_each_server(i) {
		dev->emerg_list[i].ip = 0;
		dev->emerg_list[i].port = 0;
		srv_info = &dev->servers[i];
		memset(srv_info, 0, sizeof(struct srv_info));
		init_completion(&srv_info->rx_start);
		init_completion(&srv_info->rx_stop);
		init_waitqueue_head(&srv_info->wq);
	#if (LINUX_VERSION_CODE < KERNEL_VERSION(2,6,20))
		INIT_WORK(&srv_info->work, NULL, NULL);
	#else
		INIT_WORK(&srv_info->work, NULL);
	#endif
		/* Change in /<linuxheaders>/include/linux/workqueue.h */
		srv_info->dev = dev;
	}
	dev->active_server = NULL;

	dev->to_percent = TO_PERCENT;
	dev->to_jiffies = TO_JIFFIES;

	/* Prepare struct gendisk. */
	disk = alloc_disk(1);
	if (!disk) {
		p("Could not alloc gendisk.\n");
		goto out_nodisk;
	}
	dev->disk = disk;
	disk->private_data = dev;
	disk->major = dnbd2_major;
	disk->first_minor = minor;
	disk->fops = &dnbd2_fops;
	sprintf(disk->disk_name, "vnbd%d", minor);
	set_capacity(disk, 0);
	set_disk_ro(disk, 1);

	/* Prepare struct request_queue. */
	queue = blk_init_queue(dnbd2_request, &dev->blk_lock);
	if (!queue) {
		p("Could not alloc request queue.\n");
		goto out_noqueue;
	}
	/*
	 * Tell the block layer to give us only requests consisting of
	 * one segment of DNBD2_BLOCK_SIZE bytes.
	 */
	blk_queue_max_sectors(queue, DNBD2_BLOCK_SIZE/SECTOR_SIZE);
	blk_queue_max_segment_size(queue, DNBD2_BLOCK_SIZE);
	blk_queue_hardsect_size(queue, DNBD2_BLOCK_SIZE);
	blk_queue_max_phys_segments(queue, 1);
	blk_queue_max_hw_segments(queue, 1);
	disk->queue = queue;
	add_disk(disk);

	if (start_sysfs(dev))
		goto out_nosysfs;

	if (start_device(dev))
		goto out_nostart;

	return 0;

 out_nostart:
	stop_sysfs(dev);
 out_nosysfs:
	blk_cleanup_queue(queue);
 out_noqueue:
	del_gendisk(disk);
	put_disk(disk);
 out_nodisk:
	return -ENOMEM;
}


void del_device(dnbd2_device_t *dev)
{
	int i;
	for_each_server(i)
		del_server(&dev->servers[i]);
	stop_device(dev);
	stop_sysfs(dev);
	blk_cleanup_queue(dev->disk->queue);
	del_gendisk(dev->disk);
	put_disk(dev->disk);
}
