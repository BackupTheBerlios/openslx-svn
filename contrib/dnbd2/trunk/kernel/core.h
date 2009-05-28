/*
 * kernel/core.h
 */


/* interval to send heartbeats */
#define HB_NORMAL_INTERVAL 30*HZ

/* interval to send heartbeats in emergency-mode */
#define HB_EMERG_INTERVAL  5*HZ

/* interval to check the pending-queue */
#define REQUEUE_INTERVAL HZ/20

/* interval to look for faster servers */
#define TO_INTERVAL HZ

/* dnbd0, dnbd1, etc */
#define DNBD2_DEVICES 3


/* Given to us by the kernel at load-time. */
extern int dnbd2_major;


/*
 * Called by the block layer to make the driver process some
 * requests. For each request it does the following:
 * 1. Prepares the request by attaching information to it.
 * 2. Enqueues the request into the send-queue.
 * 3. Wakes up dnbd2_tx_loop.
 */
#if LINUX_VERSION_CODE >= KERNEL_VERSION(2,6,25)
	void dnbd2_request(struct request_queue *q);
#else
	void dnbd2_request(request_queue_t *q);
#endif


/*
 * This thread sleeps until there are requests in the send-queue.
 * Each request is dequeued from the send-queue, enqueued into the
 * pending-queue and finally given to dnbd2_send_request.
 */
int dnbd2_tx_loop(void *data);

/*
 * Send a request and update the request's and the destination
 * server's counters.
 */
void dnbd2_send_request(struct request *req, dnbd2_device_t *dev);

/*
 * This thread sleeps until a reply arrives and then processes it.
 */
int dnbd2_rx_loop(void *data);

/*
 * When a reply arrives through the network it is caught by
 * dnbd2_rx_loop, which calls this function to find a matching request
 * in the pending queue.
 */
struct request *dnbd2_find_request(uint64_t num, uint16_t cmd,
				   struct srv_info *dst);

/*
 * The driver calls this function when it is done processing a request
 * and has no further use for it. Resources are freed and the block
 * layer informed if necessary.
 */
void dnbd2_end_request(struct request *req, int success);

/*
 * If a request remains too long unanswered, it is moved by this
 * function from the pending-queue into the send-queue. This function
 * is fired regularly by a timer.
 */
void dnbd2_requeue_timer(unsigned long arg);

/*
 * Periodically enqueu, for each server, a heartbeat request
 * (CMD_GET_SERVERS) into the send-queue.
 */
void dnbd2_hb_timer(unsigned long arg);

/*
 * Check every TO_INTERVAL jiffies if there is a faster server and
 * switch to it.  TO stands for "takeover".
 */
void dnbd2_to_timer(unsigned long arg);

/*
 * If the driver looses contact to all servers it starts the emergency
 * mode: First dnbd2_requeue_timer and dnbd2_to_timer are stopped.
 * Then the emergency list (the last list of servers acquired with
 * CMD_GET_SERVERS) is activated and the rate of heartbeats increased
 * to HB_EMERG_INTERVAL.
 */
void start_emergency(dnbd2_device_t *dev);

/*
 * This function is called if a server answers to a heartbeat during
 * emergency mode.  This server (@srv_info) is made the active server,
 * dnbd2_requeue_timer and dnbd2_to_timer started and the rate of
 * heartbeats decreased to HB_NORMAL_INTERVAL.
 */
void stop_emergency(struct srv_info *srv_info);
