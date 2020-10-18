# A380 systems
#
# updated by S.Hamilton from 787 codebase.
#

#
# mode - 1=PWR, 2=ENG Start, 3=TO Data,4=WOW+>80kt, 5=WOW+>120kt, 6=liftoff, 7=<400ft||15sec,
#        8=>1500ft || 120sec, Cruise until LG extend, 9=Gear extend+<800ft, 10=WOW, 11=<80kt, 12=eng off || 5min
#

## mode constants
LNAV_OFF=0;
LNAV_HDG=1;
LNAV_TRACK=2;
LNAV_LOC=3;
LNAV_FMS=4;
LNAV_RWY=5;

VNAV_OFF=0;
VNAV_ALT=1;
VNAV_VS=2;
VNAV_OPCLB=3;
VNAV_FPA=4;
VNAV_OPDES=5;
VNAV_CLB=6;
VNAV_ALTCRZ=7;
VNAV_DES=8;
VNAV_GS=9;
VNAV_SRS=10;

SPD_OFF=0;
SPD_TOGA=1;
SPD_FLEX=2;
SPD_THRCLB=3;
SPD_SPEED=4;
SPD_MACH=5;
SPD_CRZ=6;
SPD_THRDES=7;
SPD_THRIDL=8;

aircraft.livery.init("Aircraft/A380/XML/Liveries");

baro =0.0;
inhg = 0;
kpa= 0;
rev1 = nil;
r1 = nil;
r2 = nil;
v1 = nil;
cl = 0.0;
c2 = 0.0;
hpsi = 0.0;
n_offset=0;
nm_calc=0.0;
spdbrake=0.0;
et_base=0.0;
et_hr=0.0;
et_min=0.0;
et_min_start=0.0;
force = 0.0;
test = 0.0;
tgt_offset=0.0;
test_dist=0.0;
test1_dist=0.0;
norm_dist=0.0;
true_heading=0.0;
ai_craft="";
mp_craft="";
apu_running=0;
ecamRequestRef=0;
radarLastCnt=0;
radarLastAirportCnt=0;
maxMPCnt = 0;

NM2MTRS = 1852;
METRE2NM = 0.000539956803;
MSEC2KT=1.946;
FPM2MSEC=0.00508;
KT2MSEC=0.514;
MSEC2KMH=3.6;
KMH2MSEC=0.28;
METRE2FT=3.28083989501;
FT2METRE=0.3048;
CLmax = 2.4;


###srsFlapTarget = [263.0, 220.0, 210.0, 196.0, 182.0];   # copied from Airbus_fms.nas
srsFlapTarget = [263.0, 222.0, 210.0, 196.0, 182.0];   #another copy in system.nas
flapPos       = [0, 0.2424, 0.5151, 0.7878, 1.0];

##trace = 0;
version = "1.2.10";

strobe_switch = props.globals.getNode("/controls/switches/strobe", 0);
aircraft.light.new("sim/model/A380/lighting/strobe", [0.05, 1.2], strobe_switch);
beacon_switch = props.globals.getNode("/controls/lighting/beacon", 0);
aircraft.light.new("sim/model/A380/lighting/beacon", [0.05, 1.25], beacon_switch);

ewdChecklist = TextRegion.new(8, 50, "/instrumentation/ewd/checklists");
fms = AirbusFMS.new();
atnetwork = atn.new();




init_controls = func {
  setprop("/engines/engine[4]/off-start-run",0);     # APU state, 0=OFF, 1=START, 2=RUN
  setprop("/instrumentation/efis/baro",0.0);
  setprop("/instrumentation/efis/baro-std-mode",0);
  setprop("/instrumentation/efis/inhg",0);
  setprop("/instrumentation/efis/kpa",0);
  setprop("/instrumentation/efis/stab",0);
  setprop("/instrumentation/efis/baro-mode",1);
  setprop("/instrumentation/efis/fixed-temp",0.0);
  setprop("/instrumentation/efis/fixed-stab",0.0);
  setprop("/instrumentation/efis/fixed-pitch",0.0);
  setprop("/instrumentation/efis/fixed-vs",0.0);
  setprop("/instrumentation/efis/alt-mode",0.0);
  setprop("/instrumentation/efis_fo/baro",0.0);
  setprop("/instrumentation/efis_fo/baro-mode",1);
  setprop("/instrumentation/efis_fo/alt-mode",0.0);
  setprop("/instrumentation/ecam/flight-mode",1);    # A380 has 12 phases of flight
  setprop("/instrumentation/ecam/synoptic","door");  # the page that should be displayed on SD
  setprop("/instrumentation/ecam/page","door");      # the current page displayed on SD
  setprop("/instrumentation/gear/wow",1);            # to capture WOW events better
  setprop("/instrumentation/ecam/egt_limit_arm",0.0);
  setprop("/instrumentation/ecam/to-data", 0);
  setprop("/controls/engines/engine[0]/master",0);
  setprop("/controls/engines/engine[1]/master",0);
  setprop("/controls/engines/engine[2]/master",0);
  setprop("/controls/engines/engine[3]/master",0);
  setprop("/controls/engines/engine[0]/thrust-lever",0);
  setprop("/controls/engines/engine[1]/thrust-lever",0);
  setprop("/controls/engines/engine[2]/thrust-lever",0);
  setprop("/controls/engines/engine[3]/thrust-lever",0);
  setprop("/environment/turbulence/use-cloud-turbulence","true");
  setprop("/sim/current-view/field-of-view",60.0);
  setprop("/sim/view[101]/enabled", 0);
  setprop("/sim/view[103]/enabled", 0);
  setprop("/controls/gear/brake-parking",1.0);
  setprop("/controls/engines/ign-start",0);        # the IGN start switch on the OH
  setprop("/controls/APU/run",0);                  # what should we do with the APU (engine[4])
  setprop("/controls/afs/alt-inc-select",1000);
  var atmos = Atmos.new();
  ##setprop("/controls/pressurisation/cabin_alt", getprop("/position/altitude-ft"));
  setprop("/instrumentation/pressurisation/target-cabin-pressure-psi", atmos.convertAltitudePressure("feet", getprop("/position/altitude-ft"), "psi"));
  setprop("/instrumentation/pressurisation/output-cabin-pressure-psi", atmos.convertAltitudePressure("feet", getprop("/position/altitude-ft"), "psi"));
  setprop("/instrumentation/pressurisation/cabin-altitude-ft", getprop("/position/altitude-ft"));
  setprop("/instrumentation/pressurisation/cabin-pressure-psi", atmos.convertAltitudePressure("feet", getprop("/position/altitude-ft"), "psi"));
  setprop("/systems/electrical/apu-test",0);
  setprop("/instrumentation/annunciator/master-caution",0.0);
  setprop("/instrumentation/switches/seat-belt-sign",0.0);
  setprop("/systems/hydraulic/pump-psi[0]",0.0);
  setprop("/systems/hydraulic/pump-psi[1]",0.0);
  setprop("/surface-positions/speedbrake-pos-norm",0.0);
  setprop("/instrumentation/clock/ET-min",0);
  setprop("/instrumentation/clock/ET-hr",0);
  ##setprop("/instrumentation/mk-viii/speaker/volume",5);
  setprop("/instrumentation/wxradar/display-mode",2);   #is 'arc'
  setprop("/velocities/vls-factor", 1.23);

  #payload - Crew, PAX, Cargo
  setprop("/fdm/jsbsim/inertia/pointmass-weight-lbs[0]",350);
  setprop("/fdm/jsbsim/inertia/pointmass-weight-lbs[1]",48420);
  setprop("/fdm/jsbsim/inertia/pointmass-weight-lbs[2]",28350);
  setprop("/fdm/jsbsim/inertia/pointmass-weight-lbs[3]",21000);
  setprop("/fdm/jsbsim/inertia/pointmass-weight-lbs[4]",14328);
  setprop("/fdm/jsbsim/inertia/pointmass-weight-lbs[5]",1200);

  #setprop("fdm/jsbsim/propulsion/engine[0]/bleed-factor",0.0);
  #setprop("fdm/jsbsim/propulsion/engine[1]/bleed-factor",0.0);
  #setprop("fdm/jsbsim/propulsion/engine[2]/bleed-factor",0.0);
  #setprop("fdm/jsbsim/propulsion/engine[3]/bleed-factor",0.0);

  reset_et();

  DOORS.doorsystem.aftCargoDoor.open();
  DOORS.doorsystem.forwardCargoDoor.open();
  DOORS.doorsystem.paxLeftLow1Door.open();
  DOORS.doorsystem.paxLeftUp1Door.open();

  print("Register FMS delegate");
  registerFlightPlanDelegate(AirbusFMS.new);

  settimer(update_systems,0);
  setprop("/systems/electrical/apu-test",0);
  print("Aircraft systems initialised");
  settimer(update_cabin_pressure, 3);

}



update_cabin_pressure = func {
  var atmos = Atmos.new();
  setprop("/instrumentation/pressurisation/cabin-altitude-ft", getprop("/position/altitude-ft"));
  setprop("/instrumentation/pressurisation/cabin-pressure-psi", atmos.convertAltitudePressure("feet", getprop("/position/altitude-ft"), "psi"));
  ###print("Reset cabin pressure and altitude");
  ## reset our indicated airspeed, otherwise it starts with an error value and doesn't settle down
  setprop("instrumentation/airspeed-indicator/indicated-speed-kt",0.0);
}


reset_et = func {
  et_base = getprop("/sim/time/elapsed-sec");
  et_min_start = et_base;
  et_hr=0.0;
  et_min=0.0;
}

# ESTIMATED TIME CALCULATIONS 

update_radar = func {
  var true_heading = getprop("/orientation/heading-deg");
  ##var mag_heading  = getprop("orientation/heading-magnetic-deg");
  var mag_heading = getprop("/orientation/heading-deg");
  var myAlt = getprop("/position/altitude-ft");
  var currentPos = geo.Coord.new();
  currentPos.set_latlon(getprop("/position/latitude-deg"), getprop("/position/longitude-deg"), getprop("/position/altitude-ft"));

  ## calculate distance from departure airport using straight line
  #
  #var departPos = geo.Coord.new();
  #departPos.setlatlon(getprop("instrumentation/gps/wp/wp[0]/latitude-deg"), getprop("instrumentation/gps/wp/wp[0]/longitude-deg"), getprop("instrumentation/gps/wp/wp[0]/altitude-ft"));
  #var departDistMetre   = currentPos.distance_to(departPos);
  

  ## set NAV[1] (R VOR) to always be our ref navaid
  #
  var refNavFreq = getprop("/instrumentation/gps/ref-navaid/frequency-mhz");
  var currNav1Freq = getprop("/instrumentation/nav[1]/frequencies/selected-mhz");
  var autoTuned    = getprop("/instrumentation/nav[1]/auto-tuned");
  if (refNavFreq != nil and refNavFreq != currNav1Freq and autoTuned == 1) {
    setprop("/instrumentation/nav[1]/frequencies/selected-mhz", refNavFreq);
  }

  ##
  #  plot nearest airport in PLAN mode on ND.
  #
  var closeAirportName = getprop("sim/airport/closest-airport-id");
  if (closeAirportName != nil) {
    var closestApt = airportinfo(closeAirportName);
    var base = props.globals.getNode("/instrumentation/groundradar/airport",1);
    var valid = base.getNode("valid",1);
    var crs = base.getNode("crs", 1);
    var dist = base.getNode("dist-norm", 1);
    var id = base.getNode("id",1);
    if (closestApt != nil) {
      if (id.getValue() != closeAirportName) {
        debug.dump(closestApt);
      }
      var aptPos = geo.Coord.new();
      var tower  = closestApt.tower();
      #debug.dump(tower);
      aptPos.set_latlon(tower.lat, tower.lon, tower.elevation);
      var aptCourse = currentPos.course_to(aptPos);
      aptDistMetre   = currentPos.distance_to(aptPos);
      aptDist = aptDistMetre*METRE2NM;
      id.setValue(closestApt.id);
      dist.setDoubleValue(aptDist/getprop("instrumentation/groundradar/range"));
      crs.setDoubleValue(aptCourse);
      valid.setBoolValue(1);
    } else {
      valid.setBoolValue(0);
      crs.setDoubleValue(0.0);
      dist.setDoubleValue(0.0);
      id.setValue("");
    }
  }

  ######
  ## plot the three pseudo waypoints
  var wpIdx = fms.findWPType("T/C");
  if (wpIdx != nil) {
    updatePseudo(fms.getWP(wpIdx));
  }
  wpIdx = fms.findWPType("T/D");
  if (wpIdx != nil) {
    updatePseudo(fms.getWP(wpIdx));
  }
  wpIdx = fms.findWPType("DECEL");
  if (wpIdx != nil) {
    updatePseudo(fms.getWP(wpIdx));
  }
  
  var acqCL = getprop("instrumentation/afs/acquire_cl");
  var acqCRZ = getprop("instrumentation/afs/acquire_crz");
  if (acqCL == 1 and acqCRZ == 0) {
    update_toc();
  }

  seatCtrl = getprop("/controls/switches/seat-belt");
  if (seatCtrl == 1) {
    ##curAlt   = getprop("/instrumentation/altimeter/indicated-altitude-ft");
    curAlt   = getprop("/position/altitude-ft");
    seatStat = getprop("/instrumentation/switches/seatbelt-sign");
    if (curAlt > 10000 and seatStat > 0) {
      tracer("[SYS] SeatCtrl: "~seatCtrl~", curAlt: "~curAlt~", seatStat: "~seatStat);
      setprop("/instrumentation/switches/seatbelt-sign",0);
    }
    if (curAlt < 10000 and seatStat == 0) {
      tracer("[SYS] SeatCtrl: "~seatCtrl~", curAlt: "~curAlt~", seatStat: "~seatStat);
      setprop("/instrumentation/switches/seatbelt-sign",1);
    }
  }
  var spd    = getprop("/instrumentation/flightdirector/spd");
  var currFlapPos = getprop("/fdm/jsbsim/fcs/flap-cmd-norm");
  if (spd == SPD_THRCLB and currFlapPos > 0) {
    var flapConfig = 0;
    if (currFlapPos == 0.2424) {
      flapConfig = 1;
    }
    if (currFlapPos == 0.5151) {
      flapConfig = 2;
    }
    if (currFlapPos == 0.7878) {
      flapConfig = 3;
    }
    if (currFlapPos == 1.0) {
      flapConfig = 4;
    }
    #tracer("flapConfig: "~flapConfig);
    var iasKt = int(getprop("/instrumentation/airspeed-indicator/indicated-speed-kt"));
    if (iasKt != nil and iasKt != 0) {
      tracer("[SYS] ias: "~iasKt);
      flapSpd = int(srsFlapTarget[flapConfig])+10;
      #tracer("flapSpd: "~flapSpd);
      if (iasKt > flapSpd) {
        print("WARN: Flap overspeed, retracting flaps!");
        flapConfig -= 1;
        #var newFlapPos = flapPos[flapConfig];
        #print("new flap config: "~flapConfig);
        setprop("/instrumentation/ewd/flap-overspeed",1);
      } else {
        if (getprop("/instrumentation/ewd/flap-overspeed") == 1) {
          setprop("/instrumentation/ewd/flap-overspeed",0);
        }
      }
    }
  } else {
    setprop("/instrumentation/ewd/flap-overspeed",0);
  }
  var cgX    = getprop("/fdm/jsbsim/inertia/cg-x-in");
  var gwcg   = (1629.615473-cgX);    ## 1450.7874inches BLG
  setprop("/fdm/jsbsim/inertia/gwcg",gwcg);

   var rho = getprop("/environment/density-slugft3");
   var S   = getprop("/fdm/jsbsim/metrics/Sw-sqft");
   var W   = getprop("/fdm/jsbsim/inertia/weight-lbs");
   var tat = getprop("/fdm/jsbsim/propulsion/tat-c");
   var oat = getprop("/environment/temperature-degc");
   var cs  = 38.967854*math.sqrt(oat+273.15);
   var Vsfts = math.sqrt(W*2/(rho * CLmax * S));
   var Vso = ((Vsfts*60)*FPM2MSEC)*MSEC2KT;
   var Vb  = Vso*2.049;
   var Mb  = convertKtMach(Vb);
   var Mso = convertKtMach(Vso);
   var Mra = (0.89-Mso)/2+Mso;
   setprop("/velocities/Vso",Vso);
   setprop("/velocities/Mso",Mso);
   setprop("/velocities/Vb", Vb);
   setprop("/velocities/Mb", Mb);
   setprop("/velocities/Mra", Mra);

  settimer(update_radar, 1.0);
}

#############
## update_toc
update_toc = func() {
    var tocIdx = fms.findWPType("T/C");
    if (tocIdx != nil) {
      #tracer("[updatetoc] tocIDX: "~tocIdx);
      var fromApt = airportinfo(getprop("instrumentation/afs/FROM"));
      var crzFt   = getprop("instrumentation/afs/CRZ_FL")*100;
      var curAlt  = getprop("position/altitude-ft"); 
      var curVS = getprop("instrumentation/vertical-speed-indicator[1]/indicated-speed-fpm"); 
      var gSpeed = getprop("velocities/groundspeed-kt");

      var diffAlt = crzFt-curAlt;
      var vsMins = diffAlt/curVS;
      var vsHrs  = vsMins/60;
      var distNm = gSpeed*vsHrs;
      #tracer("[T/C] diffAlt: "~diffAlt~", vsMins: "~vsMins~", gSpeed: "~(gSpeed)~", distNm: "~distNm);
      #setprop("/debug/toc/diff-alt",diffAlt);
      #setprop("/debug/toc/vs-mins", vsMins);
      #setprop("/debug/toc/vs-hours", vsHrs);
      #setprop("/debug/toc/dist-nm", distNm);

      var tocWP = fms.getWP(tocIdx);
      var curPosCoord = geo.Coord.new();
      var tocWpCoord = geo.Coord.new();
      tocWpCoord.set_latlon(tocWP.wp_lat, tocWP.wp_lon, tocWP.alt_cstr);
      ###tocWpCoord.set_latlon(fromApt.lat, fromApt.lon, fromApt.elevation);
      curPosCoord.set_latlon(getprop("position/latitude-deg"), getprop("position/longitude-deg"), curAlt); 

      var hdg = curPosCoord.course_to(tocWpCoord);
      var climbNM = getprop("instrumentation/afs/top-of-climb-dist-nm")-getprop("instrumentation/gps/odometer");
      ##tracer("apply course: "~hdg~", distance: "~distNm*NM2MTRS);
      curPosCoord.apply_course_distance(hdg, (distNm*NM2MTRS));
      var tcLat = curPosCoord.lat();
      var tcLon = curPosCoord.lon();
      ##tracer("[TOC] curPosCoord.lat: "~tcLat~" / curPosCoord.lon: "~tcLon);
      tocWP.wp_lat = tcLat;
      tocWP.wp_lon = tcLon;
      ##tracer("[TOC] tocWP.wp_lat: "~tocWP.wp_lat~" / tocWP.wp_lon: "~tocWP.wp_lon);
      fms.replaceWPAt(tocWP, tocIdx);
    }
}


###############
## updatePseudo
updatePseudo = func(wp) {
  if (wp != nil and (wp.wp_name == "(T/C)" or wp.wp_name == "(T/D)" or wp.wp_name == "(DECEL)")) {
      var true_heading = getprop("/orientation/heading-deg");
      var mag_heading  = getprop("orientation/heading-magnetic-deg");
      ##var mag_heading  = getprop("orientation/heading-deg");
      var radarRange = getprop("/instrumentation/nd[0]/range");
      var currentPos = geo.Coord.new();
      currentPos.set_latlon(getprop("/position/latitude-deg"), getprop("/position/longitude-deg"), getprop("/position/altitude-ft"));
      var id = "null";

      if (wp.wp_name == "(T/C)") {
        id = "toc";
      } else if (wp.wp_name == "(T/D)") {
        id = "tod";
      } else if (wp.wp_name == "(DECEL)") {
        id = "decel";
      }
      var base = props.globals.getNode("/instrumentation/radar/"~id,1);
      var wpPos = geo.Coord.new();
      wpPos.set_latlon(wp.wp_lat, wp.wp_lon, 0);
      var wpCourse = currentPos.course_to(wpPos);
      wpDistMetre   = currentPos.distance_to(wpPos);
      wpDist = wpDistMetre*METRE2NM;
      if (mag_heading < wpCourse) {
        ##tgt_offset = wpCourse-mag_heading;
        tgt_offset = wpCourse-true_heading;
      } else {
        ##tgt_offset = 360-(mag_heading-wpCourse);
        tgt_offset = 360-(true_heading-wpCourse);
      }
      if (tgt_offset < 0){
        tgt_offset = 360-tgt_offset;
      }
      if (tgt_offset > 360){
        tgt_offset -=360;
      }
      var valid = base.getNode("valid",1);
      if (wpDist/radarRange <= 1.0) {
        valid.setBoolValue(1);
      } else {
        valid.setBoolValue(0);
      }
      var brg = base.getNode("brg-offset",1);
      brg.setDoubleValue(tgt_offset);
      var crs = base.getNode("crs",1);
      crs.setDoubleValue(wpCourse);
      var dist = base.getNode("dist-norm", 1);
      dist.setDoubleValue(wpDist/radarRange);
      var id = base.getNode("id",1);
      id.setValue(wp.wp_name);
    }

}


var convertKtMach = func(kts) {
   var TEMPSL = 518.67;
   var RHOSL = 0.00237689;
   var PRESSSL = 2116.22;
   var saTheta = 1.0;
   var saSigma = 1.0;
   var saDelta = 1.0;

   var h = getprop("/position/altitude-ft");
   var v = kts*1.6878099;

   if ( h > 232939 ){
      saTheta = 0.0;
      saSigma = 0.0;
      saDelta = 0.0;
   }
 
   if ( h<232940 ){
      saTheta = 1.434843 - h/337634;
      saSigma = math.pow( 0.79899-h/606330, 11.20114 );
      saDelta = math.pow( 0.838263-h/577922, 12.20114 );
   }
   if ( h<167323 ){
      saTheta = 0.939268;
      saSigma = 0.00116533 * math.exp( (h-154200)/-25992 );
      saDelta = 0.00109456 * math.exp( (h-154200)/-25992 );
   }
   if ( h<154199 ){
      saTheta = 0.482561 + h/337634;
      saSigma = math.pow( 0.857003+h/190115, -13.20114 );
      saDelta = math.pow( 0.898309+h/181373, -12.20114 );
   }
   if ( h<104987 ){
      saTheta = 0.682457 + h/945374;
      saSigma = math.pow( 0.978261+h/659515, -35.16319 );
      saDelta = math.pow( 0.988626+h/652600, -34.16319 );
   }
   if ( h<65617 ){
      saTheta = 0.751865;
      saSigma = 0.297076 * math.exp( (36089-h)/20806 );
      saDelta = 0.223361 * math.exp( (36089-h)/20806 );
   }
   if ( h<36089 ){
      saTheta = 1.0 - h/145442;
      saSigma = math.pow( 1.0-h/145442, 4.255876 );
      saDelta = math.pow( 1.0-h/145442, 5.255876 );
   }

   var tempVal = TEMPSL * saTheta;
   var rhoVal = RHOSL * saSigma;
   var pVal = PRESSSL * saDelta;
   var viscVal = 0.0000000226968*math.pow( tempVal, 1.5 ) / ((tempVal)+198.72);
   var soundVal = math.sqrt( 1.4*1716.56*(tempVal) );

   var machVal = v/soundVal;
   var qVal = 0.7*pVal*machVal*machVal;
   ##var reynolds = v*rl*rhoVal/viscVal;
   ##var cfturb = 0.455/math.pow((Math.log(reynolds)/Math.log(10)),2.58);
   ##var cflam = 1.328/math.sqrt(reynolds);
   return machVal;
}


# update EWD checklists
update_ewd = func {
  var flt_mode = getprop("/instrumentation/ecam/flight-mode");
  var acqClm = getprop("instrumentation/afs/acquire_cl");
  if (getprop("/controls/switches/seat-belt") == 0 and  flt_mode < 10) {
    ewdChecklist.append("SEAT BELTS");
  }
  if (getprop("/controls/switches/seat-belt") == 1 and  flt_mode > 11) {
    ewdChecklist.append("SEAT BELTS");
  }
  if (getprop("/controls/switches/smoking") == 0 and flt_mode < 11) {
    ewdChecklist.append("NO SMOKING");
  }
  if (getprop("/controls/gear/brake-parking") == 1) {
    ewdChecklist.append("PARK BRAKE ON");
  }
  if (getprop("/controls/pneumatic/APU-bleed") == 1) {
    ewdChecklist.append("APU BLEED");
  }
  if (flt_mode > 1 and flt_mode < 5) {
    var flapPos = getprop("/controls/flight/flaps");
    var flapConfig = 0;
    if (flapPos == 0.2424) {
      flapConfig = 1;
    }
    if (flapPos == 0.5151) {
      flapConfig = 2;
    }
    if (flapPos == 0.7878) {
      flapConfig = 3;
    }
    if (flapPos == 1.0) {
      flapConfig = 4;
    }
    var perfPos = getprop("instrumentation/afs/to-flaps");
    if (flapConfig < perfPos) {
      ewdChecklist.append("FLAP CONFIG");
    }
  }
  if (flt_mode > 1 and flt_mode < 8 and getprop("/instrumentation/ecam/to-data") != 1) {
    ewdChecklist.append("T.O. DATA");
  }
  if (getprop("/instrumentation/ecam/egt_limit_arm") == 1) {
      ewdChecklist.appendStyle("EGT OVERLIMIT", 0.8, 0.1, 0.1);
  }
  if (getprop("/instrumentation/ewd/flap-overspeed") == 1) {
    ewdChecklist.appendStyle("FLAP OVERSPEED", 0.8, 0.1, 0.1);
  }
  if (flt_mode == 7 and getprop("/controls/gear/gear-down") == 1) {
    ewdChecklist.append("GEARS");
  }
  if (flt_mode == 8 and getprop("position/altitude-ft")-getprop("controls/pressurisation/landing-elev-ft") < 3000 and getprop("/controls/gear/gear-down") == 0 and acqClm == 1) {
    ewdChecklist.append("GEARS", 0.8, 0.5, 0.2);
  }
  if (getprop("/controls/flight/speedbrake") > 0) {
    ewdChecklist.append("SPEEDBRAKE");
  }
  var battVolts = getprop("/systems/electrical/suppliers/batt[0]/volts");
  if (battVolts == nil) {
    battVolts = 28;
  }
  if (battVolts < 23) {
    ewdChecklist.appendStyle("BATT 1 LOW", 0.8, 0.1, 0.1);
  }
  var battVolts = getprop("/systems/electrical/suppliers/batt[1]/volts");
  if (battVolts == nil) {
    battVolts = 28;
  }
  if (battVolts < 23) {
    ewdChecklist.appendStyle("BATT 2 LOW", 0.8, 0.1, 0.1);
  }
  if (getprop("/position/altitude-ft") > 25000 and getprop("/environment/temperature-degc") > -34 and getprop("/controls/anti-ice/wing-heat") == 0) {
    ewdChecklist.append("ANTI ICE CHECK");
  }
  var allEngAntiIce = getprop("/controls/anti-ice/engine[0]/inlet-heat")+getprop("/controls/anti-ice/engine[1]/inlet-heat")+getprop("/controls/anti-ice/engine[2]/inlet-heat")+getprop("/controls/anti-ice/engine[3]/inlet-heat");
  if (flt_mode < 5 and getprop("/fdm/jsbsim/propulsion/tat-c") < 10 and (allEngAntiIce == 0)) {
    ewdChecklist.append("ANTI ICE CHECK");
  }
  var extAvail = getprop("/controls/electric/ground/external_1")+getprop("/controls/electric/ground/external_2")+getprop("/controls/electric/ground/external_3")+getprop("/controls/electric/ground/external_4");
  if (extAvail > 0) {
    ewdChecklist.append("ELEC EXT PWR");
  }
  var packOn = getprop("/controls/pressurization/pack[0]/pack-on")+getprop("/controls/pressurization/pack[1]/pack-on");
  if (getprop("/position/altitude-ft") > 1500 and packOn == 1) {
    if (getprop("/controls/pressurization/pack[0]/pack-on") == 0) {
      ewdChecklist.appendStyle("PACK 1 OFF", 0.8, 0.5, 0.2);
    }
    if (getprop("/controls/pressurization/pack[1]/pack-on") == 0) {
      ewdChecklist.append("PACK 2 OFF", 0.8, 0.5, 0.2);
    }
  }
  if (getprop("/position/altitude-ft") > 1500 and packOn == 0) {
    ewdChecklist.append("PACK 1+2 OFF", 0.8, 0.1, 0.1);
  }
  if (getprop("/consumables/fuel/total-fuel-kg") < 10000) {
    ewdChecklist.append("FUEL LOW", 0.8, 0.1, 0.1);
  }
  if (flt_mode == 8 and getprop("controls/gear/autobrakes") != 0) {
    ewdChecklist.append("AUTOBRK CHECK");
  }
  if (flt_mode > 8 and flt_mode < 12 and getprop("controls/gear/autobrakes") == 0) {
    ewdChecklist.append("AUTOBRK CHECK");
  }
  if (flt_mode > 8  and flt_mode < 10 and getprop("fdm/jsbsim/inertia/weight-kg") > 396000) {
    ewdChecklist.append("CHK LAND GW", 0.8, 0.1, 0.1);
  }

  ewdChecklist.reset();

  var mach = getprop("velocities/mach");
  var alt  = getprop("position/altitude-ft");
  var crzAlt = getprop("instrumentation/afs/thrust-cruise-alt");
  var chngAlt = getprop("instrumentation/afs/changeover-alt");
  if (chngAlt == nil) {
    chngAlt = 999999;
  }
  if (alt > chngAlt and getprop("instrumentation/flightdirector/spd") == SPD_THRCLB) {
    var diffAlt = (crzAlt-chngAlt)/3;
    var crzMach = getprop("instrumentation/afs/crz_mach");
    var clbMach = getprop("instrumentation/afs/clb_mach");
    var diffMach = (crzMach-clbMach)/3;
    var afsTargetMach = getprop("instrumentation/afs/target-speed-mach");
    var apTargetMach  = getprop("autopilot/settings/target-speed-mach");
    tracer("[SYS] alt: "~alt~", chngAlt: "~chngAlt~", diffAlt: "~diffAlt~", apTargetMach: "~apTargetMach);
    if (alt > chngAlt+diffAlt and alt < chngAlt+diffAlt+1000 and apTargetMach != clbMach+diffMach) {
      tracer("[UPDEWD] clbMach: "~clbMach~", diffMach: "~diffMach);
      interpolate("autopilot/settings/target-speed-mach", clbMach+diffMach, 20);
    }
    if (alt > chngAlt+(diffAlt*2) and alt < chngAlt+(diffAlt*2)+1000 and apTargetMach != clbMach+(diffMach*2)) {
      tracer("[UPDEWD] clbMach: "~clbMach~", diffMach: "~diffMach);
      interpolate("autopilot/settings/target-speed-mach", clbMach+(diffMach*2), 20);
    }
  }
  

  settimer(update_ewd, 2);
}


# UPDATE CLOCK 
update_clock = func {
  sec = getprop("/sim/time/elapsed-sec") - et_min_start;
  if(sec >= 60.0){et_min += 1;
    et_min_start = getprop("/sim/time/elapsed-sec");
  }
  if(et_min ==60){et_min = 0; et_hr += 1;}

  etmin = props.globals.getNode("/instrumentation/clock/ET-min");
  if (etmin !=nil) {
    etmin.setIntValue(et_min);
  }
  ethr = props.globals.getNode("/instrumentation/clock/ET-hr");
  if (ethr !=nil) {
    ethr.setIntValue(et_hr);
  }
}


# UPDATE ENGINES
update_engines = func {

  # update engine data and start engines
  var totalFuel = 0;
  for(e=0; e < 4; e=e+1) {
    ign = getprop("/controls/engines/ign-start");
    e_start  = getprop("/controls/engines/engine["~e~"]/starter");
    e_master = getprop("/controls/engines/engine["~e~"]/master");
    e_ign    = getprop("/controls/engines/engine["~e~"]/ignition");
    e_fu_kg  = getprop("fdm/jsbsim/propulsion/engine["~e~"]/fuel-used-kg");
    totalFuel = totalFuel+e_fu_kg;
    hpsi     = getprop("/engines/engine["~e~"]/n2");
    if(hpsi == nil){
      hpsi =0.0;
    }
    if(hpsi > 30.0){
      setprop("/systems/hydraulic/pump-psi["~e~"]",60.0);
    }else{
      setprop("/systems/hydraulic/pump-psi["~e~"]",hpsi * 2);
    }
    
    if (ign == 1 and e_start == 1 and e_master == 1) {
      tracer("[SYS] Engine "~e~" in start phase, N2: "~hpsi);
      if (hpsi > 20 and hpsi < 22 and getprop("/controls/engines/engine["~e~"]/cutoff") == 1) {
        setprop("/controls/engines/engine["~e~"]/cutoff",0);
      }
      if (hpsi >= 26 and hpsi < 50) {
        tracer("[SYS] engine igniter");
        setprop("/controls/engines/engine["~e~"]/ignition",1);
        #setprop("/controls/engines/engine["~e~"]/starter",0);
      }
    }
    if (hpsi >= 50 and ign == 1 and e_ign == 1) {
         tracer("[SYS] shut engine igniter");
         setprop("/controls/engines/engine["~e~"]/ignition",0);
         setprop("/controls/engines/engine["~e~"]/generator",1);
         settimer(check_all_start, 10);
    }
    if (hpsi > 55) {
      if (getprop("/controls/pneumatic/engine["~e~"]/bleed") == 0) {
        setprop("/controls/pneumatic/engine["~e~"]/bleed",1);
      }
    } else {
      if (getprop("/controls/pneumatic/engine["~e~"]/bleed") == 1) {
        setprop("/controls/pneumatic/engine["~e~"]/bleed",0);
      }
    }
    ##var eng_egtF = getprop("/engines/engine["~e~"]/egt_degf");
    var eng_egtF = getprop("/engines/engine["~e~"]/egt-degf");
    eng_egtC = (5/9)*(eng_egtF-32);
    setprop("/engines/engine["~e~"]/egt_degc",eng_egtC);
    limit = getprop("/instrumentation/ecam/egt_limit_arm");
    if (eng_egtC > 920 and limit != 1) {
      settimer(check_egt_overlimit, 20);
      setprop("/instrumentation/ecam/egt_limit_arm",1);
    }
  }
  setprop("consumables/fuel/total-used-kg",totalFuel);

  ### APU stuff 
  var apuN1 = getprop("/engines/engine[4]/n1");
  var hz = apuN1*20;
  setprop("/engines/engine[4]/gena-hz", hz);
  setprop("/engines/engine[4]/genb-hz", hz);
  # update APU status and start/stop APU  
  apu_state = getprop("/engines/engine[4]/off-start-run");
  if (apu_state == 1) {
    start_apu();
  }
  if (apu_state == 2 and getprop("/engines/engine[4]/cutoff") == 1 and getprop("/engines/engine[4]/n2") < 50) {
    setprop("/engines/engine[4]/off-start-run",0);
    settimer(update_sd, 10);
  }
  var apuN2 = getprop("/engines/engine[4]/n2");
  if (apuN2 == nil) {
    apuN2 = 0.0;
  }
  if (apuN2 > 50) {
    if (getprop("/controls/pneumatic/APU-bleed") == 0) {
      setprop("/controls/pneumatic/APU-bleed",1);
    }
  } else {
    if (getprop("/controls/pneumatic/APU-bleed") == 1) {
      setprop("/controls/pneumatic/APU-bleed",0);
    }
  }
  var apu_egtF = getprop("/engines/engine[4]/egt-degf");
  apu_egtC = (5/9)*(apu_egtF-32);
  setprop("/engines/engine[4]/egt_degc",apu_egtC);

  # update status of WOW so we only get 1 event in the listener
  wow = getprop("/instrumentation/gear/wow");
  wow1 = getprop("/gear/gear[1]/wow");
  wow2 = getprop("/gear/gear[2]/wow");
  if ((wow1 != wow) or (wow2 != wow)) {
    if (wow1 != wow) {
      setprop("/instrumentation/gear/wow",wow1);
    } else {
      setprop("/instrumentation/gear/wow",wow2);
    }
  }

  # other Flight Mode checks
  flt_mode = getprop("/instrumentation/ecam/flight-mode");
  grnd_spd = getprop("/velocities/groundspeed-kt");
  if (flt_mode > 1 and flt_mode < 4 and grnd_spd >= 80) {
    flt_mode = 4;
    setprop("/instrumentation/ecam/flight-mode",flt_mode);
  }
  if (flt_mode == 4 and grnd_spd > 130) {
    flt_mode = 5;
    setprop("/instrumentation/ecam/flight-mode",flt_mode);
  }
  if (flt_mode == 10 and grnd_spd < 80) {
    flt_mode = 11;
    setprop("/instrumentation/ecam/flight-mode",flt_mode);
  }
  alt = getprop("/instrumentation/altimeter/indicated-altitude-ft");   #960
  if (alt > 400 and flt_mode == 6) {
    flt_mode = 7;
    setprop("/instrumentation/ecam/flight-mode",flt_mode);
  }
  if (alt > 1500 and flt_mode == 7) {
    flt_mode = 8;
    setprop("/instrumentation/ecam/flight-mode",flt_mode);
  }
  gear_pos = getprop("/gear/gear[0]/position-norm");
  fpm      = getprop("/instrumentation/vertical-speed-indicator/indicated-speed-fpm");
  #if (flt_mode > 4 and flt_mode < 10 and flt_mode != 8) {
  #tracer("flt_mode: "~flt_mode~", alt: "~alt~", gear: "~gear_pos~", fpm: "~fpm); 
  #}
  if (flt_mode == 8 and (alt < 1000 and gear_pos == 1)) {
    flt_mode = 9;
    setprop("/instrumentation/ecam/flight-mode",flt_mode);
  }

  settimer(update_engines, 0.60);  
}

check_acquire_mode = func {
   var acquireMode = getprop("/instrumentation/flightdirector/alt-acquire-mode");
   var apMode      = getprop("/instrumentation/flightdirector/autopilot-on");
   var alt = getprop("/position/altitude-ft");
   if (acquireMode == 1 and apMode == 1) {
     var vnavMode = getprop("instrumentation/flightdirector/vnav");
     var vsSpeed = getprop("/instrumentation/afs/vertical-speed-fpm");
     var selectAlt = getprop("/instrumentation/afs/target-altitude-ft");
     if (vnavMode == VNAV_CLB or vnavMode == VNAV_OPCLB or (vnavMode == VNAV_VS and vsSpeed > 0)) {
       if (alt >= (selectAlt-900)) {
         tracer("[SYS] ACQ - reached selected alt: "~selectAlt);
         setprop("autopilot/settings/target-altitude-ft", getprop("instrumentation/afs/target-altitude-ft"));
         setprop("autopilot/locks/altitude","altitude-hold");
         setprop("/instrumentation/flightdirector/vnav", VNAV_ALT);
         ##setprop("/instrumentation/flightdirector/alt-acquire-mode",0);
         if (getprop("/instrumentation/flightdirector/vnav-arm") == VNAV_OFF and getprop("instrumentation/afs/vertical-alt-mode") == 0) {
           var aFMS = AirbusFMS.new();
           setprop("/instrumentation/flightdirector/vnav-arm", aFMS.evaluateManagedVNAV());
         } else {
           setprop("/instrumentation/flightdirector/vnav-arm", vnavMode);
         }
       }
     }
     if (vnavMode == VNAV_DES or vnavMode == VNAV_OPDES or (vnavMode == VNAV_VS and vsSpeed < 0)) {
       if (alt <= (selectAlt+900)) {
         tracer("[SYS] ACQ - reached selectAlt: "~selectAlt);
         setprop("autopilot/settings/target-altitude-ft", getprop("instrumentation/afs/target-altitude-ft"));
         setprop("autopilot/locks/altitude","altitude-hold");
         ##setprop("/instrumentation/flightdirector/vnav", VNAV_ALT);
         ##setprop("/instrumentation/flightdirector/alt-acquire-mode",0);
         if (getprop("/instrumentation/flightdirector/vnav-arm") == VNAV_OFF and getprop("instrumentation/afs/vertical-alt-mode") == 0) {
           var aFMS = AirbusFMS.new();
           setprop("/instrumentation/flightdirector/vnav-arm", aFMS.evaluateManagedVNAV());
         } else {
           setprop("/instrumentation/flightdirector/vnav-arm", VNAV_OFF);
         }
       }
     }
   }
}


##
#
check_egt_overlimit = func {
   limit = getprop("/instrumentation/ecam/egt_overlimit");
   for(e=0; e < 4; e=e+1) {
     egt_degC = getprop("/engines/engine["~e~"]/egt_degc");
     if (egt_degC > 920 and limit != 1) {
       limit = 1;
       # reduce thrust according to SPD and VNAV...
       print("EGT Overlimit");
     }
     setprop("/instrumentation/ecam/egt_limit_arm",0);
     setprop("/instrumentation/ecam/egt_overlimit",limit);
   }
}



check_all_start = func {
  tt = 0;
  for(e=0; e < 4; e=e+1) {
    e_run  = getprop("/engines/engine["~e~"]/running");
    ##e_master = getprop("/controls/engines/engine["~e~"]/master");
    if (e_run == 1) {
      tt = tt+1;
    }
  }
  ##print("there are: "~tt~" engines running");
  if (tt == 4) {
    print("Complete engine start OK");
    setprop("/instrumentation/ecam/page","wheel");
    atnetwork.doReportEngineStart();
  }
}


start_apu = func {
  n2 = getprop("/engines/engine[4]/n2");
  tracer("[SYS] APU n2: "~n2);
  if (n2 > 25 and n2 < 27 and getprop("/controls/engines/engine[4]/cutoff") == 1) {
    tracer("[SYS] start APU fuel flow");
    setprop("/controls/engines/engine[4]/cutoff",0);
  }
  if (n2 > 25 and n2 < 50) {
    tracer("[SYS] start APU ignition");
    setprop("/controls/engines/engine[4]/ignition",1);
    #setprop("/controls/engines/engine[4]/starter",0);
    #setprop("/controls/engines/engine[4]/bleed",1);
  }
  if (n2 > 50) {
    tracer("[SYS] stop APU ignition");
    setprop("/controls/engines/engine[4]/ignition",0);
    ##setprop("/controls/engines/engine[4]/starter",0);
    setprop("/engines/engine[4]/off-start-run",2);
    setprop("/controls/electric/engine[4]/generator", 1);
    setprop("/controls/electric/engine[4]/bus-tie", 1);
    setprop("/controls/electric/APU-generator", 1);
    settimer(update_sd, 10);
  }

}


# TOGGLE REVERSER
togglereverser = func {
  r1 = "/controls/engines/engine[1]"; 
  r2 = "/controls/engines/engine[2]"; 
  rv1 = "/surface-positions/reverser-pos-norm"; 

  val = getprop(rv1);
  if (val == 0 or val == nil) {
    interpolate(rv1, 1.0, 1.4);  
    setprop(r1,"reverser","true");
    setprop(r2,"reverser", "true");
  } else {
    if (val == 1.0){
      interpolate(rv1, 0.0, 1.4);  
      setprop(r1,"reverser",0);
      setprop(r2,"reverser",0);
    }
  }
}

# UPDATE SYSTEMS
update_systems = func {
  update_clock();
  check_acquire_mode();

  baro = getprop("/instrumentation/altimeter/setting-inhg");
  setprop("/instrumentation/efis/inhg",baro);
  setprop("/instrumentation/efis/kpa",baro * 33.8637526);
  setprop("/instrumentation/efis/stab",getprop("/controls/flight/elevator-trim") * 15);

  if(getprop("/instrumentation/efis/baro-mode")== 0){
    setprop("/instrumentation/efis/baro", baro );
  }else{
    setprop("/instrumentation/efis/baro",baro * 33.8637526);
  }
  if(getprop("/instrumentation/efis_fo/baro-mode")== 0){
    setprop("/instrumentation/efis_fo/baro", baro );
  }else{
    setprop("/instrumentation/efis_fo/baro",baro * 33.8637526);
  }

  test = getprop("/environment/temperature-degc");
  if(test < 0.00) { 
    test = -1 * test;
  }
  setprop("/instrumentation/efis/fixed-temp",test);

  test = getprop("/controls/flight/elevator-trim");
  if(test < 0.00){
    test = -1 * test;
  }
  setprop("/instrumentation/efis/fixed-stab",test);

  test = getprop("/orientation/pitch-deg");
  if(test < 0.00){
    test = -1 * test;
  }
  setprop("/instrumentation/efis/fixed-pitch",test);

  test = getprop("/autopilot/settings/vertical-speed-fpm");
  if(test == nil ){
    test=0.0;
  }
  if(test < 0.00){
    test = -1 * test;
  }
  setprop("/instrumentation/efis/fixed-vs",test);


  force = getprop("/accelerations/pilot-g");
  if(force == nil) {
    force = 1.0;
  }
  eyepoint = (getprop("sim/view/config/y-offset-m") - (force * 0.01));
  if(getprop("/sim/current-view/view-number") < 1){
    setprop("/sim/current-view/y-offset-m",eyepoint);
  }

  var jsbsimGrossWgt = getprop("/fdm/jsbsim/inertia/weight-lbs");
  var grossWgtKg    = jsbsimGrossWgt*0.45359237;
  setprop("/fdm/jsbsim/inertia/weight-kg",grossWgtKg);

  var mach = getprop("velocities/mach");
  var alt  = getprop("position/altitude-ft");
  var chngAlt = getprop("instrumentation/afs/changeover-alt");
  if (chngAlt == nil) {
    chngAlt = 999999;
  }
  if (alt > chngAlt) {
    if (mach > 0.80) {
      setprop("instrumentation/afs/limit-bank-angle-max", 20);
      setprop("instrumentation/afs/limit-bank-angle-min", -20);
    }
    if (mach < 0.80 and mach > 0.60) {
      setprop("instrumentation/afs/limit-bank-angle-max", 25);
      setprop("instrumentation/afs/limit-bank-angle-min", -25);
    }
  } else {
    setprop("instrumentation/afs/limit-bank-angle-max", 30);
    setprop("instrumentation/afs/limit-bank-angle-min", -30);
  }

  settimer(update_systems,0.5);
}


update_metric = func {
  var posAltitudeFt = getprop("/position/altitude-ft");
  var altIndicatedAltFt = getprop("/instrumentation/altimeter/indicated-altitude-ft");
  ##setprop("/position/altitude-m",posAltitudeFt*FT2METRE); ## replaced in autopilot
  setprop("/instrumentation/altimeter/indicated-altitude-m",altIndicatedAltFt*FT2METRE);

  var atmos = Atmos.new();
  var static_inHg = getprop("/systems/static/pressure-inhg");
  var static_psi  = static_inHg/2.036259;
  var static_pascal = static_inHg/ChPaTOinHG;
  setprop("/systems/static/pressure-psi",static_psi);
  setprop("/systems/static/pressure-pa", static_pascal);
  var cabin_psi   = getprop("/instrumentation/pressurisation/cabin-pressure-psi");
  if (cabin_psi < 0) {
    cabin_psi = 0.0;
  }
  var h = atmos.convertPressureAltitude("psi",cabin_psi,"feet");
  setprop("/instrumentation/pressurisation/cabin-altitude-ft", h);
  var delta_psi   = cabin_psi-static_psi;
  setprop("/instrumentation/pressurisation/cabin-delta-psi", delta_psi);
  
  settimer(update_metric, 1.0);
}


increment_flight_mode1 = func {
  flt_mode = getprop("/instrumentation/ecam/flight-mode");
  alt = getprop("/instrumentation/altimeter/indicated-altitude-ft");
  if (flt_mode == 6 and  alt < 400) {
    flt_mode = flt_mode+1;
    setprop("/instrumentation/ecam/flight-mode",flt_mode);
  }
}

increment_flight_mode2 = func {
  flt_mode = getprop("/instrumentation/ecam/flight-mode");
  alt = getprop("/instrumentation/altimeter/indicated-altitude-ft");
  if (flt_mode == 7 and alt < 1500) {
    flt_mode = flt_mode+1;
    setprop("/instrumentation/ecam/flight-mode",flt_mode);
  }
}

# revert the system page back to synoptic 30sec after manual change
revert_sd = func {
  if (ecamRequestRef == 1) {
    setprop("/instrumentation/ecam/page",getprop("/instrumentation/ecam/synoptic"));
  }
  if (ecamRequestRef > 0) {
    ecamRequestRef=ecamRequestRef-1;
  }
}

update_sd = func {
  flt_mode = getprop("/instrumentation/ecam/flight-mode");
  setprop("/instrumentation/ecam/flight-mode", flt_mode);
}

var stepSpeedbrake = func(step) {
    if(props.globals.getNode("/sim/spoilers") != nil) {
        stepProps("/controls/flight/speedbrake", "/sim/spoilers", step);
        return;
    }
    # Hard-coded spoilers movement in 4 equal steps:
    var val = 0.25 * step + getprop("/controls/flight/speedbrake");
    setprop("/controls/flight/speedbrake", val > 1 ? 1 : val < 0 ? 0 : val);
}

toggleExternalServices = func() {
   var extAvail = getprop("/controls/electric/ground/external_1")+getprop("/controls/electric/ground/external_2")+getprop("/controls/electric/ground/external_3")+getprop("/controls/electric/ground/external_4");
   var fltMode = getprop("/instrumentation/ecam/flight-mode");
   var engRun = getprop("/engines/engine[0]/running")+getprop("/engines/engine[1]/running")+getprop("/engines/engine[2]/running")+getprop("/engines/engine[3]/running");
   if (extAvail > 0) {
       extAvail = 0;
       setprop("/controls/electric/contact/external_1", 0);
       setprop("/controls/electric/contact/external_2", 0);
       setprop("/controls/electric/contact/external_3", 0);
       setprop("/controls/electric/contact/external_4", 0);
   } else {
     if ((fltMode == 1 or fltMode == 12) and engRun == 0) {
       extAvail = 1;
     }
   }
   setprop("/controls/electric/ground/external_1", extAvail);
   setprop("/controls/electric/ground/external_2", extAvail);
   setprop("/controls/electric/ground/external_3", extAvail);
   setprop("/controls/electric/ground/external_4", extAvail);
}

testFunction = func() {
  var list = [{ id: 'HAM', type: 'VOR', distance: 13102184.19392603, frequency: 11790, bearing: 294.888738064345, elevation: 1754.124, lat: 34.86680599999999, name: 'HAMADAN VOR-DME', lon: 48.550611 }, { id: 'HAM', type: 'NDB', distance: 13102977.61851923, frequency: 31700, bearing: 294.8840878802988, elevation: 1754.124, lat: 34.865889, name: 'HAMADAN NDB', lon: 48.54066699999999 }, { id: 'HAM', type: 'VOR', distance: 16256266.62669764, frequency: 11310, bearing: 317.8553711815206, elevation: 56.99760000000001, lat: 53.68557499999999, name: 'HAMBURG VORTAC', lon: 10.204997 }];
  foreach(nav; list) {
    print("Id: "~nav.id);
  }
}


## FDM init
setlistener("/sim/signals/fdm-initialized", func {
 #flight mode 
 setprop("/instrumentation/ecam/flight-mode",1);
 setprop("/instrumentation/ecam/synoptic","door");
 setprop("/instrumentation/ecam/page","door");
 update_engines();
 settimer(update_metric, 2);
 settimer(update_radar,5);
 update_ewd();
 #setprop("fdm/jsbsim/propulsion/engine[0]/bleed-factor",0.0);
 #setprop("fdm/jsbsim/propulsion/engine[1]/bleed-factor",0.0);
 #setprop("fdm/jsbsim/propulsion/engine[2]/bleed-factor",0.0);
 #setprop("fdm/jsbsim/propulsion/engine[3]/bleed-factor",0.0);
 print("Aircraft Systems ready.");
});


## we should logoff from ATN if we exit.
setlistener("/sim/signals/exit", func {
    atnetwork.doLogoff();
});


# wait for master avionics to be on to start radar
#setlistener("/controls/switches/master-avionics", func(n) {
# print("Aircraft awake now! - "~n.getValue());
# update_radar();
# setprop("fdm/jsbsim/propulsion/engine[0]/bleed-factor",0.0);
# setprop("fdm/jsbsim/propulsion/engine[1]/bleed-factor",0.0);
# setprop("fdm/jsbsim/propulsion/engine[2]/bleed-factor",0.0);
# setprop("fdm/jsbsim/propulsion/engine[3]/bleed-factor",0.0);
#});

# 

# monitor eng 0 switch for ignition
setlistener("/controls/engines/engine[0]/master", func(n) {
  master = n.getValue();
  ign = getprop("/controls/engines/ign-start");
  apu = getprop("/engines/engine[4]/off-start-run");  # 2 for run.
  if (master == 1 and ign == 1 and apu == 2) {
    tracer("[SYS] start and ignite engine 0");
    if (getprop("/instrumentation/ecam/flight-mode") == 1) {
      #print("[ECAM] set SD page: engine");
      setprop("/instrumentation/ecam/flight-mode",2);
    }
    setprop("/controls/engines/engine[0]/starter",1);
  }
  if (master == 0 and ign == 0) {
    tracer("[SYS] cutoff engine 0");
    setprop("/controls/engines/engine[0]/cutoff",1);
    setprop("/instrumentation/ecam/flight-mode",1);
  }
});

# once we have engine bleed, open air valve
setlistener("/controls/pneumatic/engine[0]/bleed", func(n) {
  bleed = n.getValue();
  tracer("[SYS] engine[0] bleed: "~bleed);
  if (bleed == 1) {
    setprop("/controls/pressurization/apu/bleed-on",0);
    setprop("/controls/pressurization/engine[0]/bleed-on",1);
  } else {
    setprop("/controls/pressurization/engine[0]/bleed-on",0);
    setprop("/controls/pressurization/pack[0]/pack-on", 0);
  }
});

# monitor eng 1 switch for ignition
setlistener("/controls/engines/engine[1]/master", func(n) {
  master = n.getValue();
  ign = getprop("/controls/engines/ign-start");
  apu = getprop("/engines/engine[4]/off-start-run");  # 2 for run.
  if (master == 1 and ign == 1 and apu == 2) {
    tracer("[SYS] start and ignite engine 1");
    if (getprop("/instrumentation/ecam/flight-mode") == 1) {
      #print("[ECAM] set SD page: engine");
      setprop("/instrumentation/ecam/flight-mode",2);
    }
    setprop("/controls/engines/engine[1]/starter","true");
    setprop("/controls/pneumatic/engine[1]/bleed",1);
  }
  if (master == 0 and ign == 0) {
    setprop("/controls/engines/engine[1]/cutoff",1);
  }
});

# once we have engine bleed open air valve
setlistener("/controls/pneumatic/engine[1]/bleed", func(n) {
  bleed = n.getValue();
  tracer("[SYS] engine[1] bleed: "~bleed);
  if (bleed == 1) {
    setprop("/controls/pressurization/apu/bleed-on",0);
    setprop("/controls/pressurization/engine[1]/bleed-on",1);
  } else {
    setprop("/controls/pressurization/engine[1]/bleed-on",0);
    setprop("/controls/pressurization/pack[0]/pack-on", 0);
  }
});

# monitor eng 2 switch for ignition
setlistener("/controls/engines/engine[2]/master", func(n) {
  master = n.getValue();
  ign = getprop("/controls/engines/ign-start");
  apu = getprop("/engines/engine[4]/off-start-run");  # 2 for run.
  if (master == 1 and ign == 1 and apu == 2) {
    tracer("[SYS] start and ignite engine 2");
    if (getprop("/instrumentation/ecam/flight-mode") == 1) {
      #print("[ECAM] set SD page: engine");
      setprop("/instrumentation/ecam/flight-mode",2);
    }
    setprop("/controls/engines/engine[2]/starter","true");
  }
  if (master == 0 and ign == 0) {
    setprop("/controls/engines/engine[2]/cutoff",1);
    
  }
});
# once we have engine bleed open air valve
setlistener("/controls/pneumatic/engine[2]/bleed", func(n) {
  bleed = n.getValue();
  tracer("[SYS] engine[2] bleed: "~bleed);
  if (bleed == 1) {
    setprop("/controls/pressurization/apu/bleed-on",0);
    setprop("/controls/pressurization/engine[2]/bleed-on",1);
  } else {
    setprop("/controls/pressurization/engine[2]/bleed-on",0);
    setprop("/controls/pressurization/pack[1]/pack-on", 0);
  }
});

# monitor eng 3 switch for ignition
setlistener("/controls/engines/engine[3]/master", func(n) {
  master = n.getValue();
  ign = getprop("/controls/engines/ign-start");
  apu = getprop("/engines/engine[4]/off-start-run");  # 2 for run.
  flt_mode = getprop("/instrumentation/ecam/flight-mode");
  if (master == 1 and ign == 1 and apu == 2) {
    tracer("[SYS] start and ignite engine 3");
    if (getprop("/instrumentation/ecam/flight-mode") == 1) {
      #print("[ECAM] set SD page: engine");
      setprop("/instrumentation/ecam/flight-mode",2);
    }
    setprop("/controls/engines/engine[3]/starter","true");
  }
  if (master == 0 and ign == 0) {
    setprop("/controls/engines/engine[3]/cutoff",1);
    if (flt_mode == 11) {
      flt_mode = 12;
      setprop("/instrumentation/ecam/flight-mode",flt_mode);
    }
  }
});
# once we have engine bleed open air valve
setlistener("/controls/pneumatic/engine[3]/bleed", func(n) {
  bleed = n.getValue();
  tracer("[SYS] engine[3] bleed: "~bleed);
  if (bleed == 1) {
    setprop("/controls/pressurization/apu/bleed-on",0);
    setprop("/controls/pressurization/engine[3]/bleed-on",1);
  } else {
    setprop("/controls/pressurization/engine[3]/bleed-on",0);
    setprop("/controls/pressurization/pack[1]/pack-on", 0);
  }
});


# control APU bleed air to pressurisation
setlistener("/controls/pneumatic/APU-bleed", func(n) {
  bleed = n.getValue();
  tracer("[SYS] apu[0] bleed: "~bleed);
  if (bleed == 1) {
    setprop("/controls/pressurization/apu/bleed-on",1);
  } else {
    setprop("/controls/pressurization/apu/bleed-on",0);
  }
});


# control HOT-AIR valves from AIR PACKS
setlistener("/controls/pressurization/pack[0]/pack-on", func(n) {
   var pack = n.getValue();
   tracer("[SYS] pack[0] bleed: "~pack);
   if (pack == 1) {
     settimer(open_hotair, 1);
     var currBleed = getprop("fdm/jsbsim/propulsion/engine[0]/bleed-factor");
     tracer("[SYS] pack[0] on - currBleed: "~currBleed);
     setprop("fdm/jsbsim/propulsion/engine[0]/bleed-factor", currBleed+0.1);
     currBleed = getprop("fdm/jsbsim/propulsion/engine[1]/bleed-factor");
     tracer("[SYS] pack[0] on - currBleed: "~currBleed);
     setprop("fdm/jsbsim/propulsion/engine[1]/bleed-factor", currBleed+0.1);
   } else {
     setprop("/controls/pressurization/pack[0]/hotair-on",0);
     var currBleed = getprop("fdm/jsbsim/propulsion/engine[0]/bleed-factor");
     if (currBleed > 0) {
       tracer("[SYS] pack[0] off - currBleed: "~currBleed);
       setprop("fdm/jsbsim/propulsion/engine[0]/bleed-factor", currBleed-0.1);
     }
     currBleed = getprop("fdm/jsbsim/propulsion/engine[1]/bleed-factor");
     if (currBleed > 0) {
       tracer("[SYS] pack[0] off - currBleed: "~currBleed);
       setprop("fdm/jsbsim/propulsion/engine[1]/bleed-factor", currBleed-0.1);
     }
   }
});


setlistener("/controls/pressurization/pack[1]/pack-on", func(n) {
   var pack = n.getValue();
   tracer("[SYS] pack[1] bleed: "~pack);
   if (pack == 1) {
     settimer(open_hotair, 1);
     var currBleed = getprop("fdm/jsbsim/propulsion/engine[2]/bleed-factor");
     tracer("[SYS] pack[1] on - currBleed: "~currBleed);
     setprop("fdm/jsbsim/propulsion/engine[2]/bleed-factor", currBleed+0.1);
     currBleed = getprop("fdm/jsbsim/propulsion/engine[3]/bleed-factor");
     tracer("[SYS] pack[1] on - currBleed: "~currBleed);
     setprop("fdm/jsbsim/propulsion/engine[3]/bleed-factor", currBleed+0.1);
   } else {
     setprop("/controls/pressurization/pack[1]/hotair-on",0);
     var currBleed = getprop("fdm/jsbsim/propulsion/engine[2]/bleed-factor");
     if (currBleed > 0) {
       tracer("[SYS] pack[1] off - currBleed: "~currBleed);
       setprop("fdm/jsbsim/propulsion/engine[2]/bleed-factor", currBleed-0.1);
     }
     currBleed = getprop("fdm/jsbsim/propulsion/engine[3]/bleed-factor");
     if (currBleed > 0) {
       tracer("[SYS] pack[1] on - currBleed: "~currBleed);
       setprop("fdm/jsbsim/propulsion/engine[3]/bleed-factor", currBleed-0.1);
     }
   }
});

open_hotair = func() {
  if (getprop("/controls/pressurization/pack[0]/pack-on") == 1) {
    setprop("/controls/pressurization/pack[0]/hotair-on",1);
  }
  if (getprop("/controls/pressurization/pack[1]/pack-on") == 1) {
    setprop("/controls/pressurization/pack[1]/hotair-on",1);
  }
}

setlistener("fdm/jsbsim/propulsion/engine[0]/bleed-factor", func(n) {
   var engBleed = n.getValue();
   tracer("[SYS] jsbsim engine[0] bleed: "~engBleed);
});

setlistener("fdm/jsbsim/propulsion/engine[2]/bleed-factor", func(n) {
   var engBleed = n.getValue();
   tracer("[SYS] jsbsim engine[2] bleed: "~engBleed);
});

# monitor main gear wow
setlistener("/instrumentation/gear/wow", func(n) {
  touch = n.getValue();
  flt_mode = getprop("/instrumentation/ecam/flight-mode");
  if (flt_mode == nil) {
    flt_mode = 0;
  }
  ##
  autospd = getprop("/controls/flight/autospeedbrakes-armed");
  if (touch == 1) {
    if (flt_mode > 7 and flt_mode < 10) {
      flt_mode = 10;
      setprop("/instrumentation/ecam/flight-mode",flt_mode);
      ##setprop("instrumentation/afs/flight-control-mode", "ground");
      tracer("[SYS] Gear wow: "~touch~", flt_mode: "~flt_mode~", autospd: "~autospd);
      if (autospd == "true" or autospd == 1) {
        print("Enable auto-speedbrakes");
        setprop("/controls/flight/speedbrake",1);
        
      }
      atnetwork.doReportTouchdown();
    }
    spd_eng = getprop("/controls/flight/speedbrake");
    if (flt_mode > 10 and spd_eng == 1) {
      setprop("/controls/flight/speedbrake",0);
      print("retract speedbrakes..");
    }
  }
  if (touch == 0) {
    if (flt_mode == 5) {
      flt_mode = 6;
      setprop("/instrumentation/ecam/flight-mode",flt_mode);
      ##setprop("instrumentation/afs/flight-control-mode", "flight");
      settimer(increment_flight_mode1, 15);
      settimer(increment_flight_mode2, 120);
      atnetwork.doReportTakeoff();
    }
  }
});

## copy the autobrake control to autopilot settings
# 
setlistener("controls/gear/autobrakes", func(n) {
  var pos = n.getValue();
  var step = getprop("autopilot/autobrake/step");
  step = pos;
  if (pos == 0) {   ## OFF
    step = -1;
  }
  if (pos == 5) {  ## RTO
   step = -2;
  }
  setprop("autopilot/autobrake/step", step);
});

#setlistener("controls/gear/gear-down", func(n) {
#   position = n.getValue();
#});

setlistener("controls/switches/logo-light", func(n) {
  var val = n.getValue();
  if (val > 0) {
    setprop("controls/switches/logo-lights", 1);
  } else {
    setprop("controls/switches/logo-lights", 0);
  }
});


###########################
#  Flight Control modes
#
setlistener("instrumentation/afs/flight-control-ground-mode", func(n) {
  var val = n.getValue();
  if (val == 1) {
    setprop("instrumentation/afs/flight-control-mode", "ground");
  }
});

setlistener("instrumentation/afs/flight-control-flight-mode", func(n) {
  var val = n.getValue();
  if (val == 1) {
    setprop("instrumentation/afs/flight-control-mode", "flight");
  }
});

setlistener("instrumentation/afs/flight-control-flare-mode", func(n) {
  var val = n.getValue();
  if (val == 1) {
    setprop("instrumentation/afs/flight-control-mode", "flare");
  }
});


##########################
#
setlistener("controls/flight/flaps", func(n) {
   var pos = n.getValue();
   var posnorm = int(pos*10);
   var fltMode = getprop("instrumentation/ecam/flight-mode");
   tracer("[SYS] flap change - pos: "~pos~", posnorm: "~posnorm~", fltMode: "~fltMode);
   if (posnorm == 0 and fltMode > 5) {
     setprop("velocities/vls-factor",1.7);
   }
   if (posnorm == 2) {
     setprop("velocities/vls-factor", 1.26);
   }
   if (posnorm > 2 and fltMode < 6) {
     setprop("velocities/vls-factor", 1.14);
   }
});

#  SD page will revert to synoptic page 30sec after manual change
setlistener("/instrumentation/ecam/page", func(n) {
  page = n.getValue();
  if (page != getprop("/instrumentation/ecam/synoptic")) {
    ecamRequestRef=ecamRequestRef+1;
    settimer(revert_sd, 30);
  }

});


##
#  flight mode for ECAM
#

## manage the System Display according to flt phase here.
setlistener("/instrumentation/ecam/flight-mode", func(n) {
  flt_mode = n.getValue();
  tracer("[SYS] Flight phase: "~flt_mode);
  if (flt_mode == 1) {
    setprop("/instrumentation/ecam/synoptic","door");
  }
  if (flt_mode == 2) {
    setprop("/instrumentation/ecam/synoptic","engine");
    setprop("/controls/electric/ground/external_1", 0);
    setprop("/controls/electric/ground/external_2", 0);
    setprop("/controls/electric/ground/external_3", 0);
    setprop("/controls/electric/ground/external_4", 0);
  }
  if (flt_mode == 3) {
    setprop("/instrumentation/ecam/synoptic","engine");
  }
  if (flt_mode == 4) {
    setprop("/instrumentation/ecam/synoptic","engine");
  }
  if (flt_mode == 5) {
    setprop("/instrumentation/ecam/synoptic","engine");
  }
  if (flt_mode == 6) {
    setprop("/instrumentation/ecam/synoptic","engine");
  }
  # if in mode 7 - reduce TOGA to FLEX
  if (flt_mode == 7) { 
    setprop("/instrumentation/ecam/synoptic","engine");
  }
  if (flt_mode == 8) {
    setprop("/instrumentation/ecam/synoptic","cruise");
  }
  if (flt_mode == 9) { 
    setprop("/instrumentation/ecam/synoptic","wheel");
  }
  if (flt_mode == 10) {
    setprop("/instrumentation/ecam/synoptic","wheel");
  }
  if (flt_mode == 11) {
    setprop("/instrumentation/ecam/synoptic","wheel");
  }
  if (flt_mode == 12) {
    setprop("/instrumentation/ecam/synoptic","door");    
  }
  setprop("/instrumentation/ecam/page",getprop("/instrumentation/ecam/synoptic"));
});


# monitor APU start
setlistener("/controls/APU/run",func(n) {
  apu_req = n.getValue();
  flt_mode = getprop("/instrumentation/ecam/flight-mode");
  apu_run = getprop("/engines/engine[4]/off-start-run");
  tracer("[SYS] APU run state: "~apu_run~" apu req state: "~apu_req);
  if (apu_req == 1 and apu_run == 0) {
    tracer("[SYS] APU start/run:"~apu_run~", flt_mode:"~flt_mode);
    if(flt_mode == 1 or flt_mode > 10) {
      setprop("/instrumentation/ecam/synoptic","apu");
    }
    setprop("/instrumentation/ecam/page","apu");
    setprop("/engines/engine[4]/off-start-run",1);
    #setprop("/controls/engines/engine[4]/cutoff",1);
    ##setprop("/controls/engines/engine[4]/bleed",1);
    setprop("/controls/engines/engine[4]/starter", 1);
  }
  if (apu_req == 0 and apu_run == 2) {
    setprop("/controls/engines/engine[4]/cutoff",1);
    setprop("/controls/engines/engine[4]/ignition",0);
    setprop("/controls/engines/engine[4]/starter",0);
    setprop("/controls/pneumatic/APU-bleed",0);
    setprop("/instrumentation/ecam/synoptic","apu");
    setprop("/instrumentation/ecam/page","apu");
  }
    
});


setlistener("/controls/switches/seat-belt", func(n) {
  seat = n.getValue();
  ## seat belt switch to off
  if (seat == 0) {
    setprop("/instrumentation/switches/seatbelt-sign",0);
  }
  ## seat belt switch set to auto
  if (seat == 1) {
    if (getprop("/instrumentation/altimeter/indicated-altitude-ft") <10000 ) {
      setprop("/instrumentation/switches/seatbelt-sign",1);
    }
  }
  ## seat belt switch set to on
  if (seat == 2) {
    setprop("/instrumentation/switches/seatbelt-sign",1);
  }
});

# monitor efis Std baro mode
setlistener("/instrumentation/efis/baro-std-mode", func(n) {
  var stdMode = n.getValue();
  if (stdMode == 1) {
    setprop("/instrumentation/altimeter/setting-inhg",29.92);
  }
});

# if the ground external power source if removed, we should auto-disconnect connector
setlistener("/controls/electric/ground/external_1", func(n) {
   var connect = n.getValue();
   if (connect == 0 and getprop("/controls/electric/contact/external_1") == 1) {
     setprop("/controls/electric/contact/external_1", 0);
   }
});

setlistener("/controls/electric/ground/external_2", func(n) {
   var connect = n.getValue();
   if (connect == 0 and getprop("/controls/electric/contact/external_2") == 1) {
     setprop("/controls/electric/contact/external_2", 0);
   }
});

setlistener("/controls/electric/ground/external_3", func(n) {
   var connect = n.getValue();
   if (connect == 0 and getprop("/controls/electric/contact/external_3") == 1) {
     setprop("/controls/electric/contact/external_3", 0);
   }
});

setlistener("/controls/electric/ground/external_4", func(n) {
   var connect = n.getValue();
   if (connect == 0 and getprop("/controls/electric/contact/external_4") == 1) {
     setprop("/controls/electric/contact/external_4", 0);
   }
});


setlistener("/controls/anti-ice/engine[0]/inlet-heat", func(n) {
   var anti = 0;
   var currBleed = getprop("fdm/jsbsim/propulsion/engine[0]/bleed-factor");
   var heat = n.getValue();
   if (heat == 0) {
     anti = -0.12;
     if (currBleed == 0) {
       anti = 0.0;
     }
   } else {
     anti = 0.12;
   }
   tracer("[SYS] inlet-heat - heat: "~heat~", currBleed: "~currBleed~", anti: "~anti);
   setprop("fdm/jsbsim/propulsion/engine[0]/bleed-factor", currBleed+anti);
});

setlistener("/controls/anti-ice/engine[1]/inlet-heat", func(n) {
   var anti = 0;
   var currBleed = getprop("fdm/jsbsim/propulsion/engine[1]/bleed-factor");
   if (n.getValue() == 0) {
     anti = -0.12;
     if (currBleed == 0) {
       anti = 0.0;
     }
   } else {
     anti = 0.12;
   }
   setprop("fdm/jsbsim/propulsion/engine[1]/bleed-factor", currBleed+anti);
});

setlistener("/controls/anti-ice/engine[2]/inlet-heat", func(n) {
   var anti = 0;
   var currBleed = getprop("fdm/jsbsim/propulsion/engine[2]/bleed-factor");
   if (n.getValue() == 0) {
     anti = -0.12;
     if (currBleed == 0) {
       anti = 0.0;
     }
   } else {
     anti = 0.12;
   }
   setprop("fdm/jsbsim/propulsion/engine[2]/bleed-factor", currBleed+anti);
});

setlistener("/controls/anti-ice/engine[3]/inlet-heat", func(n) {
   var anti = 0;
   var currBleed = getprop("fdm/jsbsim/propulsion/engine[3]/bleed-factor");
   if (n.getValue() == 0) {
     anti = -0.12;
     if (currBleed == 0) {
       anti = 0.0;
     }
   } else {
     anti = 0.12;
   }
   setprop("fdm/jsbsim/propulsion/engine[3]/bleed-factor", currBleed+anti);
});


setlistener("/sim/airport/closest-airport-id", func() {
  atnetwork.doUpdateController();
});

setlistener("instrumentation/flightdirector/mode-reversion", func(n) {
  var reversion = n.getValue();
  if (reversion == 1) {
    settimer(clearReversion, 5);
  }
});

clearReversion = func() {
  setprop("instrumentation/flightdirector/mode-reversion", 0);
}


#################################
# old radar codebase
#
old_radar = func() {
  ## plot AI aircraft on radar
  ##
  ai_craft = props.globals.getNode("/ai/models").getChildren("aircraft");
  var aiPos = 0;
  for(i=0; i<size(ai_craft);i=i+1) {
    var inRange = getprop("/ai/models/aircraft["~i~"]/radar/in-range");
    setprop("instrumentation/radar/ai["~aiPos~"]/valid",0);
    setprop("instrumentation/radar/ai["~aiPos~"]/brg-offset",0);
    setprop("instrumentation/radar/ai["~aiPos~"]/norm-dist",0);
    setprop("instrumentation/radar/ai["~aiPos~"]/diff-alt-fl",0);
    setprop("instrumentation/radar/ai["~aiPos~"]/callsign","");
    if (inRange == 1) {
      tgt_offset=getprop("/ai/models/aircraft[" ~ i ~ "]/radar/bearing-deg");
      if(tgt_offset == nil) {
        tgt_offset = 0.0;
      }
      tgt_offset -= true_heading;
      if (tgt_offset < 0){
        tgt_offset = 360-tgt_offset;
      }
      if (tgt_offset > 360){
        tgt_offset -=360;
      }
      setprop("/instrumentation/radar/ai[" ~ aiPos ~ "]/brg-offset",tgt_offset);
      test_dist=getprop("/instrumentation/nd[0]/range");
      test1_dist = getprop("/ai/models/aircraft[" ~ i ~ "]/radar/range-nm");
      if(test1_dist == nil) {
        test1_dist=0.0;
      }
      norm_dist = (1 / test_dist) * test1_dist;
      setprop("/instrumentation/radar/ai[" ~ aiPos ~ "]/norm-dist", norm_dist);
      var aiAlt = getprop("ai/models/aircraft["~i~"]/position/altitude-ft");
      var diffAlt = (myAlt-aiAlt)/100;
      setprop("/instrumentation/radar/ai["~aiPos~"]/diff-alt-fl", diffAlt);
      setprop("/instrumentation/radar/ai["~aiPos~"]/valid",1);
      setprop("/instrumentation/radar/ai["~aiPos~"]/callsign", getprop("/ai/models/aircraft["~i~"]/callsign"));
      aiPos = aiPos + 1;
    }
  }

  ## plot multiplayer aircraft
  ##
  var radarRange = getprop("/instrumentation/nd[0]/range");
  var mpPos = 0;
  var playerNum = getprop("ai/models/num-players");
  for(i=0;i<playerNum;i=i+1) {
    ##var aiHdg = getprop("/ai/models/multiplayer["~i~"]/radar/bearing-deg");
    var aiHdg = getprop("ai/models/multiplayer["~i~"]/bearing-to");
    ##var aiHdg = getprop("ai/models/multiplayer["~i~"]/radar/rotation");
    var valid    = getprop("/ai/models/multiplayer["~i~"]/valid");
    var base = props.globals.getNode("/instrumentation/radar/mp["~mpPos~"]",1);
    var validNode = base.getNode("valid",1);
    validNode.setBoolValue(valid);
    var idNode = base.getNode("callsign",1);
    idNode.setValue("");
    var distNode = base.getNode("norm-dist",1);
    distNode.setDoubleValue(-1);
    var brgNode = base.getNode("brg-offset",1);
    brgNode.setDoubleValue(0.0);
    var crsNode = base.getNode("crs",1);
    crsNode.setDoubleValue(0.0);
    var altNode = base.getNode("altitude-offset",1);
    altNode.setIntValue(0);
    if (aiHdg != nil and valid == 1) {
      var callsign = getprop("/ai/models/multiplayer["~i~"]/callsign");
      var tgt_offset = aiHdg;
      if (mag_heading > 180) {
        var dif = 360-mag_heading;
        tgt_offset = aiHdg+dif;
      } else {
        var dif = mag_heading;
        tgt_offset = aiHdg-dif;
      }
      test1_dist = getprop("ai/models/multiplayer["~i~"]/distance-to-nm");
      if(test1_dist == nil) {
        test1_dist=0.0;
      }
      norm_dist= (1 / radarRange) * test1_dist;
      if (norm_dist <= 1) {
        var aiAlt = getprop("/ai/models/multiplayer["~i~"]/position/altitude-ft");
        var diffAlt = (aiAlt-myAlt)/100;
        altNode.setIntValue(diffAlt);
        brgNode.setDoubleValue(tgt_offset);
        crsNode.setDoubleValue(aiHdg);
        distNode.setDoubleValue(norm_dist);
        idNode.setValue(callsign);
        validNode.setBoolValue(1);
        mpPos += 1;
      }
    }
  }
  for(i=mpPos; i < maxMPCnt; i=i+1) {
    setprop("/instrumentation/radar/mp["~i~"]/valid",0);
  }
  maxMPCnt = mpPos+1;

## plot waypoints 
  ##
  var wpCnt = 0;
  var wp_points = props.globals.getNode("/autopilot/route-manager/route").getChildren("wp");
  for(i=1;i <size(wp_points); i=i+1) {
    var tgt_offset = -9999;
    var wpDist = 9999;
    var wpLat = getprop("/autopilot/route-manager/route/wp["~i~"]/latitude-deg");
    var wpLon = getprop("/autopilot/route-manager/route/wp["~i~"]/longitude-deg");
    var wpId  = getprop("/autopilot/route-manager/route/wp["~i~"]/id");
    if (wpLat != nil and wpLon != nil and find("(",wpId) == -1 and find(")",wpId) == -1) {
      var wpPos = geo.Coord.new();
      wpPos.set_latlon(wpLat, wpLon, 0);
      var wpCourse = currentPos.course_to(wpPos);
      wpDistMetre   = currentPos.distance_to(wpPos);
      wpDist = wpDistMetre*METRE2NM;
      if (mag_heading < wpCourse) {
        tgt_offset = wpCourse-mag_heading;
        #print("[radar] "~wpId~" mag_head: "~mag_heading~", wpCourse: "~wpCourse~", tgt_offset: "~tgt_offset);
      } else {
        tgt_offset = 360-(mag_heading-wpCourse);
        #print("[radar] "~wpId~" mag_head: "~mag_heading~", wpCourse: "~wpCourse~", tgt_offset: "~tgt_offset);
      }
      if (tgt_offset < 0){
        tgt_offset = 360-tgt_offset;
      }
      if (tgt_offset > 360){
        tgt_offset -=360;
      }
    }
    if (wpDist <= radarRange) {
      var base = props.globals.getNode("/instrumentation/radar/wp["~wpCnt~"]",1);
      wpCnt = wpCnt + 1;
      var valid = base.getNode("valid",1);
      valid.setBoolValue(1);
      var brg = base.getNode("brg-offset",1);
      brg.setDoubleValue(tgt_offset);
      var crs = base.getNode("crs",1);
      crs.setDoubleValue(wpCourse);
      var dist = base.getNode("dist-norm", 1);
      dist.setDoubleValue(wpDist/radarRange);
      var id = base.getNode("id",1);
      id.setValue(wpId);
    }
  }

  if (wpCnt < radarLastCnt) {
    for(i=wpCnt;i<=radarLastCnt;i=i+1) {
      var base = props.globals.getNode("/instrumentation/radar/wp["~i~"]",0);
      if (base != nil) {
        var valid = base.getNode("valid",1);
        valid.setBoolValue(0);
        var brg = base.getNode("brg-offset",1);
        brg.setDoubleValue(0);
        var dist = base.getNode("dist-norm", 1);
        dist.setDoubleValue(0);
        var id = base.getNode("id",1);
        id.setValue("");
      }
    }
  }
  radarLastCnt = wpCnt;

  ## plot the GPS ref navaid on radar
  ##
  var navBrg  = getprop("/instrumentation/gps/ref-navaid/bearing-deg");
  var navBrgMag  = getprop("/instrumentation/gps/ref-navaid/mag-bearing-deg");
  var navDist = getprop("/instrumentation/gps/ref-navaid/distance-nm");
  if (navBrg != nil) {
    var tgt_offset = navBrg-mag_heading;    ##+true_heading;
    if (tgt_offset < 0) {
      tgt_offset +=360;
    }
    if (tgt_offset > 360) {
      tgt_offset -=360;
    }
    var navaidId = getprop("/instrumentation/gps/ref-navaid/id");
    if (navDist < radarRange and navaidId != '') {
      setprop("/instrumentation/radar/navaid-valid",1);
      setprop("/instrumentation/radar/navaid-id", navaidId);
    } else {
      setprop("/instrumentation/radar/navaid-valid",0);
      setprop("/instrumentation/radar/navaid-id", "");
    }
    setprop("/instrumentation/radar/navaid-brg",tgt_offset);
    setprop("/instrumentation/radar/navaid-dist-norm",navDist/radarRange);
  }
  

  ## plot nearest airports
  ##
  var pos = 0;
  var arptData = getprop("instrumentation/efis[0]/inputs/ARPT");
  
    ##var aptList = airportinfo("airport", radarRange);
    ##var listSize = size(aptList);
    ##tracer("    airportList size: "~listSize);
    ##foreach (var apt; aptList) {
    ##debug.dump(apt);
    if (pos > 0) {
      var base = props.globals.getNode("/instrumentation/radar/airports["~pos~"]",1);
      var valid = base.getNode("valid",1);
      valid.setBoolValue(0);
      var brg = base.getNode("brg-offset",1);
      brg.setDoubleValue(0.0);
      var crs = base.getNode("crs", 1);
      crs.setDoubleValue(0.0);
      var dist = base.getNode("dist-norm", 1);
      dist.setDoubleValue(0.0);
      var id = base.getNode("id",1);
      id.setValue("");
      if (apt != nil) {
        var aptPos = geo.Coord.new();
        aptPos.set_latlon(apt.lat, apt.lon, apt.elevation);
        var aptCourse = currentPos.course_to(aptPos);
        if (mag_heading > 180) {
          var dif = 360-mag_heading;
          tgt_offset = aptCourse+dif;
        } else {
          var dif = mag_heading;
          tgt_offset = aptCourse-dif;
        }
        aptDistMetre   = currentPos.distance_to(aptPos);
        aptDist = aptDistMetre*METRE2NM;
        if (aptDist > 2) {
          id.setValue(apt.id);
          dist.setDoubleValue(aptDist/radarRange);
          brg.setDoubleValue(tgt_offset);
          crs.setDoubleValue(aptCourse);
          valid.setBoolValue(1);
          pos = pos + 1;
        }
      }
    }
  ##}
  #for(var r = pos; r <= radarLastAirportCnt; r=r+1) {
  #  var base = props.globals.getNode("/instrumentation/radar/airports["~r~"]",1);
  #  var valid = base.getNode("valid",1);
  #  valid.setBoolValue(0);
  #  var brg = base.getNode("brg-offset",1);
  #  brg.setDoubleValue(0.0);
  #  var dist = base.getNode("dist-norm", 1);
  #  dist.setDoubleValue(0.0);
  #  var id = base.getNode("id",1);
  #  id.setValue("");
  #}
  #radarLastAirportCnt = pos;



}


settimer(init_controls, 0);
