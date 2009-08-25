/*
 * kernel/sysfs.c
 */


#include "dnbd2.h"
#include "misc.h"
#include "sysfs.h"
#include "devices.h"
#include "servers.h"


#define RW 0644
#define RO 0444

#define kobject_to_dev(kp) container_of(kp, dnbd2_device_t, kobj)
#define kobject_to_srv(kp) container_of(kp, struct srv_info, kobj)

#define attr_to_srvattr(ap) container_of(ap, struct server_attr, attr)
#define attr_to_devattr(ap) container_of(ap, struct device_attr, attr)

#define DEV_ATTR_RW(_name) \
static struct device_attr _name = \
__ATTR(_name, RW, show_##_name, store_##_name)

#define SRV_ATTR_RW(_name) \
static struct server_attr _name = \
__ATTR(_name, RW, show_##_name, store_##_name)

#define DEV_ATTR_RO(_name) \
static struct device_attr _name = \
__ATTR(_name, RO, show_##_name, NULL)

#define SRV_ATTR_RO(_name) \
static struct server_attr _name = \
__ATTR(_name, RO, show_##_name, NULL)


struct device_attr {
	struct attribute attr;
	ssize_t (*show)(char *, dnbd2_device_t *);
	ssize_t (*store)(const char *, size_t, dnbd2_device_t *);
};

struct server_attr {
	struct attribute attr;
	ssize_t (*show)(char *, struct srv_info *);
	ssize_t (*store)(const char *, size_t, struct srv_info *);
};


void release(struct kobject *kobj) {}

ssize_t show_running(char *, dnbd2_device_t *);
ssize_t store_running(const char *, size_t, dnbd2_device_t *);
ssize_t show_to_percent(char *, dnbd2_device_t *);
ssize_t store_to_percent(const char *, size_t, dnbd2_device_t *);
ssize_t show_to_jiffies(char *, dnbd2_device_t *);
ssize_t store_to_jiffies(const char *, size_t, dnbd2_device_t *);
ssize_t show_vid(char *, dnbd2_device_t *);
ssize_t store_vid(const char *, size_t, dnbd2_device_t *);
ssize_t show_rid(char *, dnbd2_device_t *);
ssize_t store_rid(const char *, size_t, dnbd2_device_t *);
ssize_t show_pending_reqs(char *, dnbd2_device_t *);
ssize_t show_emergency(char *, dnbd2_device_t *);

ssize_t show_sock(char *, struct srv_info *);
ssize_t store_sock(const char *, size_t, struct srv_info *);
ssize_t show_active(char *, struct srv_info *);
ssize_t store_active(const char *, size_t, struct srv_info *);
ssize_t show_rtt(char *, struct srv_info *);
ssize_t show_retries(char *, struct srv_info *);
ssize_t show_last_reply(char *, struct srv_info *);


/* device attributes */
DEV_ATTR_RW(running);
DEV_ATTR_RW(to_percent);
DEV_ATTR_RW(to_jiffies);
DEV_ATTR_RW(vid);
DEV_ATTR_RW(rid);
DEV_ATTR_RO(pending_reqs);
DEV_ATTR_RO(emergency);

static struct attribute *device_attrs[] = {
	&running.attr,
	&to_percent.attr,
	&to_jiffies.attr,
	&vid.attr,
	&rid.attr,
	&pending_reqs.attr,
	&emergency.attr,
	NULL,
};

/* server attributes */
SRV_ATTR_RW(sock);
SRV_ATTR_RW(active);
SRV_ATTR_RO(rtt);
SRV_ATTR_RO(retries);
SRV_ATTR_RO(last_reply);

struct attribute *server_attrs[] = {
	&sock.attr,
	&active.attr,
	&rtt.attr,
	&retries.attr,
	&last_reply.attr,
	NULL,
};


/*
 * Wrapper functions for show/store, one pair for device attributes
 * and one pair for server attributes.  Each attribute has its own
 * specific function(s).
 */
ssize_t device_show(struct kobject *kobj, struct attribute *attr,
			   char *buf)
{
	struct device_attr *device_attr = attr_to_devattr(attr);
	dnbd2_device_t *dev = kobject_to_dev(kobj);
	return device_attr->show(buf, dev);
}

ssize_t device_store(struct kobject *kobj, struct attribute *attr,
		     const char *buf, size_t count)
{
	int ret;
	struct device_attr *device_attr = attr_to_devattr(attr);
	dnbd2_device_t *dev = kobject_to_dev(kobj);
	down(&dev->config_mutex);
	ret = device_attr->store(buf, count, dev);
	up(&dev->config_mutex);
	return ret;
}

ssize_t server_show(struct kobject *kobj, struct attribute *attr,
			   char *buf)
{
	struct server_attr *server_attr = attr_to_srvattr(attr);
	struct srv_info *srv_info = kobject_to_srv(kobj);
	return server_attr->show(buf, srv_info);
}

ssize_t server_store(struct kobject *kobj, struct attribute *attr,
		     const char *buf, size_t count)
{
	int ret;
	struct server_attr *server_attr = attr_to_srvattr(attr);
	struct srv_info *srv_info = kobject_to_srv(kobj);
	down(&srv_info->dev->config_mutex);
	ret = server_attr->store(buf, count, srv_info);
	up(&srv_info->dev->config_mutex);
	return ret;
}


struct sysfs_ops device_ops = {
	.show   = device_show,
        .store  = device_store,
};

struct sysfs_ops server_ops = {
	.show   = server_show,
        .store  = server_store,
};

struct kobj_type device_ktype = {
	.default_attrs = device_attrs,
	.sysfs_ops = &device_ops,
	.release = release,
};

struct kobj_type server_ktype = {
	.default_attrs = server_attrs,
	.sysfs_ops = &server_ops,
	.release = release,
};


/*
 * RW device attribute functions.
 */
ssize_t show_running(char *buf, dnbd2_device_t *dev)
{
	return sprintf(buf, "%d\n", dev->running);
}

ssize_t store_running(const char *buf, size_t count, dnbd2_device_t *dev)
{
	sector_t capacity = 0;
	struct srv_info *srv_info;
	int i, running, ret = sscanf(buf, "%d", &running);

	if (ret != 1)
		return -EINVAL;

	if (!dev->running) {
		if (running != 1 || !dev->vid || !dev->rid)
			return -EINVAL;
		if (atomic_read(&dev->refcnt) > 0)
			return -EBUSY;

		for_each_server(i) {
			srv_info = &dev->servers[i];
			if (!srv_info->sock)
				continue;
			capacity = srv_get_capacity(srv_info);
			if (capacity) {
				set_capacity(dev->disk, capacity);
				dev->active_server = srv_info;
				break;
			}
		}
		if (!capacity) {
			p("Could not contact any servers.\n");
			return -EHOSTUNREACH;
		}
		for_each_server(i) {
			dev->emerg_list[i].ip   = dev->servers[i].ip;
			dev->emerg_list[i].port = dev->servers[i].port;
		}			
		printk(LOG "Device capacity = " SECT_PRECISION " KB\n",
		       capacity * SECTOR_SIZE / 1024);
		dev->running = 1;
		__module_get(THIS_MODULE);
	} else {
		if (running != 0)
			return -EINVAL;
		if (atomic_read(&dev->refcnt) > 0)
			return -EBUSY;

		/* Stop device. */
		dev->running = 0;
		set_capacity(dev->disk, 0);
		dev->active_server = NULL;
		module_put(THIS_MODULE);
	}

	return count;
}

ssize_t show_vid(char *buf, dnbd2_device_t *dev)
{
	return sprintf(buf, "%hu\n", dev->vid);
}

ssize_t store_vid(const char *buf, size_t count, dnbd2_device_t *dev)
{
	uint16_t vid;

	if (dev->running)
		return -EBUSY;
	if (sscanf(buf, "%hu", &vid) != 1)
		return -EINVAL;

	dev->vid = vid;
	return count;
}

ssize_t show_rid(char *buf, dnbd2_device_t *dev)
{
	return sprintf(buf, "%hu\n", dev->rid);
}

ssize_t store_rid(const char *buf, size_t count, dnbd2_device_t *dev)
{
	uint16_t rid;

	if (dev->running)
		return -EBUSY;
	if (sscanf(buf, "%hu", &rid) != 1)
		return -EINVAL;

	dev->rid = rid;
	return count;
}

ssize_t show_to_percent(char *buf, dnbd2_device_t *dev)
{
	return sprintf(buf, "%d\n", dev->to_percent);
}

ssize_t store_to_percent(const char *buf, size_t count, dnbd2_device_t *dev)
{
	if (sscanf(buf, "%d", &dev->to_percent) == 1)
		return count;
	return -EINVAL;
}

ssize_t show_to_jiffies(char *buf, dnbd2_device_t *dev)
{
	return sprintf(buf, "%hu\n", dev->to_jiffies);
}

ssize_t store_to_jiffies(const char *buf, size_t count, dnbd2_device_t *dev)
{
	if (sscanf(buf, "%hu", &dev->to_jiffies) == 1)
		return count;
	return -EINVAL;
}


/*
 * RO device attribute functions.
 */
ssize_t show_pending_reqs(char *buf, dnbd2_device_t *dev)
{
	return sprintf(buf, "%lu\n", dev->pending_reqs);
}

ssize_t show_emergency(char *buf, dnbd2_device_t *dev)
{
	return sprintf(buf, "%d\n", dev->emergency);
}


/*
 * RW server attribute functions.
 */
ssize_t show_sock(char *buf, struct srv_info *srv_info)
{
	return sprintf(buf, "%s %hu\n",
		       inet_ntoa(srv_info->ip),
		       ntohs(srv_info->port));
}

ssize_t store_sock(const char *buf, size_t count, struct srv_info *srv_info)
{
	char ip[sizeof "aaa.bbb.ccc.ddd 12345"];
	uint16_t port;
	dnbd2_server_t server;
	dnbd2_device_t *dev = srv_info->dev;

	if (count > sizeof "aaa.bbb.ccc.ddd 12345")
		return -EINVAL;
	if (sscanf(buf, "%s %hu", ip, &port) != 2)
		return -EINVAL;
	server.ip = in_aton(ip);
	server.port = htons(port);

	down(&dev->servers_mutex);
	if (dev->running && dev->active_server == srv_info) {
		up(&dev->servers_mutex);
		return -EBUSY;
	}
	if (srv_info->sock)
		del_server(srv_info);
	if (server.ip && server.port && add_server(server, srv_info)) {
		up(&dev->servers_mutex);
		return -EINVAL;
	}
	up(&dev->servers_mutex);

	return count;
}

ssize_t show_active(char *buf, struct srv_info *srv_info)
{
	if (!srv_info->sock)
		return sprintf(buf, "0\n");
	if (srv_info->dev->active_server == srv_info)
		return sprintf(buf, "1\n");
	return sprintf(buf, "0\n");
}

ssize_t store_active(const char *buf, size_t count, struct srv_info *srv_info)
{
	dnbd2_device_t *dev = srv_info->dev;
	int active;

	if (sscanf(buf, "%d", &active) != 1 || active != 1)
		return -EINVAL;

	down(&dev->servers_mutex);
	if (!dev->running) {
		up(&dev->servers_mutex);
		return -EINVAL;
	}
	if (!srv_info->sock || dev->active_server == srv_info) {
		up(&dev->servers_mutex);
		return -EINVAL;
	}
	dev->active_server = srv_info;
	up(&dev->servers_mutex);

	return count;
}


/*
 * RO server attribute functions.
 */
ssize_t show_rtt(char *buf, struct srv_info *srv_info)
{
	return sprintf(buf, "%hu %lu %hu\n",
		       srv_info->min,
		       srv_info->srtt >> SRTT_SHIFT,
		       srv_info->max);
}

ssize_t show_retries(char *buf, struct srv_info *srv_info)
{
	return sprintf(buf, "%lu\n", srv_info->retries);
}

ssize_t show_last_reply(char *buf, struct srv_info *srv_info)
{
	return sprintf(buf, "%lu\n", srv_info->last_reply);
}


/* Helper for start_sysfs. */
int setup_kobj(struct kobject *kobj, char *name, struct kobject *parent,
	       struct kobj_type *ktype)
{
	memset(kobj, 0, sizeof(struct kobject));
	kobj->parent = parent;
	kobj->ktype = ktype;
	
#if LINUX_VERSION_CODE >= KERNEL_VERSION(2,6,25)
	if (kobject_init_and_add(kobj, ktype, parent, name))
		return -1;
#else
	if (kobject_set_name(kobj, name))
		return -1;   
	if (kobject_register(kobj))
		return -1;
#endif
	return 0;
}


/*
 * Exported functions - see sysfs.h
 */
int start_sysfs(dnbd2_device_t *dev)
{
	int i;
	char name[] = "server99";

#if LINUX_VERSION_CODE >= KERNEL_VERSION(2,6,25)
	if (setup_kobj(&dev->kobj, "config", get_disk(dev->disk), &device_ktype))
#else
        if (setup_kobj(&dev->kobj, "config", &dev->disk->dev.kobj, &device_ktype))
#endif
            return -1;

	for_each_server(i) {
		sprintf(name, "server%d", i);
#if LINUX_VERSION_CODE >= KERNEL_VERSION(2,6,25)
        	if (setup_kobj(&dev->servers[i].kobj, name,
                               get_disk(dev->disk), &server_ktype))
#else
                if(setup_kobj(&dev-servers[i].kobj, name,
                              &dev->disk->dev.kobj, &server_ktype))
#endif
                goto out;
	}
	return 0;

 out:
	while (i--)
#if LINUX_VERSION_CODE >= KERNEL_VERSION(2,6,25)
		kobject_put(&dev->servers[i].kobj);
#else
                kobject_unregister(&dev->servers[i].kobj);
#endif
	return -1;
}

void stop_sysfs(dnbd2_device_t *dev)
{
	int i;
	for_each_server(i)
#if LINUX_VERSION_CODE >= KERNEL_VERSION(2,6,25)
		kobject_put(&dev->servers[i].kobj);
	kobject_put(&dev->kobj);
#else
                kobject_unregister(&dev->servers[i].kobj);
        kobject_unregister(&dev->kobj);

#endif
}
