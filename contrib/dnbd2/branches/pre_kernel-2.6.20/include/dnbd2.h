/*
 * libs/dnbd2.h - Stuff that applies to all programs.
 */


/*
 * The Linux Kernel's minimum block request size is PAGE_SIZE.  We use
 * the same block size to simplify things.  We don't care about other
 * sizes because our software is platform dependant.
 */
#define DNBD2_BLOCK_SIZE 4096

/*
 * Commands the data-server understands.
 */
#define CMD_GET_BLOCK   1 /* Request a block. */
#define CMD_GET_SIZE    2 /* Request the size of a Dataset. */
#define CMD_GET_SERVERS 3 /* Request a list of alternative servers. */

/*
 * Maximum number of alternative data-servers per dataset.
 */
#define ALT_SERVERS_MAX 4

/*
 * Maximum lenght of strings including the ending \0.
 */
#define FILE_NAME_MAX  255
#define LINE_SIZE_MAX  FILE_NAME_MAX

/*
 * Network byte order <-> Host byte order (64bits).
 */
#ifndef MODULE
#if __BYTE_ORDER == __BIG_ENDIAN
#define ntohll(x) (x)
#define htonll(x) (x)
#else
#define ntohll(x) bswap_64(x)
#define htonll(x) bswap_64(x)
#endif
#endif


/*
 * Dataset
 */
typedef struct dataset {
        char     path[FILE_NAME_MAX]; /* pathname to file or block-device */
        uint16_t vid;                 /* Volume-ID */
        uint16_t rid;                 /* Release-ID */
} dataset_t;

/*
 * Structure to identify servers.
 */
#pragma pack(4)
typedef struct dnbd2_server {
        uint32_t ip;   /* IP   (network byte order) */
        uint16_t port; /* Port (network byte order) */
	uint16_t pad;  /* Padding - unused */
} dnbd2_server_t;
#pragma pack()

/*
 * Structure for requests:
 *
 *   <--------- 64 bits --------->
 *
 *   +---------------------------+
 *   | cmd  | time | vid  | rid  |
 *   |---------------------------|
 *   |          offset           |
 *   +---------------------------+
 *
 *   - cmd:  Command (defined above)
 *   - time: Time of request
 *   - vid:  Volume-ID
 *   - rid:  Release-ID
 *   - num:  Offset (for CMD_GET_BLOCK), otherwise undefined
 */
#pragma pack(1)
typedef struct dnbd2_data_request {
	uint16_t cmd;
	uint16_t time;
	uint16_t vid;
	uint16_t rid;
	uint64_t num;
} dnbd2_data_request_t;
#pragma pack()

/*
 * Structure for replies:
 *
 *   <--------- 64 bits --------->
 *
 *   +---------------------------+
 *   | cmd  | time | vid  | rid  |
 *   |---------------------------|
 *   |   offset/size/n.servers   |
 *   |---------------------------|
 *   |                           |
 *   |           (4KB)           |
 *   |   Block/List of servers   |
 *   |                           |
 *   +---------------------------+
 *
 *   - req.cmd:  Always echoed
 *   - req.time: Always echoed
 *   - req.vid:  Always echoed
 *   - req.rid:  Always echoed
 *   - req.num:  Echoed (for CMD_GET_BLOCK) or
 *               Dataset size (for CMD_GET_SIZE) or
 *               Number of Servers (for CMD_GET_SERVERS)
 *   - payload:  A block (for CMD_GET_BLOCK) or
 *               Undefined (for CMD_GET_SIZE) or
 *               List of Servers (for CMD_GET_SIZE)
 */
#pragma pack(1)
typedef struct dnbd2_data_reply {
	uint16_t cmd;
	uint16_t time;
	uint16_t vid;
	uint16_t rid;
	uint64_t num;
	union {
		uint8_t data[DNBD2_BLOCK_SIZE];
		dnbd2_server_t server[ALT_SERVERS_MAX];
	} payload;
} dnbd2_data_reply_t;
#pragma pack()
