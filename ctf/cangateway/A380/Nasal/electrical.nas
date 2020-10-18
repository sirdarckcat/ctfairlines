#Syd Adams
# Jet Engine electrical system.


battery1 = nil;
battery2 = nil;
alternator = nil;
tr1a = nil;
tr2a = nil;


last_time = 0.0;
pwr_src = 0.0;

bat_bus_volts = 0.0;
dc_ess_bus_volts = 0.0;
dc_bus_left_volts = 0.0;
dc_bus_right_volts = 0.0;
ac_bus_1_1_volts = 0.0;
ac_bus_1_2_volts = 0.0;
ac_bus_2_3_volts = 0.0;
ac_bus_2_4_volts = 0.0;
ac_ess_bus_volts = 0.0;
AC_bus_amps = 0.0;
ammeter_ave = 0.0;

external_volts = 0.0;
load = 0.0;

init_electrical = func {
    print("Initializing Electrical System");
    battery1 = BatteryClass.new(0);
    battery2 = BatteryClass.new(1);
    alternator = AlternatorClass.new();
    tr1a  = TransformerClass.new();
    #tr1b  = TransformerClass.new();
    tr2a  = TransformerClass.new();
    #tr2b  = TransformerClass.new();

    setprop("/controls/electric/battery[0]/bus-tie", 1);
    setprop("/controls/electric/battery[0]/generator", 1);
    setprop("/controls/electric/battery[1]/bus-tie", 1);
    setprop("/controls/electric/battery[1]/generator", 1);
    setprop("/controls/electric/external/bus-tie", 1);
    setprop("/controls/electric/engine[0]/generator", 1);
    setprop("/controls/electric/engine[1]/generator", 1);
    setprop("/controls/electric/engine[2]/generator", 1);
    setprop("/controls/electric/engine[3]/generator", 1);
    setprop("/controls/electric/engine[4]/bus-tie", 0);
    setprop("/controls/electric/engine[4]/gen_a", 1);
    setprop("/controls/electric/engine[4]/gen_b", 1);
    setprop("/controls/switches/inverter", 1);

    settimer(update_electrical, 0);
}

BatteryClass = {};

BatteryClass.new = func(unit) {
    obj = { parents : [BatteryClass],
            ideal_volts : 24.0,
            ideal_amps : 30.0,
            amp_hours : 12.75,
            charge_percent : 1.0,
            charge_amps : 12.0 };   ## 7.0
            obj.unit = unit;
    return obj;
}


BatteryClass.apply_load = func( amps, dt ) {
    amphrs_used = amps * dt / 3600.0;
    percent_used = amphrs_used / me.amp_hours;
    me.charge_percent -= percent_used;
    if ( me.charge_percent < 0.0 ) {
        me.charge_percent = 0.0;
    } elsif ( me.charge_percent > 1.0 ) {
        me.charge_percent = 1.0;
    }
    var battAmps = me.amp_hours * me.charge_percent;
    setprop("/systems/electrical/suppliers/batt["~me.unit~"]/amps", battAmps);
    return battAmps
}


BatteryClass.get_output_volts = func {
    x = 1.0 - me.charge_percent;
    tmp = -(3.0 * x - 1.0);
    factor = (tmp*tmp*tmp*tmp*tmp + 32) / 32;
    var batVolts = me.ideal_volts * factor;
    setprop("/systems/electrical/suppliers/batt["~me.unit~"]/volts", batVolts);
    return batVolts;
}

BatteryClass.get_output_amps = func {
    x = 1.0 - me.charge_percent;
    tmp = -(3.0 * x - 1.0);
    factor = (tmp*tmp*tmp*tmp*tmp + 32) / 32;
    return me.ideal_amps * factor;
}

AlternatorClass = {};

AlternatorClass.new = func() {
    obj = { parents : [AlternatorClass],
            rpm_source : "/engines/engine[0]/n2",
            rpm_threshold : 40.0,
            ideal_volts : 115.0,
            ideal_amps : 1304.0 };
    setprop( obj.rpm_source, 0.0 );
    return obj;
}

##
# Computes available amps and returns remaining amps after load is applied
#

AlternatorClass.apply_load = func( amps, dt, src ) {
    rpm = getprop(src);
    factor = rpm / me.rpm_threshold;
    if ( factor > 1.0 ) {
        factor = 1.0;
    }
    available_amps = me.ideal_amps * factor;
    var altAvailAmps = available_amps - amps;
    return altAvailAmps;
}


AlternatorClass.get_output_volts = func( src ) {
    rpm = getprop("/engines/engine["~src~"]/n2");
    if (rpm == 0) {
        factor = 0;
    } else {
        factor = math.ln(rpm)/4;
    }
    var altVolts = me.ideal_volts * factor;
    if (altVolts < 0) {
      altVolts = 0.0;
    }
    setprop("/systems/electrical/suppliers/alt["~src~"]/volts", altVolts);
    return altVolts;
}


AlternatorClass.get_output_amps = func(src ){
    rpm = getprop("/engines/engine["~src~"]/n2");
    if (rpm == 0) {
        factor = 0;
    } else {
        factor = math.ln(rpm)/4;
    }
    var altAvailAmps = me.ideal_amps * factor;
    if (altAvailAmps < 0) {
      altAvailAmps = 0.0;
    }
    setprop("/systems/electrical/suppliers/alt["~src~"]/amps-out", altAvailAmps);
    return altAvailAmps;
}

TransformerClass = {};

TransformerClass.new = func() {
    obj = { parents : [TransformerClass],
            ideal_volts : 115.0,
            ideal_amps :   30.0 };
    return obj;
}

TransformerClass.get_output_volts = func(ac_volts) {
  return ac_volts*0.25;
}

BusBarClass = {};

BusBarClass.new = func(baseProperty) {
   obj = {parents : [BusBarClass],
          volts : 0.0,
          amps  : 0.0,
          ohms  : 0.0,
          base : baseProperty
         };
   return obj;
}

ExternalPowerClass = {};

ExternalPowerClass.new = func(unit) {
  obj = {parents : [ExternalPowerClass],
           volts : 0.0,
           avail : false,
        };
     obj.unit = unit;
    return obj;
}



update_electrical = func {
    time = getprop("/sim/time/elapsed-sec");
    dt = time - last_time;
    last_time = time;
    update_virtual_bus( dt );
    settimer(update_electrical, 1.0);
}

update_virtual_bus = func( dt ) {
    var battery1_volts = battery1.get_output_volts();
    var battery2_volts = battery2.get_output_volts();

    alternator0_volts = alternator.get_output_volts(0);
    alternator1_volts = alternator.get_output_volts(1);
    alternator2_volts = alternator.get_output_volts(2);
    alternator3_volts = alternator.get_output_volts(3);
    external_volts = 0.0;
    load = 0.0;

    master_alt0  = getprop("/controls/electric/contact/engine_1");
    master_alt1  = getprop("/controls/electric/contact/engine_2");
    master_alt2  = getprop("/controls/electric/contact/engine_3");
    master_alt3  = getprop("/controls/electric/contact/engine_4");
    master_apu_a = getprop("/controls/electric/contact/apu_gen-a");
    master_apu_b = getprop("/controls/electric/contact/apu_gen-b");
    master_batt1 = getprop("/controls/electric/contact/batt_1");
    master_batt2 = getprop("/controls/electric/contact/batt_2");
    master_ext_1 = getprop("/controls/electric/contact/external_1");
    master_ext_2 = getprop("/controls/electric/contact/external_2");
    master_ext_3 = getprop("/controls/electric/contact/external_3");
    master_ext_4 = getprop("/controls/electric/contact/external_4");
    master_bus_tie = getprop("/controls/electric/contact/bus_tie");

    # determine power source
    bat_bus_volts = 0.0;
    dc_ess_bus_volts = 0.0;
    dc_bus_left_volts = 0.0;
    dc_bus_right_volts = 0.0;
    ac_bus_1_1_volts = 0.0;
    ac_bus_1_2_volts = 0.0;
    ac_bus_2_3_volts = 0.0;
    ac_bus_2_4_volts = 0.0;
    ac_ess_bus_volts = 0.0;
    power_source = "none";
    apua_volts = 0.0;
    apub_volts = 0.0;

    ##APU generator
    a_volts = alternator.get_output_volts(4);
    b_volts = alternator.get_output_volts(4);
    if (a_volts < 0) {
      a_volts = 0;
    }
    setprop("/engines/engine[4]/volts_a",a_volts);
    setprop("/engines/engine[4]/volts_b",b_volts);
    if(master_apu_a == 1) {
      apua_volts = a_volts; 
    } else {
      apua_volts = 0;
    };
    if(master_apu_b == 1) {
      apub_volts = b_volts; 
    } else {
      apub_volts = 0;
    };
 
    ## Batteries 
    if (master_batt1 == 1 and (battery1_volts > bat_bus_volts)) {
        bat_bus_volts = battery1_volts;
        dc_ess_bus_volts = battery1_volts;
    }
    
    if (master_batt2 == 1 and (battery2_volts > bat_bus_volts)) {
        bat_bus_volts = battery2_volts;
        dc_ess_bus_volts = battery2_volts;
    }

    ## IDG 0 - 4
    if ( master_alt0 and (alternator0_volts > 110) ) {
        ac_bus_1_1_volts = alternator0_volts;
        power_source = "alternator";
    }

    if ( master_alt1 and (alternator1_volts > 110) ) {
        ac_bus_1_2_volts = alternator1_volts;
        power_source = "alternator";
    }

    if ( master_alt2 and (alternator2_volts > 110) ) {
        ac_bus_2_3_volts = alternator2_volts;
        power_source = "alternator";
    }
    
    if ( master_alt3 and (alternator3_volts > 110) ) {
        ac_bus_2_4_volts = alternator3_volts;
        power_source = "alternator";
    }

    ## APU A
    if (master_bus_tie == 1 and (apua_volts > ac_bus_1_1_volts)) {
      ac_bus_1_1_volts = apua_volts;
      power_source = "apu";
    }
    if (master_bus_tie == 1 and (apua_volts > ac_bus_1_2_volts)) {
      ac_bus_1_2_volts = apua_volts;
      power_source = "apu";
    }

    ## APU B
    if (master_bus_tie == 1 and (apub_volts > ac_bus_2_3_volts)) {
      ac_bus_2_3_volts = apub_volts;
    }
    if (master_bus_tie == 1 and (apub_volts > ac_bus_2_4_volts)) {
      ac_bus_2_4_volts = apub_volts;
    }

    ## AC Bus Tie
    if (master_bus_tie == 1) {
      max_volts = 0.0;
      if (ac_bus_1_1_volts > max_volts) {
        max_volts = ac_bus_1_1_volts;
      }
      if (ac_bus_1_2_volts > max_volts) {
        max_volts = ac_bus_1_2_volts;
      }
      if (ac_bus_2_3_volts > max_volts) {
        max_volts = ac_bus_2_3_volts;
      }
      if (ac_bus_2_4_volts > max_volts) {
        max_volts = ac_bus_2_4_volts;
      }
      ac_bus_1_1_volts = max_volts;
      ac_bus_1_2_volts = max_volts;
      ac_bus_2_3_volts = max_volts;
      ac_bus_2_4_volts = max_volts;
    }

    ## AC -> DC Transformer Rectifiers
    tr1a_volts = tr1a.get_output_volts(ac_bus_1_2_volts);
    tr2a_volts = tr2a.get_output_volts(ac_bus_2_3_volts);

    ## DC supply from Batteries
    if (bat_bus_volts > dc_bus_left_volts and tr1a_volts <= 26 ) {
      dc_bus_left_volts = bat_bus_volts;
      setprop("/controls/electric/contact/dc_left_tie",1);
      setprop("/controls/electric/contact/tr_left_tie",0);
      power_source = "battery";
    }

    if (bat_bus_volts > dc_bus_right_volts and tr2a_volts <= 26 ) {
      dc_bus_right_volts = bat_bus_volts;
      setprop("/controls/electric/contact/dc_right_tie",1);
      setprop("/controls/electric/contact/tr_right_tie",0);
      power_source = "battery";
    }

    ## DC supply from TR
    if (tr1a_volts > 26) {
      dc_bus_left_volts = tr1a_volts;
      setprop("/controls/electric/contact/tr_left_tie",1);
    }
    if (tr2a_volts > 26) {
      dc_bus_right_volts = tr2a_volts;
      setprop("/controls/electric/contact/tr_right_tie",1);
    }

    setprop("/engines/engine[0]/volts", alternator0_volts);
    setprop("/engines/engine[2]/volts", alternator2_volts);
    setprop("/engines/engine[1]/volts", alternator1_volts);
    setprop("/engines/engine[3]/volts", alternator3_volts);
    setprop("/systems/electrical/ac_bus_1-1/volts", ac_bus_1_1_volts);
    setprop("/systems/electrical/ac_bus_1-2/volts", ac_bus_1_2_volts);
    setprop("/systems/electrical/ac_bus_2-3/volts", ac_bus_2_3_volts);
    setprop("/systems/electrical/ac_bus_2-4/volts", ac_bus_2_4_volts);
    setprop("/systems/electrical/ac_bus_ess/volts", ac_ess_bus_volts);
    setprop("/systems/electrical/dc_bus_left/volts", dc_bus_left_volts);
    setprop("/systems/electrical/dc_bus_right/volts", dc_bus_right_volts);
    setprop("/systems/electrical/dc_bus_ess/volts", dc_ess_bus_volts);

    ## finally set property to show what selected power source is
    setprop("/systems/electrical/power-source", power_source);


    # left starter motor
    starter_switch = getprop("/controls/engines/engine[0]/starter");
    starter_volts = 0.0;
    if ( starter_switch ) {
        starter_volts = bat_bus_volts;
        setprop("/systems/electrical/outputs/starter[0]", starter_volts);
    }
    

    # right starter motor
    starter_switch = getprop("/controls/engines/engine[1]/starter");
    starter_volts = 0.0;
    if ( starter_switch ) {
        starter_volts = bat_bus_volts;
        setprop("/systems/electrical/outputs/starter[1]", starter_volts);
    }
    

    load += emergency_bus();
    load += Left_Main_bus();
    load += Right_Main_bus();
    load += AC_bus();

    ammeter = 0.0;
    if ( bat_bus_volts > 1.0 ) {
        # normal load
        load += 15.0;

        # ammeter gauge
        if ( power_source == "battery" ) {
            ammeter = -load;
        } else {
            ammeter = battery1.charge_amps;
        }
    }

    # charge/discharge the battery
    if ( power_source == "battery" ) {
      if (master_batt1 == 1) {
        battery1.apply_load( load, dt );
      }
      if (master_batt2 == 1) {
        battery2.apply_load( load, dt );
      }
    } 
    if ( bat_bus_volts > battery1_volts ) {
        #print("recharge battery #1 - dt: "~dt~", bat_bus_volts: "~bat_bus_volts~", battery_volts: "~battery1_volts);
        battery1.apply_load( -battery1.charge_amps, dt );
    }
    if ( bat_bus_volts > battery2_volts ) {
        #print("recharge battery #2 - dt: "~dt~", bat_bus_volts: "~bat_bus_volts~", battery_volts: "~battery2_volts);
        battery2.apply_load( -battery2.charge_amps, dt );
    }

    # filter ammeter needle pos
    ammeter_ave = 0.8 * ammeter_ave + 0.2 * ammeter;

    # outputs
    setprop("/systems/electrical/amps", ammeter_ave);
    setprop("/systems/electrical/volts", bat_bus_volts);
    setprop("/systems/electrical/ac_amps", AC_bus_amps);

    return load;
}

emergency_bus = func() {
    load = 0.0;
    setprop("/systems/electrical/outputs/nav[1]", dc_ess_bus_volts);
    setprop("/systems/electrical/outputs/com[0]", dc_ess_bus_volts);

    if ( getprop("/controls/switches/cabin-lights") > 0 and getprop("/controls/electric/contact/commercial") == 1 ) {
        setprop("/systems/electrical/outputs/cabin-lights", dc_ess_bus_volts);
} else {
        setprop("/systems/electrical/outputs/cabin-lights", 0.0);
    }
    if ( getprop("/controls/switches/pitot-heat" ) ) {
        setprop("/systems/electrical/outputs/pitot-heat", dc_ess_bus_volts);
    } else {
        setprop("/systems/electrical/outputs/pitot-heat", 0.0);
    }
    return load;
}


#Hydraulic pumps driven by N2 ,but relays controlled by 28 volt DC bus
#- so no DC power - no hydraulics

Left_Main_bus = func() {
  load = 0.0;
  setprop("/controls/hydraulic/system[0]/engine-pump","false");
  if(ac_bus_1_1_volts > 0.2){
    setprop("/controls/hydraulic/system[0]/engine-pump","true");
  }

  setprop("/systems/electrical/outputs/instr-ignition-switch", ac_bus_1_1_volts);

    if ( getprop("/controls/engines/engine[0]/fuel-pump") ) {
        setprop("/systems/electrical/outputs/fuel-pump", ac_bus_1_1_volts);
    } else {
        setprop("/systems/electrical/outputs/fuel-pump", 0.0);
    }

    if ( getprop("/controls/switches/landing-light-c") ) {
        setprop("/systems/electrical/outputs/landing-light-c",ac_bus_1_1_volts);
    } else {
        setprop("/systems/electrical/outputs/landing-light-c", 0.0 );
    }
    if ( getprop("/controls/switches/landing-light-l") ) {
        setprop("/systems/electrical/outputs/landing-light-l", ac_bus_1_1_volts);
    } else {
        setprop("/systems/electrical/outputs/landing-light-l", 0.0 );
    }
    if ( getprop("/controls/switches/landing-light-r") ) {
        setprop("/systems/electrical/outputs/landing-light-r",ac_bus_2_4_volts);
    } else {
        setprop("/systems/electrical/outputs/landing-light-r", 0.0 );
    }

    if ( getprop("/controls/switches/beacon" ) ) {
        setprop("/systems/electrical/outputs/beacon", ac_bus_1_1_volts);
        if ( bat_bus_volts > 1.0 ) { load += 7.5; }
    } else {
        setprop("/systems/electrical/outputs/beacon", 0.0);
    }
    setprop("/systems/electrical/outputs/flaps",ac_bus_1_1_volts);
    setprop("/systems/electrical/outputs/turn-coordinator", dc_bus_left_volts);
    setprop("/systems/electrical/outputs/efis", dc_bus_left_volts);

    if ( getprop("/controls/switches/nav-lights" ) ) {
        setprop("/systems/electrical/outputs/nav-lights", ac_bus_1_1_volts);
        if ( bat_bus_volts > 1.0 ) { load += 7.0; }
    } else {
        setprop("/systems/electrical/outputs/nav-lights", 0.0);
    }
    setprop("/systems/electrical/outputs/instrument-lights", dc_bus_left_volts);
    if ( getprop("/controls/switches/strobe" ) ) {
        setprop("/systems/electrical/outputs/strobe-lights", ac_bus_1_1_volts);
    } else {
        setprop("/systems/electrical/outputs/strobe-lights", 0.0);
    }
    if ( getprop("/controls/switches/taxi-lights" ) ) {
        setprop("/systems/electrical/outputs/taxi-lights", ac_bus_1_1_volts);
    } else {
        setprop("/systems/electrical/outputs/taxi-lights", 0.0);
    }
    if ( getprop("/controls/switches/logo-lights" ) ) {
        setprop("/systems/electrical/outputs/logo-lights", ac_bus_1_1_volts);
    } else {
        setprop("/systems/electrical/outputs/logo-lights", 0.0);
    }	
	    if ( getprop("/controls/switches/map-lights" ) ) {
        setprop("/systems/electrical/outputs/map-lights", dc_bus_left_volts);
    } else {
        setprop("/systems/electrical/outputs/map-lights", 0.0);
    }	
    return load;
}

Right_Main_bus = func() {
setprop("/controls/hydraulic/system[1]/engine-pump","false");
if(ac_bus_2_4_volts > 0.2){setprop("/controls/hydraulic/system[1]/engine-pump","true")};
    master_av = getprop("/controls/switches/master-avionics");
    load = 0.0;
if(master_av){
    setprop("/systems/electrical/outputs/avionics-fan",ac_bus_2_4_volts);
    setprop("/systems/electrical/outputs/gps", dc_bus_right_volts);
    setprop("/systems/electrical/outputs/hsi", dc_bus_right_volts);
    setprop("/systems/electrical/outputs/nav[0]", dc_bus_right_volts);
    setprop("/systems/electrical/outputs/dme", dc_bus_right_volts);
    setprop("/systems/electrical/outputs/audio-panel[0]", dc_bus_right_volts);
    setprop("/systems/electrical/outputs/annunciators", dc_bus_right_volts);
    setprop("/systems/electrical/outputs/audio-panel[1]", dc_bus_right_volts);
    setprop("/systems/electrical/outputs/transponder", dc_bus_right_volts);
    setprop("/systems/electrical/outputs/autopilot", dc_bus_right_volts);
    setprop("/systems/electrical/outputs/adf", dc_bus_right_volts);
    setprop("/systems/electrical/outputs/mk-viii", dc_bus_right_volts);
}
    return load;
}

AC_bus = func() {
  AC_bus_amps = 0.0;
  if(getprop("/controls/switches/inverter") > 0.0){
    if(ac_bus_2_4_volts > 0.2 ){
      AC_bus_amps = 225;
    }
    if(ac_bus_1_1_volts > 0.2) {
      AC_bus_amps = 225;
    }
  } else {
    setprop("/instrumentation/annunciator/master-caution",1.0);
  }
  load = 0.0;
  return load;
}


settimer(init_electrical, 0);
