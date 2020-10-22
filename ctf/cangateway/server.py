import socket
import time
import struct

rx = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
rx.bind(("0.0.0.0", 34567))
csocks = []

while True:
    data, address = rx.recvfrom(1024)
    tx = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    tx.sendto("\x00\x01%s\x00\x06\x00\x00\x00\x00"%(data[2:6]), (address[0], 34568))
    tx.sendto("\x00\x01%s\x00\x07\x00\x00"
              "\x00\x18" # status reg
              "\x00\x00" # error cnt
              "\x10\x01" # bit timing
              "\x01\x00" # cpm mode
              "\x00\x00\x00\x01" # tx can bits
              "\x00\x00\x00\x01" # rx can bits
              "\x00\x00\x00\x01" # tx can msgs
              "\x00\x00\x00\x01" # rx can msgs
              "\x00\x11" # board temp
              "\x00\x11" # board temp
              "\x7f\x00\x00\x01" # ip addr
              "%s" # name
              "\x00\x01" # cpm buff
              ""%(
                  struct.pack(">I", 1),
                  "x"*32
              ), (address[0], 34568))
