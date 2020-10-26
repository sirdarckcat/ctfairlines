#############################################################################
#
# Aeronatical Telecommunications Network
#
# Abstract:
#    Provides Controller-Pilot and Pilot-Airline communications
# 
# 
# Author: S.Hamilton Jan 2012
#
#
#   Copyright (C) 2012 Scott Hamilton
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

atn_trace = 0;
atcMailbox = TextRegion.new(3, 30, "/instrumentation/atn/mailbox");



var atn = {
   
   new : func() {
     var m = {parents : [atn]};
     m.atnNode = props.globals.getNode("/instrumentation/atn",1);
     m.version = "V1.1.0";
     m.baseURL = "http://example.com/";
     var baseURLNode = m.atnNode.getChild("atc-url-base",0);
     if (baseURLNode == nil) {
       print("[ATN] set <atc-url-base> in your aircraft -set.xml file");
       m.atnNode.getChild("atc-url-base",1).setValue(m.baseURL);
     } else {
       m.baseURL = baseURLNode.getValue();
       ##print("baseURL: "~m.baseURL);
     }
     m.sessionId = "";
     m.mseq = 1;
     m.connectedAirport = "";

     setlistener("/sim/signals/fdm-initialized", func m.init());
     setlistener("/instrumentation/atn/http-complete", func m.atnHTTPStateChange());
     setlistener("/instrumentation/atn/oob-complete",  func m.outOfBandStateChange());
     return m;
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
  if (atn_trace > 0) {
    print("[ATN] time: "~timeStr~" alt: "~curAltStr~", - "~msg);
    if (atn_trace > 1) {
      print("[ATN] vnav: "~me.afs.vertical_text[curVnav]~", lnav: "~me.afs.lateral_text[curLnav]~", spd: "~me.afs.spd_text[curSpd]);
    }
  }
},

   ####
   # init
   ####
   init : func() {
      var service = 1;
      if (me.baseURL == nil or me.baseURL == "") {
        service = 0;
      }
      me.atnNode.getNode("serviceable", 1).setBoolValue(service);
      setlistener("/instrumentation/atn/serviceable", func me.serviceableUpdate());
      ##settimer(func me.update(), 0);
      settimer(func me.slow_update(), 5);
      print("ATN "~me.version~" ready");
    },


   ### for high prio tasks ###
   update : func() {
     ##settimer(func me.update(), 1);
   }, 


   ### listen for changes in serviceable ###
   serviceableUpdate : func() {
     me.tracer("serviceable change");
     if (me.atnNode.getNode("serviceable") == 1) {
       settimer(func me.slow_update(), 3);
     }
   },


   ### for low prio tasks ###
   slow_update : func() {
     if (me.sessionId != "0" and me.sessionId != "") {
       me.tracer("ATN poll");
       me.tracer("sessionId: "~me.sessionId);
       var cmd = getprop("instrumentation/atn/out-of-band/command");
       if (cmd != nil and cmd != "") {
         me.tracer("[OOB] execute command: "~cmd);
         setprop("instrumentation/atn/out-of-band/command", "");
       }
       var url = me.baseURL~"/pollCommands.jsf?xid="~me.sessionId;
       var params = props.Node.new( {"url": url, "targetnode": "instrumentation/atn/out-of-band", "status": "/instrumentation/atn/oob-status", "complete": "instrumentation/atn/oob-complete", "failure": "/instrumentation/atn/oob-failure"} );
       fgcommand("xmlhttprequest", params);
     }
     if (me.atnNode.getNode("serviceable").getBoolValue() == 1) {
       settimer(func me.slow_update(), 15);
     }
   },

   outOfBandStateChange : func() {
     var httpState = getprop("instrumentation/atn/oob-complete");
     var msg = sprintf("HTTP state change: %u\n",httpState);
     me.tracer(msg);
     var cmd = getprop("instrumentation/atn/out-of-band/command");
     var cmdMsg = getprop("instrumentation/atn/out-of-band/message");
     var airport = getprop("instrumentation/atn/out-of-band/airport");
     if (cmd == "MAILBOX") {
       var time = getprop("instrumentation/clock/indicated-short-string");
       atcMailbox.append(time~"Z FROM "~airport);
       atcMailbox.appendStyle(cmdMsg, 0.1, 0.2, 0.8);
       atcMailbox.reset();
     }
   },


   ### announce ourselves to the local controller system ###
   doLogon : func() {
     var airport      = getprop("instrumentation/afs/ATC_logon_icao");
     var callSign     = getprop("instrumentation/afs/FLT_NBR");
     var username     = getprop("instrumentation/afs/ATC_logon_username");
     var aircraftType = getprop("instrumentation/afs/ATC_logon_acft-type");
     var airline      = getprop("instrumentation/afs/ATC_logon_airline");
     me.makeRequest("doLogon","callsign="~callSign~"&user="~username~"&type="~aircraftType~"&airport="~airport~"&airline="~airline);
   },

   doLogonCallback : func() {
     xid = getprop("instrumentation/atn/received/session-id");
     var airport = getprop("instrumentation/atn/received/airport");
     me.connectedAirport = airport;
     me.tracer("[LOGON] set sessionId: "~xid);
     me.sessionId = xid;
     var time = getprop("instrumentation/clock/indicated-short-string");
     atcMailbox.append(time~"Z FROM "~airport);
     atcMailbox.appendStyle("CONNECTED OK", 0.8, 0.8, 0.8); 
     atcMailbox.reset();
   },

   doUpdateController : func() {
     if (me.sessionId != nil and me.sessionId != "") {
       var airport = getprop("sim/airport/closest-airport-id");
       me.makeRequest("doUpdateController", "airport="~airport);
     }
   },

   doUpdateControllerCallback : func() {
     xid = getprop("instrumentation/atn/received/session-id");
     var airport = getprop("instrumentation/atn/received/airport");
     var time = getprop("instrumentation/clock/indicated-short-string");
     me.connectedAirport = airport;
     me.tracer("[UPDATECTLR] new airport for session: "~xid);
     atcMailbox.append(time~"Z FROM "~airport);
     atcMailbox.appendStyle("CONNECTED OK", 0.8, 0.8, 0.8); 
     atcMailbox.reset();
   },


   ### logoff for completeness ###
   doLogoff : func() {
     if (me.sessionId != "") {
       var callSign = getprop("instrumentation/afs/FLT_NBR");
       me.makeRequest("doLogoff", "callsign="~callSign);
     }
   },

   doLogoffCallback : func() {
     me.sessionId = "";
     var airport = getprop("instrumentation/atn/received/airport");
     var time = getprop("instrumentation/clock/indicated-short-string");
     atcMailbox.append(time~"Z FROM "~airport, 0.1, 0.8, 0.1);
     atcMailbox.appendStyle("DISCONNECTED", 0.8, 0.8, 0.8); 
     atcMailbox.reset();
   },


   ### request a company route, and load it into the FMS ###
   doGetCompanyRoute : func() {

   },


   ### send current fuel, weight and odometer to airline ###
   doSendFuelInfo : func() {
     var fltMode = getprop("instrumentation/ecam/flight-mode");
     if (me.sessionId != nil and me.sessionId != "" and fltMode < 10) {
       var alt = getprop("position/altitude-m");
       var vs  = (getprop("velocities/vertical-speed-fps")*60);
       var kias = getprop("velocities/airspeed-kt");
       var fob = getprop("consumables/fuel/total-fuel-kg");
       var fused = getprop("consumables/fuel/total-used-kg");
       var gw  = getprop("fdm/jsbsim/inertia/weight-kg");
       var cg  = (getprop("fdm/jsbsim/inertia/cg-x-in")*2.54);
       var elapsed = getprop("sim/time/elapsed-sec");
       var odometer = getprop("instrumentation/gps/odometer");
       var report = [];
       append(report, atnMaintRecord.new("fuel-report","altitude-m", alt));
       append(report, atnMaintRecord.new("fuel-report","airspeed-kt", kias));
       append(report, atnMaintRecord.new("fuel-report","vertical-speed", vs));
       append(report, atnMaintRecord.new("fuel-report","fob", fob));
       append(report, atnMaintRecord.new("fuel-report","fused",fused));
       append(report, atnMaintRecord.new("fuel-report","gw",gw));
       append(report, atnMaintRecord.new("fuel-report","cg-cm",cg));
       append(report, atnMaintRecord.new("fuel-report","elapsed",elapsed));
       append(report, atnMaintRecord.new("fuel-report","odometer",odometer));
       var json = me.urlencode(me.makeJSON("records",report));
       me.makeRequest("doReportMaint", "maintRecord="~json);
     }
   },



   ### send a position report to controller ###
   doPositionReport : func() {
     if (me.sessionId != nil and me.sessionId != "") {
       var alt = getprop("position/altitude-m");
       var vs  = getprop("velocities/vertical-speed-fps")*60;
       var kias = getprop("velocities/airspeed-kt");
       var lat  = getprop("position/latitude-deg");
       var lon  = getprop("position/longitude-deg");
       var report = atnPositionRecord.new(lat,lon,alt,kias);
       var json = me.urlencode("{\"atnPositionRecord\": "~report.toJSON()~"}");
       me.makeRequest("doPositionReport", "positionRecord="~json);
     }
   },


   ### request ground clearance ###
   doRequestGroundClearance : func() {
     if (me.sessionId != nil and me.sessionId != "") {
       var depAirport = getprop("instrumentation/afs/FROM");
       var arvAirport = getprop("instrumentation/afs/TO");
       var gate       = getprop("instrumentation/afs/ATC_depart_gate");
       me.makeRequest("doDepartClearance", "depart="~depAirport~"&arrival="~arvAirport~"&gate="~gate);
     }
   },

   ### ground clearance callback ###
   doDepartClearanceCallback : func() {
     var status = getprop("instrumentation/atn/received/message-status");
     var time = getprop("instrumentation/clock/indicated-short-string");
     atcMailbox.append(time~"Z");
     atcMailbox.appendStyle("CLEARANCE "~status, 0.8, 0.8, 0.8); 
     atcMailbox.reset();
   },

   ### arrival gate request ###
   doRequestGate : func() {

   },


   ### get ATIS ###
   doRequestATIS : func() {

   },

   ### report T/O ###
   doReportTakeoff : func() {
     if (me.sessionId != nil and me.sessionId != "") {
       var fob = getprop("consumables/fuel/total-fuel-kg");
       var fused = getprop("consumables/fuel/total-used-kg");
       var gw  = getprop("fdm/jsbsim/inertia/weight-kg");
       var cg  = (getprop("fdm/jsbsim/inertia/cg-x-in")*2.54);
       var alt = getprop("/position/altitude-m");
       var elapsed = getprop("sim/time/elapsed-sec");
       var report = [];
       append(report, atnMaintRecord.new("takeoff","altitude-m", alt));
       append(report, atnMaintRecord.new("takeoff","fob",fob));
       append(report, atnMaintRecord.new("takeoff","fused",fused));
       append(report, atnMaintRecord.new("takeoff","gw",gw));
       append(report, atnMaintRecord.new("takeoff","cg-cm",cg));
       append(report, atnMaintRecord.new("takeoff","elapsed",elapsed));
       var json = me.urlencode(me.makeJSON("records",report));
       me.makeRequest("doReportMaint", "maintRecord="~json);
     }
   },

   ### report Touchdown ###
   doReportTouchdown : func() {
     if (me.sessionId != nil and me.sessionId != "") {
       var fob = getprop("consumables/fuel/total-fuel-kg");
       var fused = getprop("consumables/fuel/total-used-kg");
       var gw  = getprop("fdm/jsbsim/inertia/weight-kg");
       var cg  = (getprop("fdm/jsbsim/inertia/cg-x-in")*2.54);
       var elapsed = getprop("sim/time/elapsed-sec");
       var report = [];
       append(report, atnMaintRecord.new("touchdown","fob",fob));
       append(report, atnMaintRecord.new("touchdown","fused",fused));
       append(report, atnMaintRecord.new("touchdown","gw",gw));
       append(report, atnMaintRecord.new("touchdown","cg-cm",cg));
       append(report, atnMaintRecord.new("touchdown","elapsed",elapsed));
       var json = me.urlencode(me.makeJSON("records",report));
       me.makeRequest("doReportMaint", "maintRecord="~json);
     }
   },

   ### report All Engine Startup ###
   doReportEngineStart : func() {
     if (me.sessionId != nil and me.sessionId != "") {
       var fob = getprop("consumables/fuel/total-fuel-kg");
       var fused = getprop("consumables/fuel/total-used-kg");
       var gw  = getprop("fdm/jsbsim/inertia/weight-kg");
       var cg  = (getprop("fdm/jsbsim/inertia/cg-x-in")*2.54);
       var elapsed = getprop("sim/time/elapsed-sec");
       var report = [];
       append(report, atnMaintRecord.new("engine-start","fob",fob));
       append(report, atnMaintRecord.new("engine-start","fused",fused));
       append(report, atnMaintRecord.new("engine-start","gw",gw));
       append(report, atnMaintRecord.new("engine-start","cg-cm",cg));
       append(report, atnMaintRecord.new("engine-start","elapsed",elapsed));
       var json = me.urlencode(me.makeJSON("records",report));
       me.makeRequest("doReportMaint", "maintRecord="~json);

       settimer(func me.doSendFuelInfo(), 60);
     }
   },

   ### general Report Maint callback dispatcher ###
   doReportMaintCallback : func() {
     var xid = getprop("instrumentation/atn/received/session-id");
     var type = getprop("instrumentation/atn/received/report-type");

   },

   ### make a request ###
   makeRequest : func(function, params) {
     setprop("instrumentation/atn/req-func", function);
     if (me.atnNode.getNode("serviceable").getBoolValue() == 1) {
       var url = me.baseURL~"/"~function~".jsf?"~params~"&xid="~me.sessionId~"&seq="~me.mseq;
       me.mseq = me.mseq+1;
       var params = props.Node.new( {"url": url, "targetnode": "/instrumentation/atn/received", "status": "/instrumentation/atn/http-status", "complete": "instrumentation/atn/http-complete", "failure": "/instrumentation/atn/http-failure"} );
       me.tracer("[REQ] url: "~url);
       fgcommand("xmlhttprequest", params);
       me.tracer("[REQ] done");
     }
   },


   ### listener HTTP State change ###
   atnHTTPStateChange : func() {
     var httpState = getprop("instrumentation/atn/http-status");
     var msg = sprintf("HTTP state change: %u\n",httpState);
     me.tracer(msg);
     var callBack = getprop("instrumentation/atn/req-func");
     if (callBack == "doLogon") {
       me.doLogonCallback();
     }
     if (callBack == "doLogoff") {
       me.doLogoffCallback();
     }
     if (callBack == "doUpdateController") {
       me.doUpdateControllerCallback();
     }
     if (callBack == "doReportMaint") {
       me.doReportMaintCallback();
     }
     if (callBack == "doDepartClearance") {
       me.doDepartClearanceCallback();
     }
   },


   ### make a JSON object from an array of items that support .toJSON() ###
   makeJSON : func(root, items) {
     var str = "{\""~root~"\": [";
     forindex(i; items) {
       item = items[i];
       str = str~item.toJSON();
       if (i < size(items)-1) {
         str = str~",";
       }
     }
     str = str~"]}";
     return str;
   },

   ### urlencode specific characters ###
   urlencode : func(str) {
     for(var pos=0; pos < size(str); pos=pos+1) {
       var char = str[pos];
       if (char == ` `) {
         str1 = substr(str,0,pos);
         str2 = substr(str,pos+1);
         str = str1~"%20"~str2;
         pos=pos+2;
       }
       if(char == `:`) {
         str1 = substr(str,0,pos);
         str2 = substr(str,pos+1);
         str = str1~"%3A"~str2;
         pos=pos+2;
       }
       if (char == `[`) {
         str1 = substr(str,0, pos);
         str2 = substr(str,pos+1);
         str = str1~"%5B"~str2;
         pos=pos+2;
       }
       if (char == `]`) {
         str1 = substr(str,0,pos);
         str2 = substr(str,pos+1);
         str = str1~"%5D"~str2;
         pos=pos+2;
       }
       if (char == `,`) {
         str1 = substr(str,0,pos);
         str2 = substr(str,pos+1);
         str = str1~"%2C"~str2;
         pos=pos+2;
       }
       if (char == `"`) {
         str1 = substr(str,0,pos);
         str2 = substr(str,pos+1);
         str = str1~"%22"~str2;
         pos=pos+2;
       }
     }
     return str;
   },

};
