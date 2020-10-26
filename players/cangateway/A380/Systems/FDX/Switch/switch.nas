# ********** ********** ********** ********** ********** ********** ********** ********** ********** **********
# Copyright (C) 2005  Ampere K. [Hardraade]
#
# This file is protected by the GNU Public License.  For more details, please see the text file COPYING.
# ********** ********** ********** ********** ********** ********** ********** ********** ********** **********
# switch.nas
# This Nasal script simulates an ethernet switch.
# 
# Class:
#  Switch
#  	Methods:
#  	 new(name)		- creates and returns an instance of the switch object, with the specified name
#  	 			   as the identifier.
#  	 connect(bus, portID)	- connects the specified bus to the port with the given port ID.  Returns the 
#  	 			   modified bus if successful and returns null otherwise.
#  	 disconnect(bus, portID)- disconnects the specified bus from the given port.  Returns the modified bus
#  	 			   if the operation is successful and returns null otherwise.
#  	 getBridgeID()		- returns the bridge id of this switch.
#  	 getBpduMaxAge()	- returns the maximium time that this switch will keep a BPDU message.
#  	 getForwardDelay()	- returns the amount of time that the switch will stay at the listening or
#  	 			   learning state.
#  	 getHelloTime() 	- returns the time interval between each sending of a BPDU message.
#  	 getPortPriority()	- returns the priority of the specified port.
#  	 getPriority()		- returns the priority this switch is having.
#  	 getRootID()		- returns the Root's BridgeID in human readable format.
#  	 isRoot()		- returns whether this switch is the root switch.
#  	 setBpduMaxAge(age)	- specifies the maximium time that the switch will keep a BPDU message.
#  	 setForwardDelay(delay) - specifies the time that the switch will stay at the listening or learning
#  	 			   state.
#  	 setHelloTime(interval) - specifies the time interval between each BPDU broadcast.  (Applicable only if
#  	 			   this switch is also the root.)
#  	 setPriority(priority)	- sets the priority of this switch.
#  	 setVerbose(state)	- specifies the verbosness of the switch, with:
#  	 			  * 0 being silent.
#  	 			  * 1 generates warning messages only.
#  	 			  * 2 generates warning messages and generic debug messages.
#  	 			  * 3 generates warning messages, generic debug messages, and specific debug
#  	 			       messages.
#  	 update()		- this is the function to call for the switch to run through a cycle.
# ********** ********** ********** ********** ********** ********** ********** ********** ********** **********
Switch = {
# Sub-class:
	Comparator : {
		# Compare two strings as if they are base256 values.
		compare : func(val1, val2){
			if (size(val1) > size(val2)){
				return 1;
			}
			elsif (size(val1) < size(val2)){
				return -1;
			}
			
			i = 0;
			while (i < size(val1) and strc(val1, i) == strc(val2, i)){
				i = i + 1;
			}
			
			if (i >= size(val1) - 1){
				return 0;
			}
			elsif (strc(val1, i) < strc(val2, i)){
				return -1;
			}
			elsif (strc(val1, i) > strc(val2, i)){
				return 1;
			}
			else {
				return 0;
			}
		}
	},
# Methods:
	# ********** ********** ********** ********** ********** ********** ********** ********** **********
	# Actions:
	# ********** ********** ********** ********** ********** ********** ********** ********** **********
	
	# Creates and returns a new instance of the switch object, with the specified name as the identifier.
	new : func(name){
		if (name == nil or size(name) < 1){
			# Invalid name.
			# Force an error.  DO NOT REMOVE!
			die ("specified name is invalid.");
		}
		
		# Remove all slashes in name.
		parsed = "";
		for (i = size(name) - 1; i >= 0; i = i - 1){
			tmp = substr(name, i, 1);
			if (tmp == "/"){
				if (warning == 0){
					print ("Warning in switch.nas: Switch.new(name) expects a name, not a property.");
					print ("\t Slashes in 'name' were removed.");
				}
				warning = warning + 1;
			}
			else
			{
				tmp = substr(name, i, 1);
				
				if (tmp == nil){
					print ("Error while creating Switch " ~ name ~ ": substr(name, " ~ i ~ 
					", 1) returns null in string '" ~ name ~ "'.");
				}
				parsed = tmp ~ parsed;
			}
		}
		name = parsed;
		
		obj = {};
		obj.parents = [Switch];
		
		# Instance variables:
		
		# Switch related:
		obj._address = "";
		obj._cost = 19;
		obj._isRoot = 1;
		obj._name = name;
		obj._multicast = chr(01) ~ chr(80) ~ chr(194) ~ chr(0) ~ chr(0) ~ chr(0);	# 01 80 C2 00 00 00
		obj._priority = 32768;
		obj._stpState = 0;
		obj._verboseness = 0;
		
		# BPDU related:
		obj._localBpdu = BPDU.new("");
		obj._configBpdu = BPDU.new("");
		obj._configBpduExpiry = 0;
		
		# Buffer:
		obj._outgoingBuffer = Queue.new();
		
		# Flags:
		obj._broadcastBPDU = 0;
		obj._broadcastTC  = 0;
		obj._broadcastTCN = 0;
		obj._resetPorts = 0;
		
		# Mac address table:
		obj._addressTable = AddressTable.new();
		
		# Nodes where data are stored on the property tree:
		PARENT_DIR = "/systems/afdx/switches/";
		obj._PROP_BRIDGEID = props.globals.getNode(PARENT_DIR ~ "/" ~ name ~ "/bridgeID", 1);
		obj._PROP_CURTIME = props.globals.getNode("/sim/time/elapsed-sec[0]");
		obj._PROP_EXPIRY = props.globals.getNode(PARENT_DIR ~ "/" ~ name ~ "/bpdu-remaining-life-sec", 1);
		obj._PROP_ISROOT = props.globals.getNode(PARENT_DIR ~ "/" ~ name ~ "/is-root", 1);
			obj._PROP_ISROOT.setBoolValue(1);
		obj._PROP_PRIORITY = props.globals.getNode(PARENT_DIR ~ "/" ~ name ~ "/priority", 1);
			obj._PROP_PRIORITY.setIntValue(32768);
		obj._PROP_ROOTID = props.globals.getNode(PARENT_DIR ~ "/" ~ name ~ "/root-bridgeID", 1);
		obj._PROP_VERBOSENESS = props.globals.getNode(PARENT_DIR ~ "/" ~ name ~ "/verboseness", 1);
			obj._PROP_VERBOSENESS.setIntValue(1);
		
		# Ports related:
		obj._designatedPorts = [];
		obj._ports = [];
		obj._portsOccupied = [];
		obj._rootPort = -1;
		
		# Timers:
		obj._nextBpduBroadcast = 0;
		obj._nextInfoUpdate = 0;
		obj._nextPortActivityChk = 0;
		obj._stopTCbroadcast = 0;	# When to stop TC broadcasting.
		
		return obj;
	},
	
	# Connects the specified bus to the port with the given portID.  Returns the modified bus if the
	#  operation is successful.
	# Connects the specified bus to the port with the given port ID.
	connect : func(bus, portID){
		# Validate arguments.
		if (bus == nil or portID == nil){
			me.verbose ("Warning in Switch " ~ me._name ~ ": invalid argument given to " ~
				"connect(bus, portID).  Aborting.", 1);
			return nil;
		}
		
		# Check the port's existance.
		if (portID >= size(me._ports)){
			me.verbose ("Warning in Switch " ~ me._name ~ ": cannot connect bus to " ~ 
				"port[" ~ portID ~ "].  Aborting.", 1);
			me.verbose ("\t Reason: port[" ~ portID ~ "]" ~ "does not exist.", 2);
			return nil;
		}
		
		# Check whether the port is available.
		if (me._portsOccupied[portID] == 1){
			me.verbose ("Switch " ~ me._name ~ ": cannot connect bus to port[" ~ portID ~ 
				"] because the port is already occupied.", 2);
			return nil;
		}
		
		p = bus.connect(me._ports[portID]);			
		
		if (p == nil){
			me.verbose ("Switch " ~ me._name ~ ": failed to connected bus to port[" ~ portID ~ "].", 2);
			return nil;
		}
		else {
			me.verbose ("Switch " ~ me._name ~ ": successfully connected bus to port[" ~ portID ~ "].", 2);
			me._portsOccupied[portID] = 1;
		}
		
		return bus;
	},
	
	# Disconnects the specified bus to the port with the given portID.  Returns the removed bus if the 
	#  operation is successful.			
	disconnect : func(bus, portID){
		# Validate arguments.
		if (bus == nil or portID == nil){
			me.verbose ("Warning in Switch " ~ me._name ~ ": invalid argument given to " ~
				"disconnect(bus, portID).  Aborting.", 1);
			return nil;
		}
		
		# Check the port's existance.
		if (portID >= size(me._ports)){
			me.verbose ("Warning in Switch " ~ me._name ~ ": cannot disconnect bus from " ~ 
				"port[" ~ portID ~ "].  Aborting.", 1);
			me.verbose ("\t Reason: port[" ~ portID ~ "]" ~ "does not exist.", 2);
			return nil;
		}
		
		# Check whether the port is occupied.
		if (me._portsOccupied[portID] == 0){
			me.verbose ("Switch " ~ me._name ~ ": cannot remove bus from port[" ~ portID ~ 
				"] because the port is not occupied.", 2);
			return nil;
		}
		
		p = bus.disconnect(me._ports[portID]);
		
		if (p == nil){
			me.verbose ("Switch " ~ me._name ~ ": failed to disconnected bus from port[" ~ portID ~ "].", 2);
			return nil;
		}
		else {
			me.verbose ("Switch " ~ me._name ~ ": successfully disconnected bus from port[" ~ portID ~ "].", 2);
			me._portsOccupied[portID] = 0;
		}
		
		return bus;
	},
	
	# Cycles through the switch's program for one iteration.
	update : func{
		# Get current time.
		curTime = me._PROP_CURTIME.getValue();
		
		# Initialize the switch if this is the first run.
		if (size(me._ports) <= 0){
			me.init();
		}
		
		# When the configuration BPDU expires, do the followings:
		# - give the switch root status.
		# - reset configuration BPDU to local BPDU.
		# - reset designated ports.
		# - reset ports.
		if (curTime > me._configBpduExpiry){
			me._configBpdu = BPDU.new(me._localBpdu.toString());
			me._configBpduExpiry = curTime + me._localBpdu.getMaxAge();
			
			# Debug messages:
			me.verbose ("Switch " ~ me._name ~ ":", 2);
			me.verbose ("\t BPDU aged out.", 2);
			
			if (me._isRoot == 0){
				me._nextBpduBroadcast = 0;
				me._resetPorts = 1;
				me._stpState = 0;
				# Debug message:
				me.verbose ("\t regained root status.", 2);
			}
			foreach (p ; me._ports){
				me._designatedPorts[p.getID()] = 0;
			}
			
			# Give this switch root status.
			me._isRoot = 1;
			me._rootPort = -1;
			
			# Raise flag to transfer TCN.
			me._broadcastTCN = 1;
		}
		
		# Reset ports if flag is raised.
		if (me._resetPorts){
			foreach (p ; me._ports){
				p.changeState(1);
				p.flush();
			}
			me._resetPorts = 0;
		}
		
		# Lower the TC broadcasting flag if it is raised.
		if (me._broadcastTC == 1 and curTime >= me._stopTCbroadcast){
			me._broadcastTC = 0;
		}
		
		# Update address table.
		me._addressTable.update();
		
		# Send out BPDUs.
		if (me._nextBpduBroadcast >= 0 and curTime >= me._nextBpduBroadcast){
			if (me._isRoot){
				me.verbose ("Switch " ~ me._name ~ ": attempting to broadcast BPDU.", 2);
				me.sendBPDU();
				# Set up the next broadcast time.
				me._nextBpduBroadcast = curTime + me._localBpdu.getHelloTime();
			}
			else {
				me.verbose ("Switch " ~ me._name ~ ": attempting to forward BPDU.", 2);
				me.sendBPDU();
				# Since this switch is not root, forward time is not up to this switch.
				me._nextBpduBroadcast = -1;
			}
		}
		
		# Read the ports and take a list of ports.
		skipList = Queue.new();
		foreach (port ; me._ports){
			skipList = me.readPorts(port);
			
			# Block the port if it has been inactive.
			if (port.update() > 1 and me._isRoot == 0 and (curTime - port.lastMessageTime()) > me.getBpduMaxAge() * 2){
				if (me._designatedPorts[port.getID()] == 0){
					port.changeState(1);
				}
			}
		}
		
		# Write the ports and pass a long the list of ports as the function requires.
		me.writePorts(skipList);
		
		# Update switch's info.
		if (curTime > me._nextInfoUpdate){
			me._nextUpdateInfo = curTime + 1;
			
			# Update to/from property page.
			me.readPropPage();
			me.writePropPage();
			
			# Keep address table's aging time at 300.
			me._addressTable.setAgingTime(300);
		}
	},
	
	# ********** ********** ********** ********** ********** ********** ********** ********** **********
	# Accessors:
	# ********** ********** ********** ********** ********** ********** ********** ********** **********
	
	# Returns the bridge id of this switch.
	getBridgeID : func{
		return me._localBpdu.getBridgeID();
	},
	
	# Returns the amount of time that the switch will keep a BPDU message.
	getBpduMaxAge : func{
		return me._localBpdu.getMaxAge();
	},
	
	# Returns the amount of time that the switch will stay in the listening or learning state.
	getForwardDelay : func{
		return me._localBpdu.getForwardDelay();
	},
	
	# Returns the interval of each BPDU broadcast.
	getHelloTime : func{
		return me._localBpdu.getHelloTime();
	},
	
	# Returns the priority of the given port.
	getPortPriority : func(portID){
#		return me._ports[portID].getPriority();
	},
	
	# Returns the priority of this switch.
	getPriority : func{
		return me._priority;
	},
	
	# Returns the bridge id of root switch.
	getRootID : func{
		return me._configBpdu.getRootID();
	},
	
	# ********** ********** ********** ********** ********** ********** ********** ********** **********
	# Modifiers:
	# ********** ********** ********** ********** ********** ********** ********** ********** **********
	
	# Sets the specified value as the amount of time that the switch will keep a BPDU message.
	setBpduMaxAge : func(age){
		if (age == nil){
			print ("invalid age");
			return age;
		}
		if (age > 0 and age < 32768){
			me._localBpdu.setMaxAge(age);
			me._configBpduExpiry = me._PROP_CURTIME.getValue();
			
			foreach (port ; me._ports){
				port.setMaxAge(age);
			}
			return age;
		}
	},
	
	# Sets the specified value as the amount of time that the switch will stay in the listening or 
	#  learning state.
	setForwardDelay : func(delay){
		if (delay == nil){
			print ("invalid delay");
			return nil;
		}
		if (delay > 0 and delay < 32768){
			me._localBpdu.setForwardDelay(delay);
			me._configBpduExpiry = me._PROP_CURTIME.getValue();
			
			foreach (port ; me._ports){
				port.setForwardDelay(delay);
			}
			return delay;
		}
	},
	
	# Sets the specified value as the interval between each BPDU broadcast.
	setHelloTime : func(interval){
		if (interval == nil){
			return nil;
		}
		if (interval > 0 and interval < 32768){
			me._localBpdu.setHelloTime(interval);
			me._configBpduExpiry = me._PROP_CURTIME.getValue();
			return interval;
		}
	},
	
	# Sets the priority of the specified port to the given value.
	setPortPriority : func(portID, priority){
#		if (portID or priority == nil){
#			return nil;
#		}
#		if (priority > 0 and priority < 32768){
#			me._ports[portID].setPrioirty(priority);
#			return priority;
#		}
	},
	
	# Sets the priority of this switch to the given value.
	setPriority : func(priority){
		if (priority == nil){
			return nil;
		}
		elsif (priority > 66535){
			prioirty = 66535;
		}
		elsif (priority < 0){
			priority = 0;
		}
			
		me._priority = priority;
		me._PROP_PRIORITY.setIntValue(priority);
		pAscii = decToAscii(priority);
		while (size(pAscii) < 2){
			pAscii = "0" ~ pAscii;
		}
		me._localBpdu.setBridgeID(pAscii ~ me._address);
		me._localBpdu.setRootID(pAscii ~ me._address);
		
		# Speed up expiry.
		me._configBpduExpiry = me._PROP_CURTIME.getValue();
		return priority;
	},
	
	# Sets the verbosness of the switch.
	setVerbose : func(verbose){
		if (verbose == nil){
			return nil;
		}
		if (verbose >= 0){
			me._verboseness = verbose;
			me._PROP_VERBOSENESS.setIntValue(verbose);
			return verbose;
		}
	},
	
	# ********** ********** ********** ********** ********** ********** ********** ********** **********
	# Auxiliary functions:
	# ********** ********** ********** ********** ********** ********** ********** ********** **********
	
	# Convert the given BridgeID to a human readable format.
	bridgeIDReadable : func(bridgeID){
		if (bridgeID == nil){
			return "";
		}
		
		hexOut = "";
		for (i = 0; i < size(bridgeID); i = i + 2){
			tmp = asciiToDec(substr(bridgeID, i, 2));
			tmp1 = decToHex(tmp);
			while (size(tmp1) < 4){
				tmp1 = "0" ~ tmp1;
			}
			hexOut = hexOut ~ tmp1;
			if (i < size(bridgeID) - 2){
				hexOut = hexOut ~ ":";
			}
		}
		
		return hexOut;
	},
	
	# Returns -1 if the given BPDU is superior to the dynamic BPDU; 0 if the BPDU's are the same; 1 if the
	#  specified BPDU is inferior.  This function supports different modes.  These modes are:
	#  0 - compares all aspects of the BPDU's.
	#  1 - compares the bridge ID of the senders.
	#  2 - compares the root ID only.
	#  3 - compares the root path cost only.
	#  4 - compares the sender's port ID only.
	compareBPDU : func(bpdu, mode){
		# Skip if BPDU is null.
		if (bpdu == nil){
			me.verbose ("Warning in Switch " ~ me._name ~ ": bpdu passed to compareBPDU(bpdu, mode)" ~
				" cannot be null.  Aborting.", 1);
			return nil;
		}
		
#		# Compares sender's Bridge ID.  This is a special case, as 0 will be returned regardless of
#		#  mode.
#		if (mode == 0 or mode == 1){
#			bridgeIDdiff = me.Comparator.compare(bpdu.getBridgeID(), me._localBpdu.getBridgeID());
#			if (bridgeIDdiff < 0 or bridgeIDdiff > 0){
#				return bridgeIDdiff;
#			}
#			else {
#				return 0;
#			}
#		}
		
		# Compares root ID's.
		if (mode == 0 or mode == 2){
			rootIDdiff = me.Comparator.compare(bpdu.getRootID(), me._configBpdu.getRootID());
			if (rootIDdiff < 0 or rootIDdiff > 0){
				return rootIDdiff;
			}
			elsif (mode == 2){
				return 0;
			}
		}
		
		# Compares root path costs.
		if (mode == 0 or mode == 3){
			pathCost1 = bpdu.getRootPathCost();
			pathCost2 = me._configBpdu.getRootPathCost();
			
			if (pathCost1 < pathCost2){
				return -1;
			}
			elsif (pathCost1 > pathCost2){
				return 1;
			}
			elsif (mode == 3){
				return 0;
			}
		}
		
		# Compares port ID's.
		if (mode == 0 or mode == 4){
			portID1 = bpdu.getPortID();
			portID2 = me._configBpdu.getPortID();
			
			if (portID1 < portID2){
				return -1;
			}
			elsif (portID1 > portID2){
				return 1;
			}
			elsif (mode == 4){
				return 0;
			}
		}
		
		# If we get to this point, it means both BPDU's are the same.
		return 0;
	},
	
	# Intializes the switch.
	init : func{
		# Randomly create an address for the switch.
		me._address = chr(0) ~ chr(6) ~ chr(207);	# 00 06 CF RAND RAND RAND
		me._address = me._address ~ chr(rand() * 255) ~ chr(rand() * 255) ~ chr(rand() * 255);
		
		me.setPriority(me._priority);
		
		me.verbose ("Switch " ~ me._name ~ " was given the address " ~ me.bridgeIDReadable(me._localBpdu.getBridgeID()), 2);
		
		# Initialize ports.
		me._ports = me.initPort();
		foreach (port ; me._ports){
			append (me._portsOccupied, 0);
			append (me._designatedPorts, 1);
		}
		
		me.verbose ("Switch " ~ me._name ~ " has " ~ size(me._ports) ~ " ports initialized.", 2);
		
	},
	
	# Intializes the ports on the switch.
	initPort : func{
		MAX_PORTS = 16;
		
		# Create ports and return them in a vector.
		ports = [];
		
		for (i=0; i<MAX_PORTS; i=i+1){
			append(ports, SwitchPort.new(i, "/systems/afdx/switches/" ~ me._name ~ "/ports/port[" ~ i ~ "]"));
			ports[i].setForwardDelay(me._localBpdu.getForwardDelay());
			ports[i].setMaxAge(me._localBpdu.getMaxAge());
			ports[i].setVerbose(me._verboseness);
		}
		
		return ports;
	},
	
	# Extracts messages from the given port, and returns a log that indicates which port a message is
	#  from.
	readPorts : func(port){
		# Instance variables:
		curTime = me._PROP_CURTIME.getValue();
		fromPort = Queue.new();
		outgoings = Queue.new();
		
		# Update ports.
		portID = port.getID();
		state = port.update();
		
		# Cycle through each port.
		while (port.noIncoming() == 0){
			me.verbose ("Switch " ~ me._name ~ ":", 2);
			me.verbose ("\t Reading port " ~ portID ~ "...", 2);
			
			# Flags:
			wasBPDU = 0;
			
			# Extract message.
			incoming = Frame.new(port.dequeue());
			
			if (state >= 1){
				# Functions for state 1 (blocking) and above.
				# Test whether the incoming is a BPDU message.  If so, extract the information
				#  within the message, and update this switch's BPDU accordingly.
				if (incoming.getDestination() == me._multicast){
					# Raise flag:
					wasBPDU = 1;
					
					# Extract BPDU.
					newBPDU = BPDU.new(LLC.new(incoming.getData()).getData());
					newBPDU.setMessageAge(newBPDU.getMessageAge() + 1);
					newBPDU.setRootPathCost(newBPDU.getRootPathCost() + me._cost);
					
					# Debug messages:
					me.verbose ("\t received BPDU from ", me.bridgeIDReadable(me._configBpdu.getBridgeID()));
					me.verbose ("\t current BPDU's rootID: " , me.bridgeIDReadable(me._configBpdu.getRootID()),
						"\t incoming BPDU's rootID: ", me.bridgeIDReadable(newBPDU.getRootID()), 3);
					me.verbose ("\t current BPDU's bridgeID: " , me.bridgeIDReadable(me._localBpdu.getBridgeID()),
						"\t incoming BPDU's bridgeID: ", me.bridgeIDReadable(newBPDU.getBridgeID()), 3);
					me.verbose ("\t current BPDU's root path cost: " , (me._configBpdu.getRootPathCost()),
						"\t\t incoming BPDU's root path cost: ", (newBPDU.getRootPathCost()), 3);
					me.verbose ("\t current BPDU's portID: " , (me._configBpdu.getPortID()),
						"\t\t\t incoming BPDU's portID: ", (newBPDU.getPortID()), 3);
#					print ("\t " ~ (me._configBpduExpiry - curTime));
					
					# Check for TC, TCA or TCN messages.
					if (newBPDU.isTC()){
						me.verbose ("\t Received a TC message.", 2);
#print ("Switch " ~ me._name ~ " received a TC.");
						# Raise flag to broadcast TC messages.
						me._broadcastTC = 1;
						# Reduce aging time to ForwardDelay for a 
						#  period of MaxAge + ForwardDelay.
						me._addressTable.setAgingTime(me._configBpdu.getForwardDelay());
					}
					elsif (newBPDU.isTCA()){
#print ("Switch " ~ me._name ~ " received a TCA.");
						me.verbose ("\t Received a TCA message.", 2);
						# Lower flag and stop broadcasting TCN messages.
						me._broadcastTCN = 0;
					}
					elsif (newBPDU.isTCN()){
#print ("Switch " ~ me._name ~ " received a TCN.");
						me.verbose ("\t Received a TCN message.", 2);
						# Raise flags.
						me._broadcastTC = 1;
						if (me._isRoot == 0){
							me._broadcastTCN = 1;
						}
						# Suppose we are going to broadcast TC messages, 
						#  calculate stopping time.
						me._stopTCbroadcast = curTime + me._configBpdu.getForwardDelay() + me._configBpdu.getMaxAge();
						
						# Immediately forward one TCN to the root port.
						if (me._isRoot == 0){
							me._ports[me._rootPort].enqueue(incoming.toString());
						}
						
						# Sends out a TCA to this port.
						outgoingTCA = BPDU.new(me._configBpdu.toString());
						outgoingTCA.forceTCA();
						outgoingTCA.setPortID(portID);
						
						llc = LLC.new("");
						llc.setData(outgoingTCA.toString());
						
						frameTCA = Frame.new("");
						frameTCA.setDestination(me._multicast);
						frameTCA.setSource(me._address);
						frameTCA.setData(llc.toString());
						
						port.enqueue(frameTCA.toString());
						
						me.verbose ("\t Sent a TCA message.", 2);
					}
					
					# Filter out inferior BPDU's by comparing:
					# - root ID
					# - bridge ID
					# - root path cost
					# - port ID
					compResult = 0;
					redundant = 0;
					for (compMode = 2; compMode <= 4; compMode = compMode + 1){
						compResult = me.compareBPDU(newBPDU, compMode);
						if (compMode > 2 and me._isRoot == 0){
							# Root ID from both BPDU's are the same, but the path
							#  cost is different.  This is an indication that this
							#  port is a redundant connection to the root.
							redundant = 1;
						}
						if ((compResult == 0) == 0){
							break;
						}
					}
					
					me._designatedPorts[portID] = (compResult > 0);
					if (compResult < 0){
						# Change STP state.
						me._stpState = 1;
						
						# The incoming BPDU is superior.  Use it instead.
						me.verbose ("\t Received a superior BPDU.", 2);
						me.verbose ("\t Lost root status.", 2);
						
						# Lower flag.
						me._isRoot = 0;
						
						# Remember this port as the root port.
						me._rootPort = portID;
						
						# Remember path cost.
						port.setCost(newBPDU.getRootPathCost());
						
						# Calculate a new BPDU.
						me._configBpdu = BPDU.new(newBPDU.toString());
						#me._configBpdu.setBridgeID(me._localBpdu.getBridgeID());
						me._configBpduExpiry = curTime + me._configBpdu.getMaxAge();
						
						# Raise flag:
						# Forward a BPDU after this.
						me._nextBpduBroadcast = curTime;
						
						me.verbose ("\t\t New BPDU is calculated.", 3);
					}
					elsif (compResult > 0){
						# The incoming BPDU is inferior.  Keep the current BPDU.
						me.verbose ("\t Received an inferior BPDU.", 2);
						me.verbose ("\t Retained current status.", 2);
						
#						if (redundant == 1){
#							if ((state == 1) == 0){
#								me.verbose ("\t Redundant connection to root detected.", 2);
#								me.verbose ("\t Port " ~ portID ~ " is blocked.", 2);
#								
#								# Raise flag to broadcast TCN.
#								me._broadcastTCN = 1;
#							}
#							# Block the redundant port.
#							port.changeState(1);
#						}
					}
					else {
						# Change STP's state.
						if (me._stpState == 1){
							me._stpState = 2;
						}
						
						# The BPDU's are the same.
						me.verbose ("\t Received the same BPDU message from port " ~ portID, 2);
						me.verbose ("\t Switch will maintain current status.", 2);
						
						# Maintain current status.
						if (redundant == 1){
							if ((me._rootPort == portID) == 0){
								port.changeState(state);
							}
						}
						
						me._configBpduExpiry = curTime + me._configBpdu.getMaxAge();
						
						# Forward a BPDU after this.
						me._nextBpduBroadcast = curTime;
					}
				}
			}
			if (state >= 2){
				# Functions for state 2 (listening) and above.
				
				#  Nothing is performed while reading.
			}
			if (state >= 3){
				# Functions for state 3 (learning) and above.
				
				#  One function is not performed while reading.
				
				# Memorize the source address.
				tmp = me._addressTable.add(incoming.getSource(), portID, 
					curTime);
				
				
				
				if (tmp == nil){
					me.verbose ("\t Failed to add new address to the address table.", 2);
					me.verbose ("\t\t Reason: may be the address table already contains the entry.", 3);
				}
				else {
					me.verbose ("\t Updated the address table.", 2);
					me.verbose ("\t\t Address Table now contains " ~ me._addressTable.size() ~ 
						" entries.", 3);
				}
			}
			if (state >= 4){
				# Functions for state 4 (forwaring).
				
				# Check the previous state of the port.  If the state was not
				#  in forwarding previously, raise the TCN flag.
				if ((port.previousState() == state) == 0){
					me._broadcastTCN = 1;
					port.changeState(4);
				}
				
				# Put frames into the outgoing buffer and remember from which
				#  port the message was received.
				if (wasBPDU == 0){
					me._outgoingBuffer.enqueue(incoming);
					fromPort.enqueue(portID);
					
					me.verbose ("\t Received a frame and placed it in the outgoing buffer.", 2);
				}
			}
		}
		
		return fromPort;
	},
	
	# Reads the property page.
	readPropPage : func{
		priority = me._PROP_PRIORITY.getValue();
		if ((priority == me._priority) == 0){
			me.setPriority(priority);
		}
		verbose = me._PROP_VERBOSENESS.getValue();
		if ((verbose == me._verboseness) == 0){
			me.setVerbose(verbose);
		}
	},
	
	# Sends out BPDU's.
	sendBPDU : func{
		# Generate an outgoing BPDU first.
		
		# Set up broadcast address.
		destination = me._multicast;
		
		# Encapsulate the bpdu into the llc, then encapsulate the llc into a standard ethernet frame.
		#  Convert the ethernet frame to a string, then save the string in the port's output buffer:
		
		me._configBpdu.lowerFlags();
		if (me._isRoot){
			outgoingBPDU = BPDU.new(me._localBpdu.toString());
		}
		else {
			outgoingBPDU = BPDU.new(me._configBpdu.toString());
		}
		outgoingBPDU.setBridgeID(me._localBpdu.getBridgeID());
		# Let's assume everything in LLC are 0 for now, because I do not know how LLC works.
		llc = LLC.new("");
		llc.setControl(0);
		llc.setDSAP(0);
		llc.setSSAP(0);
		outgoingFrame = Frame.new("");
		outgoingFrame.setDestination(destination);
		outgoingFrame.setSource(me._address);
		
		llc.setData(outgoingBPDU.toString());
		outgoingFrame.setData(llc.toString());
		
		# Send out BPDU message to each port.
		foreach (port ; me._ports){
			portID = port.getID();
			state = port.update();
			
#			if ((me._isRoot == 1 and state >= 2) or (state >= 3)){
#				# Functions for state 2 (listening) or higher if the switch is the
#				#  root.
#				# Functions for state 3 (learning) or higher if the switch is not
#				#  the root.
			if (state >= 2){
				#  One function is not performed while writing.
				
				if (portID == me._rootPort){
					# This is a root port, so don't send out any BPDU from this
					#  port unless the BPDU is a TCN, or the outgoing BPDU is 
					#  superior to that from the root port.
					if (me._broadcastTCN and me._isRoot == 0){
#print ("Switch " ~ me._name ~ " sending TCN message");
						outgoingTCN = BPDU.new("");
						outgoingTCN.forceTCN();
						
						llc = LLC.new("");
						llc.setControl(0);
						llc.setDSAP(0);
						llc.setSSAP(0);
						llc.setData(outgoingTCN.toString());
						
						frameTCN = Frame.new("");
						frameTCN.setDestination(me._multicast);
						frameTCN.setSource(me._address);
						frameTCN.setData(llc.toString());
						
						# Enqueue the BPDU message into the port's outgoing
						#  buffer.
						port.enqueue(frameTCN.toString());
						
						me.verbose ("\t Wrote TCN to port " ~ portID ~ ".", 2);
					}
					elsif (me._broadcastTCN){
						# This is root.  Don't broadcast TCN.
						# Lower flag.
						me._broadcastTCN = 0;
					}
					else{
					
					
						me.verbose ("\t Port " ~ portID ~ ": cannot send BPDU to root port.", 2);
					}
				}
				elsif (me._designatedPorts[portID] == 0 and me._stpState >= 2){
					# Block this port.
					port.changeState(1);
					
					# Broadcast TCN.
					if (state == 4){
						me._broadcastTCN = 1;
					}
					
					me.verbose("\t redundant connection to root is detected", 2);
					me.verbose("\t port " ~ portID ~ " is blocked.", 2);
				}
				else {
					outgoingBPDU.setPortID(portID);
					llc.setData(outgoingBPDU.toString());
					outgoingFrame.setData(llc.toString());
					# Check if broadcastTC flag has been raised.  If so, send
					#  a TC message, but only do so if this switch is the root.
					if (me._broadcastTC){
						if (me._isRoot == 1){
							outgoingBPDU.forceTC();
							llc.setData(outgoingBPDU.toString());
							outgoingFrame.setData(llc.toString());
						}
						else {
							me._broadcastTC = 0;
						}
					}
					# Enqueue the BPDU message into the port's outgoing buffer.
					port.enqueue(outgoingFrame.toString());
					
					
					me.verbose ("\t Wrote BPDU to port " ~ portID ~ ".", 2);
				}
			}
			else {
				me.verbose ("\t No BPDU was sent.", 2);
				me.verbose ("\t\t Reason: Port's current state does not permit the transmission" ~
					" of BPDU's.", 3);
			}
		}
	},
	
	# Prints out a string message according to the current verbose state.
	verbose : func{
		argc = size(arg);
		verboseness = num(arg[argc - 1]);
		if (verboseness == nil){
			return nil;
		}
		
		if (me._verboseness == 0){
			return nil;
		}
		elsif (verboseness <= me._verboseness){
			out = "";
			for (i = 0; i < argc - 1; i = i + 1){
				out = out ~ arg[i];
			}
			print (out);
		}
	},
	
	# Write outgoing messages to the ports.  The fromPorts argument indicates when to skip a port.
	writePorts : func(skipPorts){
		while (me._outgoingBuffer.isEmpty == 0){
			# Using the destination address, compute a list of ports using the entries in our
			#  address table.  Write frames to these ports' output buffer if their port-state
			#  permitted.
			frame = me._outgoingBuffer.dequeue();
			skip = skipPorts.dequeue();
			destination = frame.getDestination();
			portID = me._addressTable.find(destination);
			
			# Setup a list of ports to send message to.
			ports = [];
			if (portID == nil){
				# The specified destination was not found.  Perform flooding.
				ports = me._ports;
				
				me.verbose("\t Address not found, flooding ports...", 3);
			}
			else {
				# The specified destination was found.
				append(ports, me._ports[portID]);
				
				me.verbose("\t Writing to port " ~ portID ~ "...", 3);
			}
			
			# Write the dequeued message to each port.	
			foreach (port ; ports){
				# Check port's state.
				state = port.update();
				
				if (state >= 4){
					# Functions for state 4 (forwarding).
					
					# Enqueue message to the port's outgoing buffer only if the message
					#  was from another port.
					if ((port.getID() == skip) == 0){
						port.enqueue(frame.toString());
					}
				}
			}
		}
	},
	
	# Updates the property page.
	writePropPage : func{
		me._PROP_BRIDGEID.setValue(me.bridgeIDReadable(me._localBpdu.getBridgeID()));
		#me._PROP_CURTIME = props.globals.getNode("/sim/time/elapsed-sec[0]");
		me._PROP_EXPIRY.setIntValue(me._configBpduExpiry - me._PROP_CURTIME.getValue());
		me._PROP_ISROOT.setBoolValue(me._isRoot);
		me._PROP_PRIORITY.setIntValue(me._priority);
		me._PROP_ROOTID.setValue(me.bridgeIDReadable(me._configBpdu.getRootID()));
	}
};
# ********** ********** ********** ********** ********** ********** ********** ********** ********** **********