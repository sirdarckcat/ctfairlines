/*******************************************************************************
* Definitions for the CAN Flight Data Recording Trace Files                    *
*                                                                              *
* (C) 2010 Stock Flight Systems. All rights reserved.                          *
*                                                                              *
* Filename: can_trace.h                                                        *
*                                                                              *
* This file contains structure definitions for the CAN trace files generated   *
* by flight data recorders and XCT.                                            *
*                                                                              *
* MODIFICATIONS:                                                               *
*                                                                              *
* When          Version      What                                  Who         *
* ____________________________________________________________________________ *
*                                                                              *
* 10.02.2010    1.0          Initial Version                       M. Stock    *
* 05.03.2010    1.1          CAN_CHANNEL_x definitions added       M. Stock    *
*                                                                              *
*******************************************************************************/

/*
 * The CAN trace file header structure (16 bytes). Preceeds every data file
 * and is followed by an arbitrary number of data sets arranged in structures
 * of the type RED_TRACE_MSG or GEN_TRACE_MSG (specified in "struct_type").
 * Trace files are terminated by EOF (0xFF).
 */

typedef struct
  {
  unsigned short endianness;             /* ENDIANNESS_VALUE */
  short          header_version;         /* TRACE_HEADER_VERSION */
  short          struct_type;            /* REDUCED_TRACE, .... */
  unsigned short reserved;               /* For future use, set to "0" */
  unsigned int   start_time_hi;          /* Upper 32 bits of time stamp */
  unsigned int   start_time_lo;          /* Lower 32 bits of time stamp */
  }              TRACE_HEADER;

/*
 * The reduced CANaerospace/ARINC825 trace file message buffer structure
 * (16 bytes).
 */

typedef struct
  {
  unsigned int   time_stamp_lo;           /* Message time stamp (bits 0-31) */
  unsigned int   identifier;              /* Standard/Extended CAN identifier */
  unsigned char  data[8];                 /* 8 byte message payload buffer */
  }              RED_TRACE_MSG;

/*
 * The generic trace file message buffer structure (24 bytes).
 */

typedef struct
  {
  unsigned int   time_stamp_hi;           /* Message time stamp (bits 32-63) */
  unsigned int   time_stamp_lo;           /* Message time stamp (bits 0-31) */
  unsigned int   identifier;              /* Standard/Extended CAN identifier */
  short          channel;                 /* CAN channel */
  unsigned char  byte_count;              /* Message byte count */
  unsigned char  frame_type;              /* Data vs. remote frame */
  unsigned char  data[8];                 /* 8 byte message payload buffer */
  }              GEN_TRACE_MSG;

/*
 * Definitions for structure variables.
 */

#define ENDIANNESS_VALUE      0xabba      /* Correct "endianness" value */
#define TRACE_HEADER_VERSION  0           /* "header_version" value */

#define REDUCED_TRACE         0           /* CANaerospace, ARINC825, ... */
#define GENERIC_TRACE         1           /* Any CAN protocol */

#define TRACE_DATA_FRAME      0           /* CAN data frame */
#define TRACE_REMOTE_FRAME    0xff        /* CAN remote frame */

/*
 * Definitions to be ORed to identifier for reduced trace.
 */

#define CAN_TRACE_CH_0        0x00000000  /* Channel 0 coded into identifier */
#define CAN_TRACE_CH_1        0x20000000  /* Channel 1 coded into identifier */
#define CAN_TRACE_CH_2        0x40000000  /* Channel 2 coded into identifier */
#define CAN_TRACE_CH_3        0x60000000  /* Channel 3 coded into identifier */
#define EXT_TRACE_CANID       0x80000000  /* Ext. CAN-ID coded into identifier */

/*
 * End of file.
 */
