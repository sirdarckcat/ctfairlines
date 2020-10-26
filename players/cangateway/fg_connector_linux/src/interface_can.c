#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#include <libxml/parser.h>

#include "config.h"
#include "flightgear.h"

#include "interface_can.h"

/**
 * Create CAN frame
 */
int can_create(unsigned long int can_id, float value, unsigned char *can_frame, unsigned char *length) {

	*(can_frame+0) = (unsigned char) (can_id >> 16);
	*(can_frame+1) = (unsigned char) (can_id >> 8);
	*(can_frame+2) = (unsigned char) (can_id);
	*(can_frame+3) = 8; /* data length */
	*(can_frame+4) = 0;
	*(can_frame+5) = 2; /* data format */
	*(can_frame+6) = 0;
	*(can_frame+7) = 0;
	*(can_frame+8) = *(((unsigned char *) &value)+3);
	*(can_frame+9) = *(((unsigned char *) &value)+2);
	*(can_frame+10) = *(((unsigned char *) &value)+1);
	*(can_frame+11) = *(((unsigned char *) &value)+0);

	*length = 12;

	return 0;
}

/* void *can_open_(void *arg) {
	
	struct struct_addr_param *param;

	struct sockaddr_in addr;
	struct sockaddr_in addr_client;
	int sid;

	int len;

	int result;

	char buff[BUFF_LEN+1];

	float tmp;

	param = (struct struct_addr_param *) arg;

	memset(&addr, 0, sizeof(addr));
	memset(&addr_client, 0, sizeof(addr_client));
	addr.sin_family = AF_INET;
	addr.sin_addr.s_addr = inet_addr(param->addr);
	addr.sin_port = htons(param->port);

	len = sizeof(addr_client);

	sid = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
	bind(sid, (struct sockaddr *) &addr, sizeof(addr));

	while (1) {
		result = recvfrom(sid, buff, BUFF_LEN, 0, (struct sockaddr *) &addr_client, (socklen_t *) &len);
		*(buff+result) = '\0';

		if (result != 2) {
			continue;
		}

		tmp = get_property_value(*buff);
		sendto(sid, (char *) &tmp, sizeof(float), 0, (struct sockaddr *) &addr_client, len);
	}
	
	return (void *) 0;
} */

int can_open(struct struct_config *config, struct struct_flightgear_status *status) {

	struct struct_config_target *target;
	struct sockaddr_in address;

	int result;

	/* parse input arguments */
	if (!config || !config->targets  || !status) {
		return -1;
	}

	FD_ZERO(&(status->target_socket_set));
	status->target_socket_max = 0;
	FD_ZERO(&(status->target_socket_receive_set));
	status->target_socket_receive_max = 0;

	/* open sockets for can communication */
	target = config->targets;
	while (target) {
		char *temp;
		switch (target->type) {
                case TARGET_CANAERO:
                  // foo
                break;
		case TARGET_BROADCAST_SERVER:

			if (config->verbose) {
				temp = "BROADCAST";
				fprintf(stdout, "Opening client connection: %s [%s] (%s:%i)\t\t\t", target->name, temp, target->address, target->port_send);
			}

			memset(&(target->socket_address), 0, sizeof(struct sockaddr_in));
			target->socket_address.sin_family = AF_INET;
			target->socket_address.sin_addr.s_addr = inet_addr(target->address);
			target->socket_address.sin_port = htons(target->port_send);

			target->socket_receive_id = 0;
			target->socket_id = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
			if (!target->socket_id) {
				if (config->verbose) {
					fprintf(stdout, "FAIL\n");
				}
			} else {
				if (config->verbose) {
					fprintf(stdout, "OK\n");
				}
				FD_SET(target->socket_id, &(status->target_socket_set));

				if (target->socket_id >= status->target_socket_max) {
					status->target_socket_max = target->socket_id + 1;
				}
			}
			break;
		case TARGET_QUESTION_RESPONSE:

			if (config->verbose) {
				temp = "QUESTION/RESPONSE";
				fprintf(stdout, "Opening client connection: %s [%s] (%s:%i:%i)\t", target->name, temp, target->address, target->port_receive, target->port_send);
			}

			memset(&address, 0, sizeof(struct sockaddr_in));
			address.sin_family = AF_INET;
			address.sin_addr.s_addr = inet_addr(target->address);
			address.sin_port = htons(target->port_receive);

			target->socket_id = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
			if (!target->socket_id) {
				if (config->verbose) {
					fprintf(stdout, "FAIL");
				}
			} else {
				if (config->verbose) {
					fprintf(stdout, "OK");
				}
				FD_SET(target->socket_id, &(status->target_socket_receive_set));

				if (target->socket_id >= status->target_socket_receive_max) {
					status->target_socket_receive_max = target->socket_id + 1;
				}
			}
			result = bind(target->socket_id, (struct sockaddr *) &address, sizeof(struct sockaddr));
			if (config->verbose) {
				if (result) {
					fprintf(stdout, " + bind FAIL\n");
				} else {
					fprintf(stdout, "\n");
				}
			}
			break;
		default:
			if (config->verbose) {
				temp = "unknown";
				fprintf(stdout, "Bad type while opening client connection: %s [%s] (%s:%i:%i)\n", target->name, temp, target->address, target->port_receive, target->port_send);
			}
			break;
		}

		target = target->next;
	}

	if (config->verbose) {
		fprintf(stdout, "\n");
	}

	return 0;
}

