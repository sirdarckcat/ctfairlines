########################################################################
# Makefile for Solaris applications                                    #
########################################################################
#                                                                      #
# (C) 2000 Stock flight Systems. All rights reserved.                  #
#                                                                      #
# This Makefile takes all files in the current directory which are     #
# defined as:                                                          #
#                                                                      #
#                   C_SOURCES   (.c - suffix)                          #
#                   HEADERS     (.h - suffix)                          #
#                                                                      #
# These files are compiled/linked with the GNU toolset to produce the  #
# executable.                                                          #
#                                                                      #
# MODIFICATIONS:                                                       #
#                                                                      #	
#	Date		Vers	Description		Name           #
#	---------------------------------------------------------      #
#	14.02.2000	1.0	Initial Vers.		M. Stock       #
#                                                                      #
########################################################################

.KEEP_STATE:

########################################################################
# Variables                                                            #
########################################################################

# The "C" modules to be processed:
# C_SOURCES = specified with call of this Makefile

# Application specific header files:
# HEADERS = specified with call of this Makefile

# Library files:
# LIB_OBJECTS = specified with call of this Makefile

# The executable:
# PROGRAM = specified with call of this Makefile

########################################################################
# Macros                                                               #
########################################################################

# General include files:
GEN_INC = ../inc

# "C" objects to be linked:
C_OBJECTS = $(C_SOURCES:.c=.o)

# Tools:
CC = gcc
ASM = as
LNK = gcc
LIB = gcc
CFLAGS = -c -g -static -DBSD_COMP -o $*.o -I$(GEN_INC)

########################################################################
# Rules                                                                #
########################################################################

%.o:	%.c
	$(CC) $(CFLAGS) $*.c

########################################################################
# Dependencies                                                         #
########################################################################

$(PROGRAM):	$(C_OBJECTS) $(LIB_OBJECTS)
		$(LNK) -o $(PROGRAM) $(C_OBJECTS) $(LIB_OBJECTS) $(LIBFLAGS)

########################################################################

lib:		$(C_OBJECTS)
		$(CC) -c $(C_OBJECTS) $(LIBFLAGS)

########################################################################

$*.o: $*.s

$(ASM_OBJECTS): $(INCLUDES) $(GEN_INC)

$*.o: $*.c

$(C_OBJECTS): $(HEADERS) $(GEN_INC)

########################################################################

clean:
	rm -f *.o *% *.bck *~

########################################################################
# End of Makefile                                                      #
########################################################################

