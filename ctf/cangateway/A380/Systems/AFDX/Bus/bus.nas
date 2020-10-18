# ********** ********** ********** ********** ********** ********** ********** ********** ********** **********
# Copyright (C) 2005  Ampere K. [Hardraade]
#
# This file is protected by the GNU Public License.  For more details, please see the text file COPYING.
# ********** ********** ********** ********** ********** ********** ********** ********** ********** **********
# bus.nas
# This Nasal script simulates the functions of an ethernet cable, by copying nodes from one section of the 
#  property tree to another.
# 
# Class:
#  Bus
#  	Methods:
#  	 new()			- Creates and returns a new instance of the bus object.
#  	 connect(port)		- Connects the bus to the given port.  If successful, returns the given port
#  	 			   object.  Otherwise, returns null.
#  	 disconnect(port)	- Disconnects the bus from the given port.  If successful, returns the given
#  	 			   port object.  Otherwise, returns null.
# X	 update()		- Run this functions to transfer data from one port to another.
# ********** ********** ********** ********** ********** ********** ********** ********** ********** **********
 
Bus = {
	# Creates and returns a new instance of the bus object.
	new : func{
		obj = {};
		obj.parents = [Bus];
		
		# Instance variables:
		obj._p1 = nil;		# Port 1.
		obj._p2 = nil;		# Port 2.
		
		return obj;
	},
	
	# Modifiers:
	
	# Connects the bus to the given port.
	connect : func(port){
		
		# Validate argument.
		if (port == nil){
			return nil;
		}
		
		# Look for the free end.
		if (me._p1 == nil){
			me._p1 = port;
		}
		elsif (me._p2 == nil){
			me._p2 = port;
			# Tie queues together.
			me._p1._inputBuffer = me._p2._outputBuffer;
			me._p2._inputBuffer = me._p1._outputBuffer;
		}
		else{
			return nil;
		}
		
		return port;
	},
	
	# Disconnects the bus from the given port.
	disconnect : func(port){
		# Validate argument.
		if (port == nil){
			return nil;
		}
		
		# Look for the occupied end.
		incoming = port.toString() ~ "/incoming";
		
		if (streq(port.toString(), me._p1.toString())){
			me._p1 = nil;
			# Sever queues.
			me._p1._inputBuffer = Queue.new();
			me._p2._inputBuffer = Queue.new();
		}
		elsif (streq(port.toString(), me._p2.toString())){
			me._p2 = nil;
		}
		else{
			return nil;
		}
		
		return port;
	},
	
#	# Transfers data from one port to another.
	update : func{
#		while (me._p2.noOutgoing() == 0){
#			me._p1._inputBuffer.enqueue(me._p2._outputBuffer.dequeue());
#		}
#		while (me._p1.noOutgoing() == 0){
#			me._p2._inputBuffer.enqueue(me._p1._outputBuffer.dequeue());
#		}
	}
};
# ********** ********** ********** ********** ********** ********** ********** ********** ********** **********