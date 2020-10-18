#ifndef __FLIGHTGEAR_H__
#define __FLIGHTGEAR_H__

struct struct_flightgear_value {
	char *name;
	char *type;
	char *format;
	char *node;
        char *canid;

	void *value;
        float padding;
};

struct struct_flightgear_protocol {
	struct struct_flightgear_value value;
	struct struct_flightgear_protocol *next;
};

struct struct_flightgear_status {
	struct struct_flightgear_protocol *head;
	struct struct_flightgear_value *values;
	int values_count;

	int flightgear_socket_id;

	fd_set target_socket_set;
	int target_socket_max;

	fd_set target_socket_receive_set;
	int target_socket_receive_max;

	char *separator_value;
	char *separator_line;
};

int flightgear_open(struct struct_config *config, struct struct_flightgear_status *status);
int flightgear_parse(char *line, struct struct_flightgear_status *status);

#endif /* __FLIGHTGEAR_H__ */

