/*******************************************************************************
* PMC825 UDP/IP Socket Interface Library                                       *
*                                                                              *
* (C) 2010-2011 Stock Flight Systems. All rights reserved.                     *
*                                                                              *
* Filename: pmc825socket.c                                                     *
*                                                                              *
* This file contains the UDP/IP socket interface library for the PMC825.       *
*                                                                              *
* Function names                                                               *
* ____________________________________________________________________________ *
*                                                                              *
* int Pmc825StartInterface(PMC825_IF *intf, unsigned int pm825_ip,             *
*                                           unsigned int host_ip,              *
*                                           int rx_port, int tx_port,          *
*                                           int channel)                       *
* void Pmc825StopInterface(PMC825_IF *intf)                                    *
* int Pmc825RawCanRead(PMC825_IF *intf, CAN_MSG *msg)                          *
* int Pmc825RawCanWrite(PMC825_IF *intf, CAN_MSG *msg, int msg_count)          *
* int Pmc825CanAerospaceRead(PMC825_IF *intf, CAN_AS_MSG *msg)                 *
* int Pmc825CanAerospaceWrite(PMC825_IF *intf, CAN_AS_MSG *msg, int msg_count) *
* int Pmc825Arinc825Read(PMC825_IF *intf, ARINC825_MSG *msg)                   *
* int Pmc825Arinc825Write(PMC825_IF *intf, ARINC825_MSG *msg, int msg_count)   *
* void Pmc825SwapMsgPkt(UDP_CAN_MSG_PKT *in, UDP_CAN_MSG_PKT *out, int dir)    *
* void Pmc825SwapCtrlPkt(UDP_CAN_CTRL_PKT *in, UDP_CAN_CTRL_PKT *out)          *
* void Pmc825SwapCtrlPktHdr(UDP_CAN_CTRL_PKT *in, UDP_CAN_CTRL_PKT *out)       *
* void Pmc825SwapStatusPkt(UDP_CAN_CTRL_PKT *in, UDP_CAN_CTRL_PKT *out)        *
* void Pmc825SwapDloadCmdPkt(UDP_DLOAD_CMD_PKT *in, UDP_LOAD_CTRL_PKT *out)    *
* void Pmc825SwapDloadRespPkt(UDP_DLOAD_DATA_PKT *in, UDP_DLOAD_DATA_PKT *out) *
* int Pmc825DownloadResp(PMC825_IF *intf, UDP_DLOAD_DATA_PKT *dload_pkt)       *
* int Pmc825CtrlRead(PMC825_IF *intf, CTRL_MSG *ctrl_msg)                      *
* int Pmc825CtrlWrite(PMC825_IF *intf, CTRL_MSG *ctrl_msg)                     *
* int Pmc825ListDirCmd(PMC825_IF *intf)                                        *
* int Pmc825DownloadCmd(PMC825_IF *intf, UDP_DLOAD_CMD_PKT *dload_cmd)         *
* unsigned int Pmc825GetHostAddress(void)                                      *
* CANID ComposeArinc825Id(ARINC825_ID *id_struct)                              *
* void DecodeArinc825Id(CANID id, ARINC825_ID *id_struct)                      *
* unsigned short Swap16(unsigned short in)                                     *
* unsigned short Swap32(unsigned short in)                                     *
*                                                                              *
* MODIFICATIONS:                                                               *
*                                                                              *
* When          Version      What                                  Who         *
* ____________________________________________________________________________ *
*                                                                              *
* 16.01.2010    1.0          Initial Version                       M. Stock    *
* 05.04.2010    1.1          Windoze support added                 M. Stock    *
* 16.06.2010    1.2          Pmc825SwapStatusPkt() added           M. Stock    *
* 05.08.2010    1.3          UPD receive buffer size set           M. Stock    *
* 09.08.2010    1.4          Swapxx() functions added              M. Stock    *
* 15.05.2011    1.5          File handling functions added         M. Stock    *
*                                                                              *
*******************************************************************************/

/*
 * Includes.
 */

#include "pmc825socket.h"
#include "can_as.h"
#include "arinc825.h"

/*
 * Local definitions.
 */

#define BIG2LITTLE      0
#define LITTLE2BIG      1

//#define PMC825_DEBUG
//#define PMC825_PRINT_RX_PACKET

/*
 * Globals.
 */

int first_loop;

/*
 * Swap16() and Swap32 perform Big/Little Endian conversion for 16 and 32
 * bit parameters.
 */

unsigned short Swap16(unsigned short in)
{
unsigned short tmp, out;
unsigned char *inbyte, *outbyte;

inbyte = (unsigned char *) &(in);
outbyte = (unsigned char *) &(tmp);

#ifdef LITTLE_ENDIAN
outbyte[0] = inbyte[1];
outbyte[1] = inbyte[0];
memcpy(&out, outbyte, 2);
#else
out = in;
#endif

return(out);
}

unsigned int Swap32(unsigned int in)
{
unsigned int tmp, out;
unsigned char *inbyte, *outbyte;

inbyte = (unsigned char *) &(in);
outbyte = (unsigned char *) &(tmp);

#ifdef LITTLE_ENDIAN
outbyte[0] = inbyte[3];
outbyte[1] = inbyte[2];
outbyte[2] = inbyte[1];
outbyte[3] = inbyte[0];
memcpy(&out, outbyte, 4);
#else
out = in;
#endif

return(out);
}

/*
 * CAN message packet conversion (Big Endian <-> Little Endian).
 */

void Pmc825SwapMsgPkt(UDP_CAN_MSG_PKT *in, UDP_CAN_MSG_PKT *out, int dir)
{
int loops, cloops;
unsigned char *outbyte, *inbyte;
char buf[MAX_IP_PKT_SIZE];
short msg_count;
UDP_CAN_MSG_PKT *tmp;

tmp = (UDP_CAN_MSG_PKT *) buf;

inbyte = (unsigned char *) &(in->frame_count);
outbyte = (unsigned char *) &(tmp->frame_count);

outbyte[0] = inbyte[3];
outbyte[1] = inbyte[2];
outbyte[2] = inbyte[1];
outbyte[3] = inbyte[0];

inbyte = (unsigned char *) &(in->opcode);
outbyte = (unsigned char *) &(tmp->opcode);

outbyte[0] = inbyte[1];
outbyte[1] = inbyte[0];

inbyte = (unsigned char *) &(in->msg_count);
outbyte = (unsigned char *) &(tmp->msg_count);

outbyte[0] = inbyte[1];
outbyte[1] = inbyte[0];

if (dir == LITTLE2BIG)
  msg_count = in->msg_count;
else
  msg_count = tmp->msg_count;

for (loops = 0; loops < msg_count; loops++)
  {
  inbyte = (unsigned char *) &(in->msg[loops].data[0]); 
  outbyte = (unsigned char *) &(tmp->msg[loops].data[0]);

  for (cloops = 0; cloops < 10; cloops++)
    *(outbyte++) = *(inbyte++);

  inbyte = (unsigned char *) &(in->msg[loops].msg_control);
  outbyte = (unsigned char *) &(tmp->msg[loops].msg_control);

  outbyte[0] = inbyte[1];
  outbyte[1] = inbyte[0];

  inbyte = (unsigned char *) &(in->msg[loops].msg_control);
  outbyte = (unsigned char *) &(tmp->msg[loops].msg_control);

  outbyte[0] = inbyte[3];
  outbyte[1] = inbyte[2];
  outbyte[2] = inbyte[1];
  outbyte[3] = inbyte[0];

  inbyte = (unsigned char *) &(in->msg[loops].identifier);
  outbyte = (unsigned char *) &(tmp->msg[loops].identifier);

  outbyte[0] = inbyte[3];
  outbyte[1] = inbyte[2];
  outbyte[2] = inbyte[1];
  outbyte[3] = inbyte[0];

  inbyte = (unsigned char *) &(in->msg[loops].can_status);
  outbyte = (unsigned char *) &(tmp->msg[loops].can_status);

  outbyte[0] = inbyte[1];
  outbyte[1] = inbyte[0];

  inbyte = (unsigned char *) &(in->msg[loops].error_counter);
  outbyte = (unsigned char *) &(tmp->msg[loops].error_counter);

  outbyte[0] = inbyte[1];
  outbyte[1] = inbyte[0];

  inbyte = (unsigned char *) &(in->msg[loops].time_stamp_hi);
  outbyte = (unsigned char *) &(tmp->msg[loops].time_stamp_hi);

  outbyte[0] = inbyte[3];
  outbyte[1] = inbyte[2];
  outbyte[2] = inbyte[1];
  outbyte[3] = inbyte[0];

  inbyte = (unsigned char *) &(in->msg[loops].time_stamp_lo);
  outbyte = (unsigned char *) &(tmp->msg[loops].time_stamp_lo);

  outbyte[0] = inbyte[3];
  outbyte[1] = inbyte[2];
  outbyte[2] = inbyte[1];
  outbyte[3] = inbyte[0];
  }

inbyte = (unsigned char *) &(tmp->frame_count);
outbyte = (unsigned char *) &(out->frame_count);

for (loops = 0; loops < (MSG_HDR_SIZE + sizeof(CAN_MSG) * msg_count); loops++)
  *(outbyte++) = *(inbyte++);
}

/*
 * Control message packet conversion (Big Endian <-> Little Endian).
 */

void Pmc825SwapCtrlPkt(UDP_CAN_CTRL_PKT *in, UDP_CAN_CTRL_PKT *out)
{
int loops, cloops;
unsigned char *outbyte, *inbyte;
char buf[MAX_IP_PKT_SIZE];
UDP_CAN_CTRL_PKT *tmp;

tmp = (UDP_CAN_CTRL_PKT *) buf;

inbyte = (unsigned char *) &(in->frame_count);
outbyte = (unsigned char *) &(tmp->frame_count);

outbyte[0] = inbyte[3];
outbyte[1] = inbyte[2];
outbyte[2] = inbyte[1];
outbyte[3] = inbyte[0];

inbyte = (unsigned char *) &(in->opcode);
outbyte = (unsigned char *) &(tmp->opcode);

outbyte[0] = inbyte[1];
outbyte[1] = inbyte[0];

inbyte = (unsigned char *) &(in->svc_rsp_code);
outbyte = (unsigned char *) &(tmp->svc_rsp_code);

outbyte[0] = inbyte[1];
outbyte[1] = inbyte[0];

for (loops = 0; loops < 256; loops++)
  {
  inbyte = (unsigned char *) &(in->arg[loops]); 
  outbyte = (unsigned char *) &(tmp->arg[loops]);

  outbyte[0] = inbyte[1];
  outbyte[1] = inbyte[0];
  }

inbyte = (unsigned char *) &(tmp->frame_count);
outbyte = (unsigned char *) &(out->frame_count);

for (loops = 0; loops < sizeof(UDP_CAN_CTRL_PKT); loops++)
  *(outbyte++) = *(inbyte++);
}

/*
 * Control message packet header conversion (Big Endian <-> Little Endian).
 */

void Pmc825SwapCtrlPktHdr(UDP_CAN_CTRL_PKT *in, UDP_CAN_CTRL_PKT *out)
{
int loops, cloops;
unsigned char *outbyte, *inbyte;
char buf[MAX_IP_PKT_SIZE];
UDP_CAN_CTRL_PKT *tmp;

tmp = (UDP_CAN_CTRL_PKT *) buf;

inbyte = (unsigned char *) &(in->frame_count);
outbyte = (unsigned char *) &(tmp->frame_count);

outbyte[0] = inbyte[3];
outbyte[1] = inbyte[2];
outbyte[2] = inbyte[1];
outbyte[3] = inbyte[0];

inbyte = (unsigned char *) &(in->opcode);
outbyte = (unsigned char *) &(tmp->opcode);

outbyte[0] = inbyte[1];
outbyte[1] = inbyte[0];

inbyte = (unsigned char *) &(in->svc_rsp_code);
outbyte = (unsigned char *) &(tmp->svc_rsp_code);

outbyte[0] = inbyte[1];
outbyte[1] = inbyte[0];

for (loops = 0; loops < 256; loops++)
  tmp->arg[loops] = in->arg[loops];

inbyte = (unsigned char *) &(tmp->frame_count);
outbyte = (unsigned char *) &(out->frame_count);

for (loops = 0; loops < sizeof(UDP_CAN_CTRL_PKT); loops++)
  *(outbyte++) = *(inbyte++);
}

/*
 * Data download command packet header conversion
 * (Big Endian <-> Little Endian).
 */

void Pmc825SwapDloadCmdPkt(UDP_DLOAD_CMD_PKT *in, UDP_DLOAD_CMD_PKT *out)
{
int loops, cloops;
unsigned char *outbyte, *inbyte;
char buf[MAX_IP_PKT_SIZE];
UDP_DLOAD_CMD_PKT *tmp;

tmp = (UDP_DLOAD_CMD_PKT *) buf;

inbyte = (unsigned char *) &(in->frame_count);
outbyte = (unsigned char *) &(tmp->frame_count);

outbyte[0] = inbyte[3];
outbyte[1] = inbyte[2];
outbyte[2] = inbyte[1];
outbyte[3] = inbyte[0];

inbyte = (unsigned char *) &(in->opcode);
outbyte = (unsigned char *) &(tmp->opcode);

outbyte[0] = inbyte[1];
outbyte[1] = inbyte[0];

inbyte = (unsigned char *) &(in->svc_rsp_code);
outbyte = (unsigned char *) &(tmp->svc_rsp_code);

outbyte[0] = inbyte[1];
outbyte[1] = inbyte[0];

for (loops = 0; loops < 12; loops++)
  tmp->fname[loops] = in->fname[loops];

inbyte = (unsigned char *) &(tmp->frame_count);
outbyte = (unsigned char *) &(out->frame_count);

for (loops = 0; loops < sizeof(UDP_DLOAD_CMD_PKT); loops++)
  *(outbyte++) = *(inbyte++);
}

/*
 * Data download response packet header conversion
 * (Big Endian <-> Little Endian).
 */

void Pmc825SwapDloadRespPkt(UDP_DLOAD_DATA_PKT *in, UDP_DLOAD_DATA_PKT *out)
{
int loops;
unsigned char *outbyte, *inbyte;
char buf[MAX_IP_PKT_SIZE];
UDP_DLOAD_DATA_PKT *tmp;

tmp = (UDP_DLOAD_DATA_PKT *) buf;

inbyte = (unsigned char *) &(in->frame_count);
outbyte = (unsigned char *) &(tmp->frame_count);

outbyte[0] = inbyte[3];
outbyte[1] = inbyte[2];
outbyte[2] = inbyte[1];
outbyte[3] = inbyte[0];

inbyte = (unsigned char *) &(in->opcode);
outbyte = (unsigned char *) &(tmp->opcode);

outbyte[0] = inbyte[1];
outbyte[1] = inbyte[0];

inbyte = (unsigned char *) &(in->svc_rsp_code);
outbyte = (unsigned char *) &(tmp->svc_rsp_code);

outbyte[0] = inbyte[1];
outbyte[1] = inbyte[0];

inbyte = (unsigned char *) &(in->byte_count);
outbyte = (unsigned char *) &(tmp->byte_count);

outbyte[0] = inbyte[1];
outbyte[1] = inbyte[0];

for (loops = 0; loops < tmp->byte_count; loops++)
  tmp->data[loops] = in->data[loops];

inbyte = (unsigned char *) &(tmp->frame_count);
outbyte = (unsigned char *) &(out->frame_count);

for (loops = 0; loops < sizeof(UDP_DLOAD_DATA_PKT); loops++)
  *(outbyte++) = *(inbyte++);
}

/*
 * Status message packet conversion (Big Endian <-> Little Endian).
 */

void Pmc825SwapStatusPkt(UDP_CAN_CTRL_PKT *in, UDP_CAN_CTRL_PKT *out)
{
int loops, cloops;
unsigned char *outbyte, *inbyte;
char buf[MAX_IP_PKT_SIZE];
UDP_CAN_CTRL_PKT *tmp;

tmp = (UDP_CAN_CTRL_PKT *) buf;

inbyte = (unsigned char *) &(in->frame_count);
outbyte = (unsigned char *) &(tmp->frame_count);

outbyte[0] = inbyte[3];
outbyte[1] = inbyte[2];
outbyte[2] = inbyte[1];
outbyte[3] = inbyte[0];

inbyte = (unsigned char *) &(in->opcode);
outbyte = (unsigned char *) &(tmp->opcode);

outbyte[0] = inbyte[1];
outbyte[1] = inbyte[0];

inbyte = (unsigned char *) &(in->svc_rsp_code);
outbyte = (unsigned char *) &(tmp->svc_rsp_code);

outbyte[0] = inbyte[1];
outbyte[1] = inbyte[0];

for (loops = 0; loops < 4; loops++)
  {
  inbyte = (unsigned char *) &(in->arg[loops]); 
  outbyte = (unsigned char *) &(tmp->arg[loops]);

  outbyte[0] = inbyte[1];
  outbyte[1] = inbyte[0];
  }

for (loops = 4; loops < 12; loops+=2)
  {
  inbyte = (unsigned char *) &(in->arg[loops]); 
  outbyte = (unsigned char *) &(tmp->arg[loops]);

  outbyte[0] = inbyte[3];
  outbyte[1] = inbyte[2];
  outbyte[2] = inbyte[1];
  outbyte[3] = inbyte[0];
  }

for (loops = 12; loops < 14; loops++)
  {
  inbyte = (unsigned char *) &(in->arg[loops]); 
  outbyte = (unsigned char *) &(tmp->arg[loops]);

  outbyte[0] = inbyte[1];
  outbyte[1] = inbyte[0];
  }

inbyte = (unsigned char *) &(in->arg[14]); 
outbyte = (unsigned char *) &(tmp->arg[14]);

outbyte[0] = inbyte[0];
outbyte[1] = inbyte[1];
outbyte[2] = inbyte[2];
outbyte[3] = inbyte[3];

for (loops = 16; loops < 256; loops++)
  tmp->arg[loops] = in->arg[loops];

inbyte = (unsigned char *) &(tmp->frame_count);
outbyte = (unsigned char *) &(out->frame_count);

for (loops = 0; loops < sizeof(UDP_CAN_CTRL_PKT); loops++)
  *(outbyte++) = *(inbyte++);
}

/*
 * DecodeArinc825Id() disassembles an ARINC 825 identifier.
 */

void DecodeArinc825Id(CANID id, ARINC825_ID *id_struct)
{
id_struct->lcc = (unsigned char) ((id >> 26) & 0x7);
id_struct->scfid = (unsigned char) ((id >> 19) & 0x7f);
id_struct->smt = (unsigned char) ((id >> 18) & 0x1);
id_struct->lcl = (unsigned char) ((id >> 17) & 0x1);
id_struct->pvt = (unsigned char) ((id >> 16) & 0x1);
id_struct->doc = (unsigned int) ((id >> 2) & 0x3fff);
id_struct->rci = (unsigned char) (id & 0x3);
id_struct->sfid = (unsigned char) ((id >> 9) & 0x7f);
id_struct->sid = (unsigned char) ((id >> 2) & 0x7f);
}

/*
 * ComposeArinc825Id() assembles an ARINC 825 identifier from the
 * ARINC825_ID identifier structure.
 */

CANID ComposeArinc825Id(ARINC825_ID *id_struct)
{
unsigned int id[9];
CANID arinc825_id;

id[0] = (unsigned int) ((id_struct->lcc << 26) & 0x1c000000);
id[1] = (unsigned int) ((id_struct->scfid << 19) & 0x03f80000);
id[2] = (unsigned int) ((id_struct->smt << 18) & 0x00040000);
id[3] = (unsigned int) ((id_struct->lcl << 17) & 0x00020000);
id[4] = ((unsigned int) (id_struct->pvt << 16) & 0x00010000);

if ((id_struct->lcc == NSC) || (id_struct->lcc == TMC))
  {
  id[5] = 0;
  id[6] = (unsigned int) (id_struct->rci & 0x00000003);
  id[7] = (unsigned int) ((id_struct->sfid << 9) & 0x0000fe00);
  id[8] = (unsigned int) ((id_struct->sid  << 2) & 0x000001fc);
  }
else
  {
  id[5] = (unsigned int) ((id_struct->doc << 2) & 0x0000fffc);
  id[6] = (unsigned int) (id_struct->rci & 0x00000003);
  id[7] = 0;
  id[8] = 0;
  }

arinc825_id = EXT_ID|id[0]|id[1]|id[2]|id[3]|id[4]|id[5]|id[6]|id[7]|id[8];
return(arinc825_id);
}

/*
 * Pmc825RawCanRead() reads all available data from the specified socket
 * interface and returns the next CAN message from the circular buffer in
 * a "raw" format (that is, without protocol specific formatting).
 */

int Pmc825RawCanRead(PMC825_IF *intf, CAN_MSG *msg)
{
static char rx_buf[MAX_IP_PKT_SIZE];
static char tmp_buf[MAX_IP_PKT_SIZE];
static UDP_CAN_MSG_PKT *msg_packet = (UDP_CAN_MSG_PKT *) &(tmp_buf[0]);
static UDP_CAN_CTRL_PKT *ctrl_packet = (UDP_CAN_CTRL_PKT *) &(tmp_buf[0]);
static UDP_DLOAD_DATA_PKT *dload_packet = (UDP_DLOAD_DATA_PKT *) &(tmp_buf[0]);
unsigned short opcode, version;
unsigned int frame_count;
int bytes, loops, i, ret = 0;
char swap[4];

/*
 * Read all available data from socket and write it to the circular buffers.
 */

bytes = recv(intf->rx_sock, &rx_buf, MAX_IP_PKT_SIZE, 0);

while (bytes > 0)
  {
#ifdef PMC825_PRINT_RX_PACKET
  if ((bytes > 0) && (rx_buf[7] != 7))
    {
    printf("\n%d bytes -> ", bytes);

    for (i = 0; i < bytes; i++)
      printf("%02x ", rx_buf[i] & 0xff);
    }
#endif

  for (loops = 0; loops < bytes; loops++)
    tmp_buf[loops] = rx_buf[loops+2];

#ifdef LITTLE_ENDIAN
  swap[0] = rx_buf[1];
  swap[1] = rx_buf[0];
  version = *(unsigned short *) &(swap[0]);

  swap[0] = rx_buf[5];
  swap[1] = rx_buf[4];
  swap[2] = rx_buf[3];
  swap[3] = rx_buf[2];
  frame_count = *(unsigned int *) &(swap[0]);

  swap[0] = rx_buf[7];
  swap[1] = rx_buf[6];
  opcode = *(unsigned short *) &(swap[0]);

  if (opcode == CAN_READ)
    {
    Pmc825SwapMsgPkt((UDP_CAN_MSG_PKT *) &tmp_buf,
                     (UDP_CAN_MSG_PKT *) &tmp_buf,
                     BIG2LITTLE);
    }
  else if ((opcode == CAN_WRITE_RSP) || (opcode == CAN_CTRL_RSP) ||
           (opcode == CAN_READ_RSP))
    {
    Pmc825SwapCtrlPkt((UDP_CAN_CTRL_PKT *) &tmp_buf,
                      (UDP_CAN_CTRL_PKT *) &tmp_buf);
    }
  else if (opcode == CAN_STATUS)
    {
    Pmc825SwapStatusPkt((UDP_CAN_CTRL_PKT *) &tmp_buf,
                        (UDP_CAN_CTRL_PKT *) &tmp_buf);
    }
  else if (opcode == HOST_DOWNLOAD_RESP)
    {
    Pmc825SwapDloadRespPkt((UDP_DLOAD_DATA_PKT *) &tmp_buf,
                           (UDP_DLOAD_DATA_PKT *) &tmp_buf);
    }
#else
  version = *(unsigned short *) &(rx_buf[0]);
  frame_count = *(unsigned int *) &(tmp_buf[0]);
  opcode = *(unsigned short *) &(tmp_buf[4]);
#endif

  /*
   * Check if frame was received in proper order.
   */

#ifdef PMC825_DEBUG
  if (first_loop == 1)
    {
    intf->last_frame_count = frame_count - 1;
    first_loop = 0;
    }

  if (intf->last_frame_count != 0xffffffff)
    {
    if (frame_count != (intf->last_frame_count + 1))
      {
      printf("Frame Count Error: Expected 0x%08x, Received 0x%08x\n",
             (intf->last_frame_count + 1), frame_count);
      }
    }
  else
    {
    if (frame_count != 0x00000000)
      {  
      printf("Frame Count Error: Expected 0x%08x, Received 0x%08x\n",
             (0, frame_count));
      }
    }
#endif

  intf->last_frame_count = frame_count;

  /*
   * Place the content of the received packet in the corresponding circular
   * buffer.
   */

  if (opcode == CAN_READ)
    {
    /*
     * Regular CAN message packet: Place the messages in the CAN buffer.
     */

    for (loops = 0; loops < msg_packet->msg_count; loops++)
      {
      intf->rx_can[intf->rx_write] = msg_packet->msg[loops];

      if (intf->rx_write >= (PMC825_RX_BUFSIZE - 1))
        intf->rx_write = 0;
      else
        intf->rx_write += 1;
      }
    }
  else if (opcode != HOST_DOWNLOAD_RESP)
    {
    /*
     * Control message packet: Place it in the corresponding buffer.
     */

    intf->ctrl_pkt[intf->ctrl_write] = *ctrl_packet;

    if (intf->ctrl_write >= (PMC825_CTRL_BUFSIZE - 1))
      intf->ctrl_write = 0;
    else
       intf->ctrl_write += 1;
    }
  else /* if (opcode == HOST_DOWNLOAD_RESP) */
    {
    /*
     * Download packet: Place it in the corresponding buffer.
     */

    intf->dload_pkt[intf->dload_write] = *dload_packet;

    if (intf->dload_write >= (PMC825_DLOAD_BUFSIZE - 1))
      intf->dload_write = 0;
    else
       intf->dload_write += 1;
    }
  bytes = recv(intf->rx_sock, &rx_buf, MAX_IP_PKT_SIZE, 0);
  }

/*
 * Finally, return the next message from the buffer.
 */

if (intf->rx_read != intf->rx_write)
  {
  *msg = intf->rx_can[intf->rx_read];

  if (intf->rx_read >= (PMC825_RX_BUFSIZE - 1))
    intf->rx_read = 0;
  else
    intf->rx_read += 1;

  ret = PMC825_OK;
  }
else
  ret = PMC825_NO_MSG;

return(ret);
}

/*
 * Pmc825CanAerospaceRead() returns the next CANaerospace message from the
 * circular buffer.
 */

int Pmc825CanAerospaceRead(PMC825_IF *intf, CAN_AS_MSG *msg)
{
return(Pmc825RawCanRead(intf, (CAN_MSG *) msg));
}

/*
 * Pmc825Arinc825Read() returns the next ARINC825 message from the
 * circular buffer.
 */

int Pmc825Arinc825Read(PMC825_IF *intf, ARINC825_MSG *msg)
{
CAN_MSG raw;
int ret, byte;
unsigned char *src_ptr, *dst_ptr;

ret = Pmc825RawCanRead(intf, (CAN_MSG *) &raw);

if (ret == PMC825_OK)
  {
  src_ptr = (unsigned char *) &(raw.data[0]);
  dst_ptr = (unsigned char *) &(msg->data[0]);

  for (byte = 0; byte < 12; byte++)
    dst_ptr[byte] = src_ptr[byte];

  src_ptr = (unsigned char *) &(raw.can_status);
  dst_ptr = (unsigned char *) &(msg->can_status);

  for (byte = 0; byte < 12; byte++)
    dst_ptr[byte] = src_ptr[byte];

  DecodeArinc825Id((CANID) raw.identifier, &(msg->identifier));
  }
return(ret);
}

/*
 * Pmc825CtrlRead() reads all available data from the specified socket
 * interface and returns the next control packet from the circular buffer.
 */

int Pmc825CtrlRead(PMC825_IF *intf, CTRL_MSG *ctrl_msg)
{
static char rx_buf[MAX_IP_PKT_SIZE];
static char tmp_buf[MAX_IP_PKT_SIZE];
static UDP_CAN_MSG_PKT *msg_packet = (UDP_CAN_MSG_PKT *) &(tmp_buf[0]);
static UDP_CAN_CTRL_PKT *ctrl_packet = (UDP_CAN_CTRL_PKT *) &(tmp_buf[0]);
static UDP_DLOAD_DATA_PKT *dload_packet = (UDP_DLOAD_DATA_PKT *) &(tmp_buf[0]);
unsigned short opcode, version;
unsigned int frame_count;
int bytes, loops, ret = 0;
char swap[4];

/*
 * Read all available data from socket and write it to the circular buffers.
 */

bytes = recv(intf->rx_sock, &rx_buf, MAX_IP_PKT_SIZE, 0);

while (bytes > 0)
  {
  for (loops = 0; loops < bytes; loops++)
    tmp_buf[loops] = rx_buf[loops+2];

#ifdef LITTLE_ENDIAN
  swap[0] = rx_buf[1];
  swap[1] = rx_buf[0];
  version = *(unsigned short *) &(swap[0]);

  swap[0] = rx_buf[5];
  swap[1] = rx_buf[4];
  swap[2] = rx_buf[3];
  swap[3] = rx_buf[2];
  frame_count = *(unsigned int *) &(swap[0]);

  swap[0] = rx_buf[7];
  swap[1] = rx_buf[6];
  opcode = *(unsigned short *) &(swap[0]);

  if (opcode == CAN_READ)
    {
    Pmc825SwapMsgPkt((UDP_CAN_MSG_PKT *) &tmp_buf,
                     (UDP_CAN_MSG_PKT *) &tmp_buf,
                     BIG2LITTLE);
    }
  else if ((opcode == CAN_WRITE_RSP) || (opcode == CAN_CTRL_RSP) ||
           (opcode == CAN_READ_RSP))
    {
    Pmc825SwapCtrlPkt((UDP_CAN_CTRL_PKT *) &tmp_buf,
                      (UDP_CAN_CTRL_PKT *) &tmp_buf);
    }
  else if (opcode == TARGET_LIST_DIR_RESP)
    {
    Pmc825SwapDloadCmdPkt((UDP_DLOAD_CMD_PKT *) &tmp_buf,
                          (UDP_DLOAD_CMD_PKT *) &tmp_buf);
    }
  else if (opcode == CAN_STATUS)
    {
    Pmc825SwapStatusPkt((UDP_CAN_CTRL_PKT *) &tmp_buf,
                        (UDP_CAN_CTRL_PKT *) &tmp_buf);
    }
  else if (opcode == HOST_DOWNLOAD_RESP)
    {
    Pmc825SwapDloadRespPkt((UDP_DLOAD_DATA_PKT *) &tmp_buf,
                           (UDP_DLOAD_DATA_PKT *) &tmp_buf);
    }
#else
  version = *(unsigned short *) &(rx_buf[0]);
  frame_count = *(unsigned int *) &(tmp_buf[0]);
  opcode = *(unsigned short *) &(tmp_buf[4]);
#endif

  /*
   * Check if frame was received in proper order.
   */

#ifdef PMC825_DEBUG
  if (first_loop == 1)
    {
    intf->last_frame_count = frame_count - 1;
    first_loop = 0;
    }

  if (intf->last_frame_count != 0xffffffff)
    {
    if (frame_count != (intf->last_frame_count + 1))
      {
      printf("Frame Count Error: Expected 0x%08x, Received 0x%08x\n",
             (intf->last_frame_count + 1), frame_count);
      }
    }
  else
    {
    if (frame_count != 0x00000000)
      {  
      printf("Frame Count Error: Expected 0x%08x, Received 0x%08x\n",
             (0, frame_count));
      }
    }
#endif

  intf->last_frame_count = frame_count;

  /*
   * Place the content of the received packet in the corresponding circular
   * buffer.
   */

  if (opcode == CAN_READ)
    {
    /*
     * Regular CAN message packet: Place the messages in the CAN buffer.
     */

    for (loops = 0; loops < msg_packet->msg_count; loops++)
      {
      intf->rx_can[intf->rx_write] = msg_packet->msg[loops];

      if (intf->rx_write >= (PMC825_RX_BUFSIZE - 1))
        intf->rx_write = 0;
      else
        intf->rx_write += 1;
      }
    }
  else if (opcode != HOST_DOWNLOAD_RESP)
    {
    /*
     * Control message packet: Place it in the control packet buffer.
     */

    intf->ctrl_pkt[intf->ctrl_write] = *ctrl_packet;

    if (intf->ctrl_write >= (PMC825_CTRL_BUFSIZE - 1))
      intf->ctrl_write = 0;
    else
       intf->ctrl_write += 1;
    }
  else /* if (opcode == HOST_DOWNLOAD_RESP) */
    {
    /*
     * Download packet: Place it in the corresponding buffer.
     */

    intf->dload_pkt[intf->dload_write] = *dload_packet;

    if (intf->dload_write >= (PMC825_DLOAD_BUFSIZE - 1))
      intf->dload_write = 0;
    else
       intf->dload_write += 1;
    }
  bytes = recv(intf->rx_sock, &rx_buf, MAX_IP_PKT_SIZE, 0);
  }

/*
 * Finally, return the next control message from the buffer.
 */

if (intf->ctrl_read != intf->ctrl_write)
  {
  ctrl_msg->opcode = intf->ctrl_pkt[intf->ctrl_read].opcode;
  ctrl_msg->svc_rsp_code = intf->ctrl_pkt[intf->ctrl_read].svc_rsp_code;

  for (loops = 0; loops < 256; loops++)
    ctrl_msg->arg[loops] = intf->ctrl_pkt[intf->ctrl_read].arg[loops];

  if (intf->ctrl_read >= (PMC825_CTRL_BUFSIZE - 1))
    intf->ctrl_read = 0;
  else
    intf->ctrl_read += 1;

  ret = PMC825_OK;
  }
else
  ret = PMC825_NO_MSG;

return(ret);
}

/*
 * Pmc825DownloadResp() reads all available data from the specified socket
 * interface and returns the next download response packet from the circular
 * buffer.
 */

int Pmc825DownloadResp(PMC825_IF *intf, UDP_DLOAD_DATA_PKT *dload_pkt)
{
static char rx_buf[MAX_IP_PKT_SIZE];
static char tmp_buf[MAX_IP_PKT_SIZE];
static UDP_CAN_MSG_PKT *msg_packet = (UDP_CAN_MSG_PKT *) &(tmp_buf[0]);
static UDP_CAN_CTRL_PKT *ctrl_packet = (UDP_CAN_CTRL_PKT *) &(tmp_buf[0]);
static UDP_DLOAD_DATA_PKT *dload_packet = (UDP_DLOAD_DATA_PKT *) &(tmp_buf[0]);
unsigned short opcode, version;
unsigned int frame_count;
int bytes, loops, ret = 0;
char swap[4];

/*
 * Read all available data from socket and write it to the circular buffers.
 */

bytes = recv(intf->rx_sock, &rx_buf, MAX_IP_PKT_SIZE, 0);

while (bytes > 0)
  {
  for (loops = 0; loops < bytes; loops++)
    tmp_buf[loops] = rx_buf[loops+2];

#ifdef LITTLE_ENDIAN
  swap[0] = rx_buf[1];
  swap[1] = rx_buf[0];
  version = *(unsigned short *) &(swap[0]);

  swap[0] = rx_buf[5];
  swap[1] = rx_buf[4];
  swap[2] = rx_buf[3];
  swap[3] = rx_buf[2];
  frame_count = *(unsigned int *) &(swap[0]);

  swap[0] = rx_buf[7];
  swap[1] = rx_buf[6];
  opcode = *(unsigned short *) &(swap[0]);

  if (opcode == CAN_READ)
    {
    Pmc825SwapMsgPkt((UDP_CAN_MSG_PKT *) &tmp_buf,
                     (UDP_CAN_MSG_PKT *) &tmp_buf,
                     BIG2LITTLE);
    }
  else if ((opcode == CAN_WRITE_RSP) || (opcode == CAN_CTRL_RSP) ||
           (opcode == CAN_READ_RSP))
    {
    Pmc825SwapCtrlPkt((UDP_CAN_CTRL_PKT *) &tmp_buf,
                      (UDP_CAN_CTRL_PKT *) &tmp_buf);
    }
  else if (opcode == TARGET_LIST_DIR_RESP)
    {
    Pmc825SwapDloadCmdPkt((UDP_DLOAD_CMD_PKT *) &tmp_buf,
                          (UDP_DLOAD_CMD_PKT *) &tmp_buf);
    }
  else if (opcode == CAN_STATUS)
    {
    Pmc825SwapStatusPkt((UDP_CAN_CTRL_PKT *) &tmp_buf,
                        (UDP_CAN_CTRL_PKT *) &tmp_buf);
    }
  else if (opcode == HOST_DOWNLOAD_RESP)
    {
    Pmc825SwapDloadRespPkt((UDP_DLOAD_DATA_PKT *) &tmp_buf,
                           (UDP_DLOAD_DATA_PKT *) &tmp_buf);
    }
#else
  version = *(unsigned short *) &(rx_buf[0]);
  frame_count = *(unsigned int *) &(tmp_buf[0]);
  opcode = *(unsigned short *) &(tmp_buf[4]);
#endif

  /*
   * Check if frame was received in proper order.
   */

#ifdef PMC825_DEBUG
  if (first_loop == 1)
    {
    intf->last_frame_count = frame_count - 1;
    first_loop = 0;
    }

  if (intf->last_frame_count != 0xffffffff)
    {
    if (frame_count != (intf->last_frame_count + 1))
      {
      printf("Frame Count Error: Expected 0x%08x, Received 0x%08x\n",
             (intf->last_frame_count + 1), frame_count);
      }
    }
  else
    {
    if (frame_count != 0x00000000)
      {  
      printf("Frame Count Error: Expected 0x%08x, Received 0x%08x\n",
             (0, frame_count));
      }
    }
#endif

  intf->last_frame_count = frame_count;

  /*
   * Place the content of the received packet in the corresponding circular
   * buffer.
   */

  if (opcode == CAN_READ)
    {
    /*
     * Regular CAN message packet: Place the messages in the CAN buffer.
     */

    for (loops = 0; loops < msg_packet->msg_count; loops++)
      {
      intf->rx_can[intf->rx_write] = msg_packet->msg[loops];

      if (intf->rx_write >= (PMC825_RX_BUFSIZE - 1))
        intf->rx_write = 0;
      else
        intf->rx_write += 1;
      }
    }
  else if (opcode != HOST_DOWNLOAD_RESP)
    {
    /*
     * Control message packet: Place it in the control packet buffer.
     */

    intf->ctrl_pkt[intf->ctrl_write] = *ctrl_packet;

    if (intf->ctrl_write >= (PMC825_CTRL_BUFSIZE - 1))
      intf->ctrl_write = 0;
    else
       intf->ctrl_write += 1;
    }
  else /* if (opcode == HOST_DOWNLOAD_RESP) */
    {
    /*
     * Download packet: Place it in the corresponding buffer.
     */

    intf->dload_pkt[intf->dload_write] = *dload_packet;

    if (intf->dload_write >= (PMC825_DLOAD_BUFSIZE - 1))
      intf->dload_write = 0;
    else
       intf->dload_write += 1;
    }
  bytes = recv(intf->rx_sock, &rx_buf, MAX_IP_PKT_SIZE, 0);
  }

/*
 * Finally, return the next download message from the buffer.
 */

if (intf->dload_read != intf->dload_write)
  {
  dload_pkt->opcode = intf->dload_pkt[intf->dload_read].opcode;
  dload_pkt->svc_rsp_code = intf->dload_pkt[intf->dload_read].svc_rsp_code;
  dload_pkt->byte_count = intf->dload_pkt[intf->dload_read].byte_count;

  if (dload_pkt->byte_count > DLOAD_PKT_SIZE)
    dload_pkt->byte_count = DLOAD_PKT_SIZE;

  for (loops = 0; loops < dload_pkt->byte_count; loops++)
    dload_pkt->data[loops] = intf->dload_pkt[intf->dload_read].data[loops];

  if (intf->dload_read >= (PMC825_DLOAD_BUFSIZE - 1))
    intf->dload_read = 0;
  else
    intf->dload_read += 1;

  ret = PMC825_OK;
  }
else
  ret = PMC825_NO_MSG;

return(ret);
}

/*
 * Pmc825RawCanWrite() sends raw CAN messages to the PMC825 for transmission.
 */

int Pmc825RawCanWrite(PMC825_IF *intf, CAN_MSG *msg, int msg_count)
{
UDP_CAN_MSG_PKT msg_pkt;
char tx_buf[MAX_IP_PKT_SIZE], *src_ptr, *dst_ptr;
int loops, pkt_size, ret;

if (msg_count > MAX_CAN_MSG_COUNT)
  ret = PMC825_BUF_OVERFLOW;
else
  {
  /*
   * Assemble the UDP/IP CAN message packet.
   */

  msg_pkt.opcode = CAN_WRITE;
  msg_pkt.frame_count = intf->tx_frame_count;
  intf->tx_frame_count += 1;
  msg_pkt.msg_count = (unsigned short) msg_count;
  pkt_size = MSG_HDR_SIZE + sizeof(CAN_MSG) * msg_pkt.msg_count;

  for (loops = 0; loops < msg_count; loops++)
    msg_pkt.msg[loops] = msg[loops];

#ifdef LITTLE_ENDIAN
  Pmc825SwapMsgPkt(&msg_pkt, &msg_pkt, LITTLE2BIG);
#endif

  src_ptr = (char *) &(msg_pkt.frame_count);
  dst_ptr = &(tx_buf[2]);

  for (loops = 0; loops < pkt_size; loops++)
    *(dst_ptr++) = *(src_ptr++);

  tx_buf[0] = 0x00;	/* Packet version = 0x0001 */
  tx_buf[1] = 0x01;

  send(intf->tx_sock, (char *) &(tx_buf[0]), pkt_size, 0);
  ret = PMC825_OK;
  }
return(ret);
}

/*
 * Pmc825CanAerospaceWrite() sends CANaerospace messages to the PMC825 for
 * transmission.
 */

int Pmc825CanAerospaceWrite(PMC825_IF *intf, CAN_AS_MSG *msg, int msg_count)
{
return(Pmc825RawCanWrite(intf, (CAN_MSG *) msg, msg_count));
}

/*
 * Pmc825Arinc825Write() sends ARINC825 messages to the PMC825 for
 * transmission.
 */

int Pmc825Arinc825Write(PMC825_IF *intf, ARINC825_MSG *msg, int msg_count)
{
int loops, byte;
unsigned char *src_ptr, *dst_ptr;
CAN_MSG raw[MAX_CAN_MSG_COUNT];

if (msg_count <= MAX_CAN_MSG_COUNT)
  {
  for (loops = 0; loops < msg_count; loops++)
    {
    dst_ptr = (unsigned char *) &(raw[loops].data[0]);
    src_ptr = (unsigned char *) &(msg[loops].data[0]);

    for (byte = 0; byte < 12; byte++)
      dst_ptr[byte] = src_ptr[byte];

    dst_ptr = (unsigned char *) &(raw[loops].can_status);
    src_ptr = (unsigned char *) &(msg[loops].can_status);

    for (byte = 0; byte < 12; byte++)
      dst_ptr[byte] = src_ptr[byte];

    raw[loops].identifier = ComposeArinc825Id(&(msg[loops].identifier));
    }
  return(Pmc825RawCanWrite(intf, (CAN_MSG *) &(raw[0]), msg_count));
  }
else
  return(PMC825_BUF_OVERFLOW);
}
  
/*
 * Pmc825CtrlWrite() sends control messages to the PMC825.
 */

int Pmc825CtrlWrite(PMC825_IF *intf, CTRL_MSG *ctrl_msg)
{
UDP_CAN_CTRL_PKT ctrl_pkt;
char tx_buf[MAX_IP_PKT_SIZE], *src_ptr, *dst_ptr;
unsigned int arg_count;
int loops, i, pkt_size, ret = PMC825_OK;

/*
 * Assemble the UDP/IP CAN message packet.
 */

ctrl_pkt.opcode = CAN_CTRL;
ctrl_pkt.frame_count = intf->tx_frame_count;
intf->tx_frame_count += 1;

switch (ctrl_msg->svc_rsp_code)
  {
  case INIT_CAN_CHIP:
    arg_count = 5;
    ctrl_pkt.svc_rsp_code = INIT_CAN_CHIP;

    for (loops = 0; loops < arg_count; loops++)
      ctrl_pkt.arg[loops] = ctrl_msg->arg[loops];
    break;

  case GET_CAN_STATUS:
    arg_count = 0;
    ctrl_pkt.svc_rsp_code = GET_CAN_STATUS;
    break;

  case RESET_TIME_STAMP:
    arg_count = 1;
    ctrl_pkt.svc_rsp_code = RESET_TIME_STAMP;
    ctrl_pkt.arg[0] = ctrl_msg->arg[0];
    break;

  case CONFIG_IP_INTERFACE:
    arg_count = 256;
    ctrl_pkt.svc_rsp_code = CONFIG_IP_INTERFACE;

    src_ptr = (char *) &(ctrl_msg->arg[0]);
    dst_ptr = (char *) &(ctrl_pkt.arg[0]);

    for (loops = 0; loops < arg_count*2; loops++)
      *(dst_ptr++) = *(src_ptr++);

    break;

  case GET_MODULE_INFO:
    arg_count = 0;
    ctrl_pkt.svc_rsp_code = GET_MODULE_INFO;
    break;

  case SET_MODULE_NAME:
    arg_count = 16;
    ctrl_pkt.svc_rsp_code = SET_MODULE_NAME;

    for (loops = 0; loops < arg_count; loops++)
      ctrl_pkt.arg[loops] = ctrl_msg->arg[loops];
    break;

  default:
    ret = PMC825_INVALID_CMD;
    break;
  }

if (ret != PMC825_INVALID_CMD)
  {
  pkt_size = MSG_HDR_SIZE + arg_count * 2;

#ifdef LITTLE_ENDIAN
  if ((ctrl_msg->svc_rsp_code == CONFIG_IP_INTERFACE) ||
      (ctrl_msg->svc_rsp_code == SET_MODULE_NAME))
    Pmc825SwapCtrlPktHdr(&ctrl_pkt, &ctrl_pkt);
  else
    Pmc825SwapCtrlPkt(&ctrl_pkt, &ctrl_pkt);
#endif

  src_ptr = (char *) &(ctrl_pkt.frame_count);
  dst_ptr = &(tx_buf[2]);

  for (loops = 0; loops < pkt_size; loops++)
    *(dst_ptr++) = *(src_ptr++);

  tx_buf[0] = 0x00;	/* Packet version = 0x0001 */
  tx_buf[1] = 0x01;

  send(intf->tx_sock, (char *) &(tx_buf[0]), pkt_size, 0);
  ret = PMC825_OK;
  }
return(ret);
}

/*
 * Pmc825DownloadCmd() sends a download command message to the PMC825.
 */

int Pmc825DownloadCmd(PMC825_IF *intf, UDP_DLOAD_CMD_PKT *dload_cmd)
{
UDP_DLOAD_CMD_PKT cmd_pkt;
char tx_buf[MAX_IP_PKT_SIZE], *src_ptr, *dst_ptr;
int loops, pkt_size, ret = PMC825_OK;

/*
 * Assemble the UDP/IP CAN message packet.
 */

cmd_pkt.opcode = dload_cmd->opcode;
cmd_pkt.frame_count = intf->tx_frame_count;
intf->tx_frame_count += 1;
cmd_pkt.svc_rsp_code = dload_cmd->svc_rsp_code;

src_ptr = (char *) &(dload_cmd->fname[0]);
dst_ptr = (char *) &(cmd_pkt.fname[0]);

for (loops = 0; loops < 12; loops++)
  *(dst_ptr++) = *(src_ptr++);

pkt_size = MSG_HDR_SIZE + 12;

#ifdef LITTLE_ENDIAN
Pmc825SwapDloadCmdPkt(&cmd_pkt, &cmd_pkt);
#endif

src_ptr = (char *) &(cmd_pkt.frame_count);
dst_ptr = &(tx_buf[2]);

for (loops = 0; loops < pkt_size; loops++)
  *(dst_ptr++) = *(src_ptr++);

tx_buf[0] = 0x00;	/* Packet version = 0x0001 */
tx_buf[1] = 0x01;

send(intf->tx_sock, (char *) &(tx_buf[0]), pkt_size, 0);
ret = PMC825_OK;

return(ret);
}

/*
 * Pmc825ListDirCmd() sends a "list directory" command to the PMC825.
 */

int Pmc825ListDirCmd(PMC825_IF *intf)
{
UDP_CAN_CTRL_PKT pkt;
char tx_buf[MAX_IP_PKT_SIZE], *src_ptr, *dst_ptr;
int loops;

/*
 * Assemble the UDP/IP message packet.
 */

pkt.opcode = TARGET_LIST_DIR_CMD;
pkt.frame_count = intf->tx_frame_count;
intf->tx_frame_count += 1;

#ifdef LITTLE_ENDIAN
Pmc825SwapCtrlPktHdr(&pkt, &pkt);
#endif

src_ptr = (char *) &(pkt.frame_count);
dst_ptr = &(tx_buf[2]);

for (loops = 0; loops < MSG_HDR_SIZE; loops++)
 *(dst_ptr++) = *(src_ptr++);

tx_buf[0] = 0x00;	/* Packet version = 0x0001 */
tx_buf[1] = 0x01;

send(intf->tx_sock, (char *) &(tx_buf[0]), MSG_HDR_SIZE, 0);

return(PMC825_OK);
}

/*
 * Pmc825StartInterface() sets up the socket communication with the PMC825,
 * initializes the interface structure and activates the link.
 */

int Pmc825StartInterface(PMC825_IF *intf, unsigned int pm825_ip,
                                          unsigned int host_ip,
                                          int rx_port, int tx_port,
                                          int channel)
{
struct sockaddr_in rxsock, txsock;
unsigned char *ucptr, cfg_str[32];
unsigned int ip[4];
CTRL_MSG tx_ctrl;
int loops;
int arg = 1;
int ret = 0;
int bufsize;
void *ptr;
unsigned long opt = 1;

#ifdef WIN32
WSADATA wsadata;

ret = WSAStartup (2, &wsadata);

if (ret != 0)
  ret = PMC825_WSA_START_ERR;
#endif

/*
 * Initialize structure variables.
 */

memset ((char *) &rxsock, 0, sizeof(rxsock));
memset ((char *) &txsock, 0, sizeof(rxsock));

intf->channel = channel;
intf->tx_frame_count = 0;
intf->last_frame_count = 0;
intf->rx_write = 0;
intf->rx_read = 0;
intf->ctrl_write = 0;
intf->ctrl_read = 0;
intf->dload_write = 0;
intf->dload_read = 0;

/*
 * Allocate memory for the circular buffers.
 */

ptr = malloc(PMC825_RX_BUFSIZE * sizeof(CAN_MSG));

if (ptr == NULL)
  ret = PMC825_MEM_ALLOC_ERR;
else
  intf->rx_can = (CAN_MSG *) ptr;

ptr = malloc(PMC825_TX_BUFSIZE * sizeof(CAN_MSG));

if (ptr == NULL)
  ret = PMC825_MEM_ALLOC_ERR;
else
  intf->tx_can = (CAN_MSG *) ptr;

ptr = malloc(PMC825_CTRL_BUFSIZE * sizeof(UDP_CAN_CTRL_PKT));

if (ptr == NULL)
  ret = PMC825_MEM_ALLOC_ERR;
else
  intf->ctrl_pkt = (UDP_CAN_CTRL_PKT *) ptr;

ptr = malloc(PMC825_DLOAD_BUFSIZE * sizeof(UDP_DLOAD_DATA_PKT));

if (ptr == NULL)
  ret = PMC825_MEM_ALLOC_ERR;
else
  intf->dload_pkt = (UDP_DLOAD_DATA_PKT *) ptr;

/*
 * Create the sockets.
 */

intf->rx_sock = socket(AF_INET, SOCK_DGRAM, 0);
  
if (intf->rx_sock < 0)
  ret = PMC825_SOCKET_ERR;

intf->tx_sock = socket(AF_INET, SOCK_DGRAM, 0);
  
if (intf->tx_sock < 0)
  ret = PMC825_SOCKET_ERR;

/*
 * Set the receive socket buffer size.
 */

bufsize = 100000;

ret = setsockopt(intf->rx_sock,SOL_SOCKET,SO_RCVBUF,&bufsize,sizeof(bufsize)); 

if (ret < 0)
  { 
#ifndef WIN32
  close(intf->tx_sock);
#else
  closesocket(intf->tx_sock);
  WSACleanup();
#endif
  ret = PMC825_SOCKET_ERR;
  }

/*
 * Set the TX socket to broadcast operation if specified.
 */

if ((pm825_ip & 0x000000ff) == 0x00000000)
  {
  ret=setsockopt(intf->tx_sock,SOL_SOCKET,SO_BROADCAST,(void*)&arg,sizeof(arg));

  if (ret < 0)
    { 
#ifndef WIN32
    close(intf->tx_sock);
#else
    closesocket(intf->tx_sock);
    WSACleanup();
#endif
    ret = PMC825_SOCKET_ERR;
    }
  }

/*
 * Set the socket to reuse the assigned address to prevent invocation problems.
 */

ret = setsockopt(intf->rx_sock, SOL_SOCKET, SO_REUSEADDR, &arg, sizeof(arg));

if (ret < 0)
  { 
#ifndef WIN32
  close(intf->rx_sock);
#else
  closesocket(intf->rx_sock);
  WSACleanup();
#endif
  ret = PMC825_SOCKET_ERR;
  }

ret = setsockopt(intf->tx_sock, SOL_SOCKET, SO_REUSEADDR, &arg, sizeof(arg));

if (ret < 0)
  { 
#ifndef WIN32
  close(intf->tx_sock);
#else
  closesocket(intf->tx_sock);
  WSACleanup();
#endif
  ret = PMC825_SOCKET_ERR;
  }

/*
 * Bind the receive socket to any IP address and the specified port number.
 */

rxsock.sin_family = AF_INET;
rxsock.sin_addr.s_addr = INADDR_ANY;
rxsock.sin_port = htons((unsigned short) rx_port); 

ret = bind(intf->rx_sock,(struct sockaddr *)&rxsock,sizeof(struct sockaddr_in));
  
if (ret < 0)
  { 
#ifndef WIN32
  close(intf->rx_sock);
#else
  closesocket(intf->rx_sock);
  WSACleanup();
#endif
  ret = PMC825_SOCKET_ERR;
  }

/*
 * Set the receive socket to non-blocking operation.
 */

#ifndef WIN32
ret = ioctl(intf->rx_sock, FIONBIO, &opt);
//ret = fcntl(intf->rx_sock, F_SETFL, FNDELAY);
#else
ret = ioctlsocket(intf->rx_sock, FIONBIO, &opt);
#endif

if (ret < 0)
  { 
#ifndef WIN32
  close(intf->rx_sock);
#else
  closesocket(intf->rx_sock);
  WSACleanup();
#endif
  ret = PMC825_SOCKET_ERR;
  }

/*
 * Perform connect for the transmit socket.
 */

txsock.sin_family = AF_INET;
txsock.sin_addr.s_addr = htonl(pm825_ip);
txsock.sin_port = htons((unsigned short) tx_port);

ret = connect(intf->tx_sock, (struct sockaddr *) &txsock,
              sizeof(struct sockaddr_in));
  
if (ret < 0)
  { 
#ifndef WIN32
  close(intf->tx_sock);
#else
  closesocket(intf->tx_sock);
  WSACleanup();
#endif
  }

/*
 * Activate the link.
 */

tx_ctrl.opcode = CAN_CTRL;
tx_ctrl.svc_rsp_code = CONFIG_IP_INTERFACE;

ucptr = (unsigned char *) &host_ip;

#ifdef LITTLE_ENDIAN
ip[0] = (unsigned int) ucptr[3];
ip[1] = (unsigned int) ucptr[2];
ip[2] = (unsigned int) ucptr[1];
ip[3] = (unsigned int) ucptr[0];
#else
ip[0] = (unsigned int) ucptr[0];
ip[1] = (unsigned int) ucptr[1];
ip[2] = (unsigned int) ucptr[2];
ip[3] = (unsigned int) ucptr[3];
#endif

sprintf(cfg_str, "IP%1d=%03d.%03d.%03d.%03d LS%1d=1",
        channel, ip[0], ip[1], ip[2], ip[3], channel);

#ifdef PMC825_DEBUG
printf("%s\n", cfg_str);
#endif

ucptr = (unsigned char *) &(tx_ctrl.arg[0]);

for (loops = 0; loops < 26; loops++)
  ucptr[loops] = cfg_str[loops];

for (loops = 26; loops < 256; loops++)
  ucptr[loops] = 0;

Pmc825CtrlWrite(intf, &tx_ctrl);

first_loop = 1;

return(ret);
}

/*
 * Pmc825StopInterface() frees all resources related to the specified interface.
 */

void Pmc825StopInterface(PMC825_IF *intf)
{
CTRL_MSG tx_ctrl;
unsigned char *ucptr, cfg_str[8];
int loops;
int ret;

#ifdef WIN32
WSADATA wsadata;

ret = WSAStartup (2, &wsadata);

if (ret != 0)
  ret = PMC825_WSA_START_ERR;
#endif

/*
 * Deactivate the link.
 */

tx_ctrl.opcode = CAN_CTRL;
tx_ctrl.svc_rsp_code = CONFIG_IP_INTERFACE;

sprintf(cfg_str, "LS%1d=0", intf->channel);

ucptr = (unsigned char *) &(tx_ctrl.arg[0]);

for (loops = 0; loops < 6; loops++)
  ucptr[loops] = cfg_str[loops];

for (loops = 6; loops < 256; loops++)
  ucptr[loops] = 0;

Pmc825CtrlWrite(intf, &tx_ctrl);

/*
 * Close all active sockets and free the allocated memory.
 */

#ifndef WIN32
close(intf->rx_sock);
close(intf->tx_sock);

#else
closesocket(intf->rx_sock);
closesocket(intf->tx_sock);
WSACleanup();
#endif
free(intf->rx_can);
free(intf->tx_can);
free(intf->ctrl_pkt);
free(intf->dload_pkt);
}

/*
 * Pmc825GetHostAddress() obtains the IP address of this host.
 */

unsigned int Pmc825GetHostAddress(void)
{ 
char name[256];
int i, len = 256;
unsigned int address;
struct hostent *hp;

#ifndef WIN32
gethostname(name, len);

if ((hp = gethostbyname(name)) == 0)
  {
  perror("Unknown Host");
  return(0);
  }

address = ((unsigned char)hp->h_addr[3]) |
           ((unsigned char)hp->h_addr[2]) <<  8	|
           ((unsigned char)hp->h_addr[1]) << 16	|
           ((unsigned char)hp->h_addr[0]) << 24;

return(address);
#else
WSADATA wsadata;

ret = WSAStartup (2, &wsadata);

if (ret != 0)
  ret = PMC825_WSA_START_ERR;

if (gethostname(name, sizeof(name)) == SOCKET_ERROR)
  return(0);

hp = gethostbyname(name);

if (hp == 0) 
  return(0);

if (hp->h_addr_list[0] != 0)
  {
  memcpy(&addr, hp->h_addr_list[0], sizeof(struct in_addr));
  return(ntohl(addr.S_un.S_addr));
  }
else
  return(0);
#endif
}

/*
 * End of file.
 */

