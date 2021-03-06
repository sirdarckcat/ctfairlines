#include "pmc825socket.h"
#include "can_as.h"
#include <iostream>
#include <memory>
#include <bitset>
#include <valarray>
#include <unistd.h>

PMC825_IF Pmc825;

char ascii_to_keymap(char c) {
    if (c >= 'a' && c <= 'z')
        c -= 0x20;
    if (c >= 'A' && c <= 'Z')
        return c - 'A' + 4;
    if (c == '{') return 2;
    if (c == '}') return 3;
    return -1;
}

int push_button(char c) {
  printf("pressing %i\n", c);
  CAN_AS_MSG tx_buf;
  tx_buf.identifier = 1985;
  tx_buf.byte_count = 4;
  tx_buf.frame_type = DATA;
  tx_buf.node_id = 42; // 42 = MCDU
  tx_buf.data_type = AS_LONG;
  tx_buf.data[0] = c;
  tx_buf.data[1] = c;
  tx_buf.data[2] = c;
  tx_buf.data[3] = c;
  Pmc825CanAerospaceWrite(&Pmc825, &tx_buf, 1);
}

int main(int argc, char *argv[]) {
  if (Pmc825StartInterface(&Pmc825, 0xAC1404FF, 0xAC140408, 34567, 34568, 0)) {
    return 1;
  }
  if (argc < 1) {
    printf("Usage: \n    %s $COMBINATION\n\n", argv[0]);
  } else {
    for(int i=0; argv[1][i]; i++) {
      push_button(ascii_to_keymap(argv[1][i]));
    }
    push_button(1);
  }
  return 0;
}
