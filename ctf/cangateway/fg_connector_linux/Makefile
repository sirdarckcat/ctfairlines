PROJECT = fg_receiver
OBJS = $(BIN_DIR)/main.o $(BIN_DIR)/config.o $(BIN_DIR)/flightgear.o $(BIN_DIR)/interface_can.o

SRC_DIR = src
BIN_DIR = build

GCC = gcc
CFLAGS = -Wall -pedantic -I/usr/include/libxml2 -Iinclude -D__ON_LINUX__ -static
LIBS = -lxml2 -lcanaero -Llib/linux-x86_64/shared

all: $(PROJECT)

$(PROJECT): $(OBJS)
	$(GCC) $(OBJS) $(LIBS) -o $@

$(BIN_DIR)/%.o: $(SRC_DIR)/%.c
	$(GCC) $(CFLAGS) -c $< -o $@

clean:
	rm -rf $(OBJS)

dep: $(OBJS:.o=.c)
	makedepend -fdepend $<

