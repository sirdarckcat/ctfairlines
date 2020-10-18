#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>

#include <libxml/parser.h>

#include "config.h"

#include "flightgear.h"

int flightgear_protocol_structure_add(struct struct_flightgear_value *record, struct struct_flightgear_status *status) {
	
	struct struct_flightgear_protocol *value;

	if (!record || !status || !record->canid) {
		return -1;
	}

	value = status->head;
	if (!value) {
		status->head = (struct struct_flightgear_protocol *) malloc(sizeof(struct struct_flightgear_protocol));
		if (!status->head) {
			return -2;
		}
		value = status->head;
	} else {
		while (value) {
			if (!value->next) {
				value->next = (struct struct_flightgear_protocol *) malloc(sizeof(struct struct_flightgear_protocol));
				if (!value->next) {
					return -2;
				}
				value = value->next;
				break;
			}
			value = value->next;
		}
	}

	value->value.name = (char *) malloc(strlen(record->name) + 1);
	if (!value->value.name) {
		return -2;
	}
	strcpy(value->value.name, record->name);

	value->value.type = (char *) malloc(strlen(record->type) + 1);
	if (!value->value.type) {
		return -2;
	}
	strcpy(value->value.type, record->type);

	value->value.format = (char *) malloc(strlen(record->format) + 1);
	if (!value->value.format) {
		return -2;
	}
	strcpy(value->value.format, record->format);

	value->value.node = (char *) malloc(strlen(record->node) + 1);
	if (!value->value.node) {
		return -2;
	}
        strcpy(value->value.node, record->node);

	value->value.canid = (char *) malloc(strlen(record->canid) + 1);
	if (!value->value.canid) {
		return -2;
	}
	strcpy(value->value.canid, record->canid);

	value->value.value = 0;
	value->next = 0;

	return 0;
}

int flightgear_load_protocol_structure(xmlDocPtr document, xmlNodePtr node, struct struct_flightgear_status *status) {

	struct struct_flightgear_value record;

	xmlNodePtr child;
	xmlChar *buffer;

	while (node) {
		if (!xmlStrcmp(node->name, (const xmlChar *) "chunk")) {
			child = node->xmlChildrenNode;
                        record.canid = 0;
			while (child) {
				if (!xmlStrcmp(child->name, (const xmlChar *) "name")) {
					buffer = xmlNodeListGetString(document, child->xmlChildrenNode, 1);
					if (buffer) {
						record.name = (char *) malloc(strlen((const char *) buffer) + 1);
						if (!record.name) {
							return -1;
						}
						strcpy(record.name, (const char *) buffer);
						xmlFree(buffer);
					}
				} else if (!xmlStrcmp(child->name, (const xmlChar *) "type")) {
					buffer = xmlNodeListGetString(document, child->xmlChildrenNode, 1);
					if (buffer) {
						record.type = (char *) malloc(strlen((const char *) buffer) + 1);
						if (!record.type) {
							return -1;
						}
						strcpy(record.type, (const char *) buffer);
						xmlFree(buffer);
					}
				} else if (!xmlStrcmp(child->name, (const xmlChar *) "format")) {
					buffer = xmlNodeListGetString(document, child->xmlChildrenNode, 1);
					if (buffer) {
						record.format = (char *) malloc(strlen((const char *) buffer) + 1);
						if (!record.format) {
							return -1;
						}
						strcpy(record.format, (const char *) buffer);
						xmlFree(buffer);
					}
				} else if (!xmlStrcmp(child->name, (const xmlChar *) "CANaeroID")) {
					buffer = xmlNodeListGetString(document, child->xmlChildrenNode, 1);
					if (buffer) {
						record.canid = (char *) malloc(strlen((const char *) buffer) + 1);
						if (!record.canid) {
							return -1;
						}
						strcpy(record.canid, (const char *) buffer);
						xmlFree(buffer);
					}
				} else if (!xmlStrcmp(child->name, (const xmlChar *) "node")) {
					buffer = xmlNodeListGetString(document, child->xmlChildrenNode, 1);
					if (buffer) {
						record.node = (char *) malloc(strlen((const char *) buffer) + 1);
						if (!record.node) {
							return -1;
						}
						strcpy(record.node, (const char *) buffer);
						xmlFree(buffer);
					}
				}

				child = child->next;
			}

			flightgear_protocol_structure_add(&record, status);
		} else if (!xmlStrcmp(node->name, (const xmlChar *) "var_separator")) {
			buffer = xmlNodeListGetString(document, node->xmlChildrenNode, 1);
			if (buffer) {
				status->separator_value = (char *) malloc(strlen((char *) buffer) + 1);
				if (!status->separator_value) {
					return -1;
				}
				strcpy(status->separator_value, (const char *) buffer);
				xmlFree(buffer);
			}
		} else if (!xmlStrcmp(node->name, (const xmlChar *) "line_separator")) {
			buffer = xmlNodeListGetString(document, node->xmlChildrenNode, 1);
			if (buffer) {
				status->separator_line = (char *) malloc(strlen((char *) buffer) + 1);
				if (!status->separator_line) {
					return -1;
				}
				strcpy(status->separator_line, (const char *) buffer);
				xmlFree(buffer);
			}
		}

		node = node->next;
	}

	return 0;
}

int flightgear_load_protocol(char *file_name, struct struct_flightgear_status *status) {

	xmlDocPtr document;
	xmlNodePtr node;
	xmlNodePtr child;

	int result;

	document = xmlParseFile(file_name);
	if (!document) {
		return -1;
	}
	
	node = xmlDocGetRootElement(document);
	if (!node) {
		return -2;
	}

	if (xmlStrcmp(node->name, (const xmlChar *) "PropertyList")) {
		xmlFreeDoc(document);
		return -3;
	}

	node = node->xmlChildrenNode;
	while (node) {
		if (!xmlStrcmp(node->name, (const xmlChar *) "generic")) {
			child = node->xmlChildrenNode;
			while (child) {
				if (!xmlStrcmp(child->name, (const xmlChar *) "output")) {
					result = flightgear_load_protocol_structure(document, child->xmlChildrenNode, status);
					if (result) {
						return -4;
					}
				}

				child = child->next;
			}
		}

		node = node->next;
	}

	xmlFreeDoc(document);

	return 0;
}

int flightgear_status_init(struct struct_flightgear_status *status) {

	status->head = 0;
	status->values = 0;
	status->flightgear_socket_id = 0;

	status->separator_value = 0;
	status->separator_line = 0;

	return 0;
}

int flightgear_protocol_init(struct struct_flightgear_status *status) {

	struct struct_flightgear_protocol *protocol;
	struct struct_flightgear_value *record;
	int values_number;
	int i;

	if (!status) {
		return -1;
	}

	values_number = 0;
	protocol = status->head;
	while (protocol) {
		values_number++;
		protocol = protocol->next;
	}

	if (!status->values) {
		free(status->values);
	}
	status->values = (struct struct_flightgear_value *) malloc(sizeof(struct struct_flightgear_value) * values_number);
	if (!status->values) {
		return -2;
	}

	i = 0;
	protocol = status->head;
	while (protocol) {
		record = &(status->values[i++]);
		record->name = protocol->value.name;
		record->type = protocol->value.type;
		record->format = protocol->value.format;
		record->node = protocol->value.node;
                record->canid = protocol->value.canid;
		if (!strcmp(record->type, "float")) {
			record->value = malloc(sizeof(float));
			*((float *) record->value) = 0.0f;
		} else {
			record->value = 0;
		}

		protocol = protocol->next;
	}

	status->values_count = values_number;

	return 0;
}

int flightgear_open(struct struct_config *config, struct struct_flightgear_status *status) {

	struct sockaddr_in flightgear_socket_address;

	int result;
	int i;

	if (!config || !config->flightgear || !status) {
		return -1;
	}

#ifdef __ON_LINUX__
	for (i=0; i<strlen(config->flightgear->protocol); i++) {
		if (config->flightgear->protocol[i] == '\\') {
			config->flightgear->protocol[i] = '/';
		}
	}
#endif /* __ON_LINUX__ */

	result = flightgear_status_init(status);
	if (result) {
		return -2;
	}

	result = flightgear_load_protocol(config->flightgear->protocol, status);
	if (result) {
		return -3;
	}

	result = flightgear_protocol_init(status);
	if (result) {
		return -3;
	}

	if (config->verbose) {
		for (i=0; i<status->values_count; i++) {
			fprintf(stdout, "Loaded %s (%s): %s\n", status->values[i].name, status->values[i].type, status->values[i].node);
		}
		fprintf(stdout, "\n");
	}

	if (config->verbose) {
		fprintf(stdout, "Opening flight gear connection\n");
		fprintf(stdout, " - name: %s\n", config->flightgear->name);
		fprintf(stdout, " - protocol file: %s\n", config->flightgear->protocol);
		fprintf(stdout, " - port: %i\n", config->flightgear->port);
		fprintf(stdout, "\n");
	}

	memset(&flightgear_socket_address, 0, sizeof(struct sockaddr_in));
	flightgear_socket_address.sin_family = AF_INET;
	flightgear_socket_address.sin_addr.s_addr = htonl(INADDR_ANY);
	flightgear_socket_address.sin_port = htons(config->flightgear->port);

	status->flightgear_socket_id = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
	if (!status->flightgear_socket_id) {
		return -4;
	}
	result = bind(status->flightgear_socket_id, (struct sockaddr *) &flightgear_socket_address, sizeof(struct sockaddr));
	if (result) {
		return -5;
	}

	if (config->verbose) {
		fprintf(stdout, "Flight gear connection opened\n");
		fprintf(stdout, "\n");
	}

	/*while (1) {
		int count = 0;
		result = recv(sid, buff, BUFF_LEN, MSG_DONTWAIT);
		if (result < 1) {
			;
		} else {
			int start = 0;
			*(buff+result) = '\0';
			prop = fg_properties;
			while (prop) {

				if (prop->index == count + 1) {
					if (!strcmp("float",prop->type)) {
						result = sscanf(buff+start,"%f",&(prop->value));
						for (i = start; i < strlen(buff); i++) {
							if (*(buff+i) == separator) {
								start = i+1;
								count++;
								break;
							}
						}
					} else {
						prop->value = 0;
					}
				} else {
					break;
				}

				prop = prop->next;
			}
		}

		usleep(10000);
	}*/

	return 0;
}

/* it works just for float format */
int flightgear_parse(char *line, struct struct_flightgear_status *status) {

	int index;
	int start;
	float data;
	int i;

	start = 0;
	for (index=0; index<status->values_count; index++) {
		sscanf(line+start, "%f", &data);
		for (i = start; i < strlen(line); i++) {
			if (!strncmp(line+i, status->separator_value, strlen(status->separator_value))) {
				start = i+1;
				break;
			}
		}
		*((float *) status->values[index].value) = data;
	}

	return 0;
}

