/*
 * server/config.h
 */


/*
 * Parse the server configuration file, create a socket address
 * structure and a tree of datasets.
 *
 * Returns: Number of Datasets loaded or -1 on failure.
 */
int parse_config_file(const char *filename, struct sockaddr_in *sockaddr,
		      void **tree);
