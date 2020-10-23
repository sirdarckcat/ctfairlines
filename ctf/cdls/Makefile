INCLUDE_FLAGS=-Iobj_dir -I/usr/share/verilator/include/vltstd -I/usr/share/verilator/include -ICANflight_API/inc
VERILOG_INCLUDE=/usr/share/verilator/include

all: main

obj_dir/VCDLS.cpp: CDLS.sv
	verilator -Wall -cc CDLS.sv --top-module CDLS --trace --trace-depth 1 --no-trace-params

VCDLS_gen.cpp: ./obj_dir/VCDLS.cpp ./obj_dir/VCDLS__Trace.cpp ./obj_dir/VCDLS__Syms.cpp ./obj_dir/VCDLS__Trace__Slow.cpp
	cat $^ > $@

pmc825socket.o: CANflight_API/src/pmc825socket.c
	g++ -fpermissive -ICANflight_API/inc -c $< -o $@

main: cdls.cpp VCDLS_gen.cpp pmc825socket.o
	g++ ${INCLUDE_FLAGS} pmc825socket.o VCDLS_gen.cpp cdls.cpp ${VERILOG_INCLUDE}/verilated.cpp ${VERILOG_INCLUDE}/verilated_vcd_c.cpp -O2 -o main
