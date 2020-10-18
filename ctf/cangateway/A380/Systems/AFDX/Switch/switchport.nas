# ********** ********** ********** ********** ********** ********** ********** ********** ********** **********
# Copyright (C) 2005  Ampere K. [Hardraade]
#
# This file is protected by the GNU Public License.  For more details, please see the text file COPYING.
# ********** ********** ********** ********** ********** ********** ********** ********** ********** **********
# switchport.nas
# This Nasal script is an extension of the port object.  The SwitchPort object is specifically designed for the
#  ethernet switch (switch.nas) to use.
#  
# Class:
#  SwitchPort
#  	Methods:
#  	 new(id, prop)		- creates and returns a new instance of the switch-port object.
#  	 changeState(state)	- forces the state to change to the specified new state.  The states are as
#  	 			   follow:
#  	 			  * 1 : blocking
#  	 			  * 2 : listening
#  	 			  * 3 : learning
#  	 			  * 4 : forwarding
#  	 			  An additional two states are defined as follow:
#  	 			  * -1 : disabled
#  	 			  * 0 : initializing
#  	 			  Theoretically, you can reset the port by calling changeState(0), but this 
#  	 			   hasn't been tested thus it is not recommended.
#  	 flush()		- flushs the port and clears the buffers.
#  	 getCost()		- returns the root path cost of this port.
#  	 getID()		- returns the id of this port.
#  	 lastMessage()		- returns the last message received by this port.
#  	 previousState()	- retrives the previous state of the port.
#  	 setCost(cost)		- modifies the root path cost of this port.
#  	 setForwardDelay(delay) - sets the forward delay timer to the specified value.  Forward delay is the 
#  	 			  amount of time that the port will stay in listening or learning mode.
#  	 setMaxAge(age) 	- sets the amount of time that the port will stay in blocking mode.
#  	 update()		- updates the state according to the timer, and returns the new state.
# ********** ********** ********** ********** ********** ********** ********** ********** ********** **********
SwitchPort = {
	new : func(id, prop){
		obj = {};
		obj.parents = [SwitchPort, Port];
		
		# Instance varaibles:
		obj._cost = 0;
		obj._forwardDelay = 15;			# Forward delay timer.
		obj._id = id;
		obj._inputBuffer = Queue.new(); 	# Incoming buffer.
		obj._lastMessage = "";			# The last message received by the port.
		obj._lastMessageTime = 0;		# The time at which the last message was received.
		obj._nextUpdate = 0;			# Scheduler for next state increment.
		obj._outputBuffer = Queue.new();	# Outgoing buffer.
		obj._previousState = -1;		# The previous state of the port.
		obj._prop = prop;			# The location at which properties are stored.
		obj._maxAge = 20;			# The maximium age that the port will stay in blocking 
							#  mode.
		obj._role = 0;
		obj._state = 0;				# -1 = disabled, 0 = me.initializing, 1 = blocking, 
							# 2 = listening, 3 = learning, 4 = forwarding.
		
		return obj;
	},
	
	changeState : func(state){
		status = "";
		
		# Validate argument.
		if (state == nil){
			# Invalid time specification.
			return 0;
		}
		else {
#			if (size(state) == nil){
				# Remember previous state.
				me._previousState = me._state;
				me._state = state;
				
				
				
				me.echo("\t Port " ~ me._id ~ ": state changed to " ~ state ~ ".", 2);
#			}
#			else {
#				# Argument cannot be a string.
#				return -1;
#			}
		}
		
		# Update information on the property tree.
		if (me._state == -1){
			status = "Disabled";
		}
		elsif (me._state == 0){
			status = "Initializing";
		}
		elsif (me._state == 1){
			status = "Blocking";
		}
		elsif (me._state == 2){
			status = "Listening";
		}
		elsif (me._state == 3){
			status = "Learning";
		}
		elsif (me._state == 4){
			status = "Forwarding";
		}
		props.globals.getNode(me._prop ~ "/status").setValue(status);
		
		
		
		me.echo("\t Port " ~ me._id ~ ": current status is '" ~ status ~ "'.", 2);
		
		# Reset timer.
		curTime = props.globals.getNode("/sim/time/elapsed-sec[0]").getValue();
		if (me._state == 1){
			me._nextUpdate = curTime + me._maxAge;
		}
		else {
			me._nextUpdate = curTime + me._forwardDelay;
		}
		
		return state;
	},
	
	# Flush the buffers.
	flush : func{
		me._lastMessage = "";
		while (me._inputBuffer.isEmpty() == 0){
			# Dequeue messages to oblivian.
			me._inputBuffer.dequeue();
		}
	},
	
	update : func{
		# Get time from /sim/time/elapsed-sec[0].
		curTime = props.globals.getNode("/sim/time/elapsed-sec[0]").getValue();
		
#		me.echo("\t Port " ~ me._id ~ ": current elapsed time is " ~ curTime ~ ".", 3);
		
		if (me._state == 0){
			# Initialze the port on the property tree.
			
			
			
			me.echo("\t Port " ~ me._id ~ ": initializing... ", 2);
			me.init(me._prop, "status");
			me.echo("\t Port " ~ me._id ~ ": " ~ me._prop ~ "/status initialized on the property tree.", 3);
			me.init(me._prop, "incoming");
			me.echo("\t Port " ~ me._id ~ ": " ~ me._prop ~ "/incoming initialized on the property tree.", 3);
			me.init(me._prop, "outgoing");
			me.echo("\t Port " ~ me._id ~ ": " ~ me._prop ~ "/outgoing initialized on the property tree.", 3);
			
			# Increment state.
			me.changeState(me._state + 1);
		}
		else {
			if (me._state > -1 and me._state < 4){
				if (curTime > me._nextUpdate){
					# Increment state.
					me.changeState(me._state + 1);
				}
			}
		}
		
		return me._state;
	},
	
	# Accessors:
	
	# Override the dequeue() function in the port object.
	dequeue : func{
		if (me._inputBuffer.isEmpty()){
			return nil;
		}
		STP_MULTICAST = chr(01) ~ chr(80) ~ chr(194) ~ chr(0) ~ chr(0) ~ chr(0);	# 01 80 C2 00 00 00
		
		msg = me._inputBuffer.dequeue();
		me._lastMessage = msg;
		me._lastMessageTime = props.globals.getNode("/sim/time/elapsed-sec[0]").getValue();
		
		return msg;
	},
	
	getCost : func{
		return me._cost;
	},
	
	getID : func{
		return me._id;
	},
	
	lastMessage : func{
		return me._lastMessage;
	},
	
	lastMessageTime : func{
		return me._lastMessageTime;
	},
	
	previousState : func{
		return me._previousState;
	},
	
	# Modifiers:
	
	setCost : func(cost){
		# Validate argument.
		if (cost == nil){
			# Invalid cost specification.
			return 0;
		}
		else {
#			if (size(cost) == nil){
				me._cost = cost;
#			}
#			else {
#				# Argument cannot be a string.
#				return -1;
#			}
		}
	},
	
	setForwardDelay : func(delay){
		# Validate argument.
		if (delay == nil){
			# Invalid cost specification.
			return 0;
		}
		else {
#			if (size(delay) == nil){
				me._forwardDelay = delay;
#			}
#			else {
#				# Argument cannot be a string.
#				return -1;
#			}
		}
	},
	
	setMaxAge : func(age){
		# Validate argument.
		if (age == nil){
			# Invalid cost specification.
			return 0;
		}
		else {
#			if (size(age) == nil){
				me._maxAge = age;
#			}
#			else {
#				# Argument cannot be a string.
#				return -1;
#			}
		}
	}
}
# ********** ********** ********** ********** ********** ********** ********** ********** ********** **********