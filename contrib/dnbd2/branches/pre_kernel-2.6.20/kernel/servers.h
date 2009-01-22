/*
 * kernel/servers.h
 */


#define SRTT_BETA       990
#define SRTT_BETA_COMP   10
#define SRTT_BETA_BASE 1000

/*
 * Though presented as a 16-bit number in sysfs, the SRTT is stored in
 * an unsigned long, SRTT_SHIFT bits left-shifted.  This helps
 * preserve the precision we need tou update the SRTTs.  If we stored
 * SRTT in an integer, it would only be changed by RTTS *very* far
 * away from it.
 */
#define SRTT_SHIFT       10

/*
 * After this interval without answering
 * requests a server is considered down.
 */
#define TIMEOUT_STALLED 3*HZ


/*
 * Configure @srv_info based on @server: Create a socket, connect it
 * and start a dnbd2_rx_loop for it.
 */
int add_server(dnbd2_server_t server, struct srv_info *srv_info);

/*
 * Reset @srv_info: Stop dnbd2_rx_loop, close the socket and zero all
 * variables.
 */
void del_server(struct srv_info *srv_info);

/*
 * Look for an unused server-slot in @dev and configure it according
 * to @server (using add_server). Nothing happens if the list of
 * servers if full or if there is already a server in the list with
 * the same IP and port as @server.
 */
void try_add_server(dnbd2_server_t server, dnbd2_device_t *dev);

/*
 * This function enqueues into the send-queue a request for the device
 * capacity (CMD_GET_SIZE). This type of request is retransmitted
 * every second. If an answer doesn't arrive within 4 seconds it
 * assumes that the server is down.
 */
sector_t srv_get_capacity(struct srv_info *srv_info);

/*
 * Update min, max and srtt in @srv_info.
 */
void update_rtt(uint16_t rtt, struct srv_info *srv_info, uint16_t cmd);

/*
 * Enqueue a heartbeat request (CMD_GET_SERVERS) for @srv_info into
 * the send-queue.
 */
void enqueue_hb(struct srv_info *srv_info);

/*
 * Schedule the removal of @srv_info to be processed by the global
 * kernel workqueue as soon as possible. This function allows to
 * trigger the removal of servers from within timers, in which
 * sleeping is not allowed.
 */
void schedule_del_server(struct srv_info *srv_info);

/*
 * Schedule the search for a faster server:
 * 1. Detect if the active server is stalled (down). In this case
 *    switch to another server, if possible, and remove the old one
 *    from the list.  If no servers are available to switch to
 *    start the emergency mode.
 * 2. If the emergency mode was not started go through the list of
 *    servers and pick the one with the smallest SRTT.  If this
 *    server meets our requirements (to_jiffies and to_percent)
 *    switch to it.
 */
void schedule_activate_fastest(dnbd2_device_t *dev);
