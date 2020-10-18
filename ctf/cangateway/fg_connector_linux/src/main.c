/**
 * Toto je prvni verze, pouze pro interni ucely. Neni odladena a obsahuje
 * pomerne velke mnozstvi zdroju potencialnich problemu. Rozhodne neni
 * doporuceno ji pouzivat nikde jinde, nez pro vlastni ucely ladeni.
 */


#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/time.h>

#include <libxml/parser.h>

#include "config.h"

#include "flightgear.h"
#include "interface_can.h"

#include <ansicreceiver.h>

void * can_recv;

int main(int argc, char *argv[]) {

	struct struct_config config;
	struct struct_flightgear_status flightgear_status;

	/* toto vyhod ven - do can_interface */
	struct struct_config_target *target;

	struct timeval timeout;

	int result;
	int i;

	if (argc < 2) {
		fprintf(stderr, "too few parameters\n");
		fprintf(stderr, "usage fg_receiver [options] <config.xml>\n");
		fprintf(stderr, " --verbose (-v): verbose mode\n");

		return -1;
	}

	/* load config */
	result = config_load(argv[argc - 1], &config);
	if (result) {
		fprintf(stderr, "config file load error\n");
		return -1;
	}

	/* command line arguments */
	for (i=1; i<argc-1; i++) {
		if (!strcmp(argv[i], "--verbose") || !strcmp(argv[i], "-v")) {
			config.verbose = 1;
		}
	}

	/* init flight gear interface */
	result = flightgear_open(&config, &flightgear_status);
	if (result) {
		fprintf(stderr, "flight gear init error\n");
		return -1;
	}

	/* init user application interfaces */
	result = can_open(&config, &flightgear_status);
	if (result) {
		fprintf(stderr, "can init error\n");
		return -1;
	}
	/*	sendto(socket_id, message, total_length, 0, (struct sockaddr *) &address, len); */

        /* declare receiver */
        can_recv = createReceiver(2);

	/* start communication procedure */
	timeout.tv_sec = 0;
	timeout.tv_usec = 0;
	while (1) {
		char buff[2048+1];
		int count = 0;
		int max = 0;
		float data;
		int start;
		int i;
                run(can_recv);
		result = recv(flightgear_status.flightgear_socket_id, buff, 2048, 0);
		if (result < 1) {
			;
		} else {
			buff[result] = '\0';
			result = flightgear_parse(buff, &flightgear_status);
			if (!result) {
				/*for (i=0; i<flightgear_status.values_count; i++) {
					printf(" * %f\n", *((float *) flightgear_status.values[i].value));
				}*/
			}
		}

		/*if (flightgear_status.target_socket_receive_max > flightgear_status.target_socket_max) {
			max = flightgear_status.target_socket_receive_max;
		} else {
			max = flightgear_status.target_socket_max;
		}

		result = select(max, &(flightgear_status.target_socket_set), 0, 0, &timeout);
		if (result < 0) {
		
		} else if (result == 0) {
		
		} else {
			//// vyrid zpravy na QR
		} */

		/* transfer server messages */

		target = config.targets;
		while (target) {
			unsigned char frame[2048];
			unsigned char length;
			size_t offset;

                        run(can_recv);

                        if (target->type == TARGET_CANAERO) {
                          for (i=0; i<flightgear_status.values_count; i++) {
                            int id = atoi(flightgear_status.values[i].canid);
                            run(can_recv);
                            sendDataF(can_recv, id, id>=(2<<11), *((float *) flightgear_status.values[i].value));
                            run(can_recv);
                            printf("Just sent %d\n", id);
                          }
                          target = target->next;
                          continue;
                        }

			if (target->type != TARGET_BROADCAST_SERVER) {
				target = target->next;
				continue;
			}

			offset = 0;
			for (i=0; i<flightgear_status.values_count; i++) {
				can_create(i+1, *((float *) flightgear_status.values[i].value), frame+offset, &length);
				offset += length;
			}

			/*printf("%s (%s)\n", target->name, target->address);
			for (i=0; i<offset; i++) {
				if (!(i%12) && (i != 0)) {
					printf("\n");
				}
				printf(" %2x", frame[i]);
			}
			printf("\n\n");*/

			result = sendto(target->socket_id, frame, offset, 0, (struct sockaddr *) &(target->socket_address), sizeof(struct sockaddr_in));
			//printf("result = %i\n", result);

			target = target->next;
		}

		usleep((config.period - 1) * 1000);
	}

	/* close */

	return 0;
}

