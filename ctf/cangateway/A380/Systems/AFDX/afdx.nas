# ********** ********** ********** ********** ********** ********** ********** ********** ********** **********
# Copyright (C) 2005  Ampere K. [Hardraade]
#
# This file is protected by the GNU Public License.  For more details, please see the text file COPYING.
# ********** ********** ********** ********** ********** ********** ********** ********** ********** **********
# afdx.nas
# This nasal script defines the AFDX system (including the AFDX buses) of the A380.
# 
# The AFDX system of the A380 is seperated into four domains:
# Cockpit domain
# * encompasses avionics functions
# * involves with interfacing with primary displays
# * comprises of four IMA cabinets
#
# Cabin domain
# * associates with functions associated with the passenger cabin
# * comprises of two IMA cabinets
# * contains two afdx switches
#
# Energy domain
# * associates with electrical and hydraulical power, as well as bleed air control
# * comprises of two IMA cabinets
#
# Utility domain
# * assoiates with landing gears control, fuel system, and steering.
# * comprises of two IMA cabinets
#
# ********** ********** ********** ********** ********** ********** ********** ********** ********** **********

Network = {
	# Defines the AFDX system and put it on to the global name space.
	create : func{
		globals.switch1 = Switch.new("S_1_sw1");
		globals.switch2 = Switch.new("S_1_sw2");
		globals.switch3 = Switch.new("S_1_sw3");
		globals.switch4 = Switch.new("S_2_sw1");
		globals.switch5 = Switch.new("S_2_sw2");
		globals.switch6 = Switch.new("S_3_sw1");
		globals.switch7 = Switch.new("S_3_sw2");
		globals.switch8 = Switch.new("S_4_sw1");
		globals.switch9 = Switch.new("S_4_sw2");
		
		# Settings.
#		switch1.setVerbose(3);
#		switch2.setVerbose(3);
#		switch3.setVerbose(3);
#		switch4.setVerbose(2);
#		switch5.setVerbose(2);
#		switch6.setVerbose(2);
#		switch7.setVerbose(2);
#		switch8.setVerbose(3);
		
		switch1.setForwardDelay(7);
		switch2.setForwardDelay(7);
		switch3.setForwardDelay(7);
		switch4.setForwardDelay(7);
		switch5.setForwardDelay(7);
		switch6.setForwardDelay(7);
		switch7.setForwardDelay(7);
		switch8.setForwardDelay(7);
		switch9.setForwardDelay(7);
		
		switch1.setBpduMaxAge(10);
		switch2.setBpduMaxAge(10);
		switch3.setBpduMaxAge(10);
		switch4.setBpduMaxAge(10);
		switch5.setBpduMaxAge(10);
		switch6.setBpduMaxAge(10);
		switch7.setBpduMaxAge(10);
		switch8.setBpduMaxAge(10);
		switch9.setBpduMaxAge(10);
		
		# Update settings.
		switch1.update();
		switch2.update();
		switch3.update();
		switch4.update();
		switch5.update();
		switch6.update();
		switch7.update();
		switch8.update();
		switch9.update();
		
		# Create buses and put them on to the global name space.
		globals.bus01 = Bus.new();
		globals.bus02 = Bus.new();
		globals.bus03 = Bus.new();
		globals.bus04 = Bus.new();
		globals.bus05 = Bus.new();
		globals.bus06 = Bus.new();
		globals.bus07 = Bus.new();
		globals.bus08 = Bus.new();
		globals.bus09 = Bus.new();
		globals.bus10 = Bus.new();
		globals.bus11 = Bus.new();
		globals.bus12 = Bus.new();
		globals.bus13 = Bus.new();
		globals.bus14 = Bus.new();
		globals.bus15 = Bus.new();
		globals.bus16 = Bus.new();
		globals.bus17 = Bus.new();
		globals.bus18 = Bus.new();
		globals.bus19 = Bus.new();
		globals.bus20 = Bus.new();
	},
	
	# Connect the switches using buses.
	makeConnections : func{
		# A graphical representation of the AFDX Network can be found on the last page of:
		#  http://www.arinc.com/aeec/general_session/gs_reports/2004/presentations/using_afdx_429_replacement_jean-francios_saint-etienne.pdf
		
		# Connections between switches in group 1.
		switch1.connect(bus01, 0);
		switch2.connect(bus01, 0);
		
		switch2.connect(bus02, 1);
		switch3.connect(bus02, 0);
		
		switch1.connect(bus03, 1);
		switch3.connect(bus03, 1);
		
		# Connections between switches in group 2.
		switch4.connect(bus04, 0);
		switch5.connect(bus04, 0);
		
		# Connections between switches in group 3.
		switch6.connect(bus05, 0);
		switch7.connect(bus05, 0);
		
		# Connections between switches in group 4.
		switch8.connect(bus06, 0);
		switch9.connect(bus06, 0);
		
		# Connections between switches between group 1 and group 2.
		switch1.connect(bus07, 2);
		switch4.connect(bus07, 1);
		
		switch2.connect(bus08, 2);
		switch5.connect(bus08, 1);
		
		switch3.connect(bus09, 2);
		switch3.connect(bus10, 2);
		switch4.connect(bus09, 2);
		switch5.connect(bus10, 2);
		
		# Connections between switches between group 2 and group 3.
		switch4.connect(bus11, 3);
		switch6.connect(bus11, 1);
		
		switch5.connect(bus12, 3);
		switch7.connect(bus12, 1);
		
		# Connections between switches between group 3 and group 4.
		switch6.connect(bus13, 2);
		switch8.connect(bus13, 1);
		
		switch7.connect(bus14, 2);
		switch9.connect(bus14, 1);
		
		# Exit early.  The rest are legacy code.
		return;
		
		
		
		
		
		# This is an old arrangement created by me.  The arrangement can be describe as "a small square
		#  with in a big square, with each corner of one square connected to the same corner on
		#  another.
		
		# Connections from/to switch1.
		switch1.connect(bus01, 0);
		switch1.connect(bus02, 1);
		switch1.connect(bus03, 2);
		
		# Connections from/to switch2.
		switch2.connect(bus02, 0);
		switch2.connect(bus04, 1);
		switch2.connect(bus05, 2);
		
		# Connections from/to switch3.
		switch3.connect(bus01, 0);
		switch3.connect(bus06, 1);
		switch3.connect(bus07, 2);
		
		# Connections from/to switch4.
		switch4.connect(bus04, 0);
		switch4.connect(bus06, 1);
		switch4.connect(bus08, 2);
		
		# Connections from/to switch5.
		switch5.connect(bus03, 0);
		switch5.connect(bus09, 1);
		switch5.connect(bus10, 2);
		
		# Connections from/to switch6.
		switch6.connect(bus05, 0);
		switch6.connect(bus09, 1);
		switch6.connect(bus11, 2);
		
		# Connections from/to switch7.
		switch7.connect(bus07, 0);
		switch7.connect(bus10, 1);
		switch7.connect(bus12, 2);
		
		# Connections from/to switch8.
		switch8.connect(bus08, 0);
		switch8.connect(bus11, 1);
		switch8.connect(bus12, 2);
		
		# Additional connections:
		
		# Additional connections from/to switch1.
		switch1.connect(bus13, 3);
		switch1.connect(bus14, 4);
		
		# Additional connections from/to switch2.
		switch2.connect(bus15, 3);
		switch2.connect(bus16, 4);
		
		# Additional connections from/to switch3.
		switch3.connect(bus15, 3);
		switch3.connect(bus17, 4);
		
		# Additional connections from/to switch4.
		switch4.connect(bus13, 3);
		switch4.connect(bus19, 4);
		
		# Additional connections from/to switch5.
		switch5.connect(bus16, 3);
		switch5.connect(bus18, 4);
		
		# Additional connections from/to switch6.
		switch6.connect(bus14, 3);
		switch6.connect(bus20, 4);
		
		# Additional connections from/to switch7.
		switch7.connect(bus19, 3);
		switch7.connect(bus20, 4);
		
		# Additional connections from/to switch8.
		switch8.connect(bus17, 3);
		switch8.connect(bus18, 4);
	}
};