/*******************************************************************************
* ARINC825 interface definitions                                               *
*                                                                              *
* (C) 2007-2010 Stock Flight Systems. All rights reserved.                     *
*                                                                              *
* Filename: arinc825.h                                                         *
*                                                                              *
* This file contains definitions and the structures used for the ARINC 825     *
* interface definition.                                                        *
*                                                                              *
* MODIFICATIONS:                                                               *
*                                                                              *
* When          Version      What                                  Who         *
* ____________________________________________________________________________ *
*                                                                              *
* 03.03.2007    1.0          Initial Version                       M. Stock    *
* 01.05.2007    1.1          Some definitions added                M. Stock    *
* 08.11.2007    1.2          RCI_X definitions added               M. Stock    *
* 22.03.2010    1.3          Supplement 1 support added            M. Stock    *
* 25.07.2010    1.4          Node service support added            M. Stock    *
*                                                                              *
*******************************************************************************/

/*
 * ARINC825 identifier field definitions.
 */

#define		RCI_A           0               /* Redundancy Channel A */
#define		RCI_B           1               /* Redundancy Channel B */
#define		RCI_C           2               /* Redundancy Channel C */
#define		RCI_D           3               /* Redundancy Channel D */

#define		EEC             0               /* Emergency Event Channel */
#define		RC0             1               /* Reserved Channel #0 */
#define		NOC             2               /* Normal Operation Channel */
#define		RC1             3               /* Reserved Channel #0 */
#define		NSC             4               /* Node Service Channel */
#define		UDC             5               /* User-Defined Channel */
#define		TMC             6               /* Test & Maintenance Channel */
#define		FMC             7               /* Base Frame Channel */

/*
 * Multicast definitions.
 */

#define		MCAST_SID       0               /* Multicast Server-ID */
#define		MCAST_SFID      0               /* Multicast Server-ID */

/*
 * ARINC825 Function-ID definitions.
 */

#define	        MCAST_FNC_ID    0
#define	        FLT_STAT_FNC_ID 4
#define	        FLT_CTRL_FNC_ID 10
#define         ENGINE_FNC_ID	11
#define	        ENG_IND_FNC_ID	12
#define	        ELECTRIC_FNC_ID	13
#define	        FUEL_FNC_ID	18
#define	        WINGS_FNC_ID	21
#define	        OIL_FNC_ID	31
#define         GEAR_FNC_ID	34
#define         LIGHTS_FNC_ID	63
#define         DOORS_FNC_ID	80
#define         CABIN_FNC_ID	107
#define         PHSM_FID	125
#define         TEST_MAINT_FID	127

/*
 * ARINC825 node service function code definitions. The function codes
 * 0x0007 - 0x03FF and 0x0800 - 0xBFFF are reserved, the function codes
 * 0x0400 - 0x07FF are for ARINC812 use, the function codes 0xC000 - 0xFFFF
 * are user-defined.
 */

#define         A825_IDS        0x0000	        /* Identification service */
#define         A825_NSS        0x0001	        /* Node sync service */
#define         A825_DUS        0x0002	        /* Data upload service */
#define         A825_DDS        0x0003	        /* Data download service */
#define         A825_BCS        0x0004	        /* BIT control service */
#define         A825_PSS        0x0005	        /* Permanent storage service */
#define         A825_NIS        0x0006	        /* Node-ID setting service */

/*
 * Data upload/download service source/destination identifier and errror code
 * definitions. The identifiers 0x0007 - 0x03FF are reserved, the identifiers
 * 0x0400 - 0xFFFF are user-defined.
 */

#define         DEST_DEFAULT    0x0000          /* Default */
#define         DEST_FAULT_LOG  0x0001          /* System error log */
#define         DEST_UNIT_ID    0x0002          /* Unit identification */
#define         DEST_UNIT_CFG   0x0003          /* Unit configuration */
#define         DEST_BASIC_SW   0x0004          /* Basic software/bootstrap */
#define         DEST_UNIT_OS    0x0005          /* Operating system */
#define         DEST_APP        0x0006          /* Application program */

#define         DUS_CRC_OK      0               /* Checksum OK */
#define         DUS_ACK         1               /* Acknowledge */
#define         DUS_ABORT       -1              /* Abort data load */
#define         DUS_INVLD_DST   -2              /* Invalid destination */
#define         DUS_OUT_OF_SPCE -3              /* Out of space */
#define         DUS_INVLD_DATA  -4              /* Invalid data */
#define         DUS_CRC_ERROR   -5              /* Checksum Error */

#define         DUS_CHKSUM_OK   1               /* Checksum OK */
#define         DUS_CHKSUM_ERR  -1              /* Checksum error */

#define         DDS_CRC_OK      0               /* Checksum OK */
#define         DDS_ACK         1               /* Acknowledge */
#define         DDS_ABORT       -1              /* Abort data load */
#define         DUS_INVLD_SRC   -2              /* Invalid source */
#define         DDS_INVLD_DATA  -4              /* Invalid data */
#define         DDS_CRC_ERROR   -5              /* Checksum Error */

#define         DDS_CHKSUM_OK   1               /* Checksum OK */
#define         DDS_CHKSUM_ERR  -1              /* Checksum error */

#define         DUS_SMT_SERVER  0               /* SMT setting for server */
#define         DUS_SMT_CLIENT  1               /* SMT setting for client */
#define         DUS_PVT_CTRL    0               /* PVT setting for ctrl msgs */
#define         DUS_PVT_DATA    1               /* PVT setting for data msgs */
#define         DUS_CONSTANT    1               /* Constant for response */

#define         DDS_SMT_SERVER  0               /* SMT setting for server */
#define         DDS_SMT_CLIENT  1               /* SMT setting for client */
#define         DDS_PVT_CTRL    0               /* PVT setting for ctrl msgs */
#define         DDS_PVT_DATA    1               /* PVT setting for data msgs */
#define         DDS_CONSTANT    1               /* Constant for response */
#define         DDS_CONSTANT    1               /* Constant for response */

/*
 * The DUS/DDS state machine control structure and associated definitions.
 */

typedef struct
  {
  unsigned int    byte_count;                   /* Data buffer size */
  unsigned int    byte_index;                   /* Data buffer index */
  unsigned short  selected_blk_sep_time;        /* Selected block sep. time */
  unsigned short  selected_msg_sep_time;        /* Selected message sep. time */
  unsigned short  dest_identity;                /* Destination id */
  unsigned short  selected_blk_size;            /* Selected block size */
  unsigned short  ctrl_seq;                     /* Control state machine seq. */
  }               DATA_LOAD_CTRL;

#define         DUS_IDLE        0
#define         DUS_INIT_1      1
#define         DUS_INIT_2      2
#define         DUS_WAIT        3
#define         DUS_CONFIG      4
#define         DUS_START       5
#define         DUS_CHECK       6
#define         DUS_END         7

#define         DDS_IDLE        0
#define         DDS_INIT_1      1
#define         DDS_INIT_2      2
#define         DDS_WAIT        3
#define         DDS_CONFIG      4
#define         DDS_START       5
#define         DDS_CHECK       6
#define         DDS_END         7

/*
 * CRC32 definitions.
 */

#define         CRC_INIT        0xFFFFFFFF
#define         FINAL_XOR       0xFFFFFFFF
#define         GENERATOR       0x04C11DB7
#define         CRC32_CHECK     0xB6B5EE95

/*
 * Other node service definitions.
 */

#define         PPS_DATA_STORED 0               /* Data stored */
#define         PPS_INVLD_PWD   -1              /* Invalid password */

#define         NIS_DATA_STORED 0               /* Data stored */
#define         NIS_INVLD_NID   -1              /* Invalid Node-ID */

/*
 * End of file.
 */
