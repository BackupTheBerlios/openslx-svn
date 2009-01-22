/*
 * kernel/misc.h - Usefull stuff that doesn't fit anywhere else.
 */


#define SEND 1
#define RECV 0


/*
 * Jiffies between now and @then.
 */
uint16_t diff(uint16_t then);

/*
 * Send or receive packet (from nbd.c)
 */
int sock_xmit(struct socket *sock, int send, void *buf, int size);

/*
 * Pretty printing of IPs.
 */
char *inet_ntoa(uint32_t ip);
