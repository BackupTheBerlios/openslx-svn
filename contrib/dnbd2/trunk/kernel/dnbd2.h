/*
 * kernel/dnbd2.h
 */


#include <linux/version.h>
#include <linux/workqueue.h>
#include <linux/completion.h>
#include <linux/blkdev.h>
#include <linux/types.h>
#include <linux/wait.h>
#include <linux/inet.h>
#include <linux/in.h>
#include <linux/version.h>
#if LINUX_VERSION_CODE >= KERNEL_VERSION(2,6,26)
#include <linux/semaphore.h>
#else
#include <asm/semaphore.h>
#endif
#include <net/sock.h>
#include "../include/dnbd2.h"


#define LOG KERN_NOTICE "dnbd2: "
#define p(msg) printk(LOG msg);

#define SECTOR_SIZE 512

#define for_each_server(i) for (i=0 ; i<ALT_SERVERS_MAX ; i++)

/* max number of requests the driver can handle at once. */
#define POOL_SIZE 128

/* precision of sector_t for pretty-printing */
#ifdef CONFIG_LBD
# define SECT_PRECISION "%llu"
#else
# define SECT_PRECISION "%lu"
#endif


typedef struct dnbd2_device dnbd2_device_t;

/*
 * We stick this structure to each request before enqueing it into the
 * send-queue.  It gives information on how to treat the request.
 */
struct req_info {
	uint16_t time;             /* enqueue time            */
	uint16_t cmd;              /* command (CMD_XXX)       */
	int cnt;                   /* send count              */
	struct srv_info *dst;      /* destination server      */
	struct srv_info *last_dst; /* last destination server */
};

/*
 * Information about a server with which we communicate.
 */
struct srv_info {
	dnbd2_device_t *dev;
	struct kobject kobj;
	struct work_struct work;

	struct socket *sock; /* NULL iff server not configured */
	uint32_t ip;         /* network byte order             */
	uint32_t port;       /* network byte order             */
	uint16_t min, max;   /* min and max RTTs               */
	unsigned long srtt;  /* SRTT (SRTT_SHIFT left-shifted) */

	sector_t capacity;    /* used when a CMD_GET_SIZE reply arrives */
	wait_queue_head_t wq; /* used when a CMD_GET_SIZE reply arrives */

	long rx_id;                 /* pid of dnbd2_rx_loop      */
	struct completion rx_start; /* dnbd2_rx_loop has started */
	struct completion rx_stop;  /* dnbd2_rx_loop has stopped */

	unsigned long retries;      /* number of requests retried */
	unsigned long last_reply;   /* time of last reply         */
};

struct dnbd2_device {
	struct work_struct work;
	struct kobject kobj;
	spinlock_t kmap_lock;
	struct req_info info_pool[POOL_SIZE];

	int running;   /* device is running and capacity != 0    */
	int emergency; /* device has lost contact to all servers */

	uint16_t vid, rid; /* Volume-ID and Release-ID */

	atomic_t refcnt;               /* for open/release, see fops.c    */
	struct semaphore config_mutex; /* for open/release and sysfs-fops */

	struct gendisk *disk; /* interface to the block layer            */
	spinlock_t blk_lock;  /* queue-lock, shared with the block layer */

	wait_queue_head_t sender_wq; /* wait-queue to notify dnbd2_tx_loop */
	spinlock_t send_queue_lock;
	struct list_head send_queue;

	unsigned long pending_reqs; /* number of block requests pending */
	spinlock_t pending_queue_lock;
	struct list_head pending_queue;

	struct timer_list requeue_timer; /* requeue timer   */
	struct timer_list to_timer;      /* takeover timer  */
	struct timer_list hb_timer;      /* heartbeat timer */
	unsigned long hb_interval;       /* HB_NORMAL_ or HB_EMERG_INTERVAL */

	int tx_id;                  /* pid of dnbd2_tx_loop        */
	struct completion tx_start; /* dnbd2_tx_loop has started   */
	struct completion tx_stop;  /* dnbd2_tx_loop has stopped   */
	int tx_signal;              /* tells dnbd2_tx_loop to stop */

	struct semaphore servers_mutex;
	struct srv_info servers[ALT_SERVERS_MAX];
	dnbd2_server_t emerg_list[ALT_SERVERS_MAX]; /* last servers known */
	struct srv_info *active_server;

	int to_percent;      /* percent threshold for takeover (relativ)  */
	uint16_t to_jiffies; /* jiffies threshold for takeover (absolute) */
};
