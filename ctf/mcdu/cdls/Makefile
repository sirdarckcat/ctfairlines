all: unlock

pmc825socket.o: CANflight_API/src/pmc825socket.c
	g++ -fpermissive -ICANflight_API/inc -c $< -o $@

unlock: pmc825socket.o unlock.cpp
	g++ -ICANflight_API/inc pmc825socket.o unlock.cpp -O2 -o $@
