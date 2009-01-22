/*
 * server/query.c
 */


#include <arpa/inet.h>
#include <inttypes.h>
#include <byteswap.h>
#include <syslog.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include "dnbd2.h"
#include "query.h"
#include "tree.h"
#include "file.h"


int handle_query(dnbd2_data_request_t *request,
		 dnbd2_data_reply_t *reply,
		 void **tree)
{
	int fd, i;
	node_t node1;
	node_t *node2;
	dataset_t ds;
	off_t size, pos;
	uint16_t cmd;

	/* Fetch the right fd for this vid/rid pair. */
	ds.vid = ntohs(request->vid);
	ds.rid = ntohs(request->rid);
	node1.ds = &ds;
	node2 = tree_find(&node1, tree);
	if (!node2)
		return -1;
	fd = node2->fd;

	cmd = ntohs(request->cmd);
	switch (cmd) {
	case CMD_GET_BLOCK:
		reply->num = request->num;
		pos = ntohll(request->num);
		file_read(fd, reply->payload.data, DNBD2_BLOCK_SIZE, pos);
		break;

	case CMD_GET_SIZE:
		if (file_getsize(fd, &size) == -1)
			return -1;
		reply->num  = htonll(size);
		break;

	case CMD_GET_SERVERS:
		/* Fetch a random block to deliver a more realistic RTT. */
		pos = 0;
		if (!file_getsize(fd, &size))
			pos = (off_t) (size * (rand() / (RAND_MAX + 1.0)));
		file_read(fd, reply->payload.data, DNBD2_BLOCK_SIZE, pos);
		reply->num = htonll(node2->servers);
		for (i=0 ; i<node2->servers ; i++) {
			memcpy(&reply->payload.server[i],
			       &node2->server[i],
			       sizeof(dnbd2_server_t));
		}
		break;
	}

	reply->cmd  = request->cmd;
	reply->time = request->time;
	reply->vid  = request->vid;
	reply->rid  = request->rid;

	return 0;
}
