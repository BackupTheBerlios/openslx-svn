/*
 * test-apps/data-client.c
 */

#include <sys/socket.h>
#include <netinet/in.h>
#include <byteswap.h>
#include <arpa/inet.h>
#include <strings.h>
#include <unistd.h>
#include <string.h>
#include <stdio.h>
#include <errno.h>
#include "dnbd2.h"


void print_usage(void);
ssize_t writen(int fd, const void *msg, size_t n);
ssize_t readn(int fd, void *msg, size_t n);
int dnbd2_data_request(dnbd2_server_t server,
                       dnbd2_data_request_t request,
                       dnbd2_data_reply_t *reply);


int main(int argc, char **argv)
{
        if (argc != 6) {
		print_usage();
                return 0;
        }

	dnbd2_data_request_t request;
	dnbd2_data_reply_t reply;

	/* The time field is always echoed by the server.
	   This is an arbitrary value. */
	request.time = 28481;

	/* Read IP and Port */
	dnbd2_server_t server;
        if (!inet_aton(argv[1], (struct in_addr *) &(server.ip))) {
                fprintf(stderr, "Invalid IP\n");
                return -1;
        }
        if (sscanf(argv[2], "%hu", &(server.port)) != 1) {
                fprintf(stderr, "Invalid Port\n");
                return -1;
        }
        server.port = htons(server.port);

	/* Read Volume-ID and Release-ID */
	if (sscanf(argv[3], "%hu", &(request.vid)) != 1) {
                fprintf(stderr, "Invalid Volume-ID\n");
                return -1;
        }
	if (sscanf(argv[4], "%hu", &(request.rid)) != 1) {
                fprintf(stderr, "Invalid Release-ID\n");
                return -1;
        }

	/* Read command */
	char str[16];
	int cmd = 0;
	if (sscanf(argv[5], "%s", str) == 1) {
		if (!strcmp("getdata", str))
			cmd = 1;

		if (!strcmp("getsize", str))
			cmd = 2;

		if (!strcmp("getservers", str))
			cmd = 3;
	}
	if (!cmd) {
		fprintf(stderr, "Invalid CMD\n");
		return -1;
	}

	/* Complete and issue request(s) */
	int ret, i, rest;
	off_t size, blocks;
	switch (cmd) {
	case 1:
		/* Get Dataset size */
		request.cmd = CMD_GET_SIZE;
		ret = dnbd2_data_request(server, request, &reply);
		if (ret == -1)
			goto out_nosize;
		size = reply.num;

		/* size = blocks * DNBD2_BLOCK_SIZE + rest */
		blocks = size / DNBD2_BLOCK_SIZE;
		rest = size % DNBD2_BLOCK_SIZE;

		/* Fetch "blocks * DNBD2_BLOCK_SIZE" bytes */
		request.cmd = CMD_GET_BLOCK;
		for (i=0 ; i<blocks ; i++) {
			request.num = i * DNBD2_BLOCK_SIZE;
			ret = dnbd2_data_request(server, request, &reply);
			if (ret == -1)
				goto out_nodata;
			write(STDOUT_FILENO, reply.payload.data,
			      DNBD2_BLOCK_SIZE);
		}

		/* Fetch "rest" bytes */
		if (rest != 0) {
			request.num = i*DNBD2_BLOCK_SIZE;
			ret = dnbd2_data_request(server, request, &reply);
			if (ret == -1)
				goto out_nodata;
			write(STDOUT_FILENO, reply.payload.data, rest);
		}		
		break;

	case 2:
		/* Get Dataset size */
		request.cmd = CMD_GET_SIZE;
		ret = dnbd2_data_request(server, request, &reply);
		if (ret == -1)
			goto out_nosize;
		printf("Dataset Size = %lld\n", reply.num);
		break;

	case 3:
		/* Get list of alternative servers */
		request.cmd = CMD_GET_SERVERS;
		ret = dnbd2_data_request(server, request, &reply);
		if (ret == -1)
			goto out_noservers;
		if (reply.num == 0)
			printf("No alternative servers.\n");

		for (i=0 ; i<reply.num ; i++) {
			dnbd2_server_t server;
			struct in_addr addr;
			memcpy(&server,
			       &reply.payload.server[i],
			       sizeof(dnbd2_server_t));
			memcpy(&addr,
			       &server.ip,
			       sizeof(uint32_t));
			printf("%s:%hu\n", inet_ntoa(addr), ntohs(server.port));
		}
		break;
	}


	return 0;

 out_nodata:
	fprintf(stderr, "Could not get data.\n");
	return -1;

 out_nosize:
	fprintf(stderr, "Could not get Dataset size.\n");
	return -1;

 out_noservers:
	fprintf(stderr, "Could not get list of alternative servers.\n");
	return -1;
}


int dnbd2_data_request(dnbd2_server_t server,
                       dnbd2_data_request_t request,
                       dnbd2_data_reply_t *reply)
{
	struct sockaddr_in server_addr;
	bzero(&server_addr, sizeof(server_addr));
	server_addr.sin_addr.s_addr = server.ip;
	server_addr.sin_port = server.port;
	server_addr.sin_family = AF_INET;

	int sockfd = socket(PF_INET, SOCK_DGRAM, 0);
	if (sockfd == -1) {
		fprintf(stderr, "Could not create socket.\n");
		return -1;
	}
	if (connect(sockfd, (struct sockaddr *) &server_addr,
		    sizeof(server_addr)) == -1) {
		fprintf(stderr,"Could not connect UDP socket.");
		return -1;
	}

	request.cmd  = htons(request.cmd);
	request.time = htons(request.time);
	request.vid  = htons(request.vid);
	request.rid  = htons(request.rid);
	request.num  = htonll(request.num);

	/* Send request. */
	ssize_t n = writen(sockfd, &request, sizeof(request));
	if (n == -1) {
		fprintf(stderr, "Error sending request.\n");
		return -1;
	}
	if (n != sizeof(request)) {
		fprintf(stderr, "Sent wrong request size.\n");
		return -1;
	}

	/* Receive reply. */
	n = readn(sockfd, reply, sizeof(*reply));
	if (n == -1) {
		fprintf(stderr, "Error receiving reply.\n");
		return -1;
	}
	if (n != sizeof(*reply)) {
		fprintf(stderr, "Got wrong reply size.\n");
		return -1;
	}
	close(sockfd);

	reply->cmd  = ntohs(reply->cmd);
	reply->time = ntohs(reply->time);
	reply->vid  = ntohs(reply->vid);
	reply->rid  = ntohs(reply->rid);
	reply->num  = ntohll(reply->num);

	return 0;
}


ssize_t writen(int fd, const void *msg, size_t n) {

        size_t nleft;
        ssize_t nwritten;
        const char *ptr;

        ptr = msg;
        nleft = n;

        while (nleft > 0) {
                if ((nwritten = write(fd, ptr, nleft)) <= 0) {
                        if (errno == EINTR)
                                nwritten = 0;
                        else
                                return -1;
                }
                nleft -= nwritten;
                ptr += nwritten;
        }

        return (n);
}


ssize_t readn(int fd, void *msg, size_t n) {

        size_t nleft;
        ssize_t nread;
        char *ptr;

        ptr = msg;
        nleft = n;

        while (nleft > 0) {
                if ((nread = read(fd, ptr, nleft)) < 0) {
                        if (errno == EINTR)
                                nread = 0;
                        else
                                return -1;
                } else if (nread == 0) {
                        break;
                }
                nleft -= nread;
                ptr += nread;
        }

        return n - nleft;
}


void print_usage(void) {
	printf("usage: dnbd2-data IP Port Volume-ID Release-ID "
	       "(getsize|getdata|getservers)\n");
	printf("       getsize: Print the Dataset's size.\n");
	printf("       getdata: Write the Dataset's contents to stdout.\n");
	printf("       getsize: Print the list of alternative Servers.\n");
}
