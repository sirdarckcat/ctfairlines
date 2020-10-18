# ********** ********** ********** ********** ********** ********** ********** ********** ********** **********
# Copyright (C) 2005  Ampere K. [Hardraade]
#
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General 
# Public License as published by the Free Software Foundation; either version 2 of the License, or (at your 
# option) any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the 
# implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
# 
# You should have received a copy of the GNU General Public License along with this program; if not, write to
# the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
# ********** ********** ********** ********** ********** ********** ********** ********** ********** **********
# bus.nas
# This is an outdated Nasal script that simulates the functions of an ethernet cable, by copying nodes from one 
# section of the property tree to another.
# 
# Class:
#  Bus
#  	Methods:
#  	 new()			- Creates and returns a new instance of the bus object.
#  	 connect(port)		- Connects the bus to the given port.  If successful, returns the given port
#  	 			   object.  Otherwise, returns null.
#  	 disconnect(port)	- Disconnects the bus from the given port.  If successful, returns the given
#  	 			   port object.  Otherwise, returns null.
#  	 update()		- Run this functions to transfer data from one port to another.
# ********** ********** ********** ********** ********** ********** ********** ********** ********** **********
 
Bus = {
	# Creates and returns a new instance of the bus object.
	new : func{
		obj = {};
		obj.parents = [Bus];
		
		# Instance variables:
		obj._incoming1 = "";	# First incoming path.
		obj._incoming2 = "";	# Second incoming path.
		obj._outgoing1 = "";	# First outgoing path.
		obj._outgoing2 = "";	# Second outgoing path.
		obj._p = nil;
		
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
		if (me._incoming1 == ""){
			me._p = port;
			prop = port.toString();
			me._incoming1 = (prop ~ "/incoming");
			me._outgoing1 = (prop ~ "/outgoing");
		}
		elsif (me._incoming2 == ""){
			prop = port.toString();
			me._incoming2 = (prop ~ "/incoming");
			me._outgoing2 = (prop ~ "/outgoing");
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
		
		if (streq(me._incoming1, incoming) == 1){
			me._incoming1 = "";
			me._outgoing1 = "";
		}
		elsif (streq(me._incoming2, incoming) == 1){
			me._incoming2 = "";
			me._outgoing2 = "";
		}
		else{
			return nil;
		}
		
		return port;
	},
	
	# Transfers data from one port to another.
	update : func{
		# Copy nodes from outgoing1 to incoming 2.
		msgCount = 0;
		outgoing = props.globals.getNode(me._outgoing1);
		nodes = outgoing.getChildren();
		
		foreach (node ; nodes){
			tmpNode = props.globals.getNode(me._incoming2 ~ "/msg[" ~ msgCount ~ "]", 1);
#			tmpNode.setValue(node.getValue());
			tmpNode.setIntValue(node.getValue());
			msgCount = msgCount + 1;
		}
		
if (me._p._outputBuffer.size() > 0){
	print ("outgoing " ~ me._p._outputBuffer.size());
}
		
		# Clean the outgoing node.
		outgoing.setValue(nil);
		
		# Copy nodes from outgoing2 to incoming 1.
		msgCount = 0;
		outgoing = props.globals.getNode(me._outgoing2);
		nodes = outgoing.getChildren();
		
		foreach (node ; nodes){
			tmpNode = props.globals.getNode(me._incoming1 ~ "/msg[" ~ msgCount ~ "]", 1);
#			tmpNode.setValue(node.getValue());
			tmpNode.setIntValue(node.getValue());
			msgCount = msgCount + 1;
		}
		
		if (msgCount > 0){
			print ("outgoing " ~ me._p._outputBuffer.size());
		}
		
		# Clean the outgoing node.
		outgoing.setValue(nil);
	}
};
# ********** ********** ********** ********** ********** ********** ********** ********** ********** **********