/*******************************************************************************
* PMC825 UDP/IP Socket Interface Library Definitions                           *
*                                                                              *
* (C) 2010-2011 Stock Flight Systems. All rights reserved.                     *
*                                                                              *
* Filename: pmc825socket.h                                                     *
*                                                                              *
* MODIFICATIONS:                                                               *
*                                                                              *
* When          Version      What                                  Who         *
* ____________________________________________________________________________ *
*                                                                              *
* 16.01.2010    1.0          Initial Version                       M. Stock    *
* 26.02.2010    1.1          Flight data recording formats added   M. Stock    *
* 05.04.2010    1.2          Windoze support added                 M. Stock    *
* 12.06.2010    1.3          CAN_STAT_REGS structure added         M. Stock    *
* 09.08.2010    1.4          Swapxx() functions added              M. Stock    *
* 15.05.2011    1.5          Data load packet structures added     M. Stock    *
*                                                                              *
*******************************************************************************/

/*
 * Includes.
 */

#ifndef WIN32
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/file.h>
#include <ctype.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <netinet/in.h>
#include <netdb.h>
#include <fcntl.h>
#include <inttypes.h>
#include <sys/ipc.h>
#include <sys/shm.h>
#include <signal.h>
#else
#include "stdlib.h"
#include <winsock2.h>
#include <ws2tcpip.h>
#include <io.h>
#endif

/*
 * Make sure the LITTLE_ENDIAN switch is set for Windoze.
 */

#ifdef WIN32
#define LITTLE_ENDIAN
#endif

/*
 * CAN specific definitions.
 */

typedef unsigned int    CANID;          /* Bits 0..10 used for standard ID */

#define MAX_STD_CAN_ID  2047            /* Highest CAN-ID (11 bits) */
#define MAX_EXT_CAN_ID  0x1fffffff      /* Highest CAN-ID (29 bits) */
#define EXT_ID          0x80000000      /* Extended ID flag */

#define DATA_FRAME      0x00            /* Data frame */
#define REMOTE_FRAME    0x01            /* Remote frame */
#define ERROR_FRAME     0xff            /* Error frame */

/*
 * The general CAN message buffer structure (28 bytes).
 */

typedef struct
  {
  char            data[8];              /* 8 byte message payload buffer */
  char            byte_count;           /* Range: 0..8 */
  char            frame_type;           /* RTR or DATA frame */
  unsigned short  msg_control;          /* Optional message control var */
  CANID           identifier;           /* Standard/extended CAN ID */
  unsigned short  can_status;           /* C_CAN status register */
  unsigned short  error_counter;        /* C_CAN error counter register */
  unsigned int    time_stamp_hi;        /* Message time stamp (bits 32-63) */
  unsigned int    time_stamp_lo;        /* Message time stamp (bits 0-31) */
  }               CAN_MSG;

/*
 * The ARINC825 message buffer structure (36 bytes).
 */

typedef struct
  {
  unsigned char   lcc;                  /* communication channel */
  unsigned char	  scfid;                /* source/client function id */
  unsigned char	  smt;                  /* service message type bit */
  unsigned char	  lcl;                  /* local bit */
  unsigned char	  pvt;                  /* private bit */
  unsigned char	  rci;                  /* redundancy channel id */
  unsigned char	  sfid;                 /* server function id */
  unsigned char	  sid;                  /* server id */
  unsigned int    doc;                  /* data object code */
  }               ARINC825_ID;

typedef struct
  {
  char            data[8];              /* 8 byte message payload buffer */
  char            byte_count;           /* Range: 0..8 */
  char            frame_type;           /* RTR or DATA frame */
  unsigned short  msg_control;          /* Optional message control var */
  ARINC825_ID     identifier;           /* ARINC825 identifier */
  unsigned short  can_status;           /* C_CAN status register */
  unsigned short  error_counter;        /* C_CAN error counter register */
  unsigned int    time_stamp_hi;        /* Message time stamp (bits 32-63) */
  unsigned int    time_stamp_lo;        /* Message time stamp (bits 0-31) */
  }               ARINC825_MSG;

/*
 * The CANaerospace message buffer structure (28 bytes). Maps directly onto
 * the general CAN message buffer structure.
 */

typedef struct
  {
  char             node_id;             /* CANaerospace Node-ID */
  char             data_type;           /* CANaerospace data type identifier */
  char             service_code;        /* CANaerospace service code */
  char             msg_code;            /* CANaerospace message code */
  char             data[4];             /* Message payload */
  char             byte_count;          /* Range: 4..8 */
  char             frame_type;          /* RTR or DATA frame */
  unsigned short   msg_control;         /* Optional message control var */
  CANID            identifier;          /* Standard/extended CAN ID */
  unsigned short   can_status;          /* C_CAN status register */
  unsigned short   error_counter;       /* C_CAN error counter register */
  unsigned int     time_stamp_hi;       /* Message time stamp (bits 32-63)*/
  unsigned int     time_stamp_lo;       /* Message time stamp (bits 0-31) */
  }                CAN_AS_MSG;

/*
 * The control message buffer structure.
 */

typedef struct
  {
  unsigned short    opcode;             /* CAN_WRITE_RSP/CAN_CTRL */
  unsigned short    svc_rsp_code;       /* Service code or response code */
  unsigned short    arg[256];           /* Variable argument vector */
  }                 CTRL_MSG;

/*
 * The Ethernet/UDP/IP packet structure definitions.
 */

#define PMC825_RX_BUFSIZE   2048        /* CAN receive buffer size */
#define PMC825_TX_BUFSIZE     64        /* CAN transmit buffer size */
#define MAX_IP_PKT_SIZE     1536        /* Max. Ethernet packet size */
#define DLOAD_PKT_SIZE      1398        /* Download packet size */
#define MAX_CAN_MSG_COUNT     50        /* Max CAN messages per packet */
#define PMC825_CTRL_BUFSIZE  256        /* Control packet buffer size */
#define PMC825_DLOAD_BUFSIZE  16        /* Download packet buffer size */

#define ETH_HDR_SIZE          14        /* Size of Ethernet header */
#define IP_HDR_SIZE           20        /* Size of IP packet header */
#define UDP_HDR_SIZE           8        /* Size of UDP packet header */
#define MSG_HDR_SIZE          10        /* Size of CAN message packet header */

typedef struct
  {
  unsigned int      frame_count;        /* Incremented for each packet */
  unsigned short    opcode;             /* CAN_READ/CAN_WRITE */
  unsigned short    msg_count;          /* Number of CAN messages in packet */
  CAN_MSG           msg[MAX_CAN_MSG_COUNT]; /* Maximum number of msgs/packet */
  }                 UDP_CAN_MSG_PKT;

typedef struct
  {
  unsigned int      frame_count;        /* Incremented for each packet */
  unsigned short    opcode;             /* CAN_WRITE_RSP/CAN_CTRL */
  unsigned short    svc_rsp_code;       /* Service code or response code */
  unsigned short    arg[256];           /* Variable argument vector */
  }                 UDP_CAN_CTRL_PKT;

typedef struct
  {
  unsigned int      frame_count;        /* Incremented for each packet */
  unsigned short    opcode;             /* TARGET_LIST_DIR_CMD */
  }                 UDP_LIST_DIR_PKT;

typedef struct
  {
  unsigned int      frame_count;        /* Incremented for each packet */
  unsigned short    opcode;             /* Opcode (HOST_DOWNLOAD_RESP) */
  unsigned short    svc_rsp_code;       /* Service code */
  short             byte_count;         /* Number of bytes in data section */
  unsigned char     data[DLOAD_PKT_SIZE];  /* Data to be transferred */
  }                 UDP_DLOAD_DATA_PKT;

typedef struct
  {
  unsigned int      frame_count;        /* Incremented for each packet */
  unsigned short    opcode;             /* Opcode (HOST_DOWNLOAD_CMD) */
  unsigned short    svc_rsp_code;       /* Service code */
  unsigned char     fname[12];          /* Filename to be transferred */
  }                 UDP_DLOAD_CMD_PKT;

/*
 * The CAN status packet structure extract.
 */

typedef struct
  {
  unsigned short    can_status;         /* C_CAN bus status register content */
  unsigned short    error_counter;      /* C_CAN error counter content */
  unsigned short    btr;                /* C_CAN bus timing register content */
  short             cpm_mode;           /* CPM waraparound/single-shot mode */
  unsigned int      tx_bits;            /* Transmitted bits (last 100ms) */
  unsigned int      rx_bits;            /* Received bits (last 100ms) */
  unsigned int      tx_msgs;            /* Transmitted msgs (last 100ms) */
  unsigned int      rx_msgs;            /* Received msgs (last 100ms) */
  short             t1;                 /* Board temperature */
  short             t2;                 /* FPGA temperature */
  unsigned char     ip_addr[4];         /* PMC825 IP address */
  unsigned char     name[32];           /* PMC825 module name */
  }                 CAN_STAT_REGS;

/*
 * Opcodes for the UDP/IP interface.
 */

#define CAN_NOOP              -1        /* For internal use */
#define CAN_DHCP_INFO         0         /* DHCP information packet */
#define CAN_WRITE             1         /* CAN write operation */
#define CAN_READ              2         /* CAN read operation */
#define CAN_CTRL              3         /* CAN ctrl operation */
#define CAN_WRITE_RSP         4         /* CAN write response operation */
#define CAN_READ_RSP          5         /* CAN read response operation */
#define CAN_CTRL_RSP          6         /* CAN ctrl response operation */
#define CAN_STATUS            7         /* CAN status message */
#define HOST_DOWNLOAD_CMD     8         /* Host file download command */
#define HOST_DOWNLOAD_RESP    9         /* Host file download response */
#define HOST_UPLOAD_CMD       10        /* Host file upload command */
#define HOST_UPLOAD_RESP      11        /* Host file upload response */
#define TARGET_LIST_DIR_CMD   12        /* List directory command */
#define TARGET_LIST_DIR_RESP  13        /* List directory response */
#define DELETE_FILE_CMD       14        /* Delete file command */
#define DELETE_FILE_RESP      15        /* Delete file response */
#define FLIGHT_DATA_REC_CTRL  16        /* Flight data recording control */

/*
 * The PMC825 API interface buffer structure.
 */

typedef struct
  {
#ifndef WIN32
  int                rx_sock;           /* Receive socket descriptor */
  int                tx_sock;           /* Transmit socket descriptor */
#else
  SOCKET             rx_sock;           /* Receive socket descriptor */
  SOCKET             tx_sock;           /* Transmit socket descriptor */
#endif

  int                channel;           /* CAN channel */
  unsigned int       tx_frame_count;    /* Transmit frame count */
  unsigned int       last_frame_count;  /* Frame count of last packet */

  int                rx_write;          /* Receive buffer write index */
  int                rx_read;           /* Receive buffer read index */
  CAN_MSG            *rx_can;           /* CAN receive buffer pointer */
  CAN_MSG            *tx_can;           /* CAN transmit buffer pointer */

  int                ctrl_write;        /* Control buffer write index */
  int                ctrl_read;         /* Control buffer read index */
  UDP_CAN_CTRL_PKT   *ctrl_pkt;         /* Control packet buffer pointer */

  int                dload_write;       /* Download buffer write index */
  int                dload_read;        /* Download buffer read index */
  UDP_DLOAD_DATA_PKT *dload_pkt;        /* Download receive buffer pointer */
  }                  PMC825_IF;

/*
 * Parameters for CAN_CTRL.
 */

#define INIT_CAN_CHIP         10        /* CAN controller initialization */
#define GET_CAN_STATUS        11        /* Tx/Rx errors */
#define RESET_TIME_STAMP      12        /* Reset time stamp counters */
#define CONTROL_CPM           13        /* CPM on/off/pause control */
#define GET_TEMPERATURES      14        /* Board/FPGA temperatures in deg. C */
#define CONFIG_READBACK       15        /* Readback function on/off control */
#define CONFIG_BRIDGE         16        /* CAN bridge function on/off control */

#define CONFIG_IP_INTERFACE   100       /* Configure the IP interface */
#define GET_MODULE_INFO       101       /* Get PMC-825 module information */
#define SET_MODULE_NAME       102       /* Set PMC-825 module name string */
#define SET_IP_TX_INTERVAL    103       /* Set Ethernet Tx interval (100us) */

/*
 * Arguments for INIT_CAN_CHIP.
 */

#define CAN_1M                0x1403
#define CAN_500K              0x1407
#define CAN_250K              0x140f
#define CAN_125K              0x141f
#define CAN_83K               0x141f

#define CPM_ENABLE            0x0001    /* CPM enable */
#define CPM_PAUSE             0x0002    /* CPM temporary pause */
#define CPM_CYCLIC            0x0004    /* CPM cyclic mode */

#define CPM_STATUS_MASK       0xf000
#define CPM_STATUS_IDLE       0x1000
#define CPM_STATUS_WAIT       0x6000

#define CPM_TIME_125US        4000
#define CPM_TIME_250US        8000
#define CPM_TIME_500US        16000
#define CPM_TIME_1MS          32000     /* 1ms time equivalent */
#define CPM_TIME_10MS         (CPM_TIME_1MS * 10)
#define CPM_TIME_100MS        (CPM_TIME_1MS * 100)
#define CPM_TIME_1S           (CPM_TIME_1MS * 1000)
#define CPM_TIME_10S          (CPM_TIME_1MS * 10000)
#define CPM_TIME_100S         (CPM_TIME_1MS * 100000)

/*
 * Arguments for RESET_TIME_STAMP.
 */

#define RES_CAN_0_TMR         0x0001
#define RES_CAN_1_TMR         0x0002
#define RES_CAN_2_TMR         0x0004
#define RES_CAN_3_TMR         0x0008
#define RES_CAN_4_TMR         0x0010
#define RES_CAN_5_TMR         0x0020
#define RES_CAN_6_TMR         0x0040
#define RES_CAN_7_TMR         0x0080

#define RES_ALL_CAN_TMRS      0x00ff

/*
 * Parameters for file upload/download.
 */

#define START_DOWNLOAD        0
#define START_UPLOAD          0
#define DATA_ACKNOWLEDGE      1
#define RESEND_PACKET         2
#define ABORT                 3

#define NO_SUCH_FILE          0
#define FILE_OPENED           0
#define DATA_PACKET           1
#define LAST_PACKET           2
#define ABORT                 3
#define DELETED               4

#define FDR_STOP              0
#define FDR_RUN               1
#define REC_CTRL_CANAEROSPACE 2
#define REC_CTRL_ETHERNET     3

/*
 * Function return values.
 */

#define PMC825_OK              0        /* 0x0000 */
#define PMC825_BUSY           -1        /* 0xffff */
#define PMC825_INIT_ERR       -2        /* 0xfffe */
#define PMC825_INVALID_CMD    -3        /* 0xfffd */
#define PMC825_INVALID_REQ    -4        /* 0xfffc */
#define PMC825_INVALID_ARG    -5        /* 0xfffb */
#define PMC825_CHAN_ERR       -6        /* 0xfffa */
#define PMC825_BUF_FULL       -7        /* 0xfff9 */
#define PMC825_MSG_ERR        -8        /* 0xfff8 */
#define PMC825_MEM_ALLOC_ERR  -9        /* 0xfff7 */
#define PMC825_SOCKET_ERR     -10       /* 0xfff6 */
#define PMC825_NO_MSG         -11       /* 0xfff5 */
#define PMC825_BUF_OVERFLOW   -12       /* 0xfff4 */
#define PMC825_WSA_START_ERR  -13       /* 0xfff3 */

/*
 * Socket library function prototypes.
 */

#ifdef WIN32
#define EXPORT __declspec (dllexport)
#else
#define EXPORT 
#endif

EXPORT unsigned short Swap16(unsigned short in);
EXPORT unsigned int Swap32(unsigned int in);
EXPORT int Pmc825StartInterface(PMC825_IF *intf, unsigned int pm825_ip, unsigned int host_ip, int rx_port, int tx_port, int channel);
EXPORT void Pmc825StopInterface(PMC825_IF *intf);
EXPORT CANID ComposeArinc825Id(ARINC825_ID *id_struct);
EXPORT void DecodeArinc825Id(CANID id, ARINC825_ID *id_struct);
EXPORT int Pmc825RawCanRead(PMC825_IF *intf, CAN_MSG *msg);
EXPORT int Pmc825RawCanWrite(PMC825_IF *intf, CAN_MSG *msg, int msg_count);
EXPORT void Pmc825SwapMsgPkt(UDP_CAN_MSG_PKT *in, UDP_CAN_MSG_PKT *out, int dir);
EXPORT void Pmc825SwapCtrlPkt(UDP_CAN_CTRL_PKT *in, UDP_CAN_CTRL_PKT *out);
EXPORT void Pmc825SwapCtrlPktHdr(UDP_CAN_CTRL_PKT *in, UDP_CAN_CTRL_PKT *out);
EXPORT int Pmc825CtrlRead(PMC825_IF *intf, CTRL_MSG *ctrl_msg);
EXPORT int Pmc825CtrlWrite(PMC825_IF *intf, CTRL_MSG *ctrl_msg);
EXPORT int Pmc825CanAerospaceRead(PMC825_IF *intf, CAN_AS_MSG *msg);
EXPORT int Pmc825CanAerospaceWrite(PMC825_IF *intf, CAN_AS_MSG *msg, int msg_count);
EXPORT int Pmc825ListDirCmd(PMC825_IF *intf);
EXPORT int Pmc825DownloadResp(PMC825_IF *intf, UDP_DLOAD_DATA_PKT *dload_pkt);
EXPORT int Pmc825Arinc825Read(PMC825_IF *intf, ARINC825_MSG *msg);
EXPORT int Pmc825Arinc825Write(PMC825_IF *intf, ARINC825_MSG *msg, int msg_count);
EXPORT unsigned int Pmc825GetHostAddress(void);

/*
 * End of file.
 */
