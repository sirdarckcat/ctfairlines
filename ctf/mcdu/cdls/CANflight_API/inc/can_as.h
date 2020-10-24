/*******************************************************************************
* CANaerospace interface definitions                                           *
*                                                                              *
* (C) 1998 - 2006 Stock Flight Systems. All rights reserved.                   *
*                                                                              *
* Filename: can_as.h                                                           *
*                                                                              *
* This file contains definitions and the structures used for the CANaerospace  *
* interface definition.                                                        *
*                                                                              *
* MODIFICATIONS:                                                               *
*                                                                              *
* When          Version      What                                  Who         *
* ____________________________________________________________________________ *
*                                                                              *
* 24.02.1998    1.00         Initial Version                       M. Stock    *
* 26.06.1998    1.05         CAN_AS_OBJ definition changed         M. Stock    *
* 15.07.1998    1.10         AS_BSHORT_2 definition added          M. Stock    *
* 21.01.1999    1.20         Identifier ranges changed             M. Stock    *
* 13.04.1999    1.30         Identifier definitions modified       M. Stock    *
* 10.05.1999    1.31         Some identifiers added                M. Stock    *
* 10.05.1999    1.32         Nav sensor definitions changed     K. Heidenreich *
* 14.05.1999    1.33         Some identifiers rearranged           M. Stock    *
* 19.05.1999    1.34         DME frequencies added              K. Heidenreich *
* 12.07.1999    1.40         Command definitions added             M. Stock    *
* 30.10.1999    1.41         CAN_AS_OBJ expanded                   M. Stock    *
* 23.10.2000    1.42         Node service error return codes added M. Stock    *
* 29.12.2000    1.43         Some service code definitions added   M. Stock    *
* 19.06.2001    1.44         29-bit ID support for CAN_AS_OBJ      M. Stock    *
* 17.09.2001    1.45         State transmission service code added M. Stock    *
* 14.02.2002    1.46         Some more GPS/flightstate identifiers M. Stock    *
* 05.06.2002    1.47         Density alitude identifier added      M. Stock    *
* 18.07.2002    1.48         Wind speed/direction dentifiers added M. Stock    *
* 31.03.2003    1.49         3-byte data types added               M. Stock    *
* 29.06.2004    1.50         CIS/BSS node services added           M. Stock    *
* 04.07.2005    1.51         NIS node service added                M. Stock    *
* 16.07.2005    1.52         MIS/MCS/CSS/DSS node services added   M. Stock    *
* 10.02.2006    1.53         RCS node service added                M. Stock    *
*                                                                              *
*******************************************************************************/

/*
 * Various definitions.
 */

#define		DATA		0

/*
 * The CANaerospace standard message structure (20 bytes).
 */

typedef struct
  {
  unsigned char		node_id;		/* node-ID */
  unsigned char		data_type;		/* data type identifier */
  unsigned char		service_code;		/* service code */
  unsigned char		msg_code;		/* message code */
  unsigned char		data[4];		/* message data */
  char			byte_count;		/* in the range of 0..8 */
  char			frame_type;		/* remote or data frame */
  short			status;			/* presently unused */
  unsigned int		identifier;		/* CAN-ID of this object */
  unsigned int		time_stamp;		/* 1ms units */
  }			CAN_AS_OBJ;

/*
 * The CANaerospace emergency message structure.
 */

typedef struct
  {
  unsigned char		node_id;		/* node-ID */
  unsigned char		data_type;		/* data type identifier */
  unsigned char		service_code;		/* service code */
  unsigned char		msg_code;		/* message code */
  unsigned char		location;		/* location identifier */
  unsigned char		operation;		/* operation identifier */
  unsigned short	error_code;		/* error code */
  char			byte_count;		/* in the range of 0..8 */
  char			frame_type;		/* remote or data frame */
  short			status;			/* presently unused */
  unsigned int		identifier;		/* CAN-ID of this object */
  unsigned int		time_stamp;		/* 1ms units */
  }			CAN_EMERG_OBJ;

/*
 * Data type definitions.
 */

#define		AS_NODATA		0
#define 	AS_ERROR		1
#define 	AS_FLOAT		2
#define 	AS_LONG			3
#define 	AS_ULONG		4
#define 	AS_BLONG		5
#define 	AS_SHORT		6
#define 	AS_USHORT		7
#define 	AS_BSHORT		8
#define 	AS_CHAR			9
#define 	AS_UCHAR		10
#define 	AS_BCHAR		11
#define 	AS_SHORT_2		12
#define 	AS_USHORT_2		13
#define 	AS_BSHORT_2		14
#define 	AS_CHAR_4		15
#define 	AS_UCHAR_4		16
#define 	AS_BCHAR_4		17
#define 	AS_CHAR_2		18
#define 	AS_UCHAR_2		19
#define 	AS_BCHAR_2		20
#define 	AS_MEMID		21
#define 	AS_CHKSUM		22
#define 	AS_ACHAR		23
#define 	AS_ACHAR_2		24
#define 	AS_ACHAR_4		25
#define 	AS_CHAR_3		26
#define 	AS_UCHAR_3		27
#define 	AS_BCHAR_3		28
#define 	AS_ACHAR_3		29

/*
 * Node-ID definitions.
 */

#define 	ALL_NODES	0

/*
 * Service code definitions.
 */

#define		IDS		0	/* identification service */
#define		NSS		1	/* node synchronisation service */
#define		DDS		2	/* data download service */
#define		DUS		3	/* data upload service */
#define		SCS		4	/* simulation control service */
#define		TIS		5	/* transmission interval service */
#define		FPS		6	/* FLASH programming service */
#define		STS		7	/* state transmission service */
#define		FSS		8	/* filter setting service */
#define		CIS		9	/* CAN identifier setting service */
#define		BSS		10	/* CAN baudrate setting service */
#define		NIS		11	/* node-ID setting service */
#define		MIS		12	/* module information service */
#define		MCS		13	/* module configuration service */
#define		CSS		14	/* CAN identifier setting service */
#define		DSS		15	/* ID distribution setting service */
#define		RCS		16	/* Data recording control service */

/*
 * Command definitions for identification service (IDS).
 */

#define		NS_STD_INFO_REQ	0x00	/* get standard revision information */
#define 	NS_UNKNOWN_CODE 0xff

/*
 * Command definitions for data upload/download service (UDS/DDS).
 */

#define		NS_XOFF		0	/* halt transmission */
#define		NS_XON		1	/* resume transmission */
#define		NS_ABORT	-1	/* abort upload/download */
#define		NS_INVALID	-2	/* invalid operation or memory ID */

/*
 * Node service error return codes. User-defined codes start from -40.
 */

#define		NS_OK		0
#define		NS_UNKNOWN_SVC	-1	/* 0xff */
#define		NS_UNKNOWN_MSG	-2	/* 0xfe */
#define		NS_INVALID_MODE	-3	/* 0xfd */
#define		NS_INVALID_CHAN	-4	/* 0xfc */
#define		NS_INVALID_ADDR	-5	/* 0xfb */
#define		NS_OUT_OF_RANGE	-6	/* 0xfa */
#define		NS_OUT_OF_BUFS	-7	/* 0xf9 */
#define		NS_BUF_FULL	-8	/* 0xf8 */
#define		NS_SVC_FAILED	-9	/* 0xf7 */
#define		NS_DISABLED	-10	/* 0xf6 */
#define		NS_OVERLAPPING	-11	/* 0xf5 */
#define		NS_BUSY		-12	/* 0xf4 */
#define		NS_NOEXIST	-13	/* 0xf3 */
#define		NS_INVALID_CMD	-14	/* 0xf2 */

/*
 * Definitions for frequently used conversions.
 */

#define		M_2_FT		3.28213		/* meter to feet */
#define		FT_2_M		0.30468		/* feet to meter */
#define		MPS_2_FPM	196.9279	/* m/s to feet/min. */
#define		MPS_2_KTS	1.9438		/* m/s to kts */
#define		KTS_2_MPS	0.51450		/* kts to m/s */
#define		FPM_2_MPS	0.00508		/* feet/min. to m/s */
#define		KMH_2_KTS	0.53996		/* km/h to kts */
#define		KTS_2_KMH	1.852		/* kts to km/h */
#define		MPS_2_KMH	3.6		/* m/s to km/h */
#define		NM_2_KM		1.852		/* nautical miles to km */
#define		HG_2_HPA	33.8759		/* inch Hg to hPa */
#define		HPA_2_HG	0.02952		/* hPa to inch Hg */
#define		KG_2_LBS	2.205		/* kg to lbs */
#define		LBS_2_KG	0.45351		/* kg to lbs */
#define		LBSSQFT_2_KGM2	4.8854		/* lbs/sqft to kg/m^2 */
#define		KGM2_2_LBSSQFT	0.20469		/* lbs/sqft to kg/m^2 */
#define		GALS_2_LTR	3.7853		/* US gallons to liters */
#define		LTR_2_GALS	0.2642		/* liters to US gallons */
#define		LTR_2_QUARTS	1.0567		/* liters to US liquid quarts */
#define		QUARTS_2_LTR	0.9463		/* US liquid quarts to liters */

/*
 * Node service identifier definitions.
 */

#define	NS_REQ_0_ID		128	/* high priority node service request */
#define	NS_RSP_0_ID		129	/* high priority node service response*/
#define	NS_REQ_1_ID		NS_REQ_0_ID+2
#define	NS_RSP_1_ID		NS_RSP_0_ID+2
#define	NS_REQ_2_ID		NS_REQ_0_ID+4
#define	NS_RSP_2_ID		NS_RSP_0_ID+4
#define	NS_REQ_3_ID		NS_REQ_0_ID+6
#define	NS_RSP_3_ID		NS_RSP_0_ID+6
#define	NS_REQ_4_ID		NS_REQ_0_ID+8
#define	NS_RSP_4_ID		NS_RSP_0_ID+8
#define	NS_REQ_5_ID		NS_REQ_0_ID+10
#define	NS_RSP_5_ID		NS_RSP_0_ID+10
#define	NS_REQ_6_ID		NS_REQ_0_ID+12
#define	NS_RSP_6_ID		NS_RSP_0_ID+12
#define	NS_REQ_7_ID		NS_REQ_0_ID+14
#define	NS_RSP_7_ID		NS_RSP_0_ID+14
#define	NS_REQ_8_ID		NS_REQ_0_ID+16
#define	NS_RSP_8_ID		NS_RSP_0_ID+16
#define	NS_REQ_9_ID		NS_REQ_0_ID+18
#define	NS_RSP_9_ID		NS_RSP_0_ID+18
#define	NS_REQ_10_ID		NS_REQ_0_ID+20
#define	NS_RSP_10_ID		NS_RSP_0_ID+20
#define	NS_REQ_11_ID		NS_REQ_0_ID+22
#define	NS_RSP_11_ID		NS_RSP_0_ID+22
#define	NS_REQ_12_ID		NS_REQ_0_ID+24
#define	NS_RSP_12_ID		NS_RSP_0_ID+24
#define	NS_REQ_13_ID		NS_REQ_0_ID+26
#define	NS_RSP_13_ID		NS_RSP_0_ID+26
#define	NS_REQ_14_ID		NS_REQ_0_ID+28
#define	NS_RSP_14_ID		NS_RSP_0_ID+28
#define	NS_REQ_15_ID		NS_REQ_0_ID+30
#define	NS_RSP_15_ID		NS_RSP_0_ID+30
#define	NS_REQ_16_ID		NS_REQ_0_ID+32
#define	NS_RSP_16_ID		NS_RSP_0_ID+32
#define	NS_REQ_17_ID		NS_REQ_0_ID+34
#define	NS_RSP_17_ID		NS_RSP_0_ID+34
#define	NS_REQ_18_ID		NS_REQ_0_ID+36
#define	NS_RSP_18_ID		NS_RSP_0_ID+36
#define	NS_REQ_19_ID		NS_REQ_0_ID+38
#define	NS_RSP_19_ID		NS_RSP_0_ID+38
#define	NS_REQ_20_ID		NS_REQ_0_ID+40
#define	NS_RSP_20_ID		NS_RSP_0_ID+40
#define	NS_REQ_21_ID		NS_REQ_0_ID+42
#define	NS_RSP_21_ID		NS_RSP_0_ID+42
#define	NS_REQ_22_ID		NS_REQ_0_ID+44
#define	NS_RSP_22_ID		NS_RSP_0_ID+44
#define	NS_REQ_23_ID		NS_REQ_0_ID+46
#define	NS_RSP_23_ID		NS_RSP_0_ID+46
#define	NS_REQ_24_ID		NS_REQ_0_ID+48
#define	NS_RSP_24_ID		NS_RSP_0_ID+48
#define	NS_REQ_25_ID		NS_REQ_0_ID+50
#define	NS_RSP_25_ID		NS_RSP_0_ID+50
#define	NS_REQ_26_ID		NS_REQ_0_ID+52
#define	NS_RSP_26_ID		NS_RSP_0_ID+52
#define	NS_REQ_27_ID		NS_REQ_0_ID+54
#define	NS_RSP_27_ID		NS_RSP_0_ID+54
#define	NS_REQ_28_ID		NS_REQ_0_ID+56
#define	NS_RSP_28_ID		NS_RSP_0_ID+56
#define	NS_REQ_29_ID		NS_REQ_0_ID+58
#define	NS_RSP_29_ID		NS_RSP_0_ID+58
#define	NS_REQ_30_ID		NS_REQ_0_ID+60
#define	NS_RSP_30_ID		NS_RSP_0_ID+60
#define	NS_REQ_31_ID		NS_REQ_0_ID+62
#define	NS_RSP_31_ID		NS_RSP_0_ID+62
#define	NS_REQ_32_ID		NS_REQ_0_ID+64
#define	NS_RSP_32_ID		NS_RSP_0_ID+64
#define	NS_REQ_33_ID		NS_REQ_0_ID+66
#define	NS_RSP_33_ID		NS_RSP_0_ID+66
#define	NS_REQ_34_ID		NS_REQ_0_ID+68
#define	NS_RSP_34_ID		NS_RSP_0_ID+68
#define	NS_REQ_35_ID		NS_REQ_0_ID+70
#define	NS_RSP_35_ID		NS_RSP_0_ID+70

#define	NS_REQ_100_ID		2000	/* low priority node service request */
#define	NS_RSP_100_ID		2001	/* low priority node service response */
#define	NS_REQ_101_ID		NS_REQ_100_ID+2
#define	NS_RSP_101_ID		NS_RSP_100_ID+2
#define	NS_REQ_102_ID		NS_REQ_100_ID+4
#define	NS_RSP_102_ID		NS_RSP_100_ID+4
#define	NS_REQ_103_ID		NS_REQ_100_ID+6
#define	NS_RSP_103_ID		NS_RSP_100_ID+6
#define	NS_REQ_104_ID		NS_REQ_100_ID+8
#define	NS_RSP_104_ID		NS_RSP_100_ID+8
#define	NS_REQ_105_ID		NS_REQ_100_ID+10
#define	NS_RSP_105_ID		NS_RSP_100_ID+10
#define	NS_REQ_106_ID		NS_REQ_100_ID+12
#define	NS_RSP_106_ID		NS_RSP_100_ID+12
#define	NS_REQ_107_ID		NS_REQ_100_ID+14
#define	NS_RSP_107_ID		NS_RSP_100_ID+14
#define	NS_REQ_108_ID		NS_REQ_100_ID+16
#define	NS_RSP_108_ID		NS_RSP_100_ID+16
#define	NS_REQ_109_ID		NS_REQ_100_ID+18
#define	NS_RSP_109_ID		NS_RSP_100_ID+18
#define	NS_REQ_110_ID		NS_REQ_100_ID+20
#define	NS_RSP_110_ID		NS_RSP_100_ID+20
#define	NS_REQ_111_ID		NS_REQ_100_ID+22
#define	NS_RSP_111_ID		NS_RSP_100_ID+22
#define	NS_REQ_112_ID		NS_REQ_100_ID+24
#define	NS_RSP_112_ID		NS_RSP_100_ID+24
#define	NS_REQ_113_ID		NS_REQ_100_ID+26
#define	NS_RSP_113_ID		NS_RSP_100_ID+26
#define	NS_REQ_114_ID		NS_REQ_100_ID+28
#define	NS_RSP_114_ID		NS_RSP_100_ID+28
#define	NS_REQ_115_ID		NS_REQ_100_ID+30
#define	NS_RSP_115_ID		NS_RSP_100_ID+30

/*
 * Flight state identifier definitions.
 */

#define	BODY_LONG_ACC_ID	300	/* body longitudinal acceleration */
#define	BODY_LAT_ACC_ID		301	/* body lateral acceleration */
#define	BODY_NORM_ACC_ID	302	/* body normal acceleration */
#define	BODY_PITCH_RATE_ID	303	/* a/c pitch rate */
#define	BODY_ROLL_RATE_ID	304	/* a/c roll rate */
#define	BODY_YAW_RATE_ID	305	/* a/c yaw rate */
#define	RUDDER_POS_ID		306	/* rudder position */
#define	STABILIZER_POS_ID	307	/* horizontal stabilizer position */
#define	ELEVATOR_POS_ID		308	/* elevator position */
#define	LEFT_AILERON_POS_ID	309	/* left aileron position */
#define	RIGHT_AILERON_POS_ID	310	/* right aileron position */
#define	BODY_PITCH_ANGLE_ID	311	/* a/c pitch angle */
#define	BODY_ROLL_ANGLE_ID	312	/* a/c roll angle */
#define	BODY_SIDESLIP_ID	313	/* a/c sideslip */
#define	ALTITUDE_RATE_ID	314	/* vertical speed */
#define	IND_AIRSPEED_ID		315	/* indicated airspeed */
#define	TRUE_AIRSPEED_ID	316	/* true airspeed */
#define	CAL_AIRSPEED_ID		317	/* calibrated airspeed */
#define	MACH_NUMBER_ID		318	/* mach number */
#define	BARO_CORRECTION_ID	319	/* barometric correction (QNH) */
#define	BARO_ALTITUDE_ID	320	/* barometric altitude */
#define	HEADING_ANGLE_ID	321	/* heading angle */
#define	STANDARD_ALTITUDE_ID	322	/* standard altitude */
#define	TOTAL_AIR_TEMP_ID	323	/* total air temperature */
#define	STATIC_AIR_TEMP_ID	324	/* static air temperature */
#define	DIFFERENTIAL_PRESS_ID	325	/* differential pressure */
#define	STATIC_PRESS_ID		326	/* static pressure */
#define	HEADING_RATE_ID		327	/* magnetic heading rate */
#define	PORT_AOA_ID		328	/* port side angle-of-attack */
#define	STARBORD_AOA_ID		329	/* starbord side angle-of-attack */
#define	DENSITY_ALT_ID		330	/* density altitude */
#define	TURN_COORD_RATE_ID	331	/* turn coordination rate */
#define	TRUE_ALTITUDE_ID	332	/* temperature corrected altitude */
#define	WIND_SPEED_ID		333	/* wind speed */
#define	WIND_DIRECTION_ID	334	/* wind direction in degrees */
#define	OUTSIDE_AIR_TEMP_ID	335	/* outside air temperature */
#define	BODY_NORM_VEL_ID	336	/* body normal velocity */
#define	BODY_LONG_VEL_ID	337	/* body longitudinal velocity */
#define	BODY_LAT_VEL_ID		338	/* body latral velocity */
#define	TOTAL_PRESS_ID		339	/* total pressure */

/*
 * Flight controls identifier definitions.
 */

#define	PITCH_CTRL_POS_ID	400	/* pitch control position */
#define	ROLL_CTRL_POS_ID	401	/* roll control position */
#define	LAT_TRIM_POS_ID		402	/* lateral stick trim position */
#define	YAW_CTRL_POS_ID		403	/* yaw control position */
#define	COLLECTIVE_CTRL_POS_ID	404	/* collective control position */
#define	LONG_TRIM_POS_ID	405	/* longitudinal stick trim position */
#define	PEDAL_TRIM_POS_ID	406	/* directional pedals trim position */
#define	COLLECTIVE_TRIM_POS_ID	407	/* collective stick trim position */
#define	CONTROL_SWITCH_ID	408	/* control stick switches */
#define	LAT_TRIM_SPEED_ID	409	/* lateral trim speed */
#define	LONG_TRIM_SPEED_ID	410	/* longitudinal trim speed */
#define	PEDAL_TRIM_SPEED_ID	411	/* pedal trim speed */
#define	COLLECTIVE_TRIM_SPEED_ID 412	/* collective trim speed */
#define	NOSE_WHEEL_STEER_POS_ID	413	/* nose wheel steering position */
#define	THROTTLE_1_POS_A_ID	414	/* power lever position (engine #1) */
#define	THROTTLE_2_POS_A_ID	415	/* power lever position (engine #2) */
#define	THROTTLE_3_POS_A_ID	416	/* power lever position (engine #3) */
#define	THROTTLE_4_POS_A_ID	417	/* power lever position (engine #4) */
#define	CONDITION_1_POS_A_ID	418	/* condition lever pos. (engine #1) */
#define	CONDITION_2_POS_A_ID	419	/* condition lever pos. (engine #2) */
#define	CONDITION_3_POS_A_ID	420	/* condition lever pos. (engine #3) */
#define	CONDITION_4_POS_A_ID	421	/* condition lever pos. (engine #4) */
#define	THROTTLE_1_POS_B_ID	422	/* power lever position (engine #1) */
#define	THROTTLE_2_POS_B_ID	423	/* power lever position (engine #2) */
#define	THROTTLE_3_POS_B_ID	424	/* power lever position (engine #3) */
#define	THROTTLE_4_POS_B_ID	425	/* power lever position (engine #4) */
#define	CONDITION_1_POS_B_ID	426	/* condition lever pos. (engine #1) */
#define	CONDITION_2_POS_B_ID	427	/* condition lever pos. (engine #2) */
#define	CONDITION_3_POS_B_ID	428	/* condition lever pos. (engine #3) */
#define	CONDITION_4_POS_B_ID	429	/* condition lever pos. (engine #4) */
#define	FLAPS_LEVER_POS_ID	430	/* flaps lever position */
#define	SLATS_LEVER_POS_ID	431	/* slats lever position */
#define	PARK_BRAKE_LEVER_POS_ID	432	/* park brake lever position */
#define	SPEED_BRAKE_LVR_POS_ID	433	/* speed brake lever position */
#define	THROTTLE_MAX_POS_ID	434	/* maximum power lever position */
#define	PLT_LEFT_BRAKE_POS_ID	435	/* pilot's left foot brake position */
#define	PLT_RIGHT_BRAKE_POS_ID	436	/* pilot's right foot brake position */
#define	CPLT_LEFT_BRAKE_POS_ID	437	/* copilot's left foot brake position */
#define	CPLT_RIGHT_BRAKE_POS_ID 438	/* copilot's right foot brake pos. */
#define	TRIM_SWITCH_ID		439	/* trim system switches */
#define	TRIM_LIGHTS_ID		440	/* trim system indicator lights */
#define	COLLECTIVE_SWITCH_ID	441	/* collective control stick switches */
#define	STICK_SHAKER_ID		442	/* stick shaker stall warning device */

/*
 * Engine/fuel system data identifier definitions.
 */

#define	ENGINE_1_N1_A_ID	500	/* engine #1 N1/rpm */
#define	ENGINE_2_N1_A_ID	501	/* engine #2 N1/rpm */
#define	ENGINE_3_N1_A_ID	502	/* engine #3 N1/rpm */
#define	ENGINE_4_N1_A_ID	503	/* engine #4 N1/rpm */
#define	ENGINE_1_N2_A_ID	504	/* engine #1 N2/prop rpm */
#define	ENGINE_2_N2_A_ID	505	/* engine #2 N2/prop rpm */
#define	ENGINE_3_N2_A_ID	506	/* engine #3 N2/prop rpm */
#define	ENGINE_4_N2_A_ID	507	/* engine #4 N2/prop rpm */
#define	ENGINE_1_TORQUE_A_ID	508	/* engine #1 torque */
#define	ENGINE_2_TORQUE_A_ID	509	/* engine #2 torque */
#define	ENGINE_3_TORQUE_A_ID	510	/* engine #3 torque */
#define	ENGINE_4_TORQUE_A_ID	511	/* engine #4 torque */
#define	ENGINE_1_TIT_A_ID	512	/* engine #1 turbine inlet temp */
#define	ENGINE_2_TIT_A_ID	513	/* engine #2 turbine inlet temp */
#define	ENGINE_3_TIT_A_ID	514	/* engine #3 turbine inlet temp */
#define	ENGINE_4_TIT_A_ID	515	/* engine #4 turbine inlet temp */
#define	ENGINE_1_ITT_A_ID	516	/* engine #1 interturbine temp */
#define	ENGINE_2_ITT_A_ID	517	/* engine #2 interturbine temp */
#define	ENGINE_3_ITT_A_ID	518	/* engine #3 interturbine temp */
#define	ENGINE_4_ITT_A_ID	519	/* engine #4 interturbine temp */
#define	ENGINE_1_TOT_A_ID	520	/* engine #1 turbine outlet temp */
#define	ENGINE_2_TOT_A_ID	521	/* engine #2 turbine outlet temp */
#define	ENGINE_3_TOT_A_ID	522	/* engine #3 turbine outlet temp */
#define	ENGINE_4_TOT_A_ID	523	/* engine #4 turbine outlet temp */
#define	ENGINE_1_FUEL_FLOW_A_ID	524	/* engine #1 fuel flow rate */
#define	ENGINE_2_FUEL_FLOW_A_ID	525	/* engine #2 fuel flow rate */
#define	ENGINE_3_FUEL_FLOW_A_ID	526	/* engine #3 fuel flow rate */
#define	ENGINE_4_FUEL_FLOW_A_ID	527	/* engine #4 fuel flow rate */
#define	ENGINE_1_MAN_PRESS_A_ID	528	/* engine #1 manifold pressure */
#define	ENGINE_2_MAN_PRESS_A_ID	529	/* engine #2 manifold pressure */
#define	ENGINE_3_MAN_PRESS_A_ID	530	/* engine #3 manifold pressure */
#define	ENGINE_4_MAN_PRESS_A_ID	531	/* engine #4 manifold pressure */
#define	ENGINE_1_OIL_PRESS_A_ID	532	/* engine #1 oil pressure */
#define	ENGINE_2_OIL_PRESS_A_ID	533	/* engine #2 oil pressure */
#define	ENGINE_3_OIL_PRESS_A_ID	534	/* engine #3 oil pressure */
#define	ENGINE_4_OIL_PRESS_A_ID	535	/* engine #4 oil pressure */
#define	ENGINE_1_OIL_TEMP_A_ID	536	/* engine #1 oil temp */
#define	ENGINE_2_OIL_TEMP_A_ID	537	/* engine #2 oil temp */
#define	ENGINE_3_OIL_TEMP_A_ID	538	/* engine #3 oil temp */
#define	ENGINE_4_OIL_TEMP_A_ID	539	/* engine #4 oil temp */
#define	ENGINE_1_CHT_A_ID	540	/* engine #1 cylinder head temp */
#define	ENGINE_2_CHT_A_ID	541	/* engine #2 cylinder head temp */
#define	ENGINE_3_CHT_A_ID	542	/* engine #3 cylinder head temp */
#define	ENGINE_4_CHT_A_ID	543	/* engine #4 cylinder head temp */
#define	ENGINE_1_OIL_QUANT_A_ID	544	/* engine #1 oil quantity */
#define	ENGINE_2_OIL_QUANT_A_ID	545	/* engine #2 oil quantity */
#define	ENGINE_3_OIL_QUANT_A_ID	546	/* engine #3 oil quantity */
#define	ENGINE_4_OIL_QUANT_A_ID	547	/* engine #4 oil quantity */
#define	ENGINE_1_COOL_TEMP_A_ID	548	/* engine #1 cooland temp */
#define	ENGINE_2_COOL_TEMP_A_ID	549	/* engine #2 cooland temp */
#define	ENGINE_3_COOL_TEMP_A_ID	550	/* engine #3 cooland temp */
#define	ENGINE_4_COOL_TEMP_A_ID	551	/* engine #4 cooland temp */
#define	ENGINE_1_POW_RATIO_A_ID	552	/* engine #1 power ratio */
#define	ENGINE_2_POW_RATIO_A_ID	553	/* engine #1 power ratio */
#define	ENGINE_3_POW_RATIO_A_ID	554	/* engine #1 power ratio */
#define	ENGINE_4_POW_RATIO_A_ID	555	/* engine #1 power ratio */
#define	ENGINE_1_STATUS_1_A_ID	556	/* engine #1 status word 1 */
#define	ENGINE_2_STATUS_1_A_ID	557	/* engine #2 status word 1 */
#define	ENGINE_3_STATUS_1_A_ID	558	/* engine #3 status word 1 */
#define	ENGINE_4_STATUS_1_A_ID	559	/* engine #4 status word 1 */
#define	ENGINE_1_STATUS_2_A_ID	560	/* engine #1 status word 2 */
#define	ENGINE_2_STATUS_2_A_ID	561	/* engine #2 status word 2 */
#define	ENGINE_3_STATUS_2_A_ID	562	/* engine #3 status word 2 */
#define	ENGINE_4_STATUS_2_A_ID	563	/* engine #4 status word 2 */

#define	ENGINE_1_N1_B_ID	564	/* engine #1 N1/rpm */
#define	ENGINE_2_N1_B_ID	565	/* engine #2 N1/rpm */
#define	ENGINE_3_N1_B_ID	566	/* engine #3 N1/rpm */
#define	ENGINE_4_N1_B_ID	567	/* engine #4 N1/rpm */
#define	ENGINE_1_N2_B_ID	568	/* engine #1 N2/prop rpm */
#define	ENGINE_2_N2_B_ID	569	/* engine #2 N2/prop rpm */
#define	ENGINE_3_N2_B_ID	570	/* engine #3 N2/prop rpm */
#define	ENGINE_4_N2_B_ID	571	/* engine #4 N2/prop rpm */
#define	ENGINE_1_TORQUE_B_ID	572	/* engine #1 torque */
#define	ENGINE_2_TORQUE_B_ID	573	/* engine #2 torque */
#define	ENGINE_3_TORQUE_B_ID	574	/* engine #3 torque */
#define	ENGINE_4_TORQUE_B_ID	575	/* engine #4 torque */
#define	ENGINE_1_TIT_B_ID	576	/* engine #1 turbine inlet temp */
#define	ENGINE_2_TIT_B_ID	577	/* engine #2 turbine inlet temp */
#define	ENGINE_3_TIT_B_ID	578	/* engine #3 turbine inlet temp */
#define	ENGINE_4_TIT_B_ID	579	/* engine #4 turbine inlet temp */
#define	ENGINE_1_ITT_B_ID	580	/* engine #1 interturbine temp */
#define	ENGINE_2_ITT_B_ID	581	/* engine #2 interturbine temp */
#define	ENGINE_3_ITT_B_ID	582	/* engine #3 interturbine temp */
#define	ENGINE_4_ITT_B_ID	583	/* engine #4 interturbine temp */
#define	ENGINE_1_TOT_B_ID	584	/* engine #1 turbine outlet temp */
#define	ENGINE_2_TOT_B_ID	585	/* engine #2 turbine outlet temp */
#define	ENGINE_3_TOT_B_ID	586	/* engine #3 turbine outlet temp */
#define	ENGINE_4_TOT_B_ID	587	/* engine #4 turbine outlet temp */
#define	ENGINE_1_FUEL_FLOW_B_ID	588	/* engine #1 fuel flow rate */
#define	ENGINE_2_FUEL_FLOW_B_ID	589	/* engine #2 fuel flow rate */
#define	ENGINE_3_FUEL_FLOW_B_ID	590	/* engine #3 fuel flow rate */
#define	ENGINE_4_FUEL_FLOW_B_ID	591	/* engine #4 fuel flow rate */
#define	ENGINE_1_MAN_PRESS_B_ID	592	/* engine #1 manifold pressure */
#define	ENGINE_2_MAN_PRESS_B_ID	593	/* engine #2 manifold pressure */
#define	ENGINE_3_MAN_PRESS_B_ID	594	/* engine #3 manifold pressure */
#define	ENGINE_4_MAN_PRESS_B_ID	595	/* engine #4 manifold pressure */
#define	ENGINE_1_OIL_PRESS_B_ID	596	/* engine #1 oil pressure */
#define	ENGINE_2_OIL_PRESS_B_ID	597	/* engine #2 oil pressure */
#define	ENGINE_3_OIL_PRESS_B_ID	598	/* engine #3 oil pressure */
#define	ENGINE_4_OIL_PRESS_B_ID	599	/* engine #4 oil pressure */
#define	ENGINE_1_OIL_TEMP_B_ID	600	/* engine #1 oil temp */
#define	ENGINE_2_OIL_TEMP_B_ID	601	/* engine #2 oil temp */
#define	ENGINE_3_OIL_TEMP_B_ID	602	/* engine #3 oil temp */
#define	ENGINE_4_OIL_TEMP_B_ID	603	/* engine #4 oil temp */
#define	ENGINE_1_CHT_B_ID	604	/* engine #1 cylinder head temp */
#define	ENGINE_2_CHT_B_ID	605	/* engine #2 cylinder head temp */
#define	ENGINE_3_CHT_B_ID	606	/* engine #3 cylinder head temp */
#define	ENGINE_4_CHT_B_ID	607	/* engine #4 cylinder head temp */
#define	ENGINE_1_OIL_QUANT_B_ID	608	/* engine #1 oil quantity */
#define	ENGINE_2_OIL_QUANT_B_ID	609	/* engine #2 oil quantity */
#define	ENGINE_3_OIL_QUANT_B_ID	610	/* engine #3 oil quantity */
#define	ENGINE_4_OIL_QUANT_B_ID	611	/* engine #4 oil quantity */
#define	ENGINE_1_COOL_TEMP_B_ID	612	/* engine #1 cooland temp */
#define	ENGINE_2_COOL_TEMP_B_ID	613	/* engine #2 cooland temp */
#define	ENGINE_3_COOL_TEMP_B_ID	614	/* engine #3 cooland temp */
#define	ENGINE_4_COOL_TEMP_B_ID	615	/* engine #4 cooland temp */
#define	ENGINE_1_POW_RATIO_B_ID	616	/* engine #1 power ratio */
#define	ENGINE_2_POW_RATIO_B_ID	617	/* engine #1 power ratio */
#define	ENGINE_3_POW_RATIO_B_ID	618	/* engine #1 power ratio */
#define	ENGINE_4_POW_RATIO_B_ID	619	/* engine #1 power ratio */
#define	ENGINE_1_STATUS_1_B_ID	620	/* engine #1 status word 1 */
#define	ENGINE_2_STATUS_1_B_ID	621	/* engine #2 status word 1 */
#define	ENGINE_3_STATUS_1_B_ID	622	/* engine #3 status word 1 */
#define	ENGINE_4_STATUS_1_B_ID	623	/* engine #4 status word 1 */
#define	ENGINE_1_STATUS_2_B_ID	624	/* engine #1 status word 2 */
#define	ENGINE_2_STATUS_2_B_ID	625	/* engine #2 status word 2 */
#define	ENGINE_3_STATUS_2_B_ID	626	/* engine #3 status word 2 */
#define	ENGINE_4_STATUS_2_B_ID	627	/* engine #4 status word 2 */

#define	FUEL_PUMP_1_FLOW_ID	660	/* fuel pump #1 flow */
#define	FUEL_PUMP_2_FLOW_ID	661	/* fuel pump #2 flow */
#define	FUEL_PUMP_3_FLOW_ID	662	/* fuel pump #3 flow */
#define	FUEL_PUMP_4_FLOW_ID	663	/* fuel pump #4 flow */
#define	FUEL_PUMP_5_FLOW_ID	664	/* fuel pump #5 flow */
#define	FUEL_PUMP_6_FLOW_ID	665	/* fuel pump #6 flow */
#define	FUEL_PUMP_7_FLOW_ID	666	/* fuel pump #7 flow */
#define	FUEL_PUMP_8_FLOW_ID	667	/* fuel pump #8 flow */
#define	TANK_1_FUEL_QUANT_ID	668	/* tank #1 fuel quantity */
#define	TANK_2_FUEL_QUANT_ID	669	/* tank #2 fuel quantity */
#define	TANK_3_FUEL_QUANT_ID	670	/* tank #3 fuel quantity */
#define	TANK_4_FUEL_QUANT_ID	671	/* tank #4 fuel quantity */
#define	TANK_5_FUEL_QUANT_ID	672	/* tank #5 fuel quantity */
#define	TANK_6_FUEL_QUANT_ID	673	/* tank #6 fuel quantity */
#define	TANK_7_FUEL_QUANT_ID	674	/* tank #7 fuel quantity */
#define	TANK_8_FUEL_QUANT_ID	675	/* tank #8 fuel quantity */
#define	TANK_1_FUEL_TEMP_ID	676	/* tank #1 fuel temp */
#define	TANK_2_FUEL_TEMP_ID	677	/* tank #2 fuel temp */
#define	TANK_3_FUEL_TEMP_ID	678	/* tank #3 fuel temp */
#define	TANK_4_FUEL_TEMP_ID	679	/* tank #4 fuel temp */
#define	TANK_5_FUEL_TEMP_ID	680	/* tank #5 fuel temp */
#define	TANK_6_FUEL_TEMP_ID	681	/* tank #6 fuel temp */
#define	TANK_7_FUEL_TEMP_ID	682	/* tank #7 fuel temp */
#define	TANK_8_FUEL_TEMP_ID	683	/* tank #8 fuel temp */
#define	FUEL_SYS_1_PRESS_ID	684	/* fuel system #1 pressure */
#define	FUEL_SYS_2_PRESS_ID	685	/* fuel system #2 pressure */
#define	FUEL_SYS_3_PRESS_ID	686	/* fuel system #3 pressure */
#define	FUEL_SYS_4_PRESS_ID	687	/* fuel system #4 pressure */
#define	FUEL_SYS_5_PRESS_ID	688	/* fuel system #5 pressure */
#define	FUEL_SYS_6_PRESS_ID	689	/* fuel system #6 pressure */
#define	FUEL_SYS_7_PRESS_ID	690	/* fuel system #7 pressure */
#define	FUEL_SYS_8_PRESS_ID	691	/* fuel system #8 pressure */

/*
 * Power transmission system data identifier definitions.
 */

#define ROTOR_1_RPM_ID		700	/* rotor 1 RPM */
#define ROTOR_2_RPM_ID		701	/* rotor 2 RPM */
#define ROTOR_3_RPM_ID		702	/* rotor 3 RPM */
#define ROTOR_4_RPM_ID		703	/* rotor 4 RPM */
#define GEARBOX_1_RPM_ID	704	/* gearbox 1 speed */ 
#define GEARBOX_2_RPM_ID	705	/* gearbox 2 speed */ 
#define GEARBOX_3_RPM_ID	706	/* gearbox 3 speed */ 
#define GEARBOX_4_RPM_ID	707	/* gearbox 4 speed */ 
#define GEARBOX_5_RPM_ID	708	/* gearbox 5 speed */ 
#define GEARBOX_6_RPM_ID	709	/* gearbox 6 speed */ 
#define GEARBOX_7_RPM_ID	710	/* gearbox 7 speed */ 
#define GEARBOX_8_RPM_ID	711	/* gearbox 8 speed */ 
#define GEARBOX_1_OIL_PRESS_ID	712	/* gearbox 1 oil pressure */ 
#define GEARBOX_2_OIL_PRESS_ID	713	/* gearbox 2 oil pressure */ 
#define GEARBOX_3_OIL_PRESS_ID	714	/* gearbox 3 oil pressure */ 
#define GEARBOX_4_OIL_PRESS_ID	715	/* gearbox 4 oil pressure */ 
#define GEARBOX_5_OIL_PRESS_ID	716	/* gearbox 5 oil pressure */ 
#define GEARBOX_6_OIL_PRESS_ID	717	/* gearbox 6 oil pressure */ 
#define GEARBOX_7_OIL_PRESS_ID	718	/* gearbox 7 oil pressure */ 
#define GEARBOX_8_OIL_PRESS_ID	719	/* gearbox 8 oil pressure */ 
#define GEARBOX_1_OIL_TEMP_ID	720	/* gearbox 1 oil temperature */ 
#define GEARBOX_2_OIL_TEMP_ID	721	/* gearbox 2 oil temperature */ 
#define GEARBOX_3_OIL_TEMP_ID	722	/* gearbox 3 oil temperature */ 
#define GEARBOX_4_OIL_TEMP_ID	723	/* gearbox 4 oil temperature */ 
#define GEARBOX_5_OIL_TEMP_ID	724	/* gearbox 5 oil temperature */ 
#define GEARBOX_6_OIL_TEMP_ID	725	/* gearbox 6 oil temperature */ 
#define GEARBOX_7_OIL_TEMP_ID	726	/* gearbox 7 oil temperature */ 
#define GEARBOX_8_OIL_TEMP_ID	727	/* gearbox 8 oil temperature */
#define GEARBOX_1_OIL_QTY_ID	728	/* gearbox 1 oil temperature */ 
#define GEARBOX_2_OIL_QTY_ID	729	/* gearbox 2 oil oil quantity */ 
#define GEARBOX_3_OIL_QTY_ID	730	/* gearbox 3 oil oil quantity */ 
#define GEARBOX_4_OIL_QTY_ID	731	/* gearbox 4 oil oil quantity */ 
#define GEARBOX_5_OIL_QTY_ID	732	/* gearbox 5 oil oil quantity */ 
#define GEARBOX_6_OIL_QTY_ID	733	/* gearbox 6 oil oil quantity */ 
#define GEARBOX_7_OIL_QTY_ID	734	/* gearbox 7 oil oil quantity */ 
#define GEARBOX_8_OIL_QTY_ID	735	/* gearbox 8 oil oil quantity */

/*
 * hydraulic system data identifier definitions.
 */

#define HYDRAULIC_1_PRESS_ID	800	/* hydraulic system 1 pressure */
#define HYDRAULIC_2_PRESS_ID	801	/* hydraulic system 2 pressure */
#define HYDRAULIC_3_PRESS_ID	802	/* hydraulic system 3 pressure */
#define HYDRAULIC_4_PRESS_ID	803	/* hydraulic system 4 pressure */
#define HYDRAULIC_5_PRESS_ID	804	/* hydraulic system 5 pressure */
#define HYDRAULIC_6_PRESS_ID	805	/* hydraulic system 6 pressure */
#define HYDRAULIC_7_PRESS_ID	806	/* hydraulic system 7 pressure */
#define HYDRAULIC_8_PRESS_ID	807	/* hydraulic system 8 pressure */
#define HYDRAULIC_1_TEMP_ID	808	/* hydraulic system 1 temperature */
#define HYDRAULIC_2_TEMP_ID	809	/* hydraulic system 2 temperature */
#define HYDRAULIC_3_TEMP_ID	810	/* hydraulic system 3 temperature */
#define HYDRAULIC_4_TEMP_ID	811	/* hydraulic system 4 temperature */
#define HYDRAULIC_5_TEMP_ID	812	/* hydraulic system 5 temperature */
#define HYDRAULIC_6_TEMP_ID	813	/* hydraulic system 6 temperature */
#define HYDRAULIC_7_TEMP_ID	814	/* hydraulic system 7 temperature */
#define HYDRAULIC_8_TEMP_ID	815	/* hydraulic system 8 temperature */
#define HYDRAULIC_1_QTY_ID	816	/* hydraulic system 1 fluid quantity */
#define HYDRAULIC_2_QTY_ID	817	/* hydraulic system 2 fluid quantity */
#define HYDRAULIC_3_QTY_ID	818	/* hydraulic system 3 fluid quantity */
#define HYDRAULIC_4_QTY_ID	819	/* hydraulic system 4 fluid quantity */
#define HYDRAULIC_5_QTY_ID	820	/* hydraulic system 5 fluid quantity */
#define HYDRAULIC_6_QTY_ID	821	/* hydraulic system 6 fluid quantity */
#define HYDRAULIC_7_QTY_ID	822	/* hydraulic system 7 fluid quantity */
#define HYDRAULIC_8_QTY_ID	823	/* hydraulic system 8 fluid quantity */


/*
 * Electric system data identifier definitions.
 */

#define	AC_VOLTAGE_1_ID		900	/* AC system #1 voltage */
#define	AC_CURRENT_1_ID		910	/* AC current */
#define	DC_VOLTAGE_1_ID		920	/* DC voltage */
#define	DC_CURRENT_1_ID		930	/* DC current */
#define	PROP_ICEGUARD_1_CURR_ID	940	/* prop iceguard amps */

/*
 * Navigation system data identifier definitions.
 */

#define ACT_NAV_LATITUDE_ID	1000	/* active nav system latitude */
#define ACT_NAV_LONGITUDE_ID	1001	/* active nav system longitude */
#define ACT_NAV_HEIGHT_ID	1002	/* active nav system height */
#define ACT_NAV_ALTITUDE_ID	1003	/* active nav system altitude */
#define ACT_NAV_GND_SPEED_ID	1004	/* active nav system ground speed */
#define ACT_NAV_TT_ID		1005	/* active nav system true track */
#define ACT_NAV_MT_ID		1006	/* active nav system magnetic track */
#define ACT_NAV_XTK_ID		1007	/* active nav system cross track err. */
#define ACT_NAV_TKE_ID		1008	/* active nav system track err. angle */
#define ACT_NAV_TTG_ID		1009	/* active nav system time-to-go */
#define ACT_NAV_ETA_ID		1010	/* active nav system ETA */
#define ACT_NAV_ETE_ID		1011	/* active nav system ETE */

#define NAV_WP_IDENT_1_ID	1012	/* WP identifier char 0-3 */
#define NAV_WP_IDENT_2_ID	1013	/* WP identifier char 4-7 */
#define NAV_WP_IDENT_3_ID	1014	/* WP identifier char 8-11 */
#define NAV_WP_IDENT_4_ID	1015	/* WP identifier char 12-15 */
#define NAV_WP_TYPE_ID		1016	/* WP route segment type */
					/* also VOR/VOR-DME/DME/NDB/INTRSCT */
#define NAV_WP_LATITUDE_ID	1017	/* waypoint latitude */
#define NAV_WP_LONGITUDE_ID	1018	/* waypoint longitude */
#define NAV_WP_MIN_ALT_ID	1019	/* minimum WP altitude */
#define NAV_WP_MIN_FL_ID	1020	/* minimum WP flight level */
#define NAV_WP_MIN_RDRHGT_ID	1021	/* minimum WP radar height */
#define NAV_WP_MIN_HGT_WGS_ID	1022	/* minimum WP height above ellipsoid */
#define NAV_WP_MAX_ALT_ID	1023	/* maximum WP altitude */
#define NAV_WP_MAX_FL_ID	1024	/* maximum WP flight level */
#define NAV_WP_MAX_RDRHGT_ID	1025	/* maximum WP radar height */
#define NAV_WP_MAX_HGT_WGS_ID	1026	/* maximum WP height above ellipsoid */
#define NAV_WP_PLAN_ALT_ID	1027	/* planned WP altitude */
#define NAV_WP_PLAN_FL_ID	1028	/* planned WP flight level */
#define NAV_WP_PLAN_RDRHGT_ID	1029	/* planned WP radar height */
#define NAV_WP_PLAN_HGT_WGS_ID	1030	/* planned WP height above ellipsoid */
#define NAV_WP_DIST_ID		1031	/* WP Distance to Waypoint */
#define NAV_WP_TTG_ID		1032	/* WP time-to-go */
#define NAV_WP_ETA_ID		1033	/* WP ETA */
#define NAV_WP_ETE_ID		1034	/* WP ETE */
#define NAV_WP_TO_FR_FLG_ID	1035	/* FROM/TO/APCHNG/OFF flag */

#define GPS_AC_LATITUDE_ID	1036	/* GPS aircraft latitude */
#define GPS_AC_LONGITUDE_ID	1037	/* GPS aircraft longitude */
#define GPS_AC_HGT_ABV_EL_ID	1038	/* GPS aircraft height above WGS 84 */
#define GPS_AC_GND_SPEED_ID	1039	/* GPS ground speed */
#define GPS_AC_TT_ID		1040	/* GPS true track */
#define GPS_AC_MT_ID		1041	/* GPS magnetic track */
#define GPS_AC_XTK_ID		1042	/* GPS cross track error */
#define GPS_AC_TKE_ID		1043	/* GPS track error angle */
#define	GPS_AC_GS_DEV_ID	1044	/* GPS GS deviation */
#define GPS_PRED_RAIM_ID	1045	/* GPS predicted RAIM */
#define GPS_VERT_POS_TOL_ID	1046	/* vertical figure of merit */
#define GPS_HOR_POS_TOL_ID	1047	/* horizontal figure of merit */
#define GPS_MODE_ID		1048	/* GPS operation mode */

#define INS_AC_LATITUDE_ID	1049	/* INS aircraft latitude */
#define INS_AC_LONGITUDE_ID	1050	/* INS aircraft longitude */
#define INS_AC_HGT_ABV_EL_ID	1051	/* INS aircraft height above WGS 84 */
#define INS_AC_GND_SPEED_ID	1052	/* INS ground speed */
#define INS_AC_TT_ID		1053	/* INS true track */
#define INS_AC_MT_ID		1054	/* INS magnetic track */
#define INS_AC_XTK_ID		1055	/* INS cross track error */
#define INS_AC_TKE_ID		1056	/* INS track error angle */
#define INS_VERT_POS_TOL_ID	1057	/* vertical figure of merit */
#define INS_HOR_POS_TOL_ID	1058	/* horizontal figure of merit */

#define AUX_AC_LATITUDE_ID	1059	/* AUX aircraft latitude */
#define AUX_AC_LONGITUDE_ID	1060	/* AUX aircraft longitude */
#define AUX_AC_HGT_ABV_EL_ID	1061	/* AUX aircraft height above WGS 84 */
#define AUX_AC_GND_SPEED_ID	1062	/* AUX ground speed */
#define AUX_AC_TT_ID		1063	/* AUX true track */
#define AUX_AC_MT_ID		1064	/* AUX magnetic track */
#define AUX_AC_XTK_ID		1065	/* AUX cross track error */
#define AUX_AC_TKE_ID		1066	/* AUX track error angle */
#define AUX_VERT_POS_TOL_ID	1067	/* vertical figure of merit */
#define AUX_HOR_POS_TOL_ID	1068	/* horizontal figure of merit */

#define	MAG_HEADING_ID		1069	/* magnetic heading */
#define	RADIO_HEIGHT_ID		1070	/* radio height */
#define DME_1_DISTANCE_ID	1071	/* DME #1 distance */
#define DME_2_DISTANCE_ID	1072	/* DME #2 distance */
#define DME_3_DISTANCE_ID	1073	/* DME #3 distance */
#define DME_4_DISTANCE_ID	1074	/* DME #4 distance */
#define DME_1_TTG_ID		1075	/* DME #1 time to station */
#define DME_2_TTG_ID		1076	/* DME #2 time to station */
#define DME_3_TTG_ID		1077	/* DME #3 time to station */
#define DME_4_TTG_ID		1078	/* DME #4 time to station */
#define DME_1_GND_SPD_ID	1079	/* DME #1 ground speed */
#define DME_2_GND_SPD_ID	1080	/* DME #2 ground speed */
#define DME_3_GND_SPD_ID	1081	/* DME #3 ground speed */
#define DME_4_GND_SPD_ID	1082	/* DME #4 ground speed */
#define ADF_1_REL_BRG_ID	1083	/* ADF #1 relative bearing */
#define ADF_2_REL_BRG_ID	1084	/* ADF #2 relative bearing */
#define ADF_3_REL_BRG_ID	1085	/* ADF #3 relative bearing */
#define ADF_4_REL_BRG_ID	1086	/* ADF #4 relative bearing */
#define	ILS_1_LOC_DEV_ID	1087	/* ILS #1 LOC deviation */
#define	ILS_2_LOC_DEV_ID	1088	/* ILS #2 LOC deviation */
#define	ILS_3_LOC_DEV_ID	1089	/* ILS #3 LOC deviation */
#define	ILS_4_LOC_DEV_ID	1090	/* ILS #4 LOC deviation */
#define	ILS_1_GS_DEV_ID		1091	/* ILS #1 GS deviation */
#define	ILS_2_GS_DEV_ID		1092	/* ILS #2 GS deviation */
#define	ILS_3_GS_DEV_ID		1093	/* ILS #3 GS deviation */
#define	ILS_4_GS_DEV_ID		1094	/* ILS #4 GS deviation */
#define	FD_1_PITCH_DEV_ID	1095	/* flight director #1 pitch deviation */
#define	FD_2_PITCH_DEV_ID	1096	/* flight director #2 pitch deviation */
#define	FD_1_ROLL_DEV_ID	1097	/* flight director #1 roll deviation */
#define	FD_2_ROLL_DEV_ID	1098	/* flight director #2 roll deviation */
#define DECISION_HEIGHT_ID	1099	/* decision height */
#define VHF_1_FREQ_ID		1100	/* VHF COM #1 frequency */
#define VHF_2_FREQ_ID		1101	/* VHF COM #2 frequency */
#define VHF_3_FREQ_ID		1102	/* VHF COM #3 frequency */
#define VHF_4_FREQ_ID		1103	/* VHF COM #4 frequency */
#define VOR_ILS_1_FREQ_ID	1104	/* VOR ILS #1 frequency */
#define VOR_ILS_2_FREQ_ID	1105	/* VOR ILS #2 frequency */
#define VOR_ILS_3_FREQ_ID	1106	/* VOR ILS #3 frequency */
#define VOR_ILS_4_FREQ_ID	1107	/* VOR ILS #4 frequency */
#define ADF_1_FREQ_ID		1108	/* ADF #1 frequency */
#define ADF_2_FREQ_ID		1109	/* ADF #2 frequency */
#define ADF_3_FREQ_ID		1110	/* ADF #3 frequency */
#define ADF_4_FREQ_ID		1111	/* ADF #4 frequency */
#define DME_1_FREQ_ID		1112	/* DME #1 frequency */
#define DME_2_FREQ_ID		1113	/* DME #2 frequency */
#define DME_3_FREQ_ID		1114	/* DME #3 frequency */
#define DME_4_FREQ_ID		1115	/* DME #4 frequency */
#define XPDR_1_CODE_ID		1116	/* transponder #1 code */
#define XPDR_2_CODE_ID		1117	/* transponder #2 code */
#define XPDR_3_CODE_ID		1118	/* transponder #3 code */
#define XPDR_4_CODE_ID		1119	/* transponder #4 code */

#define DESIRED_TRK_MAG_ID	1120	/* desired track angle */
#define MAG_VARIATION_ID	1121	/* magnetic variation */
#define SEL_GPATH_ANGLE_ID	1122	/* selected glidepath angle */
#define SEL_RWY_HDG_ID		1123	/* selected runway heading */
#define COMPUTED_VERT_VEL_ID	1124	/* computed vertical velocity */
#define SEL_COURSE_ID		1125	/* selected course */

#define VOR_1_RADIAL_ID		1126	/* VOR #1 radial bearing */
#define VOR_2_RADIAL_ID		1127	/* VOR #2 radial bearing */
#define VOR_3_RADIAL_ID		1128	/* VOR #3 radial bearing */
#define VOR_4_RADIAL_ID		1129	/* VOR #4 radial bearing */

#define TRUE_EAST_VEL_ID	1130	/* true east velocity */
#define TRUE_NORTH_VEL_ID	1131	/* true north velocity */
#define TRUE_UP_VEL_ID		1132	/* true up velocity */
#define	TRUE_HEADING_ID		1133	/* true heading angle */

/*
 * Landing gear system data identifier definitions.
 */

#define	GEAR_SWITCH_ID		1175	/* gear lever switches */
#define	GEAR_LIGHTS_WOW_ID	1176	/* gear lever indicator lights/WOW */
#define	TIRE_PRESS_1_ID		1177	/* landing gear #1 tire pressure */
#define	TIRE_PRESS_2_ID		1178	/* landing gear #2 tire pressure */
#define	TIRE_PRESS_3_ID		1179	/* landing gear #3 tire pressure */
#define	TIRE_PRESS_4_ID		1180	/* landing gear #4 tire pressure */
#define	BRAKE_PAD_THCK_1_ID	1181	/* landing gear #1 brakepad thickness */
#define	BRAKE_PAD_THCK_2_ID	1182	/* landing gear #2 brakepad thickness */
#define	BRAKE_PAD_THCK_3_ID	1183	/* landing gear #3 brakepad thickness */
#define	BRAKE_PAD_THCK_4_ID	1184	/* landing gear #4 brakepad thickness */

/*
 * Miscellaneous data identifier definitions.
 */

#define UTC_ID			1200	/* Universal Time Coordinated */
#define CABIN_P_ID		1201	/* cabin pressure */
#define CABIN_ALT_ID		1202	/* cabin altitude */
#define CABIN_T_ID		1203	/* cabin temperature */
#define CG_LONG_ID		1204	/* longitudinal center of gravity */
#define CG_LAT_ID		1205	/* lateral center of gravity */
#define DATE_ID			1206	/* date */
#define TOP_MARKER_ID		1207	/* flight data recording TOP marker */

/*
 * User defined data identifier definitions.
 */

#define	FIRST_USER_DEFINED_ID	1500
#define	LAST_USER_DEFINED_ID	1799

/*
 * End of file.
 */
