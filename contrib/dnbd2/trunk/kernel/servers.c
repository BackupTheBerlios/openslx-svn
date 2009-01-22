/*
 * kernel/servers.c
 */


#include "dnbd2.h"
#include "servers.h"
#include "core.h"
#include "misc.h"


/* Only use RTTs smaller than RTT_MAX for statistics. */
#define RTT_MAX HZ/4


/*
 * Find the next configured server which is not active.
 */
struct srv_info *next_server(dnbd2_device_t *dev)
{
	int i;
	struct srv_info *srv_info, *next_srv = NULL;

	for_each_server(i) {
		srv_info = &dev->servers[i];
		if (srv_info->sock && srv_info != dev->active_server) {
			next_srv = srv_info;
			break;
		}
	}
	return next_srv;
}


/*
 * Find the server with smallest SRTT.
 */
struct srv_info *fastest_server(uint16_t *srtt, dnbd2_device_t *dev)
{
	int i;
	struct srv_info *srv_info, *alt_srv = NULL;
	unsigned long min = RTT_MAX << SRTT_SHIFT;
	
	for_each_server(i) {
		srv_info = &dev->servers[i];
		if (srv_info->sock &&
		    srv_info->srtt < min &&
		    srv_info->min < RTT_MAX) {
			min = srv_info->srtt;
			alt_srv = srv_info;
		}
	}

	*srtt = min >> SRTT_SHIFT;
	return alt_srv;
}


/*
 * This function can be enqueued in a workqueue. It removes srv_info
 * from the list of servers.
 */
void del_server_work(struct work_struct *work)
{
	struct srv_info *srv_info = container_of(work, struct srv_info, work);
	dnbd2_device_t *dev = srv_info->dev;

	down(&dev->servers_mutex);
	if (!srv_info->sock || dev->active_server == srv_info) {
		up(&dev->servers_mutex);
		return;
	}
	del_server(srv_info);
	up(&dev->servers_mutex);
	return;
}


/*
 * This function can be enqueued in a workqueue. Read comment on
 * schedule_activate_fastest in servers.h
 */
void activate_fastest_work(struct work_struct *work)
{
	dnbd2_device_t *dev = container_of(work, dnbd2_device_t, work);
	struct srv_info *alt_srv, *next_srv;
	uint16_t min, srtt;
	int newsrv = 0;
	long unsigned delta;

	down(&dev->servers_mutex);
	if (!dev->active_server)
		goto out;

	/* Detect if dev->active_server is stalled. */
	delta = (long)jiffies - (long)dev->active_server->last_reply;
	if (dev->pending_reqs && delta > TIMEOUT_STALLED) {
		next_srv = next_server(dev);
		if (!next_srv) {
			start_emergency(dev);
			goto out;
		}
		alt_srv = dev->active_server;
		dev->active_server = next_srv;
		del_server(alt_srv);
	}

	/* Switch to another server if requirements met. */
	srtt = dev->active_server->srtt >> SRTT_SHIFT;
	alt_srv = fastest_server(&min, dev);
	if (!alt_srv || alt_srv == dev->active_server)
		goto out;
	if (dev->to_percent) {
		if (100 * (srtt - min) < dev->to_percent * srtt)
			goto out;
		newsrv = 1;
	}
	if (dev->to_jiffies) {
		if (min + dev->to_jiffies > srtt)
			goto out;
		newsrv = 1;
	}
	if (newsrv)
		dev->active_server = alt_srv;

 out:
	up(&dev->servers_mutex);
}


int start_rx_loop(struct srv_info *srv_info)
{
	srv_info->rx_id = kernel_thread(dnbd2_rx_loop, srv_info, CLONE_KERNEL);
	if (srv_info->rx_id < 0) {
		srv_info->rx_id = 0;
		return -1;
	}
	wait_for_completion(&srv_info->rx_start);
	return 0;
}


void stop_rx_loop(struct srv_info *srv_info)
{
	if (!srv_info->rx_id)
		return;
	kill_proc(srv_info->rx_id, SIGKILL, 1);
	wait_for_completion(&srv_info->rx_stop);
	srv_info->rx_id = 0;
}


/******************************************************/
/* For the next functions see servers.h for comments. */
/******************************************************/


int add_server(dnbd2_server_t server, struct srv_info *srv_info)
{
	struct sockaddr_in addr;
	struct socket *sock;

	if (!server.ip || !server.port)
		return -1;

	if (sock_create(PF_INET,SOCK_DGRAM, IPPROTO_UDP, &sock) < 0) {
		p("Could not create socket.\n");
		return -1;
	}
	addr.sin_family = AF_INET;
	addr.sin_addr.s_addr = server.ip;
	addr.sin_port = server.port;
	if (sock->ops->connect(sock,
			       (struct sockaddr *)&addr,
			       sizeof(addr), 0)) {
		p("Could not connect to socket.\n");
		goto out;
	}

	srv_info->sock = sock;
	srv_info->ip = server.ip;
	srv_info->port = server.port;
	srv_info->min = RTT_MAX;

	if (start_rx_loop(srv_info)) {
		p("Could not start rx_loop\n");
		goto out;
	}

	return 0;
 out:
	del_server(srv_info);
	return -1;
}


void del_server(struct srv_info *srv_info)
{
	stop_rx_loop(srv_info);
	if (srv_info->sock)
		sock_release(srv_info->sock);
	srv_info->sock = NULL;
	srv_info->ip = 0;
	srv_info->port = 0;
	srv_info->srtt = 0;
	srv_info->min = 0;
	srv_info->max = 0;
	srv_info->srtt = 0;
	srv_info->retries = 0;
	srv_info->last_reply = 0;
}


void try_add_server(dnbd2_server_t server, dnbd2_device_t *dev)
{
	int i;

        for_each_server(i)
		if (dev->servers[i].sock &&
		    dev->servers[i].ip == server.ip &&
		    dev->servers[i].port == server.port)
			return;

	for_each_server(i)
		if (!dev->servers[i].sock)
			break;

	if (i == ALT_SERVERS_MAX)
		return;

	add_server(server, &dev->servers[i]);
}


sector_t srv_get_capacity(struct srv_info *srv_info)
{
	struct request *req;
	struct req_info *info;
	dnbd2_device_t *dev = srv_info->dev;
	sector_t capacity;
	int ret;

	info = kmalloc(sizeof(struct req_info), GFP_KERNEL);
	if (!info)
		return 0;
	req = kmalloc(sizeof(struct request), GFP_KERNEL);
	if (!req) {
		kfree(info);
		return 0;
	}
	info->cmd = CMD_GET_SIZE;
	info->cnt = 0;
	info->time = jiffies;
	info->dst = srv_info;
	info->last_dst = srv_info;
	req->special = info;
	req->sector = 0;
	INIT_LIST_HEAD(&req->queuelist);

	/* Enqueue the request for sending. */
	spin_lock_bh(&dev->send_queue_lock);
	list_add_tail(&req->queuelist, &dev->send_queue);
	spin_unlock_bh(&dev->send_queue_lock);

	/* Wake up sender function. */
	wake_up_interruptible(&dev->sender_wq);

	/* If we don't get an answer in 4 seconds we give up. */
	ret = wait_event_timeout(srv_info->wq, srv_info->capacity, 4*HZ);
	capacity = srv_info->capacity;
	srv_info->capacity = 0;

	return ret ? capacity : 0;
}


void update_rtt(uint16_t rtt, struct srv_info *srv_info, uint16_t cmd)
{
	if (rtt == 0)
		rtt = 1;
	if (rtt > RTT_MAX)
		return;

	if (rtt < srv_info->min)
		srv_info->min = rtt;
	if (rtt > srv_info->max)
		srv_info->max = rtt;

 	if (!srv_info->srtt) {
		srv_info->srtt = rtt << SRTT_SHIFT;
		return;
	}

	switch (cmd) {
	case CMD_GET_BLOCK:
		srv_info->srtt = SRTT_BETA * srv_info->srtt;
		srv_info->srtt += (SRTT_BETA_COMP * ((int)rtt)) << SRTT_SHIFT;
		srv_info->srtt /= SRTT_BETA_BASE;
		break;

	case CMD_GET_SIZE:
	case CMD_GET_SERVERS:
		srv_info->srtt = rtt << SRTT_SHIFT;
		break;
	}
}


void enqueue_hb(struct srv_info *srv_info)
{
	struct request *req;
	struct req_info *info;
	dnbd2_device_t *dev = srv_info->dev;

	if (!srv_info->sock)
		return;
	info = kmalloc(sizeof(struct req_info), GFP_ATOMIC);
	if (!info)
		return;
	req = kmalloc(sizeof(struct request), GFP_ATOMIC);
	if (!req) {
		kfree(info);
		return;
	}
	info->cmd = CMD_GET_SERVERS;
	info->cnt = 0;
	info->time = jiffies;
	info->dst = srv_info;
	info->dst = srv_info;
	info->last_dst = srv_info;
	req->special = info;
	req->sector = 0;
	INIT_LIST_HEAD(&req->queuelist);

	/* Enqueue the request for sending. */
	spin_lock_bh(&dev->send_queue_lock);
	list_add_tail(&req->queuelist, &dev->send_queue);
	spin_unlock_bh(&dev->send_queue_lock);
}


void schedule_del_server(struct srv_info *srv_info)
{
	PREPARE_WORK(&srv_info->work, del_server_work); //, srv_info);
	/* Change in /<linuxheaders>/include/linux/workqueue.h */
	schedule_work(&srv_info->work);
}


void schedule_activate_fastest(dnbd2_device_t *dev)
{
	PREPARE_WORK(&dev->work, activate_fastest_work); //, dev);
	/* Change in /<linuxheaders>/include/linux/workqueue.h */
	schedule_work(&dev->work);
}
