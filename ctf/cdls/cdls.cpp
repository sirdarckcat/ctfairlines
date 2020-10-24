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

int reset(const std::unique_ptr<VCDLS> &top) {
  top->rst = 0;
  top->do_eval = 0;
  top->eval();
  top->rst = 1;
  top->do_eval = 0;
  top->eval();
  top->rst = 1;
  top->do_eval = 1;
  top->eval();
  top->rst = 0;
  top->do_eval = 1;
  top->eval();
  top->do_eval = 0;
  top->eval();
  top->matrix_w = 0;
  top->matrix_h = 2;
  top->do_eval = 1;
  top->eval();
  top->do_eval = 0;
  top->matrix_h = 3;
  top->do_eval = 1;
  top->eval();
  top->do_eval = 0;
  top->matrix_h = 1;
  top->do_eval = 1;
  top->eval();
  top->do_eval = 0;
  if (!top->locked) {
    return 1;
  }
  top->matrix_h = 2;
  top->do_eval = 1;
  top->eval();
  top->do_eval = 0;
  top->matrix_h = 3;
  top->do_eval = 1;
  top->eval();
  top->do_eval = 0;
  top->matrix_h = 1;
  top->do_eval = 1;
  top->eval();
  top->do_eval = 0;
}

int main(int argc, char *argv[]) {
    Verilated::commandArgs(argc, argv);
    auto top = std::make_unique<VCDLS>();
    int ret = Pmc825StartInterface(&Pmc825, 0xAC1404FF, 0xAC140410, 34567, 34568, 0);
    if (reset(top) || ret) {
      printf("Failed to start\n");
      return 1;
    }
    CAN_AS_MSG rx_buf, tx_buf;
    int last_value = -1, force_send = 0;
    while(1) {
      while(1) {
        ret = Pmc825CanAerospaceRead(&Pmc825, &rx_buf);
        if (ret == PMC825_NO_MSG) break;
        if (rx_buf.identifier == 1985) {
          // 1985 = CDLS_PRESS_BUTTON
          int c = tx_buf.data[0];
          top->matrix_w = c / 5;
          top->matrix_h = c % 5;
          top->do_eval = 0;
          top->eval();
          top->do_eval = 1;
          top->eval();
          force_send = 1;
        }
      }
      if (top->lights != last_value || force_send) {
        // 1988 = CDLS_LEDS_STATUS
        tx_buf.identifier = 1988;
        tx_buf.byte_count = 4;
        tx_buf.frame_type = DATA;
        tx_buf.node_id = 50; // 50 = CDLS_NODE_ID
        tx_buf.data_type = AS_LONG;
        tx_buf.data[0] = top->lights;
        Pmc825CanAerospaceWrite(&Pmc825, &tx_buf, 1);
        force_send = 0;
      }
      usleep(50000);
      top->eval();
    }
    return 0;
}
