#include "obj_dir/VCDLS.h"
#include "verilated_vcd_c.h"
#include <iostream>
#include <memory>
#include <bitset>
#include <valarray>

int clkcount = 0;
int dumpit = 0;

int ascii_to_keymap(char c) {
    if (c >= 'a' && c <= 'z')
        c -= 0x20;
    if (c >= 'A' && c <= 'Z')
        return c - 'A' + 4;
    if (c == '{') return 2;
    if (c == '}') return 3;
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
  top->reset = 0;
  top->do_eval = 0;
  top->eval();
  top->reset = 1;
  top->do_eval = 0;
  top->eval();
  top->reset = 1;
  top->do_eval = 1;
  top->eval();
  top->reset = 0;
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
    // listen for messages for us on the canbus
    // press_button -> return press_button_ok
    // get_status -> return is_locked and debug
    return 0;
}
