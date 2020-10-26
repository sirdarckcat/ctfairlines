# ********** ********** ********** ********** ********** ********** ********** ********** ********** **********
# Copyright (C) 2005  Ampere K. [Hardraade]
#
# This file is protected by the GNU Public License.  For more details, please see the text file COPYING.
# ********** ********** ********** ********** ********** ********** ********** ********** ********** **********
# This is an *OLD* implementation of a port object in Nasal.
# Class:
#  Port
#  	Methods:
#  	 new(prop)		- creates a new instance of the class.
#  	 enqueue(msg)		- enqueues a message to the outgoing buffer.
#  	 dequeue()		- dequeues a message from the incoming buffer.
#  	 lastBPDU()		- returns the last BPDU received by the port.
#  	 noIncoming()		- returns wether the incoming buffer is empty.
#  	 send() 		- sends out the messages contained in the outgoing buffer.
#  	 setVerbose(state)	- specifies the verbosness of the switch, with:
#  	 			  * 0 being silent.
#  	 			  * 1 generates warning messages only.
#  	 			  * 2 generates warning messages and generic debug messages.
#  	 			  * 3 generates warning messages, generic debug messages, and specific debug
#  	 			       messages.
#  	 toString()		- returns this port's location on the property tree.
# ********** ********** ********** ********** ********** ********** ********** ********** ********** **********
Port = {
	# Creates an instance of the port object.
	new : func(prop){
		obj = {};
		obj.parents = [Port];
		
		# prop cannot be empty.
		if (size(prop) == 0 or prop == nil){
			print ("Warning in port.nas: unable to create port.");
			print ("\t Reason: the user specified property is invalid.");
			return nil;
		}
		
		# Fix up argument.
		if (substr(prop, size(prop) - 1, size(prop) - 1) == "/"){
			prop = substr(prop, 0, size(prop) - 1);
		}
		
		# Instance variables:
		obj._incoming = Queue.new();	# Incoming buffer.
		obj._lastBPDU = "";
		obj._outgoing = Queue.new();	# Outgoing buffer.
		obj._outputBuffer = Queue.new();
		obj._prop = prop;		# The location at which properties are stored.
		
		return obj;
	},
	
	# Dequeues string message from the incoming buffer.
	dequeue : func{
		if (me._incoming.size() == 0){
			# Update buffer.
#			nodes = props.globals.getNode(me._prop ~ "/incoming").getChildren();
#			
#			foreach (node ; nodes){
#				me._incoming.enqueue(node.getValue());
#			}
			
			incomings = me.read();
			foreach (incoming ; incomings){
				me._incoming.enqueue(incoming);
			}
			
			# Flush the property tree.
			tmp = me.init(me._prop, "incoming");
			tmp.setValue(nil);
		}
		
		return me._incoming.dequeue();
	},
	
	# Enqueues string messages to the outgoing buffer.
	enqueue : func(msg){
		# Screen out empty message.
		if (size(msg) == 0 or msg == nil){
			return nil;
		}
		
		# Write to buffer.
		me._outputBuffer.enqueue(msg);
		me._outgoing.enqueue(msg);
	},
	
	init : func(prop, node){
#		#print (prop);
#		#print (node);
#		
#		# Initialize nodes on the property tree recursively.
#		tmp = props.globals.getNode(prop);
#		
#		if (tmp == nil){
#			pt = size(prop) - 1;
#			for (; pt > 1; pt = pt - 1){
#				if (substr(prop, pt, 1) == "/"){ break; }
#			}
#			if (pt > 0){
#				parent = substr(prop, 0, pt);
#				child = substr(prop, pt + 1);
#				tmp = me.init(parent, child);
#			}
#		}
#		setprop(prop, node, nil);
#		
#		return props.globals.getNode(prop ~ "/" ~ node);
		
		return props.globals.getNode(prop ~ "/" ~ node, 1);
	},
	
	# Returns whether the incoming buffer is empty.
	noIncoming : func{
		if (me._incoming.size() == 0){
#			nodes = props.globals.getNode(me._prop ~ "/incoming").getChildren();
#			
#			foreach (node ; nodes){
#				me._incoming.enqueue(node.getValue());
#			}
			
			incomings = me.read();
			foreach (incoming ; incomings){
				me._incoming.enqueue(incoming);
			}
			
			# Flush the property tree.
			tmp = me.init(me._prop, "incoming");
			tmp.setValue(nil);
		}
		
		return me._incoming.isEmpty();
	},
	
	# Sends out the messages that were enqueued in the outgoing buffer.
	send : func{
		count = 0;
		
		while (me._outgoing.size() > 0){
			# Write to property tree.
#			me.init(me._prop ~ "/outgoing", "msg[" ~ count ~ "]");
#			node = props.globals.getNode(me._prop ~ "/outgoing/msg[" ~ count ~ "]", 1);
			
			msg = me._outgoing.dequeue();
			
			if (msg == nil){
			}
			else {
#				node.setValue(msg);
				for (i = 0; i < size(msg); i = i + 1){
					node = props.globals.getNode(me._prop ~ "/outgoing/msg[" ~ count ~ "]", 1);
					count = count + 1;
					node.setIntValue(strc(msg, i));
				}
			}
			
#			count = count + 1;	
		}
	},
	
	# Reads and returns the messages in the input buffer.
	read : func{
		count = 0;
		finish = -1;
		out = [];
		dataSize = "";
		tmp = "";
		
		nodes = props.globals.getNode(me._prop ~ "/incoming").getChildren();
		
		foreach (node ; nodes){
			if (count == 0){
				dataSize = "";
				tmp = "";
				finish = -1;
			}
			elsif (count == 25){
				dataSize = dataSize ~ node.getValue();
			}
			elsif (count == 26){
				finish = count + asciiToDec(dataSize) + 4;
			}
			
			# Read a byte.
			tmp = tmp ~ chr(node.getValue());
			
			if (count >= finish + 4 and finish > -1){
				append(out, tmp);
				count = 0;
			}
			else{
				count = count + 1;
			}
		}
		
		if (size(out) == 0 and size(tmp) > 0){
			append(out, tmp);
		}
		
		return out;
	},
	
	toString : func{
		return me._prop;
	},
	
	# Misc. functions:
	
	# me.echo a string message according to the current verbose state.
	echo : func(message, verbose){
		if (me._verboseState == 0){
			# Do nothing.
			return nil;
		}
		elsif (verbose <= me._verboseState){
			print (message);
		}
	},
	
	# Modifies the verbose state.
	setVerbose : func(state){
		# State 0: Silent.
		# State 1: Warning messages only.
		# State 2: Warning + Generic Debug messages.
		# State 3: Warning + Generic Debug + Specific Debug messages.
		me._verboseState = state;
	}
};
# ********** ********** ********** ********** ********** ********** ********** ********** ********** **********