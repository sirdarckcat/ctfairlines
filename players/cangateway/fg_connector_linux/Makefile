PROJECT = fg_receiver
OBJS = $(BIN_DIR)/main.o $(BIN_DIR)/config.o $(BIN_DIR)/flightgear.o $(BIN_DIR)/interface_can.o CANflight_API/src/pmc825socket.o

SRC_DIR = src
BIN_DIR = build

GCC = gcc
CFLAGS = -Wall -pedantic -I/usr/include/libxml2 -Iinclude -ICANflight_API/inc -D__ON_LINUX__ -static
LIBS = -lxml2 -lcanaero -Llib/linux-x86_64/shared

all: $(PROJECT)

$(PROJECT): $(OBJS)
	$(GCC) $(OBJS) $(LIBS) -o $@

$(BIN_DIR)/%.o: $(SRC_DIR)/%.c
	$(GCC) $(CFLAGS) -c $< -o $@

CANflight_API/src/%.o: CANflight_API/src/%.c
	$(GCC) -ICANflight_API/inc -c $< -o $@

clean:
	rm -rf $(OBJS)

dep: $(OBJS:.o=.c)
	makedepend -fdepend $<

