/*
 * kernel/core.c - The principal component of the driver.
 *                 See core.h for comments on each function.
 */


#include "dnbd2.h"
#include "core.h"
#include "devices.h"
#include "misc.h"
#include "fops.h"
#include "servers.h"


int dnbd2_major;
static dnbd2_device_t dev[DNBD2_DEVICES];

#if LINUX_VERSION_CODE >= KERNEL_VERSION(2,6,25)
void dnbd2_request(struct request_queue *q)
#else
void dnbd2_request(request_queue_t *q)
#endif
{
	int i;
	struct request *req;
	struct req_info *info;
	dnbd2_device_t *dev;

	while ((req = elv_next_request(q)) != NULL) {
		/* Discard invalid block requests. */
		if (!blk_fs_request(req)) {
			end_request(req, 0);
			continue;
		}
		if (rq_data_dir(req) != READ) {
			end_request(req, 0);
			continue;
		}

		/* Prepare request. */
		dev = req->rq_disk->private_data;
		for (i=0 ; i<POOL_SIZE ; i++) {
			if (dev->info_pool[i].cnt == -1)
				break;
		}
		if (i == POOL_SIZE)
			continue;
		dev->pending_reqs++;
		info = &dev->info_pool[i];
		info->time = jiffies;
		info->cnt  = 0;
		info->cmd  = CMD_GET_BLOCK;
		info->dst  = dev->active_server;
		req->special = info;
		blkdev_dequeue_request(req);

		/* Enqueue the request for sending. */
		spin_lock_bh(&dev->send_queue_lock);
		list_add_tail(&req->queuelist, &dev->send_queue);
		spin_unlock_bh(&dev->send_queue_lock);

		/* Wakeup sender function. */
		wake_up_interruptible(&dev->sender_wq);
	}
}


int dnbd2_tx_loop(void *data)
{
	struct request *req;
	dnbd2_device_t *dev = data;
	struct req_info *info;

	daemonize("dnbd2_tx_loop");
	allow_signal(SIGKILL);
	complete(&dev->tx_start);

	while (1) {
		wait_event_interruptible(dev->sender_wq,
					 !list_empty(&dev->send_queue));

		/*
		 * If wait_event_interruptible is interrupted while
		 * the queue is not empty it retunrs 0, not
		 * -ERESTARTSYS. Therefore we need another flag.
		 */
		if (dev->tx_signal)
			break;

		/* Dequeue request from the send-queue. */
		spin_lock_bh(&dev->send_queue_lock);
		req = blkdev_entry_to_request(dev->send_queue.next);
		list_del_init(&req->queuelist);
		spin_unlock_bh(&dev->send_queue_lock);

		/*
		 * This is a good place to do some sanity checks
		 * because the request is neither in the send- nor in
		 * the pending-queue.
		 */
		down(&dev->servers_mutex);
		info = req->special;
		switch (info->cmd) {
		case CMD_GET_BLOCK:
			/*
			 * If dnbd2_request is called w/o first
			 * opening the device or with the device's
			 * capacity set to zero we should land here.
			 */
			if (!dev->running) {
				dnbd2_end_request(req, 0);
				up(&dev->servers_mutex);
				continue;
			}
			/*
			 * Send block requests to dev->active_server,
			 * which is always set while running.
			 */
			info->last_dst = info->dst;
			info->dst = dev->active_server;
			break;

		case CMD_GET_SERVERS:
		case CMD_GET_SIZE:
			/*
			 * Discard the request if it's destination is
			 * no longer available.
			 */
			if (!info->dst->sock) {
				dnbd2_end_request(req, 1);
				up(&dev->servers_mutex);
				continue;
			}
			break;
		}

		/* Enqueue request in the pending-queue. */
		spin_lock_bh(&dev->pending_queue_lock);
		list_add_tail(&req->queuelist, &dev->pending_queue);
		spin_unlock_bh(&dev->pending_queue_lock);

		/* Send request. */
		dnbd2_send_request(req, dev);
		up(&dev->servers_mutex);
	}

	complete_and_exit(&dev->tx_stop, 0);
}


void dnbd2_send_request(struct request *req, dnbd2_device_t *dev) {
	dnbd2_data_request_t dnbd2_req;
	struct req_info *info = req->special;

	dnbd2_req.cmd  = cpu_to_be16(info->cmd);
	dnbd2_req.time = cpu_to_be16(info->time);
	dnbd2_req.vid  = cpu_to_be16(dev->vid);
	dnbd2_req.rid  = cpu_to_be16(dev->rid);
	dnbd2_req.num  = cpu_to_be64(req->sector * SECTOR_SIZE);

	/*
	 * If sock_xmit fails the request eventually gets requeued.
	 * That's why we don't check its return value.
	 */
	sock_xmit(info->dst->sock, SEND, &dnbd2_req, sizeof(dnbd2_req));
	info->cnt++;
	if (info->dst != info->last_dst) {
		info->cnt = 1;
	} else if (info->cnt > 1) {
		info->dst->retries++;
	}
}


int dnbd2_rx_loop(void *data)
{
	struct srv_info *srv_info = data;
	dnbd2_device_t *dev = srv_info->dev;
	dnbd2_data_reply_t dnbd2_rep;
	struct request *req;
	uint64_t num;
	uint16_t cmd, time;
	char *buffer;
	int ret, i;

	daemonize("dnbd2_rx_loop");
	allow_signal(SIGKILL);
	complete(&srv_info->rx_start);

	while (1) {
		ret = sock_xmit(srv_info->sock, RECV,
				&dnbd2_rep, sizeof(dnbd2_rep));
		if (ret == -EINTR)
			break;
		if (ret != sizeof(dnbd2_rep) ||
		    be16_to_cpu(dnbd2_rep.vid) != dev->vid ||
		    be16_to_cpu(dnbd2_rep.rid) != dev->rid)
			continue;

		cmd = be16_to_cpu(dnbd2_rep.cmd);
		num = be64_to_cpu(dnbd2_rep.num);
		time = be16_to_cpu(dnbd2_rep.time);

		/* Find a matching request in the pending-queue. */
		req = dnbd2_find_request(num, cmd, srv_info);
		if (!req)
			continue;
		srv_info->last_reply = jiffies;
		update_rtt(diff(time), srv_info, cmd);

		switch (cmd) {
		case CMD_GET_BLOCK:
			spin_lock(&dev->kmap_lock);
			buffer = __bio_kmap_atomic(req->bio, 0, KM_USER0);
			memcpy(buffer,
			       dnbd2_rep.payload.data,
			       DNBD2_BLOCK_SIZE);
			__bio_kunmap_atomic(req->bio, KM_USER0);
			spin_unlock(&dev->kmap_lock);
			break;

		case CMD_GET_SIZE:
			if (!srv_info->capacity) {
				srv_info->capacity = num / SECTOR_SIZE;
				wake_up_all(&srv_info->wq);
			}
			break;

		case CMD_GET_SERVERS:
			down(&dev->servers_mutex);

			if (dev->emergency)
				stop_emergency(srv_info);

			/* Recreate the emergency list. */
			dev->emerg_list[0].ip = srv_info->ip;
			dev->emerg_list[0].port = srv_info->port;
			for (i=1 ; i<ALT_SERVERS_MAX; i++) {
				if (num) {
					memcpy(&dev->emerg_list[i],
					       &dnbd2_rep.payload.server[i-1],
					       sizeof(dnbd2_server_t));
					try_add_server(dev->emerg_list[i], dev);
					num--;
				} else {
					dev->emerg_list[i].ip = 0;
					dev->emerg_list[i].port = 0;
				}
			}
			up(&dev->servers_mutex);
			break;
		}
		dnbd2_end_request(req, 1);
	}

	complete_and_exit(&srv_info->rx_stop, 0);
}


struct request *dnbd2_find_request(uint64_t num,
				   uint16_t cmd,
				   struct srv_info *dst)
{
	dnbd2_device_t *dev = dst->dev;
	struct list_head *cur, *next;
	struct req_info *info;
	struct request *req;
	sector_t sector;

	switch (cmd) {
	case CMD_GET_BLOCK:
		sector = num / SECTOR_SIZE;
		spin_lock_bh(&dev->pending_queue_lock);
		list_for_each_safe(cur, next, &dev->pending_queue) {
			req = blkdev_entry_to_request(cur);
			info = req->special;

			if (req->sector == sector && info->cmd == cmd) {
				list_del_init(&req->queuelist);
				spin_unlock_bh(&dev->pending_queue_lock);
				return req;
			}
		}
		break;

	case CMD_GET_SIZE:
	case CMD_GET_SERVERS:
		spin_lock_bh(&dev->pending_queue_lock);
		list_for_each_safe(cur, next, &dev->pending_queue) {
			req = blkdev_entry_to_request(cur);
			info = req->special;

			if (info->cmd == cmd && info->dst == dst) {
				list_del_init(&req->queuelist);
				spin_unlock_bh(&dev->pending_queue_lock);
				return req;
			}
		}
	}

	spin_unlock_bh(&dev->pending_queue_lock);
	return NULL;
}


void dnbd2_end_request(struct request *req, int success)
{
	unsigned long flags;
	struct req_info *info = req->special;
	dnbd2_device_t *dev;

	switch (info->cmd) {
	case CMD_GET_BLOCK:
		dev = req->rq_disk->private_data;
		spin_lock_irqsave(&dev->blk_lock, flags);
		list_del_init(&req->queuelist);
#if LINUX_VERSION_CODE >= KERNEL_VERSION(2,6,25)
		if(!__blk_end_request(req, success, req->nr_sectors)) {
#else
		if (!end_that_request_first(req, success, req->nr_sectors)) {
			end_that_request_last(req, success);
#endif
		}
		dev->pending_reqs--;
		spin_unlock_irqrestore(&dev->blk_lock, flags);
		info->cnt = -1;
		break;

	case CMD_GET_SIZE:
	case CMD_GET_SERVERS:
		kfree(info);
		kfree(req);
		break;
	}
}


void dnbd2_requeue_timer(unsigned long arg)
{
	dnbd2_device_t *dev = (dnbd2_device_t *)arg;
	struct list_head *cur, *next;
	struct request *req;
	struct req_info *info;
	unsigned long too_long;
	int requeue;

	spin_lock(&dev->pending_queue_lock);
	list_for_each_safe(cur, next, &dev->pending_queue) {
		requeue = 0;
		req = blkdev_entry_to_request(cur);
		info = req->special;
		if (!info->cnt)
			continue;

		/* Each request type has a specific requeue policy. */
		switch (info->cmd) {
		case CMD_GET_BLOCK:
			too_long = 2 * (info->dst->srtt >> SRTT_SHIFT);
			too_long *= 4 << info->cnt;
			if (too_long > HZ)
				too_long = HZ;
			if (diff(info->time) >= too_long)
				requeue = 1;
			break;

		case CMD_GET_SERVERS:
		case CMD_GET_SIZE:
			if (info->cnt == 4) {
				list_del_init(&req->queuelist);
				dnbd2_end_request(req, 0);
				schedule_del_server(info->dst);
				break;
			}
			if (diff(info->time) >= HZ)
				requeue = 1;
			break;
		}

		if (requeue) {
			list_del_init(&req->queuelist);
			spin_lock(&dev->send_queue_lock);
			list_add_tail(&req->queuelist, &dev->send_queue);
			spin_unlock(&dev->send_queue_lock);
		}
	}
	spin_unlock(&dev->pending_queue_lock);

	wake_up_interruptible(&dev->sender_wq);
	dev->requeue_timer.expires = jiffies + REQUEUE_INTERVAL;
	add_timer(&dev->requeue_timer);
}


void dnbd2_hb_timer(unsigned long arg)
{
	dnbd2_device_t *dev = (dnbd2_device_t *)arg;
	int i;

	if (dev->running)
		for_each_server(i)
			enqueue_hb(&dev->servers[i]);

	wake_up_interruptible(&dev->sender_wq);
	dev->hb_timer.expires = jiffies + dev->hb_interval;
	add_timer(&dev->hb_timer);
}


void dnbd2_to_timer(unsigned long arg)
{
	dnbd2_device_t *dev = (dnbd2_device_t *)arg;

	if (dev->running)
		schedule_activate_fastest(dev);

	dev->to_timer.expires = jiffies + TO_INTERVAL;
	add_timer(&dev->to_timer);
}


void start_emergency(dnbd2_device_t *dev)
{
	int i;

	if (dev->emergency)
		return;

	p("No servers reachable, starting emergency mode!\n");
	dev->emergency = 1;

	del_timer(&dev->requeue_timer);
	del_timer(&dev->to_timer);
	del_timer(&dev->hb_timer);

	/* Activate the emergency list. */
	for_each_server(i)
		try_add_server(dev->emerg_list[i], dev);

	/* Increase frequency of heartbeats. */
	dev->hb_interval = HB_EMERG_INTERVAL;
	dev->hb_timer.expires = jiffies + HB_EMERG_INTERVAL;
	add_timer(&dev->hb_timer);
}


void stop_emergency(struct srv_info *srv_info)
{
	dnbd2_device_t *dev = srv_info->dev;

	if (!dev->emergency)
		return;

	p("Stopping emergency mode.\n");
	del_timer(&dev->hb_timer);

	dev->active_server = srv_info;

	/* Decrease frequency of heartbeats. */
	dev->hb_interval = HB_NORMAL_INTERVAL;
	dev->hb_timer.expires = jiffies + HB_NORMAL_INTERVAL;
	add_timer(&dev->hb_timer);

	dev->requeue_timer.expires = jiffies + REQUEUE_INTERVAL;
	add_timer(&dev->requeue_timer);
	dev->to_timer.expires = jiffies + TO_INTERVAL;
	add_timer(&dev->to_timer);

	dev->emergency = 0;
}


static int __init dnbd2_init(void)
{
	int i;

	/* We are platform dependant. */
	if (DNBD2_BLOCK_SIZE != PAGE_SIZE) {
		printk(LOG "DNBD2_BLOCK_SIZE (%d) != PAGE_SIZE (%d)\n",
		       (int) DNBD2_BLOCK_SIZE, (int) PAGE_SIZE);
		return -EINVAL;
	}

	dnbd2_major = register_blkdev(0, "dnbd2");
	if (dnbd2_major <= 0) {
		p("Could not get major number.\n");
		return -EBUSY;
	}

	for (i=0 ; i<DNBD2_DEVICES ; i++)
		if (add_device(&dev[i], i))
			goto out;

	p("DNBD2 loaded.\n");
	return 0;

 out:
	while (i--)
		del_device(&dev[i]);
	return -ENOMEM;
}


static void __exit dnbd2_exit(void)
{
	int i;
	for (i=0 ; i<DNBD2_DEVICES ; i++)
		del_device(&dev[i]);
	unregister_blkdev(dnbd2_major, "dnbd2");
	p("DNBD2 unloaded.\n");
}


module_init(dnbd2_init);
module_exit(dnbd2_exit);

MODULE_DESCRIPTION("Distributed Network Block Device v2");
MODULE_LICENSE("GPL");
