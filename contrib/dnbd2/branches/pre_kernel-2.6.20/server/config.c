/*
 * server/config.c
 */


#include <arpa/inet.h>
#include <stdlib.h>
#include <string.h>
#include <syslog.h>
#include <stdio.h>
#include "dnbd2.h"
#include "tree.h"
#include "file.h"
#include "config.h"


char *get_line(char *buf, FILE *file);
dataset_t *parse_dataset_file(const char *filename);
int parse_server(dnbd2_server_t *server, const char *str);


/*
 * The config file looks like this:
 *
 * 192.168.178.120
 * 5000
 * /etc/dnbd2/datasets/debian-3.1 192.168.178.119:5005
 * /etc/dnbd2/datasets/suse-10.2 192.168.178.119:5005 192.168.178.118:5005
 * ...
 *
 */
int parse_config_file(const char *filename, struct sockaddr_in *sockaddr,
		      void **tree)
{
	char buf[LINE_SIZE_MAX];
	FILE *file;

	bzero(sockaddr, sizeof(sockaddr));
	sockaddr->sin_family = AF_INET;

	/* Open file. */
	file = fopen(filename, "r");
	if (!file) {
		syslog(LOG_ERR, "Could not open config file %s", filename);
		return -1;
	}
	syslog(LOG_NOTICE, "Config file: %s", filename);

	/* Read IP from file. */
	if (!get_line(buf, file) || !inet_aton(buf, &(sockaddr->sin_addr))) {
		syslog(LOG_ERR, "Could not read IP.");
		return -1;
	}

	/* Read port number from file. */
	if (!get_line(buf, file) ||
	    sscanf(buf, "%hu", &(sockaddr->sin_port)) != 1) {
		syslog(LOG_ERR, "Could not read port number.");
		return -1;
	}
	sockaddr->sin_port = htons(sockaddr->sin_port);

	syslog(LOG_NOTICE, "IP = %s, Port = %hu",
	       inet_ntoa(sockaddr->sin_addr), ntohs(sockaddr->sin_port));

	int datasets = 0;
	char server[ALT_SERVERS_MAX][LINE_SIZE_MAX];
	char dsfile[LINE_SIZE_MAX];
	while (get_line(buf, file)) {

		int ret = sscanf(buf, "%s %s %s %s %s",
				 dsfile,
				 server[0],
				 server[1],
				 server[2],
				 server[3]) - 1;

		/* Parse a dataset file and put it into a tree-node. */
		dataset_t *dataset = parse_dataset_file(dsfile);
		if (!dataset)
			goto out_nodsfile;
		node_t *data = (node_t *)malloc(sizeof(node_t));
		if (!data) {
			syslog(LOG_ERR,
			       "Could not allocate memory for new Dataset.");
			goto out_nodataset;
		}
		int fd = file_open(dataset->path);
		if (fd == -1) {
			syslog(LOG_ERR,
			       "Could not open file or block device %s",
			       dataset->path);
			goto out_nodata;
		}
		strncpy(data->path, dsfile, FILE_NAME_MAX);
		data->ds = dataset;
		data->fd = fd;

		/* Parse the list of alterntive servers. */
		int i;
		int cnt = 0;
		for (i=0 ; i<ret ; i++)	
			cnt += parse_server(&data->server[cnt], server[i]);
		data->servers = cnt;

		/* Check if the Volume-ID-Release-ID pair is already in use. */
		node_t *data2 = tree_find(data, tree);
		if (data2) {
			syslog(LOG_ERR,
			       "Vol-ID/Rel-ID already used in Dataset file %s",
			       data2->path);
			goto out_nodata;
		}

		/* Insert Dataset into tree. */
		if (tree_insert(data, tree) == -1) {
			syslog(LOG_ERR, "Could not insert Dataset into tree.");
			goto out_nodata;
		}

		datasets++;
		continue;

	out_nodata:
		free(data);
	out_nodataset:
		free(dataset);
	out_nodsfile:
		syslog(LOG_ERR, "Problem parsing %s", dsfile);
	}

	syslog(LOG_NOTICE, "Loaded %d Dataset(s).", datasets);

	fclose(file);
	return datasets;
}


/*
 * A dataset config file looks like this:
 * 
 * /path/to/file/or/block/device
 * Volume-ID
 * Release-ID
 */
dataset_t *parse_dataset_file(const char *filename)
{
	char buf[LINE_SIZE_MAX];

	FILE *file = fopen(filename, "r");
	if (!file) {
		syslog(LOG_ERR, "Could not open Dataset file %s", filename);
		return NULL;
	}

	dataset_t *dataset = (dataset_t *) malloc(sizeof(dataset_t));
	if (!dataset) {
		syslog(LOG_ERR, "Could not allocate memory for new Dataset.");
		return NULL;
	}

	/* Read file- or block device name from file. */
	if (!get_line(dataset->path, file)) {
		syslog(LOG_ERR, "Could not read path to file or block device");
		return NULL;
	}

	/* Read Volume-ID from file. */
	if (!get_line(buf, file) || sscanf(buf, "%hu", &(dataset->vid)) != 1) {
		syslog(LOG_ERR, "Could not read Volume-ID.");
		return NULL;
	}

	/* Read Release-ID from file. */
	if (!get_line(buf, file) || sscanf(buf, "%hu", &(dataset->rid)) != 1) {
		syslog(LOG_ERR, "Could not read Release-ID.");
		return NULL;
	}

	fclose(file);
	return dataset;
}


char *get_line(char *buf, FILE *file)
{
	char *ret = fgets(buf, LINE_SIZE_MAX, file);

	/* change \n with \0 */
	if (ret)
		buf[strlen(buf)-1] = '\0';

	return ret;
}


int parse_server(dnbd2_server_t *server, const char *str)
{
	char ip[LINE_SIZE_MAX];
	uint16_t port;
	struct in_addr tmp;

	if (sscanf(str, "%[^:]:%hu", ip, &port) != 2)
		return 0;

	if (!inet_aton(ip, &tmp))
		return 0;

	memcpy(&server->ip, &tmp, sizeof(uint32_t));
	server->port = htons(port);

	return 1;
}
