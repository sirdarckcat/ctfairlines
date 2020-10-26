# =====
# Doors
# =====

Doors = {};

Doors.new = func {
   obj = { parents : [Doors],
           forwardCargoDoor : aircraft.door.new("instrumentation/doors/forward-cargo",  8.0, 0),
           aftCargoDoor : aircraft.door.new("instrumentation/doors/aft-cargo", 8.0, 0),
           paxLeftLow1Door : aircraft.door.new("instrumentation/doors/lower-left-pax1", 5.0, 0),
           paxLeftUp1Door : aircraft.door.new("instrumentation/doors/upper-left-pax1",  5.0, 0),
           paxLeftLow2Door : aircraft.door.new("instrumentation/doors/lower-left-pax2", 5.0, 0),
           paxRightLow1Door : aircraft.door.new("instrumentation/doors/lower-right-pax1", 5.0, 0),
           paxRightUp1Door  : aircraft.door.new("instrumentation/doors/upper-right-pax1", 5.0, 0),
           paxRightLow2Door  : aircraft.door.new("instrumentation/doors/lower-right-pax2", 5.0, 0)
         };
   print("Door system ready");
   return obj;
};

Doors.forwardCargo = func {
   me.forwardCargoDoor.toggle();
}

Doors.aftCargo = func {
   me.aftCargoDoor.toggle();
}

Doors.paxLeftLow1 = func {
   if (getprop("instrumentation/pressurisation/cabin-delta-psi") < 0.5) {
     me.paxLeftLow1Door.toggle();
   }
}

Doors.paxLeftLow2 = func {
   if (getprop("instrumentation/pressurisation/cabin-delta-psi") < 0.5) {
     me.paxLeftLow2Door.toggle();
   }
}

Doors.paxLeftUp1 = func {
   if (getprop("instrumentation/pressurisation/cabin-delta-psi") < 0.5) {
     me.paxLeftUp1Door.toggle();
   }
}

Doors.paxRightLow1 = func {
   if (getprop("instrumentation/pressurisation/cabin-delta-psi") < 0.5) {
     me.paxRightLow1Door.toggle();
   }
}

Doors.paxRightLow2 = func {
   if (getprop("instrumentation/pressurisation/cabin-delta-psi") < 0.5) {
     me.paxRightLow2Door.toggle();
   }
}

Doors.paxRightUp1 = func {
   if (getprop("instrumentation/pressurisation/cabin-delta-psi") < 0.5) {
     me.paxRightUp1Door.toggle();
   }
}

# ==============
# Initialization
# ==============

# objects must be here, otherwise local to init()
doorsystem = Doors.new();