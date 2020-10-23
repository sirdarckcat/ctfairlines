#include "obj_dir/VCDLS.h"
#include "verilated_vcd_c.h"
#include "pmc825socket.h"
#include "can_as.h"
#include <iostream>
#include <memory>
#include <bitset>
#include <valarray>
#include <unistd.h>


int clkcount = 0;
int dumpit = 0;

PMC825_IF Pmc825;

int ascii_to_keymap(char c) {
    if (c >= 'a' && c <= 'z')
        c -= 0x20;
    if (c >= 'A' && c <= 'Z')
        return c - 'A' + 4;
    if (c == '{') return 2;
    if (c == '}') return 3;
    return -1;
}

char keymap_to_ascii(int k) {
    if (k == 2) return '{';
    if (k == 3) return '}';
    return 'A' + k - 4;
}

void press_button(const std::unique_ptr<VCDLS> &top, int c) {
    top->matrix_w = c / 5; // MATRIX_H
    top->matrix_h = c % 5;
    top->do_eval = 0;
    top->eval();
    top->do_eval = 1;
    top->eval();
}


void reset(const std::unique_ptr<VCDLS> &top) {
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
  top->do_eval=0;
  top->eval();
  press_button(top,2);
  press_button(top,3);
  press_button(top,1);
  if (!top->locked) {
    std::cerr << "failed to lock reset" << std::endl;
    abort();
  }
  press_button(top,2);
  press_button(top,3);
  press_button(top,1);
}

int main(int argc, char *argv[]) {
    Verilated::commandArgs(argc, argv);
    auto top = std::make_unique<VCDLS>();
    // reset the door on boot.
    reset(top);
    // listen for messages for us on the canbus.
    int ret = Pmc825StartInterface(&Pmc825, 0xAC1404FF, 0xAC140410, 34567, 34568, 0);
    if (ret) {
      // failed to start interface.
      printf("oops\n");
      return 1;
    }
    CAN_AS_MSG rx_buf, tx_buf;
    while(1) {
      while(1) {
        ret = Pmc825CanAerospaceRead(&Pmc825, &rx_buf);
        if (ret == PMC825_NO_MSG) break;
        if (rx_buf.identifier == 1985) {
          // 1985 = CDLS_PRESS_BUTTON
          press_button(top, tx_buf.data[0]);
        }
      }
      // 1988 = CDLS_LEDS_STATUS
      tx_buf.identifier = 1988;
      tx_buf.byte_count = sizeof(int);
      tx_buf.frame_type = DATA;
      tx_buf.node_id = 50; // 50 = CDLS_NODE_ID
      tx_buf.data_type = AS_LONG;
      tx_buf.data[0] = top->lights;
      Pmc825CanAerospaceWrite(&Pmc825, &tx_buf, 1);
      usleep(50000); // sleep for 50ms
      top->eval();
    }
    return 0;
}
