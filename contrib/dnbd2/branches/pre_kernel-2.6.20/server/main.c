/*
 * server/main.c
 */


#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <unistd.h>
#include <syslog.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include "dnbd2.h"
#include "tree.h"
#include "file.h"
#include "config.h"
#include "query.h"


char *cfile = NULL; /* path to config file */
void *tree = NULL;  /* tree containing datasets */
int server_fd;      /* file descriptor for UPD communication */
struct sockaddr_in server_addr;


/*
 * Flags and signal handlers.
 */
int sig_exit, sig_config;
void exit_handler(int sig);
void config_handler(int sig);


/*
 * Function to configure server.  We call it with LOAD on
 * initialization and with RELOAD when SIGHUP is caught.
 */
enum config_action { LOAD, RELOAD };
int configure(enum config_action action);


void print_usage(void);
int daemon_init(void);


int main(int argc, char **argv)
{
	int ret;
	ssize_t n;
	socklen_t len;
	dnbd2_data_reply_t reply;
	dnbd2_data_request_t request;
	struct sockaddr_in client_addr;
	struct sigaction exit_act, config_act;

	if (argc != 2) {
		print_usage();
		return -1;
	}

	cfile = argv[1];
	openlog(argv[0], LOG_PID, LOG_LOCAL2);
	syslog(LOG_NOTICE, "Starting DNBD2 Server.");

	/* Load datasets and bind to socket. */
	if (configure(LOAD) == -1)
		goto out_no_start;

	/* Daemonize. */
	ret = daemon_init();
	if (ret == -1) {
		syslog(LOG_ERR, "Could not fork and background.");
		goto out_no_start;
	}

	/* Setup signal handlers. */
	sigaction(SIGTERM, NULL, &exit_act);
	exit_act.sa_flags &= ~SA_RESTART;
	exit_act.sa_handler = exit_handler;

	sigaction(SIGHUP, NULL, &config_act);
	config_act.sa_flags &= ~SA_RESTART;
	config_act.sa_handler = config_handler;

	sigaction(SIGTERM, &exit_act, NULL);
	sigaction(SIGINT, &exit_act, NULL);
	sigaction(SIGHUP, &config_act, NULL);

	while (1) {
		if (sig_exit) {
		        syslog(LOG_NOTICE, "Stopping Server.");
			exit(0);
		}
		if (sig_config) {
			syslog(LOG_NOTICE, "Reloading configuration.");
			if (configure(RELOAD) == -1)
				syslog(LOG_ERR, "Not using new configuration.");
			sig_config = 0;
		}

		/* Receive request. */
		len = sizeof(client_addr);
		n = recvfrom(server_fd, &request, sizeof(request), 0,
			     &client_addr, &len);

		if (n == -1 || n != sizeof(request))
			continue;

		/* Process request. */
		ret = handle_query(&request, &reply, &tree);
		if (ret == -1)
			continue;

		/* Send reply. */
		sendto(server_fd, &reply, sizeof(reply), 0, &client_addr, len);
	}

	return 0;

 out_no_start:
        syslog(LOG_ERR, "Server not started.");
        fprintf(stderr, "Server not started - "
		"consult your syslog for errors.\n");
        return -1;
}


void config_handler(int sig)
{
	sig_config = 1;
}


void exit_handler(int sig)
{
	sig_exit = 1;
}


int cmp_addr(struct sockaddr_in addr1, struct sockaddr_in addr2)
{
	int diff = memcmp(&addr1.sin_addr.s_addr,
			  &addr2.sin_addr.s_addr,
			  sizeof(in_addr_t));

	if (diff)
		return diff;

	return memcmp(&addr1.sin_port,
		      &addr2.sin_port,
		      sizeof(in_port_t));
}


int configure(enum config_action action)
{
	void *tmp_tree = NULL;
	int datasets, ret, tmp_fd = server_fd;
	struct sockaddr_in tmp_addr;

	datasets = parse_config_file(cfile, &tmp_addr, &tmp_tree);
	if (datasets <= 0)
		return -1;

	/* Create a socket and bind to it. */
	if (action == LOAD || cmp_addr(tmp_addr, server_addr)) {
		tmp_fd = socket(PF_INET, SOCK_DGRAM, 0);
		if (tmp_fd == -1) {
			syslog(LOG_ERR, "Could not create socket.");
			return -1;
		}

		ret = bind(tmp_fd, (struct sockaddr *) &tmp_addr,
			   sizeof(tmp_addr));

		if (ret == -1) {
			close(tmp_fd);
			syslog(LOG_ERR, "Could not assign name to socket.");
			return -1;
		}
	}
	
	/* Make new socket available and close the old one if necesary. */
	if (action == RELOAD && cmp_addr(tmp_addr, server_addr)) {
		if (close(server_fd) == -1 ) {
			syslog(LOG_ERR, "Could not close socket.");
		}
	}

	server_fd = tmp_fd;
	server_addr = tmp_addr;

	tree_destroy(tree);
	tree = tmp_tree;
	return 0;
}


void print_usage(void)
{
	printf("usage: dnbd2-dserver config-file\n");
}


int daemon_init(void)
{
	pid_t pid = fork();

	if (pid == -1)
		return pid;

	if (pid != 0) {
		/* We are the parent. */
		exit(0); 
	}

	/* We are the child. */
	setsid();
	chdir("/");
	umask(0);

	return 0;
}
