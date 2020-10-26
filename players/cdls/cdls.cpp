#include "obj_dir/VCDLS.h"
#include "verilated_vcd_c.h"
#include "pmc825socket.h"
#include "can_as.h"
#include <iostream>
#include <memory>
#include <bitset>
#include <valarray>
#include <unistd.h>

PMC825_IF Pmc825;

#define VEVAL(command) do{                          \
    command;                                        \
    top->do_eval = 0; top->eval();                  \
    top->do_eval = 1; top->eval();                  \
  } while(0)

void reset(const std::unique_ptr<VCDLS> &top) {
  VEVAL(top->rst=0);
  VEVAL(top->rst=1);
  VEVAL(top->rst=0);
  top->matrix_w=0;
  VEVAL(top->matrix_h=2);
  VEVAL(top->matrix_h=3);
  VEVAL(top->matrix_h=1);
  VEVAL(top->matrix_h=2);
  VEVAL(top->matrix_h=3);
  VEVAL(top->matrix_h=1);
  top->matrix_h=0;
}

void send_status(int status) {
  CAN_AS_MSG tx_buf;
  // 1988 = CDLS_STATUS
  tx_buf.identifier = 1988;
  tx_buf.byte_count = 4;
  tx_buf.frame_type = DATA;
  tx_buf.node_id = 50; // 50 = CDLS_NODE_ID
  tx_buf.data_type = AS_LONG;
  tx_buf.data[0] = status>>24;
  tx_buf.data[1] = status>>16;
  tx_buf.data[2] = status>>8;
  tx_buf.data[3] = status;
  Pmc825CanAerospaceWrite(&Pmc825, &tx_buf, 1);
}

int main(int argc, char *argv[]) {
    Verilated::commandArgs(argc, argv);
    auto top = std::make_unique<VCDLS>();
    Pmc825StartInterface(&Pmc825, 0xAC1404FF, 0xAC140410, 34568, 34568, 0);
    reset(top);
    fflush(stdout);
    CAN_AS_MSG rx_buf;
    int last_value = -1, force_send = 0;
    while(1) {
      while(1) {
        int ret = Pmc825CanAerospaceRead(&Pmc825, &rx_buf);
        if (ret == PMC825_NO_MSG) break;
        // 1985 = CDLS_PRESS_BUTTON
        if (rx_buf.identifier == 1985) {
          char c = rx_buf.data[0];
          top->matrix_w = c / 5;
          top->matrix_h = c % 5;
          top->do_eval = 0;
          top->eval();
          send_status(top->lights);
          top->do_eval = 1;
          top->eval();
          send_status(top->lights);
        }
      }
      fflush(stdout);
      usleep(50000);
    }
    return 0;
}
