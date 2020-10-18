# ********** ********** ********** ********** ********** ********** ********** ********** ********** **********
# Copyright (C) 2005  Ampere K. [Hardraade]
#
# This file is protected by the GNU Public License.  For more details, please see the text file COPYING.
# ********** ********** ********** ********** ********** ********** ********** ********** ********** **********
BPDU = {
	# Parse a string to create an instance of the BPDU format.
	new : func(data){
		obj = {};
		obj.parents = [BPDU];
		
		tmp = [];
		
		if (size(data) == 35){
			# Protocol Identifer (2 bytes)
			id = strc(data, 0) + strc(data, 1);
			
			if (id == 0){
				# Protocol Identifier (2 bytes)
				append(tmp, substr(data, 0, 2));
				# Version (1 byte)
				append(tmp, substr(data, 2, 1));
				# Message type (1 byte)
				append(tmp, substr(data, 3, 1));
				# Flags (1 byte)
				append(tmp, substr(data, 4, 1));
				# RootID (8 bytes)
				append(tmp, substr(data, 5, 8));
				# Root path cost (4 bytes)
				append(tmp, substr(data, 13, 4));
				# BridgeID (8 bytes)
				append(tmp, substr(data, 17, 8));
				# PortID (2 bytes)
				append(tmp, substr(data, 25, 2));
				# Message age (2 bytes)
				append(tmp, substr(data, 27, 2));
				# Maximium age (2 bytes)
				append(tmp, substr(data, 29, 2));
				# Hello time (2 bytes)
				append(tmp, substr(data, 31, 2));
				# Forward delay (2 bytes)
				append(tmp, substr(data, 33, 2));
			}
		}
		
		if (size(tmp) == 0){
			# Protocol Identifier (2 bytes)
			append(tmp, chr(0) ~ chr(0));
			# Version (1 byte)
			append(tmp, chr(0));
			# Message type (1 byte)
			append(tmp, chr(0));
			# Flags (1 byte)
			append(tmp, chr(0));
			# RootID (8 bytes)
			append(tmp, decToAscii(65535) ~ chr(255) ~ chr(255) ~ chr(255) ~ chr(255) ~ chr(255) ~ chr(255));
			# Root path cost (4 bytes)
			append(tmp, chr(0) ~ chr(0) ~ chr(0) ~ chr(0));
			# BridgeID (8 bytes)
			append(tmp, decToAscii(65535) ~ chr(255) ~ chr(255) ~ chr(255) ~ chr(255) ~ chr(255) ~ chr(255));
			# PortID (2 bytes)
			append(tmp, chr(0) ~ chr(0));
			# Message age (2 bytes)
			append(tmp, chr(0) ~ chr(0));
			# Maximium age (2 bytes)
			append(tmp, chr(0) ~ chr(20));
			# Hello time (2 bytes)
			append(tmp, chr(0) ~ chr(2));
			# Forward delay (2 bytes)
			append(tmp, chr(0) ~ chr(15));
		}
		obj = {};
		obj.parents = [BPDU];
		

		
		# Instance variables:
		obj.block = tmp;
		
		return obj;
	},
	
	# Query:
	
	isTC : func{
		return (me.block[3] == chr(129));
	},
	
	isTCA : func{
		return (me.block[3] == chr(1));
	},
	
	isTCN : func{
		return (me.block[3] == chr(128));
	},
	
	# Accessors:
	getBridgeID : func{
		return me.block[6];
	},
	
	getForwardDelay : func{
		return asciiToDec(me.block[11]);
	},
	
	getHelloTime : func{
		return asciiToDec(me.block[10]);
	},
	
	getMaxAge : func{
		return asciiToDec(me.block[9]);
	},
	
	getMessageAge : func{
		return asciiToDec(me.block[8]);
	},
	
	getPortID : func{
		return asciiToDec(me.block[7]);
	},
	
	getRootID : func{
		return me.block[4];
	},
	
	getRootPathCost : func{
		return asciiToDec(me.block[5]);
	},
	
	# Modifiers:
	
	# Force the BPDU to be a Topology Change message.
	forceTC : func{
		me.block[3] = chr(129);
	},
	
	# Force the BPDU to be a Topology Change Acknowledgement Message.
	forceTCA : func{
		me.block[3] = chr(1);
	},
	
	# Force the BPDU to be a Topology Change Notification message.
	forceTCN : func{
		me.block[3] = chr(128);
	},
	
	# Lower all flags.
	lowerFlags : func{
		me.block[3] = chr(0);
	},
	
	setBridgeID : func(bid){
		if (size(bid) == 8){
			me.block[6] = bid;
			return 1;
		}
		else {
			# Invalid BID.
			return 0;
		}
	},
	
	setForwardDelay : func(delay){
		if (delay == nil){
			# Invalid time specification.
			return 0;
		}
		else {
#			if (size(delay) == nil){
				tmp = decToAscii(delay);
				while (size(tmp) < 2){
					tmp = chr(0) ~ tmp;
				}

				me.block[11] = tmp;
#			}
#			else {
#				# Argument cannot be a string.
#				return -1;
#			}
		}
	},
	
	setHelloTime : func(elapse){
		if (elapse == nil){
			# Invalid time specification.
			return 0;
		}
		else {
#			if (size(elapse) == nil){
				tmp = decToAscii(elapse);
				while (size(tmp) < 2){
					tmp = chr(0) ~ tmp;
				}

				me.block[10] = tmp;
#			}
#			else {
#				# Argument cannot be a string.
#				return -1;
#			}
		}
	},
	
	setMaxAge : func(age){
		if (age == nil){
			# Invalid time specification.
			return 0;
		}
		else {
#			if (size(age) == nil){
				tmp = decToAscii(age);
				while (size(tmp) < 2){
					tmp = chr(0) ~ tmp;
				}

				me.block[9] = tmp;
#			}
#			else {
#				# Argument cannot be a string.
#				return -1;
#			}
		}
	},
	
	setMessageAge : func(age){
		if (age == nil){
			# Invalid time specification.
			return 0;
		}
		else {
#			if (size(age) == nil){
				tmp = decToAscii(age);
				while (size(tmp) < 2){
					tmp = chr(0) ~ tmp;
				}
				me.block[8] = tmp;
#			}
#			else {
#				# Argument cannot be a string.
#				return -1;
#			}
		}
	},
	
	setPortID : func(id){
		if (id == nil){
			# Invalid id specification.
			return 0;
		}
		else {
#			if (size(id) == nil){
				tmp = decToAscii(id);
				while (size(tmp) < 2){
					tmp = chr(0) ~ tmp;
				}
				me.block[7] = tmp;
#			}
#			else {
#				# Argument cannot be a string.
#				return -1;
#			}
		}
	},
	
	setRootID : func(rid){
		if (size(rid) == 8){
			me.block[4] = rid;
			return 1;
		}
		else {
			# Invalid RID.
			return 0;
		}
	},
	
	setRootPathCost : func(cost){
		if (cost == nil){
			# Invalid cost specification.
			return 0;
		}
		else {
#			if (size(cost) == nil){
				tmp = decToAscii(cost);
				while (size(tmp) < 4){
					tmp = chr(0) ~ tmp;
				}
				me.block[5] = tmp;
#			}
#			else {
#				# Argument cannot be a string.
#				return -1;
#			}
		}
	},
	
	# Turn the frame into a string.
	toString : func{
		out = "";
		foreach (block ; me.block){
			out = out ~ block;
		}
		return (out);
	}
};

Frame = {
	# Parse a string to create an instance of the frame format.
	new : func(packet){
		obj = {};
		obj.parents = [Frame];
		
		tmp = [];
		
		if (size(packet) > 26){
			# Sync (7 bytes) ignored.
			append(tmp, substr(packet, 0, 7));
			# Delimiter (1 byte) ignored.
			append(tmp, substr(packet, 7, 1));
			# Destination (6 bytes)
			append(tmp, substr(packet, 8, 6));
			# Source (6 bytes)
			append(tmp, substr(packet, 14, 6));
			# Length of data field (2 bytes)
			append(tmp, substr(packet, 20, 2));
			# Data field (1500 bytes MAX)
			append(tmp, substr(packet, 22, asciiToDec(tmp[4])));
			# Check sum (4 bytes)
			append(tmp, substr(packet, size(packet) - 5), 4);
		}
		else {
			# Sync (7 bytes)
			append(tmp, chr(170) ~ chr(170) ~ chr(170) ~ chr(170) ~ chr(170) ~ chr(170) ~ chr(170));
			# Delimiter (1 byte)
			append(tmp, chr(171));
			# Destination (6 bytes)
			append(tmp, chr(0) ~ chr(0) ~ chr(0) ~ chr(0) ~ chr(0) ~ chr(0));
			# Source (6 bytes)
			append(tmp, chr(0) ~ chr(0) ~ chr(0) ~ chr(0) ~ chr(0) ~ chr(0));
			# Length of data field (2 bytes)
			append(tmp, chr(0) ~ chr(0));
			# Data field (1500 bytes MAX)
			append(tmp, chr(0));
			# Check sum (4 bytes)
			append(tmp, chr(0) ~ chr(0) ~ chr(0) ~ chr(0));
		}
		
		# Instance variables:
		obj.block = tmp;
		
		return obj;
	},
	
	# Retrieve the data field in string.
	getData : func{
		return me.block[5];
	},
	
	# Retrieve the destination address.
	getDestination : func{
		return me.block[2];
	},
	
	# Retrieve the source address.
	getSource : func{
		return me.block[3];
	},
	
	# Modify the data field.
	setData : func(data){
		me.block[5] = data;
		me.block[4] = decToAscii(size(data));
		while (size(me.block[4]) < 2){
			me.block[4] = chr(0) ~ me.block[4];
		}
	},
	
	# Modify the destination address.
	setDestination : func(address){
		if (size(address) == 6){
			me.block[2] = address;
			return 1;
		}
		else {
			# Invalid address.
			return 0;
		}
	},
	
	# Modify the source address.
	setSource : func(address){
		if (size(address) == 6){
			me.block[3] = address;
			return 1;
		}
		else {
			# Invalid address.
			return 0;
		}
	},
	
	# Turn the frame into a string.
	toString : func{
		out = "";
		foreach (block ; me.block){
			out = out ~ block;
		}
		return out;
	}
};

LLC = {
	# Parse a string to create an instance of the Logical Link Control (LLC) layer.
	new : func(data){
		obj = {};
		obj.parents = [LLC];
		
		tmp = [];
		
		if (size(data) > 0){
			# DSAP (1 byte)
			append(tmp, substr(data, 0, 1));
			# SSAP (1 byte)
			append(tmp, substr(data, 1, 1));
			# Control (1 byte)
			append(tmp, substr(data, 2, 1));
			# Data (1497 bytes MAX)
			append(tmp, substr(data, 3));
		}
		else {
			# DSAP (1 byte)
			append(tmp, chr(0));
			# SSAP (1 byte)
			append(tmp, chr(0));
			# Control (1 byte)
			append(tmp, chr(0));
			# Data (1497 bytes MAX)
			append(tmp, chr(0));
		}
		
		# Instance variables:
		obj.block = tmp;
		
		return obj;
	},
	
	# Accessors:
	getControl : func{
		return asciiToDec(me.block[2]);
	},
	
	getData : func{
		return me.block[3];
	},
	
	getDSAP : func{
		return asciiToDec(me.block[0]);
	},
	
	getSSAP : func{
		return asciiToDec(me.block[1]);
	},
	
	# Modifiers:
	setControl : func(val){
		if (val == nil){
			# Invalid cost specification.
			return 0;
		}
		else {
#			if (size(val) == nil){
				tmp = chr(val);
				me.block[2] = tmp;
#			}
#			else {
#				# Argument cannot be a string.
#				return -1;
#			}
		}
	},
	
	setData : func(data){
		me.block[3] = data;
	},
	
	setDSAP : func(val){
		if (val == nil){
			# Invalid cost specification.
			return 0;
		}
		else {
#			if (size(val) == nil){
				tmp = chr(val);
				me.block[0] = tmp;
#			}
#			else {
#				# Argument cannot be a string.
#				return -1;
#			}
		}
	},
	
	setSSAP : func(val){
		if (val == nil){
			# Invalid cost specification.
			return 0;
		}
		else {
#			if (size(val) == nil){
				tmp = chr(val);
				me.block[1] = tmp;
#			}
#			else {
#				# Argument cannot be a string.
#				return -1;
#			}
		}
	},
		
	# Turn the frame into a string.
	toString : func{
		return (me.block[0] ~ me.block[1] ~ me.block[2] ~ me.block[3]);
	}
};