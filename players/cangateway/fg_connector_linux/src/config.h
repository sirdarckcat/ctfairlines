#ifndef __CONFIG_H__
#define __CONFIG_H__

#include <arpa/inet.h>

enum enum_target_type {
	TARGET_BROADCAST_SERVER,
	TARGET_QUESTION_RESPONSE,
        TARGET_CANAERO
};

struct struct_config_flightgear {
	char *name; /* name of connection */
	char *protocol; /* file defining the flight gear protocol */
	int port; /* receiving port */

	struct struct_config_flightgear *next;
};

struct struct_config_target {
	char *name; /* name of connection */
	char *address; /* address for sending can frames */
	int port_send; /* port for sending can frames */
	int port_receive; /* port for receiving commands - only for q/a communication */

	enum enum_target_type type;

	int socket_id;
	struct sockaddr_in socket_address;

	int socket_receive_id;

	struct struct_config_target *next;
};

struct struct_config {
	struct struct_config_flightgear *flightgear;
	struct struct_config_target *targets;

	int period; /* delay */
	char *protocol; /* match file */

	int verbose;
};

int config_load(char *file_name, struct struct_config *config);

#endif /* __CONFIG_H__ */

