#include <stdio.h>
#include <string.h>

#include <libxml/parser.h>

#include "config.h"

int config_load_flightgear(xmlDocPtr document, xmlNodePtr node, struct struct_config *config) {

	xmlChar *buffer;

	if (!config || !document) {
		return -1;
	}

	if (config->flightgear) {
		free(config->flightgear);
	}

	config->flightgear = (struct struct_config_flightgear *) malloc(sizeof(struct struct_config_flightgear));
	if (!config->flightgear) {
		return -2;
	}

	while (node) {
		if (!xmlStrcmp(node->name, (const xmlChar *) "Txt")) {
			buffer = xmlNodeListGetString(document, node->xmlChildrenNode, 1);
			if (buffer) {
				config->flightgear->name = (char *) malloc(strlen((char *) buffer) + 1);
				strcpy(config->flightgear->name, (char *) buffer);
				xmlFree(buffer);
			}
		} else if (!xmlStrcmp(node->name, (const xmlChar *) "Protocol")) {
			buffer = xmlNodeListGetString(document, node->xmlChildrenNode, 1);
			if (buffer) {
				config->flightgear->protocol = (char *) malloc(strlen((char *) buffer) + 1);
				strcpy(config->flightgear->protocol, (char *) buffer);
				xmlFree(buffer);
			}
		} else if (!xmlStrcmp(node->name, (const xmlChar *) "RecvPort")) {
			buffer = xmlNodeListGetString(document, node->xmlChildrenNode, 1);
			if (buffer) {
				config->flightgear->port = atoi((char *) buffer);
				xmlFree(buffer);
			}
		}

		node = node->next;
	}

	return 0;
}

int config_load_target_add(struct struct_config_target *target, struct struct_config *config) {

	struct struct_config_target *target_temp;

	if (!target || !config) {
		return -1;
	}

	if (!config->targets) {
		config->targets = (struct struct_config_target *) malloc(sizeof(struct struct_config_target));
		if (!config->targets) {
			return -2;
		}
		target_temp = config->targets;
	} else {
		target_temp = config->targets;
		while (target_temp) {
			if (!target_temp->next) {
				target_temp->next = (struct struct_config_target *) malloc(sizeof(struct struct_config_target));
				if (!target_temp) {
					return -2;
				}
				target_temp = target_temp->next;
				break;
			}

			target_temp = target_temp->next;;
		}
	}

	target_temp->next = 0;
	target_temp->name = (char *) malloc(strlen(target->name) + 1);
	if (!target_temp->name) {
		return -2;
	}
	strcpy(target_temp->name, target->name);

	target_temp->address = (char *) malloc(strlen(target->address) + 1);
	if (!target_temp->address) {
		return -2;
	}
	strcpy(target_temp->address, target->address);

	target_temp->port_send = target->port_send;
	target_temp->port_receive = target->port_receive;
	target_temp->type = target->type;

	return 0;
}

int config_load_target(xmlDocPtr document, xmlNodePtr node, struct struct_config *config, enum enum_target_type type) {

	struct struct_config_target target;

	xmlChar *buffer;
	int result;

	if (!config || !document) {
		return -1;
	}

	while (node) {
		if (!xmlStrcmp(node->name, (const xmlChar *) "Txt")) {
			buffer = xmlNodeListGetString(document, node->xmlChildrenNode, 1);
			if (buffer) {
				target.name = (char *) malloc(strlen((char *) buffer) + 1);
				if (!target.name) {
					return -2;
				}
				strcpy(target.name, (char *) buffer);
				xmlFree(buffer);
			}
		} else if (!xmlStrcmp(node->name, (const xmlChar *) "IP")) {
			buffer = xmlNodeListGetString(document, node->xmlChildrenNode, 1);
			if (buffer) {
				target.address = (char *) malloc(strlen((char *) buffer) + 1);
				if (!target.address) {
					return -2;
				}
				strcpy(target.address, (char *) buffer);
				xmlFree(buffer);
			}
		} else if (!xmlStrcmp(node->name, (const xmlChar *) "SendPort")) {
			buffer = xmlNodeListGetString(document, node->xmlChildrenNode, 1);
			if (buffer) {
				target.port_send = atoi((char *) buffer);
				xmlFree(buffer);
			}
		} else if (!xmlStrcmp(node->name, (const xmlChar *) "RecvPort")) {
			buffer = xmlNodeListGetString(document, node->xmlChildrenNode, 1);
			if (buffer) {
				target.port_receive = atoi((char *) buffer);
				xmlFree(buffer);
			}
		}

		node = node->next;
	}

	target.type = type;
	result = config_load_target_add(&target, config);
	if (result) {
		return -3;
	}

	return 0;
}

int config_load_targets(xmlDocPtr document, xmlNodePtr node, struct struct_config *config, enum enum_target_type type) {

	xmlChar *buffer;
	int result;

	if (!config || !document) {
		return -1;
	}

	while (node) {
		if (!xmlStrcmp(node->name, (const xmlChar *) "Delay")) {
			buffer = xmlNodeListGetString(document, node->xmlChildrenNode, 1);
			if (buffer) {
				config->period = atoi((char *) buffer);
				xmlFree(buffer);
			}
		} else if (!xmlStrcmp(node->name, (const xmlChar *) "MatchFile")) {
			buffer = xmlNodeListGetString(document, node->xmlChildrenNode, 1);
			if (buffer) {
				config->protocol = (char *) malloc(strlen((char *) buffer) + 1);
				if (!config->protocol) {
					return -2;
				}
				strcpy(config->protocol, (char *) buffer);
				xmlFree(buffer);
			}
		} else if (!xmlStrcmp(node->name, (const xmlChar *) "Item")) {
			result = config_load_target(document, node->xmlChildrenNode, config, type);
			if (result) {
				return -2;
			}
		}

		node = node->next;
	}
	return 0;
}

/**
 * Load configuration
 */
int config_load(char *file_name, struct struct_config *config) {

	xmlDocPtr document;
	xmlNodePtr node;

	if (!config || !file_name) {
		return -1;
	}

	config->flightgear = 0;
	config->targets = 0;
	config->period = 0;
	config->protocol = 0;
	config->verbose = 0;

	document = xmlParseFile(file_name);
	if (!document) {
		return -1;
	}
	
	node = xmlDocGetRootElement(document);
	if (!node) {
		return -2;
	}

	if (xmlStrcmp(node->name, (const xmlChar *) "Connection")) {
		xmlFreeDoc(document);
		return -3;
	}

	node = node->xmlChildrenNode;
	while (node) {
		if (!xmlStrcmp(node->name, (const xmlChar *) "FGC_FG")) {
			config_load_flightgear(document, node->xmlChildrenNode, config);
		} else if (!xmlStrcmp(node->name, (const xmlChar *) "CanAerospace")) {
			config_load_targets(document, node->xmlChildrenNode, config, TARGET_CANAERO);
                } else if (!xmlStrcmp(node->name, (const xmlChar *) "QuestionResponse")) {
                        config_load_targets(document, node->xmlChildrenNode, config, TARGET_QUESTION_RESPONSE);
		} else if (!xmlStrcmp(node->name, (const xmlChar *) "TransferServer")) {
			config_load_targets(document, node->xmlChildrenNode, config, TARGET_BROADCAST_SERVER);
		}

		node = node->next;
	}

	xmlFreeDoc(document);

	return 0;
}

