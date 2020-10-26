#ifndef __INTERFACE_CAN_H__
#define __INTERFACE_CAN_H__

int can_open(struct struct_config *config, struct struct_flightgear_status *status);
int can_create(unsigned long int can_id, float value, unsigned char *can_frame, unsigned char *length);
/*void *can_open(void *arg);
void *can_open2(void *arg);*/

#endif /* __INTERFACE_CAN_H__ */

