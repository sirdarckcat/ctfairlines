#############################################################################
#
# Airbus Flight Management.
#
# Abstract:
#    This is a utility helper class for the moment, later to be expanded to do more.
# 
# 
# Author: S.Hamilton Jan 2010
#
#
#   Copyright (C) 2010 Scott Hamilton
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

fms_trace = 0;


## mode constants
LNAV_OFF=0;
LNAV_HDG=1;
LNAV_TRACK=2;
LNAV_LOC=3;
LNAV_FMS=4;
LNAV_RWY=5;

VNAV_OFF=0;
VNAV_ALTs=1;
VNAV_VS=2;
VNAV_OPCLB=3;
VNAV_FPA=4;
VNAV_OPDES=5;
VNAV_CLB=6;
VNAV_ALTCRZ=7;
VNAV_DES=8;
VNAV_GS=9;
VNAV_SRS=10;
VNAV_LEVEL=11;

SPD_OFF=0;
SPD_TOGA=1;
SPD_FLEX=2;
SPD_THRCLB=3;
SPD_SPEED=4;
SPD_MACH=5;
SPD_CRZ=6;
SPD_THRDES=7;
SPD_THRIDL=8;

lnavStr = ["off","HDG","TRK","LOC","NAV","RWY"];
vnavStr = ["off","ALT(s)","V/S","OP CLB","FPA","OP DES","CLB","ALT CRZ","DES","G/S","SRS","LEVEL"];
spdStr  = ["off","TOGA","FLEX","THR CLB","SPEED","MACH","CRZ","THR DES","THR IDL"];

MANAGED_MODE = -1;
SELECTED_MODE = 0;






var AirbusFMS = {
   new: func() {
   
     var m = {parents : [AirbusFMS]};
     m.FMSnode = props.globals.getNode("/instrumentation/fms",1);
     m.activeFpln = m.FMSnode.getNode("plan[0]",1);
     m.secFpln = m.FMSnode.getNode("plan[1]",1);
     m.activePlan = [];
     m.lastWP = 0;
     m.secondPlan = [];
     m.depDB = nil;
     m.arvDB = nil;
     m.flightplan = nil;
     setprop("instrumentation/fms/plan[0]/display-nodes/current-page",0);
     setprop("instrumentation/fms/plan[0]/display-nodes/current-wp",0);
     setprop("/autopilot/route-manager/disable-fms", 1);
     m.version = "V1.1.7";

     setlistener("/sim/signals/fdm-initialized", func m.init());
     setlistener("/autopilot/route-manager/current-wp", func m.updateCurrentWP());

     return m;
   },

   delegate: func(fp) {
     print("initiate FMS delegate");
     me.flightplan = fp;
     return me;
   },

#############################################################################
#  output a debug message to stdout or file.
#############################################################################
tracer : func(msg) {
  var timeStr = getprop("/sim/time/gmt-string");
  var curAltStr = getprop("/position/altitude-ft");
  var curVnav    = getprop("/instrumentation/flightdirector/vnav");
  var curLnav    = getprop("/instrumentation/flightdirector/lnav");
  var curSpd     = getprop("/instrumentation/flightdirector/spd");
  var athrStr   = getprop("/instrumentation/flightdirector/at-on");
  var ap1Str     = getprop("/instrumentation/flightdirector/ap");
  var altHold = getprop("/autopilot/settings/target-altitude-ft");
  var vsHold  = getprop("/autopilot/settings/vertical-speed-fpm");
  var spdHold = getprop("/autopilot/settings/target-speed-kt");
  if (curVnav == nil) curVnav = "0";
  if (curLnav == nil) curLnav = "0";
  if (curSpd  == nil) curSpd  = "0";
  if (fms_trace > 0) {
    print("[AFMS] time: "~timeStr~" alt: "~curAltStr~", - "~msg);
    if (fms_trace > 1) {
      print("[AFMS] vnav: "~me.afs.vertical_text[curVnav]~", lnav: "~me.afs.lateral_text[curLnav]~", spd: "~me.afs.spd_text[curSpd]);
    }
  }
},

   ####
   # init
   ####
   init : func() {
      print("AFMS "~me.version~" ready");
      for(var w=0; w < 9; w=w+1) {
        var wp = me.activeFpln.getNode("display-nodes/wp["~w~"]",1);
        wp.getNode("id",1).setValue("");
        wp.getNode("parent",1).setValue("");
        wp.getNode("spd-lim-display",1).setValue("0.00");
        wp.getNode("alt-lim-display",1).setValue("FL000");
        wp.getNode("time-utc-display",1).setValue("00:00");
        wp.getNode("active", 1).setBoolValue(0);
        wp.getNode("track",1).setDoubleValue(0.0);
        wp.getNode("dist",1).setIntValue(0);
      }
      ##settimer(func me.update(), 0);
      ##settimer(func me.slow_update(), 0);
      setlistener("/instrumentation/fms/plan[0]/display-nodes/current-page", func me.updateDisplay());
    },

   ### for high prio tasks ###
   update : func() {
     settimer(func me.update(), 1);
   }, 

   ### for low prio tasks ###
   slow_update : func() {
     me.tracer("FMS update");
     settimer(func me.slow_update(), 3);
   },

   ####
   # evaluate managed VNAV
   ####
   evaluateManagedVNAV : func() {
     var retVNAV = VNAV_OFF;
     me.tracer("evaluateManagedVNAV");
     ##var curAlt = getprop("/instrumentation/altimeter/indicated-altitude-ft");
     var curAlt = getprop("/position/altitude-ft");
     var curFlightMode = getprop("/instrumentation/ecam/flight-mode");
     var redAlt = getprop("/instrumentation/afs/thrust-reduce-alt");
     var accAlt = getprop("/instrumentation/afs/thrust-accel-alt");
     var crzAlt = getprop("/instrumentation/afs/thrust-cruise-alt");
     var crzAcquire = getprop("/instrumentation/afs/acquire_crz");
     var accelArm = getprop("/instrumentation/flightdirector/accel-arm");
     var clbArm   = getprop("/instrumentation/flightdirector/climb-arm");
     var flapPos = me.getFlapConfig();
     var vnavMode = getprop("/instrumentation/flightdirector/vnav");
     var lnavMode = getprop("/instrumentation/flightdirector/lnav");
     var spdMode = getprop("/instrumentation/flightdirector/spd");
     var vsi = getprop("/instrumentation/vertical-speed-indicator/indicated-speed-fpm");
     var altSelect = getprop("/instrumentation/afs/vertical-alt-mode");
     var vsSelect = getprop("/instrumentation/afs/vertical-vs-mode");
     var spdSelect = getprop("/instrumentation/afs/speed-mode");
     var apMode = getprop("/instrumentation/flightdirector/autopilot-on");
     var foundTD = getprop("/instrumentation/flightdirector/past-td");
     var bothSelect = MANAGED_MODE;
     if (altSelect == SELECTED_MODE or vsSelect == SELECTED_MODE) {
       bothSelect = SELECTED_MODE;
     }
      me.tracer("bothSelect: "~bothSelect);
      me.tracer("clbArm: "~clbArm);
      me.tracer("crzAcquire: "~crzAcquire);
      me.tracer("spdMode: "~spdMode);
      me.tracer("flapPos: "~flapPos);
      me.tracer("curFlightMode: "~curFlightMode);

      if (bothSelect == MANAGED_MODE) {
        setprop("instrumentation/afs/vertical-lvl-managed-mode",-1);
      }
       ## managed Speed Reference System mode
       if (curAlt < accAlt and clbArm == 0 and bothSelect == MANAGED_MODE and (spdMode == SPD_FLEX or spdMode == SPD_TOGA or spdMode == SPD_THRCLB) and flapPos > 0 ) {
         retVNAV = VNAV_SRS;
         me.tracer("retVNAV = VNAV_SRS");
       }
       ## managed cruise alt
       if (curAlt > (crzAlt-5000) and bothSelect == MANAGED_MODE) {
         retVNAV = VNAV_ALTCRZ;
         me.tracer("retVNAV = VNAV_ALTCRZ");
       }
       ## managed climb
       if (curAlt >= accAlt and curAlt < (crzAlt-500) and crzAcquire == 0) {
         if (lnavMode == LNAV_FMS) {
           retVNAV = VNAV_CLB;
           me.tracer("retVNAV = VNAV_CLB");
         } else {
           retVNAV = VNAV_OPCLB;
           me.tracer("retVNAV = VNAV_OPCLB");
           setprop("instrumentation/afs/vertical-lvl-managed-mode",0);
         }
       }
       ## managed descend
       var wpLen = getprop("/autopilot/route-manager/route/num");
       var curWp = getprop("/autopilot/route-manager/current-wp");
       if (curWp > 0) {
         me.tracer("foundTD: "~foundTD~", bothSelect: "~bothSelect~", lnavMode: "~lnavMode);
         if (foundTD == 1 and curAlt > 400) {
           if(bothSelect == MANAGED_MODE) {
             if (lnavMode == LNAV_FMS) {
               retVNAV = VNAV_DES;
               me.tracer("retVNAV = VNAV_DES");
             } else {
               retVNAV = VNAV_OPDES;
               me.tracer("retVNAV = VNAV_OPDES");
               setprop("instrumentation/afs/vertical-lvl-managed-mode",0);
             }
           } else {
             retVNAV = VNAV_OPDES;
             me.tracer("retVNAV = VNAV_OPDES");
             setprop("instrumentation/afs/vertical-lvl-managed-mode",0);
           }
         }
         if (getprop("instrumentation/afs/target-altitude-ft") < crzAlt and crzAcquire == 1 and bothSelect == MANAGED_MODE) {
           retVNAV = VNAV_DES;
         }
       }
       if (getprop("/position/altitude-agl-ft") < 400 and vnavMode == VNAV_GS and lnavMode == LNAV_LOC) {
         ## combined LAND mode....
       }
     
     return retVNAV;
   },

   ##########
   # evaluate VNAV
   ##########
   evaluateVNAV : func() {
     var retVNAV = VNAV_OFF;
     var apMode = getprop("/instrumentation/flightdirector/autopilot-on");
     if (apMode == 1) {
       retVNAV = me.evaluateManagedVNAV();

       var altSelect = getprop("/instrumentation/afs/vertical-alt-mode");
       var vsSelect = getprop("/instrumentation/afs/vertical-vs-mode");
       if (altSelect == SELECTED_MODE) {
         retVNAV = VNAV_ALTs;
         setprop("instrumentation/afs/vertical-lvl-managed-mode",0);
       }
       if (vsSelect == SELECTED_MODE) {
         retVNAV = VNAV_VS;
         setprop("instrumentation/afs/vertical-lvl-managed-mode",0);
       }
     } else {
       retVNAV = VNAV_OFF;
       setprop("instrumentation/afs/vertical-lvl-managed-mode",0);
       setprop("instrumentation/flightdirector/alt-acquire-mode",0);
     }
     return retVNAV;
   },


   #############
   # evaluate managed LNAV
   #
   evaluateManagedLNAV : func() {
     var retLNAV = LNAV_OFF;
     var agl = getprop("/position/altitude-agl-ft");
     var latMode = getprop("instrumentation/afs/lateral-mode");
     var apMode = getprop("/instrumentation/flightdirector/autopilot-on");
     var fltMode = getprop("instrumentation/ecam/flight-mode");
     var spd = getprop("instrumentation/flightdirector/spd");

     if (apMode == 1) {
       if (latMode == MANAGED_MODE) {
         setprop("instrumentation/afs/lateral-managed-mode",-1);
         retLNAV = LNAV_FMS;
         if ((fltMode >= 2 and fltMode <= 5) and (spd == SPD_FLEX or spd == SPD_TOGA)) {
           retLNAV = LNAV_RWY;
         }
       } else {
         setprop("instrumentation/afs/lateral-managed-mode",0);
         retLNAV = LNAV_HDG;
       }
     } else {
       setprop("instrumentation/afs/lateral-managed-mode",0);
     }
     
     return retLNAV;
   },

   evaluateLateral : func() {
     return me.evaluateManagedLNAV();
   },


   #################
   # evaluate managed SPD
   #################
   evaluateManagedSpeed : func() {
     var retSpeed = SPD_OFF;
     var altMode = getprop("/instrumentation/afs/vertical-alt-mode");
     var vsMode = getprop("/instrumentation/afs/vertical-vs-mode");
     var apMode = getprop("/instrumentation/flightdirector/autopilot-on");
     var athrMode = getprop("/instrumentation/flightdirector/at-on");
     var vnav = getprop("instrumentation/flightdirector/vnav");
     var lnav  = getprop("instrumentation/flightdirector/lnav");
     var spdMode = getprop("instrumentation/afs/speed-mode");
     var curAlt = getprop("/position/altitude-ft");
     var curFlightMode = getprop("/instrumentation/ecam/flight-mode");
     var redAlt = getprop("/instrumentation/afs/thrust-reduce-alt");
     var accAlt = getprop("/instrumentation/afs/thrust-accel-alt");
     var crzAlt = getprop("/instrumentation/afs/thrust-cruise-alt");
     var crzAcquire = getprop("/instrumentation/afs/acquire_crz");
     var accelArm = getprop("/instrumentation/flightdirector/accel-arm");
     var clbArm   = getprop("/instrumentation/flightdirector/climb-arm");
     var afterTD  = getprop("instrumentation/flightdirector/past-td");
     var decelAlt = getprop("instrumentation/afs/decelAlt");
     var changeoverAlt = getprop("instrumentation/afs/changeover-alt");
     
     if (apMode == 1) {
       if (spdMode == MANAGED_MODE) {
         setprop("instrumentation/afs/speed-managed-mode",-1);
         if (curAlt >= accAlt and curAlt < crzAlt and (vnav == VNAV_CLB or vnav == VNAV_SRS) and crzAcquire == 0) {
           retSpeed = SPD_THRCLB;
         }
         if (curAlt > 5000 and afterTD == 1) {
           retSpeed = SPD_THRDES;
         }
         if(curAlt > crzAlt-100 and afterTD == 0) {
           retSpeed = SPD_CRZ;
         }
       } else {
         setprop("instrumentation/afs/speed-managed-mode",SELECTED_MODE);
         if (curAlt > changeoverAlt) {
           retSpeed = SPD_MACH;
         } else {
           retSpeed = SPD_SPEED;
         }
       }
     } else {
       setprop("instrumentation/afs/speed-managed-mode",SELECTED_MODE);
       retSpeed = SPD_OFF;
     }
     return retSpeed;
   },


   #########################
   # evaluateArmedVertical
   #########################
   evaluteArmedVertical : func() {
     var retMode = VNAV_OFF;
     var altMode = getprop("/instrumentation/afs/vertical-alt-mode");
     var vsMode = getprop("/instrumentation/afs/vertical-vs-mode");
     var apMode = getprop("/instrumentation/flightdirector/autopilot-on");
     var athrMode = getprop("/instrumentation/flightdirector/at-on");
     var vnav = getprop("instrumentation/flightdirector/vnav");
     var lnav  = getprop("instrumentation/flightdirector/lnav");
     var spdMode = getprop("instrumentation/afs/speed-mode");
     var curAlt = getprop("/position/altitude-ft");
     var curFlightMode = getprop("/instrumentation/ecam/flight-mode");
     var redAlt = getprop("/instrumentation/afs/thrust-reduce-alt");
     var accAlt = getprop("/instrumentation/afs/thrust-accel-alt");
     var crzAlt = getprop("/instrumentation/afs/thrust-cruise-alt");
     var crzAcquire = getprop("/instrumentation/afs/acquire_crz");
     var accelArm = getprop("/instrumentation/flightdirector/accel-arm");
     var clbArm   = getprop("/instrumentation/flightdirector/climb-arm");
     var afterTD  = getprop("instrumentation/flightdirector/past-td");
     var decelAlt = getprop("instrumentation/afs/decelAlt");

     return retMode;   
   },


   #########################
   # evaluateArmedLateral
   #########################
   evaluteArmedLateral : func() {
     var retMode = LNAV_OFF;
     var altMode = getprop("/instrumentation/afs/vertical-alt-mode");
     var vsMode = getprop("/instrumentation/afs/vertical-vs-mode");
     var apMode = getprop("/instrumentation/flightdirector/autopilot-on");
     var athrMode = getprop("/instrumentation/flightdirector/at-on");
     var vnav = getprop("instrumentation/flightdirector/vnav");
     var lnav  = getprop("instrumentation/flightdirector/lnav");
     var spdMode = getprop("instrumentation/afs/speed-mode");
     var curAlt = getprop("/position/altitude-ft");
     var curFlightMode = getprop("/instrumentation/ecam/flight-mode");
     var redAlt = getprop("/instrumentation/afs/thrust-reduce-alt");
     var accAlt = getprop("/instrumentation/afs/thrust-accel-alt");
     var crzAlt = getprop("/instrumentation/afs/thrust-cruise-alt");
     var crzAcquire = getprop("/instrumentation/afs/acquire_crz");
     var accelArm = getprop("/instrumentation/flightdirector/accel-arm");
     var clbArm   = getprop("/instrumentation/flightdirector/climb-arm");
     var afterTD  = getprop("instrumentation/flightdirector/past-td");
     var decelAlt = getprop("instrumentation/afs/decelAlt");

     return retMode;   
   },



   ####
   #  calculate the current flap position
   #
   getFlapConfig : func() {
     var flapConfig = 0;
     var currFlapPos = getprop("/fdm/jsbsim/fcs/flap-cmd-norm");
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
     return flapConfig;
    },

    ###################################
    #  called from the autopilot/route-manager/current-wp tied property listener
    #
    updateCurrentWP : func() {
      var rteWP = getprop("autopilot/route-manager/current-wp");
      if (rteWP == nil) {
        rteWP = -1;
      }
      if (rteWP > 0) {
        var rteWPId = getprop("autopilot/route-manager/route/wp["~rteWP~"]/id");
        var planIdx = me.findWPName(rteWPId);
        if (planIdx != nil) {
          var tmp = int(planIdx/9);
          var mod = (planIdx-(tmp*9));
          setprop("instrumentation/fms/plan[0]/display-nodes/current-wp", mod);
          var currPage = getprop("instrumentation/fms/plan[0]/display-nodes/current-page");
          if (tmp != currPage) {
            setprop("instrumentation/fms/plan[0]/display-nodes/current-page", tmp);
            me.updateDisplay();
          }
        }
      }
    },

    ####
    # copy current page from active flight plan to display nodes
    #
    updateDisplay : func() {
      var startPage = getprop("instrumentation/fms/plan[0]/display-nodes/current-page");
      var startWP = startPage*9;
      var max = size(me.activePlan);
      if (max > 9) {
        max = 9;
      }
      for(var w = 0; w != 9; w=w+1) {
        var dn = me.activeFpln.getNode("display-nodes/wp["~w~"]",1);
        dn.getNode("active",1).setBoolValue(0);
      }
      for(var w = 0; w != max; w=w+1) {
        var pos = startWP+w;
        var dn = me.activeFpln.getNode("display-nodes/wp["~w~"]",1);
        ###var wp = me.activeFpln.getNode("wp["~pos~"]",0);
        if (pos < size(me.activePlan)) {
          var wp = me.activePlan[pos];
          if (wp != nil) {
            dn.getNode("id",1).setValue(wp.wp_name);
            dn.getNode("parent",1).setValue(wp.wp_parent_name);
            var spdLim = wp.spd_cstr;
            if (spdLim < 1 and spdLim > 0) {
              dn.getNode("spd-lim-display",1).setValue(sprintf("%01.2f", spdLim));
            } else {
              dn.getNode("spd-lim-display",1).setValue(sprintf("%5.0f", spdLim));
            }
            var altLim = wp.alt_cstr;
            if (altLim > 10000) {
              dn.getNode("alt-lim-display",1).setValue(sprintf("FL%3.0f",(altLim/100)));
            } else {
              dn.getNode("alt-lim-display",1).setValue(sprintf("%5.0f",altLim));
            }
            dn.getNode("wp-type",1).setValue(wp.wp_type);
            ##dn.getNode("time-utc-display",1).setValue(sprintf("%2f:%2f",wp.getNode("time-utc-hours").getIntValue(),wp.getNode("time-utc-mins").getIntValue()));
            dn.getNode("time-utc-display",1).setValue("00:00");
            dn.getNode("active", 1).setBoolValue(1);
            dn.getNode("track",1).setDoubleValue(wp.leg_bearing);
            dn.getNode("dist",1).setIntValue(wp.leg_distance);
          } else {
            dn.getNode("active",1).setBoolValue(0);
          }
        }
      }
      # if the current autopilot WP is not on this page, then set our display status to some high number
      var rteWP = getprop("autopilot/route-manager/current-wp");
      if (rteWP > -1) {
        var rteWPId = getprop("autopilot/route-manager/route/wp["~rteWP~"]/id");
        var planIdx = me.findWPName(rteWPId);
        if (planIdx != nil) {
          var tmp = int(planIdx/9);
          if (tmp != startPage) {
            setprop("instrumentation/fms/plan[0]/display-nodes/current-wp",99);
          }
        }
      }
    },

    ######
    # add WP to FMS plan.
    #
    appendWP : func(wp) {
      me.tracer("Append WP: "~wp.wp_name~" at pos: "~me.lastWP);
      append(me.activePlan, wp);
      me.lastWP = me.lastWP+1;
      ##flightplan().appendWP(wp);
      me.updateDisplay();
      return me.lastWP-1;
    },

    ###################
    # insert a WP into FMS plan at positon
    #
    insertWP : func(wp, idx) {
      me.tracer("insert WP: "~wp.wp_name);
      me.tracer("   at pos: "~idx);
      if (idx > size(me.activePlan)-1) {
        append(me.activePlan, wp);
        ##flightplan().append(wp);
      } else {
        me.activePlan = setsize(me.activePlan, size(me.activePlan)+1);
        # shuffle down all elements
        for(var p = size(me.activePlan)-1; p > idx; p=p-1) {
          me.activePlan[p] = me.activePlan[p-1];
        }
        me.activePlan[idx] = wp;
        me.lastWP = me.lastWP+1;
      }
      me.updateDisplay();
    },

    ###################
    # insert a WP into FMS plan after positon
    #
    insertWPAfter : func(wp, idx) {
      idx = idx + 1;
      me.tracer("insert WP: "~wp.wp_name~" at pos: "~idx);
      if (idx > size(me.activePlan)-1) {
        append(me.activePlan, wp);
        ##flightplan().appendWP(wp);
      } else {
        me.activePlan = setsize(me.activePlan, size(me.activePlan)+1);
        # shuffle down all elements
        for(var p = size(me.activePlan)-1; p > idx; p=p-1) {
          me.activePlan[p] = me.activePlan[p-1];
        }
        me.activePlan[idx] = wp;
        me.lastWP = me.lastWP+1;
      }
      me.updateDisplay();
    },

    ##################
    # replace a WP in plan at specified index
    #
    replaceWPAt : func(wp, idx) {
      ##me.tracer("replace WP: "~wp.wp_name~" at pos: "~idx);
      if (idx > size(me.activePlan)-1) {
        append(me.activePlan, wp);
      } else {
        me.activePlan[idx] = wp;
      }
      me.updateDisplay();
    },

    ##################
    # find index of WP in plan of the same wp_name
    #
    findWPName : func(name) {
      var retValue = nil;
      forindex(i; me.activePlan) {
        if (me.activePlan[i].wp_name == name) {
          retValue = i;
          break;
        }
      }
      return retValue;
    },

    ###################
    # find index of WP by type
    #
    findWPType : func(type) {
      var retValue = nil;
      forindex(i; me.activePlan) {
        if (me.activePlan[i].wp_type == type) {
          retValue = i;
          break;
        }
      }
      return retValue;
    },

    ##################
    # get WP from display by index
    #
    getWPIdx : func(idx) {
      var startPage = getprop("instrumentation/fms/plan[0]/display-nodes/current-page");
      var wpIdx = startPage*9+idx;
      if (wpIdx > size(me.activePlan)) {
        return nil;
      }
      return me.activePlan[wpIdx];
    },

    ##################
    # get WP from plan by index
    #
    getWP : func(idx) {
      return me.activePlan[idx];
    },

    ###################
    # clear plan
    #
    clearPlan : func() {
      me.lastPos = 0;
      setsize(me.activePlan, 0);
    },

    ###################
    #  get plan size
    #
    getPlanSize : func() {
      return size(me.activePlan);
    },

    ###################
    # clear all WP by type
    #
    clearWPType : func(type) {
      var tmpPlan = [];
      var tmpPos = 0;
      forindex(i; me.activePlan) {
        var wp = me.activePlan[i];
        if (wp.wp_type != type) {
          append(tmpPlan, wp);
          tmpPos = tmpPos+1;
        }
      }
      me.activePlan = tmpPlan;
      me.lastPost = tmpPos;
    },

    waypointsChanged: func {
      print("Waypoints changed, update FMS");

    },

    currentWaypointChanged: func {
      print("currentWaypointChanged, update FMS");
    }



};

