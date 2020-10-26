#############################################################################
#
# Abstract:
#  Airbus Flight Management System for A380. Builds Flight Plans and manages
#  the waypoints in the autopilot. Provides the interface between the MCDU panel
#  and the Route-Manager plan.
#
# Author: Scott Hamilton  - Sept 2009.
# Version: V1.0.3
#
#   Copyright (C) 2009 Scott Hamilton
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Modification History:
# When		Who     Version		What
# 01-SEP-2009	S.H.	V1.0		Initial version
# 13-DEC-2009	S.H.	V1.0.3		Calculate descent where more than one WP has unknown altitude
# 28-APR-2010	S.H.	V1.0.6		Roughly calculate Vr and V2 based on Vso
# 12-APR-2011	S.H.	V1.0.19		build internal flightplan
# 09-SEP-2011	S.H.	V2.0.0		move to using internal FlightPlan
# 29-JAN-2012	S.H.	V2.0.5		add Vref and landing speed calculations
#
# 



currentField = "";
currentFieldPos = 0;
inputValue = "";
inputType  = "";
trace = 0;         ## Set to 0 to turn off all tracing messages
depDB = nil;
arvDB = nil;
version = "V2.2.9";
wpMode = "V2";    ## set to "V2" for new mode (airbusFMS) or "V1" for old mode (route-manager)

routeClearArm = 0;
airbusFMS = nil;   ###A380.fms;
atn = nil;   ###A380.atn;

menuCanvas = nil;
menuLink   = nil;
menuGroup  = nil;
menuLinkGrp = nil;
menuDisplay = -1;


#### CONSTANTS ####
#trigonometric values for glideslope calculations
FD_TAN3DEG = 0.052407779283;
FD_SIN3DEG = 0.052335956243;
FD_COS3DEG = 0.998629534755;

FD_TAN15DEG = 0.2679491924311227332;
FD_SIN30DEG = 0.5;
FD_TAN2_5DEG = 0.04366094290851206068;
FD_SIN5DEG = 0.08715574274765816587;

PI = 3.141592653589793116;
PI2 = 1.570796326794896558;
TWOPI=6.283185307179586232;
DEG2RAD = 0.01745329251994329509;
RAD2DEG = 57.29577951308232311;
RAD2NM  = 3437.7475;
MSEC2KT=1.946;
FPM2MSEC=0.00508;
KT2MSEC=0.514;
MSEC2KMH=3.6;
KMH2MSEC=0.28;
NM2MTRS = 1852;
METRE2NM = 0.000539956803;
METRE2FT = 3.2808399;
lur_koeff1 = 5.661872017348443498;   #=g*tan(30deg)
CLmax = 2.3;



CODE_ERR=3;
CODE_WARN=2;
CODE_INFO=1;




#############################################################################
#  output a debug message to stdout or file.
#############################################################################
tracer = func(msg) {
  var timeStr = getprop("/sim/time/gmt-string");
  var curAltStr = getprop("/position/altitude-ft");
  var curVnav   = getprop("/instrumentation/flightdirector/vnav");
  var curLnav   = getprop("/instrumentation/flightdirector/lnav");
  var curSpd    = getprop("/instrumentation/flightdirector/spd");
  var athrStr   = getprop("/instrumentation/flightdirector/at-on");
  var ap1Str     = getprop("/instrumentation/flightdirector/ap");
  var altHold = getprop("/autopilot/settings/target-altitude-ft");
  var vsHold  = getprop("/autopilot/settings/vertical-speed-fpm");
  var spdHold = getprop("/autopilot/settings/target-speed-kt");
  if (curVnav == nil) curVnav = "0";
  if (curLnav == nil) curLnav = "0";
  if (curSpd  == nil) curSpd  = "0";
  if (trace > 0) {
    print("[FMS] time: "~timeStr~" - "~msg);
    if (trace > 1) {
      print("[FMS0] vnav: "~vnavStr[curVnav]~", lnav: "~lnavStr[curLnav]~", spd: "~spdStr[curSpd]);
    }
  }
}


init_mcdu = func() {
  print("Init FMS "~version);
    setprop("/instrumentation/mcdu[0]/page","active.init");
    setprop("/instrumentation/mcdu[1]/page","active.init");
    setprop("/instrumentation/afs/current-fpln","0");

    setprop("/instrumentation/mcdu[0]/sid-arm",0);
    setprop("/instrumentation/mcdu[0]/star-arm",0);
    setprop("/instrumentation/mcdu[1]/sid-arm",0);
    setprop("/instrumentation/mcdu[1]/star-arm",0);
    setprop("/instrumentation/mcdu[0]/opt-scroll",0);
    setprop("/instrumentation/mcdu[1]/opt-scroll",0);
    setprop("/instrumentation/mcdu[0]/opt-error-display",0);
    setprop("/instrumentation/mcdu[1]/opt-error-display",0);
  
    setprop("/instrumentation/afs/routeClearArm",0);

    setprop("/controls/pressurisation/landing-elev-ft", 0);

    var depapt = airportinfo();
    if (depapt != nil) {
      ##setprop("/instrumentation/afs/FROM",depapt["id"]);
      setprop("/instrumentation/afs/FROM",depapt.id);
      setprop("instrumentation/afs/ATC_logon_icao", depapt.id);
      #setprop("/instrumentation/afs/depart-runway","");
      var multiCall = getprop("/sim/multiplay/callsign");
      if (getprop("/sim/multiplay/rxhost") != "0" and getprop("/sim/multiplay/txhost") != "0" and multiCall != "callsign") {
        setprop("/instrumentation/afs/FLT_NBR", multiCall);
        setprop("sim/multiplay/generic/string[0]", multiCall);
      }
    }
    airbusFMS = A380.fms;
    atn = A380.atnetwork;
    ###foreach(i; keys(globals)) { print("  ", i); }
    copyMenuNodes(0, 4, 0);
    copyMenuNodes(1, 4, 0);
    for(m = 0; m < 4; m=m+1) {
      copyMenuNodes(0, m, 0);
      copyMenuNodes(1, m, 0);
    }

}


selectField = func(field) {
   currentField = field;
   tracer("set current field to: "~currentField);
   var attr = "/instrumentation/afs/"~field;
   setprop("instrumentation/afs/current-field", "input."~currentField);
   inputValue = getprop(attr);
   inputType = props.globals.getNode(attr).getType();
   if (inputType == "DOUBLE") {
     if (inputValue > 0 and inputValue < 1) {
       inputType = "DECIMAL";
     }
   }
   ##print("selectField is of type: "~inputType);
   if (inputValue == nil) {
     inputValue = "";
   }
}


eventDeleteWp = func(idx) {
  var wp = airbusFMS.getWPIdx(idx);
  tracer("eventDeleteWP("~idx~")");
}

eventInsertWp = func(idx) {
  var wp = airbusFMS.getWPIdx(idx);
  tracer("eventInsertWP("~idx~")");
}

eventAirways = func(idx) {
  var wp = airbusFMS.getWPIdx(idx);
  tracer("eventAirways("~idx~")");
}

#################
#  when user clicks on flight plan row
#
selectWP = func(idx) {
   var wp = airbusFMS.getWPIdx(idx);
   if (idx == menuDisplay) {
     menuGroup.setVisible(0);
     menuLinkGrp.setVisible(0);
     menuDisplay = -1;
   } else {
     if (wp != nil) {
       print("[selectWP] Got back WP: "~wp.wp_name);
       var node1 = "fltpln.field"~idx~".menu";
       var node2 = "fltpln.menu"~idx;
       tracer("attach canvas to node: "~node1);
       if (menuCanvas == nil) {
         menuCanvas = canvas.new({"name": "fltpln-menu",   
           "size": [256, 256], 
           "view": [256, 256], 
           "mipmapping": 0       # Enable mipmapping (optional)
         });
         menuLink = canvas.new({"name": "fltpln-link",   
           "size": [256, 256], 
           "view": [256, 256], 
           "mipmapping": 0       # Enable mipmapping (optional)
         });
         menuCanvas.setColorBackground(0,0,0,0);
         menuLink.setColorBackground(0,0,0);
         menuCanvas.addPlacement({"node": node1, "capture-events": 1});
         menuLink.addPlacement({"node": node2});
         menuGroup = menuCanvas.createGroup("menu-group");
         menuLinkGrp = menuLink.createGroup("link-group");
         #menuGroup.setCenter(128,128);
         #menuGroup.setRotation(0,5.0);
         #menuGroup.setScale(1);
         var x1 = 0;
         var y1 = 0;
         var w1 = 180;
         var h1 = 256;
         var box = menuGroup.createChild("path", "box1")
           .moveTo(x1 + w1, y1)
           .vertTo(y1 + h1)
           .horizTo(x1)
           .vertTo(y1)
           .close()
           .setColorFill(0.31,0.31,0.31)
           .setStrokeLineWidth(0);
         var x2 = 0;
         var y2 = 0;
         var w2 = 256;
         var h2 = 256;
         var box2 = menuLinkGrp.createChild("path", "box2")
           .moveTo(x2 + w2, y2)
           .vertTo(y2 + h2)
           .horizTo(x2)
           .vertTo(y2)
           .close()
           .setColorFill(0.31,0.31,0.31)
           .setStrokeLineWidth(0);

         var y3 = 10;
         var h3 = 20;
         var text1 = menuGroup.createChild("text", "menu1")
                .setTranslation(10, y3)      # The origin is in the top left corner
                .setAlignment("left-center") # All values from osgText are supported (see $FG_ROOT/Docs/README.osgtext)
                .setFont("LiberationFonts/LiberationSans-Regular.ttf") # Fonts are loaded either from $AIRCRAFT_DIR/Fonts or $FG_DATA/Fonts
                .setFontSize(20, 1.4)        # Set fontsize and optionally character aspect ratio
                .setColor(1,1,1)             # Text color
                .setText("INSERT NEXT WPT");
         ##text1.setCenter(0,0);
         ##text1.setRotation(0,0);
         text1.show();
         y3 = y3 + h3;
         var text2 = menuGroup.createChild("text", "menu2")
                  .setTranslation(10,y3)
                  .setAlignment("left-center")
                  .setFont("LiberationFonts/LiberationSans-Regular.ttf")
                  .setFontSize(20,1.4)
                  .setColor(1,1,1)
                  .setText("DELETE");
         text2.show(); 
         y3 = y3 + h3;
         var text3 = menuGroup.createChild("text", "menu3")
                  .setTranslation(10,y3)
                  .setAlignment("left-center")
                  .setFont("LiberationFonts/LiberationSans-Regular.ttf")
                  .setFontSize(20,1.4)
                  .setColor(1,1,1)
                  .setText("OFFSET");
         y3 = y3 + h3;
         var text4 = menuGroup.createChild("text", "menu4")
                  .setTranslation(10,y3)
                  .setAlignment("left-center")
                  .setFont("LiberationFonts/LiberationSans-Regular.ttf")
                  .setFontSize(20,1.4)
                  .setColor(1,1,1)
                  .setText("HOLD");
         y3 = y3 + h3;
         var text5 = menuGroup.createChild("text", "menu5")
                  .setTranslation(10,y3)
                  .setAlignment("left-center")
                  .setFont("LiberationFonts/LiberationSans-Regular.ttf")
                  .setFontSize(20,1.4)
                  .setColor(1,1,1)
                  .setText("AIRWAYS");

         text1.addEventListener("click", func eventInsertWp(idx));
         text2.addEventListener("click", func eventDeleteWp(idx));
         text5.addEventListener("click", func eventAirways(idx));
       } else {
         setprop("canvas/by-index/texture[1]/placement/node", node1);
         setprop("canvas/by-index/texture[2]/placement/node", node2);
         var text1 = menuGroup.getElementById("menu1");
         var text2 = menuGroup.getElementById("menu2");
         var text3 = menuGroup.getElementById("menu3");
         var text4 = menuGroup.getElementById("menu4");
         var text5 = menuGroup.getElementById("menu5");
         #text1.removeEventListener("click");
         #text2.removeEventListener("click");
         #text5.removeEventListener("click");
         text1.addEventListener("click", func eventInsertWp(idx));
         text2.addEventListener("click", func eventDeleteWp(idx));
         text5.addEventListener("click", func eventAirways(idx));
       }

       menuGroup.show();
       menuDisplay = idx;
     }
  }
}




keyPress = func(key) {
  ##print("key: "~key~", inputValue: >>>"~inputValue~"<<<");
  if (num(inputValue) != nil) {
    ##print("convert inputValue to String");
    if (inputType == "DECIMAL") {
      valLen = size(""~inputValue);
      valLen2 = valLen-2;
      if (valLen2 < 1) {
         valLen2 = 1;
      }
      var fmtStr = "%0.0"~valLen2~"f";
      ##print("fmtStr: "~fmtStr);
      inputValue = sprintf(fmtStr, inputValue);
    } else {
      inputValue = sprintf("%0.0f",inputValue);
    }
  }
  ##print("sprintf'd inputValue: "~inputValue);
  if (key == "DEL") {
    var len = (size(inputValue))-1;
    if (len < 0) {
      len = 0;
    }
    inputValue = substr(inputValue,0,len);
    if (inputValue == "") {
      if (inputType == "DECIMAL") {
        inputValue = "0.0";
      }
      if (inputType == "INT" or inputType == "DOUBLE") {
        inputValue = "0";
      }
    }
    ##print("len: "~len~", new inputValue: >>>"~inputValue~"<<<");
  } else {
    ##print("append key...");
    if (inputType == "DECIMAL") {
      var tmpStr = substr(inputValue,size(inputValue)-2,2);
      ##print("tmpStr: "~tmpStr);
      if (tmpStr == ".0") {
        inputValue = substr(inputValue, 0, size(inputValue)-1);
      }
    }
    inputValue = inputValue~key;
    ##print("post append: "~inputValue);
  }
  #if (num(inputValue) != nil) {
  #  print("convert back to num");
  #  inputValue = num(inputValue);
  #}
  ## the to-flaps field is a single digit
  if (currentField == "to-flaps") {
    if (key == "DEL") {
      key = "0";
    }
    inputValue = num(key);
  }
  ## mach values should not exceed Vne
  if (currentField == "crz_mach") {
    ##inputValue = num(inputValue)+0.001;
    if (num(inputValue) > 0.93) {
      inputValue = 0.93;
    }
    var tocIdx = airbusFMS.findWPType("T/C");
    if (tocIdx != nil) {
      var tocWP = airbusFMS.getWP(tocIdx);
      tocWP.spd_cstr = inputValue;
      airbusFMS.replaceWPAt(tocWP, tocIdx);
    }
  }
  var attr = "/instrumentation/afs/"~currentField;
  tracer("set field: "~attr~", with value: "~inputValue);
  setprop(attr, inputValue);

  ## here we can do field specific stuff

  if (currentField == "CRZ_FL") {
    var cruiseFt = num(inputValue);
    if (cruiseFt == nil) {
      #print("CRZ_FL: inputValue: "~inputValue);
      cruiseFt = int(inputValue)
    }
    if (cruiseFt != nil) {
      cruiseFt = int(cruiseFt*100);
      setprop("/instrumentation/afs/thrust-cruise-alt",cruiseFt);
      if (getprop("instrumentation/ecam/flight-mode") < 3 and cruiseFt > 20000) {
        setprop("instrumentation/afs/target-altitude-ft",cruiseFt);
      }
    }
  }
  if (currentField == "FLT_NBR") {
    if (getprop("/sim/multiplay/rxhost") != "0" and getprop("/sim/multiplay/txhost") != "0") {
      setprop("sim/multiplay/generic/string[0]", inputValue);
      setprop("sim/multiplay/callsign", inputValue);
    }
  }
}


changeDropdown = func(unit, menu, item) {
  var page = getprop("/instrumentation/mcdu["~unit~"]/dropdown["~menu~"]/menu/page["~item~"]");
  tracer("unit: "~unit~", menu: "~menu~", item: "~item);
  changePage(unit, page);
  if (menu == 4) {
    for(m = 0; m < 4; m=m+1) {
      var title = getprop("instrumentation/mcdu-menus/dropdown["~m~"]/menu["~item~"]/title");
      setprop("instrumentation/mcdu["~unit~"]/dropdown["~m~"]/title", title);
      copyMenuNodes(unit, m, item);
    }
    var title = getprop("instrumentation/mcdu-menus/dropdown["~menu~"]/menu/item["~item~"]");
    setprop("instrumentation/mcdu["~unit~"]/dropdown["~menu~"]/title", title );
  }
}

var copyMenuNodes = func(toUnit, toDrop, fromMenuSet) {
    var srcNode = props.globals.getNode("instrumentation/mcdu-menus/dropdown["~toDrop~"]/menu["~fromMenuSet~"]/");
      var dstNode = props.globals.getNode("instrumentation/mcdu["~toUnit~"]/dropdown["~toDrop~"]/menu/");
      var itemSibling = srcNode.getChildren();
      foreach(var mi; itemSibling ) {
        ##debug.dump(mi);
        if (mi.getName() == "item" or mi.getName() == "page") {  
          var key = mi.getName()~"["~mi.getIndex()~"]";
          var val = mi.getValue();
          ##print("fromSet: "~fromMenuSet~", toDrop: "~toDrop~" - key: "~key~", val: "~val);
          var dest = props.globals.getNode("instrumentation/mcdu["~toUnit~"]/dropdown["~toDrop~"]/menu/"~key, 1);
          ##print("set dest: "~dest.getPath());
          var type = mi.getType();
          if(type == "BOOL") dest.setBoolValue(val);
          elsif(type == "INT" or type == "LONG") dest.setIntValue(val);
          elsif(type == "FLOAT" or type == "DOUBLE") dest.setDoubleValue(val);
          else dest.setValue(val);
        }
      }
}




################
## general menu action function.
changePage = func(unit,page) {
  tracer("**** Start changePage("~page~")");
  var crzFl = getprop("/instrumentation/afs/CRZ_FL");
  setprop("/instrumentation/mcdu["~unit~"]/opt-error-display",0);
  setprop("/instrumentation/mcdu["~unit~"]/dropdown[0]/active",0);
  setprop("/instrumentation/mcdu["~unit~"]/dropdown[1]/active",0);
  setprop("/instrumentation/mcdu["~unit~"]/dropdown[2]/active",0);
  setprop("/instrumentation/mcdu["~unit~"]/dropdown[3]/active",0);
  setprop("/instrumentation/mcdu["~unit~"]/dropdown[4]/active",0);

  for(r =0; r != 8; r=r+1) {
      var optAttr = sprintf("/instrumentation/mcdu[%i]/opt%02i",unit,r+1);
      var col1Attr = sprintf("/instrumentation/mcdu[%i]/col01-opt%02i",unit,r+1);
      var col2Attr = sprintf("/instrumentation/mcdu[%i]/col02-opt%02i",unit,r+1);
     
      setprop(optAttr,"");
      setprop(col1Attr,"");
      setprop(col2Attr,"");
  }

  ### active.departure.dep
  if (page == "active.departure.dep") {
    var rwyScroll = getprop("/instrumentation/mcdu["~unit~"]/opt-scroll");
    var depApt = airportinfo(getprop("/instrumentation/afs/FROM"));

    var arvApt = call(func airportinfo(getprop("/instrumentation/afs/TO")),nil, var err = []);
    if (size(err)) {
      arvApt = nil;
    }
    if (depApt != nil and arvApt != nil) {    
      if (trace > 0) {
        debug.dump(arvApt);
      }
      if (getprop("/instrumentation/afs/routeClearArm") == 0) {
        setprop("/autopilot/route-manager/cruise/flight-level",crzFl);
        setprop("/autopilot/route-manager/cruise/altitude-ft",crzFl*100);
        setprop("/autopilot/route-manager/active",0);
	tracer("/autopilot/route-manager/input,@clear");
        setprop("/autopilot/route-manager/input","@clear");
        
        setprop("/instrumentation/afs/routeClearArm",1);
        setprop("/instrumentation/afs/thrust-cruise-alt",crzFl*100);
      }

    var depCourse = getprop("/instrumentation/afs/dep-course");
    depCourse = calcOrthHeadingDeg(depApt.lat,depApt.lon,arvApt.lat,arvApt.lon);
    setprop("/instrumentation/afs/dep-course",depCourse);
    ##var runWays = depApt["runways"];
    var runWays = depApt.runways;
    tracer("runways len: "~size(runWays));
    setprop("/instrumentation/mcdu["~unit~"]/opt-size",size(runWays));
    if (rwyScroll > int(size(runWays)/8)) {
      rwyScroll = 0;
    }
    var ks = keys(runWays);
    var max = size(ks);
    if (max > (rwyScroll*8)+8) {
      max = (rwyScroll*8)+8;
    }
    var pos = 0;
    for(r = (rwyScroll*8); r != max; r=r+1) {
      var key = ks[r];
      var run = runWays[key];
      if (run.length > 2000) {
        pos = pos+1;
        var rwyAttr = sprintf("/instrumentation/mcdu[%i]/opt%02i",unit,pos);
        var rwyLenAttr = sprintf("/instrumentation/mcdu[%i]/col01-opt%02i",unit,pos);
        var rwyHdgAttr = sprintf("/instrumentation/mcdu[%i]/col02-opt%02i",unit,pos);
        tracer("[MCDU] set attr: "~rwyAttr~", run val: "~key);
        setprop(rwyAttr,key);
        var lenStr = sprintf("%im",run.length);
        var crsStr = sprintf("%03i", run.heading);
        setprop(rwyLenAttr, lenStr);
        setprop(rwyHdgAttr, crsStr);
      }
    }
    setprop("/instrumentation/mcdu["~unit~"]/star-arm",0);
    setprop("/instrumentation/mcdu["~unit~"]/sid-arm",0);
    var rwy = getprop("/instrumentation/afs/dep-rwy");
    if (rwy != nil) {
      if (size(rwy) > 0) {
        setprop("/instrumentation/mcdu["~unit~"]/sid-arm",1);
      }
    }
    } else {
      print("[MCDU] failed to find either DEPART or ARRIVAL Airport in FMS data");
      print("  check the README file on how to add FMS database files");
      setprop("/instrumentation/mcdu["~unit~"]/opt-error","ARPT NOT IN DB");
      setprop("/instrumentation/mcdu["~unit~"]/opt-error-display",CODE_WARN);
    }
  }

  ### active.departure.arv
  if (page == "active.departure.arv") {
    var rwyScroll = getprop("/instrumentation/mcdu["~unit~"]/opt-scroll");
    var depApt = airportinfo(getprop("/instrumentation/afs/FROM"));
    var arvApt = airportinfo(getprop("/instrumentation/afs/TO"));
    if (arvDB == nil) { 
        arvDB = fmsDB.new(getprop("/instrumentation/afs/TO"));
    }
    if (trace > 0) {
      debug.dump(arvApt);
    }
    var depCourse = getprop("/instrumentation/afs/dep-course");
    if (depCourse == nil) {
      depCourse = calcOrthHeadingDeg(depApt.lat,depApt.lon,arvApt.lat,arvApt.lon);
      setprop("/instrumentation/afs/dep-course",depCourse);
    }
    var ldgElev = arvApt.elevation;
    var atmos = Atmos.new();
    var ldgElevPSI = atmos.convertAltitudePressure("feet",ldgElev,"psi");
    setprop("/controls/pressurisation/landing-elev-ft", ldgElev);
    setprop("/controls/pressurisation/landing-elev-psi", ldgElevPSI);
    setprop("environment/metar[1]/station-id", getprop("/instrumentation/afs/TO"));
    

    if (arvDB != nil) {
      ##var runWays = arvApt["runways"];
      var runWays = arvApt.runways;
      tracer("runways len: "~size(runWays));
      setprop("/instrumentation/mcdu["~unit~"]/opt-size",size(runWays));
      var ks = keys(runWays);
      var max = size(ks);
      if (max > (rwyScroll*8)+8) {
        max = (rwyScroll*8)+8;
      }
      tracer("runways max: "~max~", rwyScroll: "~rwyScroll);
      var pos = 0;
      for(r = (rwyScroll*8); r != max; r=r+1) {
        var key = ks[r];
        ##var run = runWays[key];
        var run = arvApt.runway(key);
        ## find all approach procedures for this runway.
        var aprchList = arvDB.getApproachList(run, "all");
      
        if (run.length > 1900) {
          pos = pos+1;
          var rwyAttr = sprintf("/instrumentation/mcdu[%i]/opt%02i",unit,pos);
          var rwyLenAttr = sprintf("/instrumentation/mcdu[%i]/col01-opt%02i",unit,pos);
          var rwyHdgAttr = sprintf("/instrumentation/mcdu[%i]/col02-opt%02i",unit,pos);
          tracer("[MCDU] set attr: "~rwyAttr~", run val: "~key);
          setprop(rwyAttr,key);
          var lenStr = sprintf("%im",run.length);
          var crsStr = sprintf("%03i", run.heading);
          setprop(rwyLenAttr, lenStr);
          setprop(rwyHdgAttr, crsStr);
        }
      }
      setprop("/instrumentation/mcdu["~unit~"]/sid-arm",0);
      setprop("/instrumentation/mcdu["~unit~"]/star-arm",0);
      var rwy = getprop("/instrumentation/afs/arv-rwy");
      if (rwy != nil) {
        if (size(rwy) > 0) {
          setprop("/instrumentation/mcdu["~unit~"]/star-arm",1);
        }
      }
    } else {
      setprop("/instrumentation/mcdu["~unit~"]/opt-error","ARPT NOT IN DB");
      setprop("/instrumentation/mcdu["~unit~"]/opt-error-display",CODE_WARN);
    }
  }

  #### active.departure.sid
  if (page == "active.departure.sid") {
    depDB = fmsDB.new(getprop("/instrumentation/afs/FROM"));
    ####   setup the array of SID options to be displayed
    if (depDB != nil) {
      var sidList = depDB.getSIDList(getprop("/instrumentation/afs/dep-rwy"));
      var rwyScroll = getprop("/instrumentation/mcdu["~unit~"]/opt-scroll");
      var max = size(sidList);
      setprop("/instrumentation/mcdu["~unit~"]/opt-size",size(sidList));
      if (max > (rwyScroll*8)+8) {
        max = (rwyScroll*8)+8;
      }
      var pos = 0;
      for(var p = (rwyScroll*8); p != size(sidList); p=p+1) {
        var sidAttr = sprintf("/instrumentation/mcdu[%i]/opt%02i",unit,pos+1);
        var sidNumWptAttr = sprintf("/instrumentation/mcdu[%i]/col01-opt%02i",unit,pos+1);
        var sidTransAttr = sprintf("/instrumentation/mcdu[%i]/col02-opt%02i",unit,pos+1);
        var proc = sidList[p];
        tracer("[MCDU] found SID procedure: "~proc.wp_name~", with "~size(proc.wpts)~" waypoints and "~size(proc.transitions)~" transitions");
        setprop(sidAttr,proc.wp_name);
        var wptLen = sprintf("%2i",size(proc.wpts));
        setprop(sidNumWptAttr, wptLen);
        if (proc.transitions != nil and size(proc.transitions) > 0) {
          var transStr = "";
          # make a comma seperated string of transition wp for display
          foreach(var tr; proc.transitions) {
            if (tr.trans_type == "sid") {
              transStr = transStr~", "~tr.trans_name;
            }
          }
          setprop(sidTransAttr, transStr);
        } else {
          setprop(sidTransAttr, "");
        }
        pos = pos+1;
      }
      setprop("/autopilot/route-manager/departure/airport",getprop("/instrumentation/afs/FROM"));
      setprop("/autopilot/route-manager/departure/runway",getprop("/instrumentation/afs/dep-rwy"));

    } else {
      print("[MCDU] failed to find Depart Airport in FMS data");
      print("  check the README file on how to add FMS database files");
      setprop("/instrumentation/mcdu["~unit~"]/opt-error","ARPT NOT IN DB");
      setprop("/instrumentation/mcdu["~unit~"]/opt-error-display",CODE_WARN);
    }
  }

  ### active.departure.star
  if (page == "active.departure.star") {
    arvDB = fmsDB.new(getprop("/instrumentation/afs/TO"));
    if (arvDB != nil) {
      var rwyScroll = getprop("/instrumentation/mcdu["~unit~"]/opt-scroll");
      starList = arvDB.getSTARList(getprop("/instrumentation/afs/arv-rwy"));
      var max = size(starList);
      setprop("/instrumentation/mcdu["~unit~"]/opt-size",size(starList));
      if (max > (rwyScroll*8)+8) {
        max = (rwyScroll*8)+8;
      }
      var pos = 0;
      for(var p = (rwyScroll*8); p != size(starList); p=p+1) {
        var starAttr = sprintf("/instrumentation/mcdu[%i]/opt%02i",unit,pos+1);
        var starTransAttr = sprintf("/instrumentation/mcdu[%i]/col02-opt%02i",unit,pos+1);
        var starNumWptAttr = sprintf("/instrumentation/mcdu[%i]/col01-opt%02i",unit,pos+1);
        var proc = starList[p];
        tracer("[MCDU] found STAR procedure: "~proc.wp_name~", with "~size(proc.wpts)~" waypoints and "~size(proc.transitions)~" transitions");
        setprop(starAttr,proc.wp_name);
	var wptLen = sprintf("%2i",size(proc.wpts));
        setprop(starNumWptAttr, wptLen);
        if (proc.transitions != nil and size(proc.transitions) > 0) {
          var transStr = "";
          foreach(var tr; proc.transitions) {
            transStr = transStr~", "~tr.trans_name;
          }
          setprop(starTransAttr, transStr);
        } else {
          setprop(starTransAttr, "");
        }
        pos = pos+1;
      }
      setprop("/autopilot/route-manager/destination/airport",getprop("/instrumentation/afs/TO"));
      setprop("/autopilot/route-manager/destination/runway",getprop("/instrumentation/afs/arv-rwy"));
    } else {
      print("[MCDU] failed to find Arrival Airport in FMS data");
      print("  check the README file on how to add FMS database files");
      setprop("/instrumentation/mcdu["~unit~"]/opt-error","ARPT NOT IN DB");
      setprop("/instrumentation/mcdu["~unit~"]/opt-error-display", CODE_WARN);
    }
  }
  
  ### active.departure.sid.trans
  if (page == "active.departure.sid.trans") {
     if (depDB == nil) {
      depDB = fmsDB.new(getprop("/instrumentation/afs/FROM"));
    }
    if (depDB != nil) {
      var sidVal = getprop("/instrumentation/afs/sid");
      var sid = depDB.getSid(sidVal);
      setprop("/instrumentation/mcdu["~unit~"]/opt-size",size(sid.transitions));
      var pos = 1;
      foreach(var proc; sid.transitions) {
        if (proc.trans_type == "sid") {
          var sidAttr = sprintf("/instrumentation/mcdu[%i]/opt%02i",unit,pos);
          var sidNumWptAttr = sprintf("/instrumentation/mcdu[%i]/col01-opt%02i",unit,pos);
          var sidTransAttr = sprintf("/instrumentation/mcdu[%i]/col02-opt%02i",unit,pos);
          setprop(sidAttr, proc.trans_name);
          setprop(sidNumWptAttr, size(proc.trans_wpts));
          pos = pos+1;
        }
      }
    } else {
      print("[MCDU] failed to find Depart Airport in FMS data");
      print("  check the README file on how to add FMS database files");
      setprop("/instrumentation/mcdu["~unit~"]/opt-error","ARPT NOT IN DB");
      setprop("/instrumentation/mcdu["~unit~"]/opt-error-display", CODE_WARN);
    }
  }

  ### active.departure.sid.trans
  if (page == "active.departure.star.trans") {
     if (arvDB == nil) {
      arvDB = fmsDB.new(getprop("/instrumentation/afs/TO"));
    }
    if (arvDB != nil) {
      var sidVal = getprop("/instrumentation/afs/star");
      var star = arvDB.getStar(sidVal);
      setprop("/instrumentation/mcdu["~unit~"]/opt-size",size(star.transitions));
      var pos = 1;
      foreach(var proc; star.transitions) {
        if (proc.trans_type == "star") {
          var starAttr = sprintf("/instrumentation/mcdu[%i]/opt%02i",unit,pos);
          var starNumWptAttr = sprintf("/instrumentation/mcdu[%i]/col01-opt%02i",unit,pos);
          var starTransAttr = sprintf("/instrumentation/mcdu[%i]/col02-opt%02i",unit,pos);
          setprop(starAttr, proc.trans_name);
          setprop(starNumWptAttr, size(proc.trans_wpts));
          pos = pos+1;
        }
      }
    } else {
      print("[MCDU] failed to find Arrival Airport in FMS data");
      print("  check the README file on how to add FMS database files");
      setprop("/instrumentation/mcdu["~unit~"]/opt-error","ARPT NOT IN DB");
      setprop("/instrumentation/mcdu["~unit~"]/opt-error-display", CODE_WARN);
    }
  }

  if (page == "active.to_perf") {
     #V = √( 2 W g / ρ S Clmax )
     #
     #where:
     #  V = Stall Speed M/s
     #  ρ (rho) = air density KG/M^3 (about 1.25 kg/m3)
     #  g = 9.81 m s^-2
     #  S = wing area M^2
     #  Cl_max = Max Coefficient of Lift
     #  W = weight KG

     tracer(" active.to-perf calc Vso, Vr, V2");
     calcVSpeeds();
     calcVapp();
     if (getprop("instrumentation/afs/dep-rwy") != nil) {
       var depApt = airportinfo(getprop("/instrumentation/afs/FROM"));
       ##var runWays = depApt["runways"];
       var rwy = getprop("instrumentation/afs/dep-rwy");
       var run = depApt.runway(rwy);
       #var rwyLen = run["length"];
       var rwyLen  = run.length;
       var rwyLenHalf = (rwyLen/2);
     }

     var fltMode    = getprop("/instrumentation/ecam/flight-mode");
     if (fltMode == 2) {
       setprop("/instrumentation/ecam/flight-mode", fltMode+1);
     }
     setprop("/instrumentation/ecam/to-data", 1);
  }

  if (page == "active.crz.stepalt") {
  
  }
  if (page == "active.appr_perf") {
    calcVapp();
  }
  if (page == "atc.connect") {
  }
  if (page == "atc.request") {
  }


  tracer("**** End changePage("~page~")");
  setprop("/instrumentation/mcdu["~unit~"]/page",page);
}


calcVSpeeds = func() {
   var Vso = getprop("/velocities/Vso");
   if (Vso != nil) {
     var flapConfig = getprop("instrumentation/afs/to-flaps");
     var flapFactor = 1.4;
     if (flapConfig == 1) {
       flapFactor = 1.55;
     }
     if (flapConfig == 2) {
       flapFactor = 1.41;
     }
     if (flapConfig == 3) {
       flapFactor = 1.3;
     } 
     var Vr  = (Vso*flapFactor);
     var V2  = (Vso*(flapFactor+0.05))+10;
     setprop("/instrumentation/afs/Vr", Vr);
     setprop("/instrumentation/afs/V2", V2);
     var Vf = getprop("instrumentation/afs/to-F");
     var Vs = getprop("instrumentation/afs/to-S");
     var Vgreen = getprop("instrumentation/afs/to-greendot");
     if (Vf < V2) {
       Vf = (Vso*(flapFactor+0.05))+16;
       setprop("instrumentation/afs/to-F", Vf);
     }
     if (Vs < Vf) {
       Vs = (Vso*(flapFactor+0.05))+35;
       setprop("instrumentation/afs/to-S", Vs);
     }
     if (Vgreen < Vs) {
       Vgreen = (Vso*(flapFactor+0.05))+55;
       setprop("instrumentation/afs/to-greendot", Vgreen);
     }
     tracer("  Vso: "~Vso~", Vr: "~Vr~", V2: "~V2~", flapFactor: "~flapFactor);
   }

}


#####################
##  Dispatch option value to either selectRwyAction or selectSidAction

dispatchAction = func(val, unit) {
   tracer("**** Start dispatchAction("~val~")");
   var page = getprop("/instrumentation/mcdu["~unit~"]/page");
   if (page == "active.departure.dep" or page == "active.departure.arv") {
     selectRwyAction(val, unit);
   }
   if (page == "active.departure.sid" or page == "active.departure.star") {
     selectSidAction(val, unit);
   }
   if (page == "active.departure.sid.trans" or page == "active.departure.star.trans") {
     selectSidTransAction(val, unit);
   }
   tracer("**** End dispatchAction("~val~")");
}




###################
## From the departure page, set the depart and arrival runways 
selectRwyAction = func(rwy, unit) {
  var direct = "dep";
  if (getprop("/instrumentation/mcdu["~unit~"]/page") == "active.departure.arv") {
    direct = "arv";
    setprop("/instrumentation/mcdu[0]/sid-arm",0);
    setprop("/instrumentation/mcdu[0]/star-arm",1);
  } else {
    setprop("/instrumentation/mcdu[0]/sid-arm",1);
    setprop("/instrumentation/mcdu[0]/star-arm",0);
  }
  tracer("** selectRwyAction("~rwy~","~unit~") - direction: "~direct);
  var rwyAttr = sprintf("/instrumentation/afs/%s-rwy",direct);
  var rwyVal = getprop("/instrumentation/mcdu["~unit~"]/"~rwy);
  setprop(rwyAttr,rwyVal);
  var wp = nil;
  if (direct == "dep") {
    var apt = airportinfo(getprop("/instrumentation/afs/FROM"));
    var mhz = getILS(apt,rwyVal);
    if (mhz != nil) {
      tracer("depart ILS: "~mhz);
      ##setprop("/instrumentation/nav[0]/selected-mhz",mhz);
      setprop("/instrumentation/nav[0]/frequencies/selected-mhz",mhz);
      ##setprop("/instrumentation/nav[0]/frequencies/selected-mhz-fmt",mhz);
    }
    wp = makeAirportWP(apt, rwyVal);
    if (airbusFMS.findWPName(wp.wp_name) == nil) {
      airbusFMS.appendWP(wp);
    }
    var discWP = fmsWP.new();
    discWP.wp_name = "discontinuity";
    discWP.wp_type = "DISC";
    tracer("[selectRwyAction] check if existing DISC");
    if (airbusFMS.findWPType("DISC") == nil) {
      tracer("Append DISC");
      airbusFMS.appendWP(discWP);
      var eopWP = fmsWP.new();
    eopWP.wp_name = "end-of-plan";
    eopWP.wp_type = "END";
    airbusFMS.clearWPType("END");
    airbusFMS.appendWP(eopWP);
    }
  } else {
    var apt = airportinfo(getprop("/instrumentation/afs/TO"));
    var mhz = getILS(apt,rwyVal);
    if (mhz != nil) {
      tracer("arrive ILS: "~mhz);
      ##setprop("/instrumentation/nav[0]/standby-mhz",mhz);
      setprop("/instrumentation/nav[0]/frequencies/standby-mhz",mhz);
      ##setprop("/instrumentation/nav[0]/frequencies/standby-mhz-fmt",mhz);
    }
    endWP = airbusFMS.findWPType("END");
    wp = makeAirportWP(apt, rwyVal);
    var idx = airbusFMS.findWPName(wp.wp_name);
    if (idx != nil) {
      airbusFMS.replaceWPAt(wp, idx);
    } else {
      airbusFMS.insertWP(wp, endWP);
    }
  }
  tracer("[MCDU] set: "~rwyAttr~", runway: "~rwyVal);
}


######################
## From Sid or Star page, set tmp-fpln sid/star opt.
selectSidAction = func(opt, unit) {
  var direct = "sid";
  
  if (getprop("/instrumentation/mcdu["~unit~"]/page") == "active.departure.star") {
    direct = "star";
  } 
  var nextPage = "active.init";
  var sidAttr = sprintf("/instrumentation/afs/%s",direct);
  var sidVal = getprop("/instrumentation/mcdu["~unit~"]/"~opt);
  setprop(sidAttr,sidVal);
  tracer("[MCDU] set: "~sidAttr~", with: "~sidVal);
  if (direct == "sid") {
    var sid = depDB.getSid(sidVal);
    var pos = 0;
    var crzFl = getprop("/instrumentation/afs/CRZ_FL");
    tracer("Got back sid: "~sid.wp_name~", with: "~size(sid.wpts)~" wp");
    var toSpd = 200;
    airbusFMS.clearWPType("SID");
    airbusFMS.clearWPType("T/C");
    var discontIdx = airbusFMS.findWPType("DISC");

    for(var w=0; w != size(sid.wpts);w=w+1) {
      var wpIns = "";
      var wp = sid.wpts[w];
      tracer(" add sid wp: "~wp.wp_name);
      if (w == size(sid.wpts)-1) {
        wp.alt_cstr = (crzFl*100);
      }
      ## V1
      if (wpMode == "V1") {
        var wpLen = getprop("/autopilot/route-manager/route/num");
        if (wp.alt_cstr != nil and wp.alt_cstr > 0) {
          wpIns = sprintf("%i:%s@%i",wpLen,wp.wp_name,int(wp.alt_cstr));
        } else {
          wpIns = sprintf("%i:%s@-1",wpLen,wp.wp_name);
        }
        tracer("[FMS] Insert route: "~wpIns~", of type: "~wp.wp_type);
      }
      if (wp.wp_type == "Normal") {
        if (wpMode == "V1") {
	  tracer("[V1] /autopilot/route-manager/input, @insert "~wpIns);
          ##setprop("/autopilot/route-manager/input", "@insert "~wpIns);
        }
        var wpt = wp;
        wpt.wp_parent_name = getprop("instrumentation/afs/sid");
        wpt.wp_type = "SID";
        if (wpt.spd_cstr == nil and wpt.spd_cstr > 0) {
          wpt.spd_cstr = toSpd;
        } else {
          toSpd = wpt.spd_cstr;
        }
        airbusFMS.insertWP(wpt, discontIdx);
        discontIdx = discontIdx+1;
      }
    }
    var transArm = 0;
    if (sid.transitions != nil and size(sid.transitions) > 0) {
      foreach(var tr; sid.transitions) {
        if (tr.trans_type == "sid") {
          transArm = 1;
        }
      }
    }
    if (transArm == 1) {
      nextPage = "active.departure.sid.trans";
    } else {
      nextPage = "active.departure.arv";
      copyPlanToRoute();
      if (getprop("autopilot/route-manager/active") == 0) {
        tracer("@ACTIVATE");
        ##setprop("/autopilot/route-manager/input", "@ACTIVATE");
        ##setprop("/autopilot/route-manager/active",1);
      }
    }

    #
    ####  calculate T/C
    #
    var prevWpt = airbusFMS.getWP(discontIdx-1);
    var fromApt = airportinfo(getprop("/instrumentation/afs/FROM"));
    var toApt = airportinfo(getprop("/instrumentation/afs/TO"));
    var crzFt  = getprop("/instrumentation/afs/thrust-cruise-alt");
    var tocWP = fmsWP.new();
    tocWP.wp_name="(T/C)";
    tocWP.wp_type = "T/C";
    ###var climbNM = calcDistAtAngle(3, crzFt);
    var climbTime = crzFt/1570;
    var climbNM = climbTime*5.095;
    var tocWpCoord = geo.Coord.new();
    tocWpCoord.set_latlon(fromApt.lat, fromApt.lon, fromApt.elevation);
    var prevCoord = geo.Coord.new();
    var toAptCoord = geo.Coord.new();
    toAptCoord.set_latlon(toApt.lat, toApt.lon, 0);
    tracer("prevWPT.wp_lat: "~prevWpt.wp_lat~", prevWPT.wp_lon: "~prevWpt.wp_lon~", toApt.lat: "~toApt.lat~", toApt.lon: "~toApt.lon);
    prevCoord.set_latlon(prevWpt.wp_lat, prevWpt.wp_lon, 0);
    var hdg = prevCoord.course_to(toAptCoord);
    tracer("apply course: "~hdg~", distance: "~climbNM*NM2MTRS);
    tocWpCoord.apply_course_distance(hdg, (climbNM*NM2MTRS));
    var tcLat = tocWpCoord.lat();
    var tcLon = tocWpCoord.lon();
    tracer("tocWpCoord.lat: "~tcLat~" / tocWpCoord.lon: "~tcLon);
    tocWP.wp_lat = tcLat;
    tocWP.wp_lon = tcLon;
    tracer("tocWP.wp_lat: "~tocWP.wp_lat~" / tocWP.wp_lon: "~tocWP.wp_lon);
    tocWP.alt_cstr = crzFt;
    tocWP.spd_cstr = getprop("instrumentation/afs/crz_mach");
    var existIdx = airbusFMS.findWPType("T/C");
    if (existIdx == nil) {
      airbusFMS.insertWP(tocWP, discontIdx);
      discontIdx = discontIdx+1;
      if (wpMode == "V1") {           ## V1
        var wpLen = getprop("/autopilot/route-manager/route/num");
        insertAbsWP("(T/C)",wpLen-1,tocWP.wp_lat,tocWP.wp_lon, tocWP.alt_cstr);
      }
    } else {
      airbusFMS.replaceWPAt(tocWP, existIdx);
    }
  }
  if (direct == "star") {
    var star = arvDB.getStar(sidVal);
    var wpLen = getprop("/autopilot/route-manager/route/num");
    var crzFl = getprop("/instrumentation/afs/CRZ_FL");

    var appSpd = 270;
    airbusFMS.clearWPType("STAR");
    airbusFMS.clearWPType("IAP");
    airbusFMS.clearWPType("T/D");
    foreach(var w; star.wpts) {
      if (wpMode == "V1") {
        var wpIns = "";
        var wpLen = getprop("/autopilot/route-manager/route/num");
        tracer("wpLen now: "~wpLen);
        if (w.alt_cstr > 0) {
          wpIns = sprintf("%i:%s@%i",wpLen-1,w.wp_name,int(w.alt_cstr));
        } else {
          wpIns = sprintf("%i:%s@-1",wpLen-1,w.wp_name);
        }
        tracer("Insert star route: "~wpIns~", of type: "~w.wp_type);
      }
      if (w.wp_type == "Normal") {
        if (wpMode == "V1") {   ##V1
	  tracer("[V1] /autopilot/route-manager/input, @insert "~wpIns);
          ##setprop("/autopilot/route-manager/input", "@insert "~wpIns);
          ##checkInsert(w, wpLen-1);
        }
        var wpt = fmsWP.new();
        wpt.copy(w);
        wpt.wp_parent_name = getprop("instrumentation/afs/star");
        wpt.wp_type = "STAR";
        if (wpt.alt_cstr != nil and wpt.alt_cstr < 11000) {
          appSpd = 250;
        }
        if (wpt.alt_cstr != nil and wpt.alt_cstr <= 6000) {
          appSpd = 220;
        }
        if (wpt.alt_cstr != nil and wpt.alt_cstr <= 3000) {
          appSpd = 210;
        }
        if (wpt.spd_cstr == nil) {
          wpt.spd_cstr = appSpd;
          spd_cstr_ind = 0;
        } else {
          appSpd = wpt.spd_cstr;
          wpt.spd_cstr_ind = 1;
        }
        ##var lastPos = airbusFMS.getPlanSize()-1;
        var arpIdx = airbusFMS.findWPName(getprop("/instrumentation/afs/TO"));
        var lastPos = airbusFMS.findWPType("END");
        if (lastPos == nil) {
          lastPos = airbusFMS.getPlanSize()-1;
        } else {
          lastPos = lastPos;
        }
        airbusFMS.insertWP(wpt, arpIdx);
      }
    }
    tracer("insert T/D after STAR");
    insertTopOfDescent();

    var transArm = 0;
    if (star.transitions != nil and size(star.transitions) > 0) {
      foreach(var tr; star.transitions) {
        if (tr.trans_type == "star") {
          transArm = 1;
        }
      }
    }
    ##################
    ## insert approach transition and IAP wpts

    if (transArm == 1) {
      nextPage = "active.departure.arv";
    } else {
      nextPage = "active.departure.arv";
    }
    var appr = arvDB.getApproachList(getprop("/instrumentation/afs/arv-rwy"), "ILS");
    if (appr == nil or size(appr) == 0) {
      tracer("No ILS approach found, try RNAV...");
      appr = arvDB.getApproachList(getprop("/instrumentation/afs/arv-rwy"), "RNAV");
    }
    if (appr == nil or size(appr) == 0) {
      tracer("No ILS approach found, try RNAV...");
      appr = arvDB.getApproachList(getprop("/instrumentation/afs/arv-rwy"), "VOR");
    }
    tracer("Approaches found: "~size(appr));
    if (size(appr) == 1) {
      var iap = appr[0];
      airbusFMS.clearWPType("IAP");
      tracer("star approach avail: "~iap.wp_name~", with "~size(iap.wpts)~" wps");
      foreach(var trans; iap.transitions) {
        if (trans.trans_name == sidVal) {
          tracer("transition to approach has "~size(trans.trans_wpts)~" wps");
          foreach(var twp; trans.trans_wpts) {
            if (twp.wp_type == "Normal" or twp.wp_type == "Outer Marker") {
              var iapWP =  fmsWP.new();
              iapWP.copy(twp);
              iapWP.wp_type = "IAP";
              if (wpMode == "V1") {   ## V1
                var wpLen = getprop("/autopilot/route-manager/route/num");
                var wpIns = "";
                var idExists = 0;
                for(var r=0; r != wpLen; r=r+1) {
                  var rId = getprop("/autopilot/route-manager/route/wp["~r~"]/id");
                  if (rId == twp.wp_name) {
                    idExists = 1;
                  }
                }
              }
              var idExists = airbusFMS.findWPName(twp.wp_name);
              if (idExists == nil) {
                var wpName = twp.wp_name;
                var wpAlt = -1;
                if (twp.alt_cstr > 0) {
                  wpAlt = int(twp.alt_cstr);
                }
                if (twp.wp_type == "Outer Marker") {
                  if (wpMode == "V1") {  ## V1
                    wpName = sprintf("%i:%s,%s",wpLen-1,twp.wp_lon,twp.wp_lat);
                    insertAbsWP("OM",wpLen-1,wp_lat,wp_lon,wpAlt);
                    tracer("insert approach OM");
                  }
                  iapWP.wp_name = "O.M";
                  var arpIdx = airbus.findWPName(getprop("/instrumentation/afs/TO"));
                  airbusFMS.insertWP(iapWP, arpIdx);
                } else {
                 if (wpMode == "V1") {  ## V1
                    wpIns = sprintf("%i:%s@%i",wpLen-1,wpName,wpAlt);
                    tracer("Insert approach transition: "~wpIns~", of type: "~twp.wp_type);
		    tracer("[V1] /autopilot/route-manager/input, @insert "~wpIns);
                    ##setprop("/autopilot/route-manager/input", "@insert "~wpIns);
                 }
                 var arpIdx = airbus.findWPName(getprop("/instrumentation/afs/TO"));
                 iapWP.wp_type = "IAP";
                 airbusFMS.insertWP(iapWP, arpIdx);
                }
              }
            }
            
          }
        }
      }
      var runwayTransArm = 0;
      foreach(var awp; iap.wpts) {
        tracer("[Star.IAP] approach wp: "~awp.wp_name~", type: "~awp.wp_type);
        if (awp.wp_type == "Runway") {
              runwayTransArm = 1;   #Don't include GA in approach.
              break;
        }
        if ((awp.wp_type == "Normal" or awp.wp_type == "Outer Marker" or awp.wp_type == "Middle Marker") and runwayTransArm == 0) {
          if (wpMode == "V1") {  ## V1
            var wpLen = getprop("/autopilot/route-manager/route/num");
            var wpIns = "";
            var idExists = 0;
            for(var r=0; r!= wpLen; r=r+1) {
              var rId = getprop("/autopilot/route-manager/route/wp["~r~"]/id");
              if (rId == awp.wp_name) {
                tracer("[Star.IAP] awp: "~awp.wp_name~" already exists!");
                idExists = 1;
              }
            }
          }
          var idExists = airbusFMS.findWPName(awp.wp_name);
          if (idExists == nil) {
            var iapWP = fmsWP.new();
            iapWP.copy(awp);
            iapWP.wp_type = "IAP";
            var wpAlt = -1;
            if (awp.alt_cstr >0) {
              wpAlt = int(awp.alt_cstr);
              iapWP.alt_cstr_ind = 1;
            }
            if (awp.wp_type == "Outer Marker" or awp.wp_type == "Middle Marker") {
              var type = "O.M";
              if (awp.wp_type == "Middle Marker") {
                type = "M.M";
              }
              if (wpMode == "V1") {  ## V1
                wpLen = getprop("/autopilot/route-manager/route/num");
                var wpName = awp.wp_name;
                insertAbsWP(type,wpLen-1,awp.wp_lat,awp.wp_lon,wpAlt);
              }
              var arpIdx = airbusFMS.findWPName(getprop("/instrumentation/afs/TO"));
              iapWP.wp_type = "IAP";
              iapWP.wp_name = type;
              airbusFMS.insertWP(iapWP, arpIdx);
            } else {
              if (wpMode == "V1") { ## V1
                wpIns = sprintf("%i:%s@%i",wpLen-1,wpName,wpAlt);
                tracer("Insert approach route: "~wpIns~", of type: "~awp.wp_type);
	        tracer("[V1] /autopilot/route-manager/input, @insert "~wpIns);
                ##setprop("/autopilot/route-manager/input", "@insert "~wpIns);
              }
              var arpIdx = airbusFMS.findWPName(getprop("/instrumentation/afs/TO"));
              iapWP.wp_type = "IAP";
              airbusFMS.insertWP(iapWP, arpIdx);
            }
          }
        }
      }
    } else {
      tracer("[MCDU] WARN: found "~size(appr)~" approaches, can't use any!!");
    }
    
    updateApproachAlts();
    
    var newIdx = copyPlanToRoute();

    if (getprop("autopilot/route-manager/active") == 0) {
      tracer("@ACTIVATE");
      setprop("/autopilot/route-manager/input", "@ACTIVATE");
      ##setprop("/autopilot/route-manager/active",1);
    }
    if (newIdx > 0) {
      tracer("@JUMP"~newIdx);
      setprop("autopilot/route-manager/input", "@JUMP"~newIdx);
    }
  }
  setprop("/instrumentation/mcdu["~unit~"]/opt-scroll", 0);
  changePage(unit, nextPage);
}


####################################
## copy from airbusFMS to Route Manager plan.
##
var copyPlanToRoute = func() {
    tracer("clear route-manager and copy from FMS plan");
    var crzFl = getprop("/instrumentation/afs/CRZ_FL");
    var curWPIdx = getprop("autopilot/route-manager/current-wp");
    var curWPId = "";
    if (curWPIdx == nil) {
      curWPIdx = -1;
    }
    if (curWPIdx > 0) {
      tracer("[copyPlan] Get current WP at "~curWPIdx);
      curWPId  = getprop("autopilot/route-manager/route/wp["~curWPIdx~"]/id");
    }
    var newCurIdx = curWPIdx;
    ###setprop("/autopilot/route-manager/active",0);
    setprop("autopilot/route-manager/input", "@CLEAR");
    setprop("/autopilot/route-manager/departure/airport",getprop("/instrumentation/afs/FROM"));
    setprop("/autopilot/route-manager/departure/runway",getprop("/instrumentation/afs/dep-rwy"));
    setprop("/autopilot/route-manager/destination/airport",getprop("/instrumentation/afs/TO"));
    if (getprop("/instrumentation/afs/arv-rwy") != nil) {
      setprop("/autopilot/route-manager/destination/runway",getprop("/instrumentation/afs/arv-rwy"));
    }

    var maxWP = airbusFMS.getPlanSize();
    var fp = flightplan();
    var idx = 1;
    for(var w = 0; w < maxWP; w=w+1) {
      var wp = airbusFMS.getWP(w);
      if (wp.wp_type == "APT" or wp.wp_type == "DISC" or wp.wp_type == "END") {
        ##
      } else {
        tracer("FPinsert WP: "~wp.wp_name~", at index: "~idx~", of wp_type: "~wp.wp_type);
        var wpAlt = wp.alt_cstr;
        var wpSpd = wp.spd_cstr;
        tracer("FPinsert wp_alt: "~wpAlt~", wp_spd: "~wpSpd);
        var role = "";
        if (wp.wp_type == "SID" or wp.wp_type == "STAR") {
          role = string.lc(wp.wp_type);
        }
        if (wp.wp_type == "IAP") {
          role = "approach";
        }
        if (wp.wp_type == "T/C" or wp.wp_type == "T/D") {
          role = "pseudo";
        }

          ##var fixList = findFixesByID(wp.wp_name);
          ##var vorList = findNavaidsByID(wp.wp_name);
          var wpGeo = geo.Coord.new();
          wpGeo.set_latlon(wp.wp_lat, wp.wp_lon);
          var wptList = findNavaidsWithinRange(wpGeo, 1);
          
          var wpG = nil;
          tracer("FPinsert, WPlist size: "~size(wptList));
          if (size(wptList) == 0 or wptList[0].id != wp.wp_name) {
            tracer("FPinsert, create WP from lat: "~wp.wp_lat~", lon: "~wp.wp_lon~" name: "~wp.wp_name~" role: "~role);
            var wpt = geo.Coord.new();
            wpt.set_latlon(wp.wp_lat, wp.wp_lon);
            wpG = createWP(wpt, wp.wp_name, role);
          } else {
              tracer("FPinsert, create WP from wptList[0] role: "~role);
              if (size(wptList) > 1) {
              }
              wpG = createWPFrom(wptList[0], role);
          }
        
        fp.insertWP(wpG, idx);
        var leg = fp.getWP(idx);
        if (wp.alt_cstr > 0) {
          tracer("FPinsert: set alt_cstr: "~wp.alt_cstr);
          leg.setAltitude(num(wp.alt_cstr), "at");
        }
        if (wp.spd_cstr > 1) {
          tracer("FPinsert: set spd_cstr: "~wp.spd_cstr);
          leg.setSpeed(num(wp.spd_cstr), "at");
          
        }
        if (wp.spd_cstr > 0 and wp.spd_cstr < 1) {
          tracer("FPinsert: set mach: "~wp.spd_cstr);
          leg.setSpeed(num(wp.spd_cstr), "mach");
        }

        if (curWPIdx > 0 and wp.wp_name == curWPId) {
          tracer("[copyPlan] set new index for WP: "~curWPId~", to: "~idx);
          newCurIdx = idx;
        }
       
        var nme = getprop("autopilot/route-manager/route/wp["~idx~"]/id");
        var legAlt = getprop("autopilot/route-manager/route/wp["~idx~"]/altitude-ft");
        var mach = getprop("autopilot/route-manager/route/wp["~idx~"]/speed-mach");
        var kias = getprop("autopilot/route-manager/route/wp["~idx~"]/speed-kts");
        var spd = "nil";
        if (legAlt == nil) {
          legAlt="nil";
        }
        if (mach != nil) {
          spd=mach;
        }
        if (kias != nil) {
          spd=kias
        }
        tracer("[route] idx: "~idx~", id: "~nme~", alt: "~legAlt~", speed: "~spd);
        tracer("-------------------------");
        idx=idx+1;
      }
    }
    setprop("/autopilot/route-manager/cruise/flight-level",crzFl);
    setprop("/autopilot/route-manager/cruise/altitude-ft",(crzFl*100));
    setprop("/autopilot/route-manager/cruise/speed-kts",480);
    return newCurIdx;
}


#####################################
#
#
selectSidTransAction = func(val, unit) {
    
    var sidTransVal = getprop("/instrumentation/mcdu["~unit~"]/"~val);
    setprop("/instrumentation/afs/sid-trans", sidTransVal);
    tracer("[MCDU] set sid transition with: "~sidTransVal);
    var sidVal = getprop("/instrumentation/afs/sid");
    var sid = depDB.getSid(sidVal);
    var pos = 0;
    var crzFl = getprop("/instrumentation/afs/CRZ_FL");
    var wpLen = getprop("/autopilot/route-manager/route/num");
    foreach(var sidTran; sid.transitions) {
      if (sidTran.trans_name == sidTransVal) {
        for(var w=0; w != size(sidTran.trans_wpts);w=w+1) {
          var wpIns = "";
          var wp = sidTran.trans_wpts[w];
          tracer(" add sid wp: "~wp.wp_name);
          if (w == size(sidTran.trans_wpts)-1) {
            wp.alt_cstr = (crzFl*100);
          }
          var sidTransWP = wp;
          if (wp.alt_cstr != nil and wp.alt_cstr > 0) {
            wpIns = sprintf("%i:%s@%i",(wpLen+w),wp.wp_name,int(wp.alt_cstr));
            sidTransWP.alt_cstr_ind = 1;
          } else {
            wpIns = sprintf("%i:%s@-1",(wpLen+w),wp.wp_name);
          }
          tracer("[FMS] Insert route: "~wpIns~", of type: "~wp.wp_type);
          if (wp.wp_type == "Normal") {
            if (wpMode == "V1" ) { ## V1
	      tracer("[V1] /autopilot/route-manager/input, @insert "~wpIns);
              ##setprop("/autopilot/route-manager/input", "@insert "~wpIns);
            }
            sidTransWP.wp_type = "SID";
            var TCIdx = airbusFMS.findWPType("T/C");
            if (TCIdx == nil) {
              TCIdx = airbusFMS.findWPType("DISC");
            }
            airbusFMS.insertWP(sidTransWP, TCIdx);
          }
        }
      }
    }
  copyPlanToRoute();
  if (getprop("autopilot/route-manager/active") == 0) {
      tracer("@ACTIVATE");
      ###setprop("/autopilot/route-manager/input", "@ACTIVATE");
      ##setprop("/autopilot/route-manager/active",1);
  }
  changePage(unit, "active.departure.dep");
}

######################################
#
#
selectApprConf = func(mode) {
  setprop("instrumentation/afs/appr_conf3", 0);
  setprop("instrumentation/afs/appr_full", 0);
  if (mode == "appr_full") {
    setprop("instrumentation/afs/appr_full", 1);
  } else {
    setprop("instrumentation/afs/appr_conf3", 1);
  }
  calcVapp();
}




#########################################
#
#
atcSend = func(page) {
  if (atn == nil) {
    atn = A380.atnetwork;
  }
  if (page == "logon") {
    atn.doLogon();
    settimer(updatePositionReport, 3);
  }
  if (page == "logoff") {
    atn.doLogoff();
  }
  if (page == "departClear") {
    atn.doRequestGroundClearance();
  }
}

updatePositionReport = func() {
  atn.doPositionReport();
}

#########################################
#
#
calcVapp = func() {
  var flapConfigExtra = 0;
  var speedDif = 1;
  var gwNow = getprop("fdm/jsbsim/inertia/weight-kg");
  tracer("Calculate Vref and Vls");
  var flt_mode = getprop("instrumentation/ecam/flight-mode");
  if (flt_mode < 10) {
    if (flt_mode > 7) {    ## if we are airborne
      var timeToTouchdown = getprop("autopilot/route-manager/wp-last/eta");
      var timeParts = split(":", timeToTouchdown);
      var minsToTouch = timeParts[0]*60+timeParts[1];
      var ffph = getprop("fdm/jsbsim/propulsion/engine[0]/fuel-flow-rate-kgph")+getprop("fdm/jsbsim/propulsion/engine[1]/fuel-flow-rate-kgph")+getprop("fdm/jsbsim/propulsion/engine[2]/fuel-flow-rate-kgph")+getprop("fdm/jsbsim/propulsion/engine[3]/fuel-flow-rate-kgph");
      var ffpm = ffph/60;
      var fuelToBeUsed = ffpm*minsToTouch;
      var estGW = gwNow-fuelToBeUsed;
      tracer("[calcVapp] estGW: "~estGW~", minToTouch: "~minsToTouch);
      speedDif = (470000-estGW)/3333;
    } else {
      var wpNum = getprop("autopilot/route-manager/route/num");
      if (wpNum != nil and wpNum > 0) {
        var totalDist = 0;
        for(var p = 0; p < (wpNum-1); p = p+1) {
          var nextNM =getprop("autopilot/route-manager/route/wp["~p~"]/leg-distance-nm");
          totalDist = totalDist+nextNM;
        }
        tracer("[calcVapp] totalDist: "~totalDist);
        var fu = (totalDist/380)*8600;
        var estGW = gwNow-fu;
        tracer("[calcVapp] route based forecast - fuel est: "~fu~", gw est: "~estGW);
        speedDif = (470000-estGW)/3333;
      }
    }
    tracer("[calcVapp] speedDif: "~speedDif);
    var Vref = 221-speedDif;
    if (getprop("instrumentation/afs/appr_full") == 1) {
      flapConfigExtra = 9;
    }
    Vref = Vref-flapConfigExtra;
    Vls = Vref-15;
    setprop("instrumentation/afs/Vref", Vref);
    setprop("instrumentation/afs/Vls", Vls);
    setprop("instrumentation/afs/appr_wind_deg", getprop("environment/metar[1]/base-wind-dir-deg"));
    setprop("instrumentation/afs/appr_wind_kts", getprop("environment/metar[1]/base-wind-speed-kt"));
    setprop("instrumentation/afs/appr_oat", getprop("environment/metar[1]/temperature-degc"));
  }
}


updateApproachAlts = func() {
### we need to calculate diff alt.
     tracer(" update approach heights..");
     var crzFt  = getprop("/instrumentation/afs/thrust-cruise-alt");
     tracer(">>>>>>>>>>>>>> current thrust-cruise-alt: "~crzFt);
     var crzArm = 0;
     var appSpeed = 270;
     if (wpMode == "V1") {
       var rtSize = getprop("/autopilot/route-manager/route/num");
       for(var r=0; r < rtSize-1; r=r+1) {
         rtSize = getprop("/autopilot/route-manager/route/num");
         var rtAlt = getprop("/autopilot/route-manager/route/wp["~r~"]/altitude-ft");
         if (crzArm == 1 and rtAlt < 0 and (r+1) <= rtSize) {
           var rtLat = getprop("/autopilot/route-manager/route/wp["~r~"]/latitude-deg");
           var rtLon = getprop("/autopilot/route-manager/route/wp["~r~"]/longitude-deg");
           var rtId  = getprop("/autopilot/route-manager/route/wp["~r~"]/id");
           var nextLat = getprop("/autopilot/route-manager/route/wp["~(r+1)~"]/latitude-deg");
           var nextLon = getprop("/autopilot/route-manager/route/wp["~(r+1)~"]/longitude-deg");
           var nextAlt = getprop("/autopilot/route-manager/route/wp["~(r+1)~"]/altitude-ft");
           var prevLat = getprop("/autopilot/route-manager/route/wp["~(r-1)~"]/latitude-deg");
           var prevLon = getprop("/autopilot/route-manager/route/wp["~(r-1)~"]/longitude-deg");
           var prevAlt = getprop("/autopilot/route-manager/route/wp["~(r-1)~"]/altitude-ft");
         
           var nextWpLat = 0.0;
           var nextWpLon = 0.0;
           var nextWpAlt = 1;
           if (r+2 <= rtSize) {
             nextWpAlt = getprop("/autopilot/route-manager/route/wp["~(r+1)~"]/altitude-ft");
           }

           tracer("[FMS] start - r="~r~" of "~rtSize);
           tracer("[FMS] rtId="~rtId~" prev trans lat: "~prevLat~"/lon: "~prevLon~", next lat: "~nextLat~"/lon: "~nextLon~", this lat: "~rtLat~"/lon: "~rtLon);
           tracer("[FMS] prev trans alt: "~prevAlt~", next alt: "~nextAlt);
           var prevDist = gcd2(prevLat, prevLon, rtLat, rtLon, "nm");
           var nextDist = gcd2(rtLat, rtLon, nextLat, nextLon, "nm");
           if (nextAlt == 0) {
             var lastWpLat = nextLat;
             var lastWpLon = nextLon;
             tracer("[FMS] begin calc intermediate: nextWpAlt: "~nextWpAlt~", nextDist: "~nextDist);
             for(var rplus = r+2; rplus <= rtSize and (nextWpAlt == -1); rplus=rplus+1) {
               nextWpLat = getprop("/autopilot/route-manager/route/wp["~(rplus)~"]/latitude-deg");
               nextWpLon = getprop("/autopilot/route-manager/route/wp["~(rplus)~"]/longitude-deg");
               nextWpAlt = getprop("/autopilot/route-manager/route/wp["~(rplus)~"]/altitude-ft");
               var tmpDist = gcd2(lastWpLat, lastWpLon, nextWpLat, nextWpLon, "nm");
               tracer("[FMS] add intermediate WP dist: "~tmpDist);
               nextDist = nextDist+tmpDist;
               lastWpLat = nextWpLat;
               lastWpLon = nextWpLon;
             }
             #####nextAlt = nextWpAlt;
             tracer("[FMS] total intermediate distance: "~nextDist~", nextAlt: "~nextAlt);
             nextAlt = nextWpAlt;
           }

           if (nextAlt == 0) {
             var angle = 3;
             if ((prevAlt-5000) < 11000) {
               angle = 2;
             }
             var tmpHeight = calcHeightAtAngle(angle,(prevDist+nextDist));
             nextAlt = prevAlt-tmpHeight;
             tracer("[FMS] invalid nextAlt recalc - nextAlt: "~nextAlt~", tmpHeight: "~tmpHeight~", angle: "~angle);
           }
           tracer("[FMS] end - prev trans Dist: "~prevDist~"nm, nextDist: "~nextDist~"nm");
           var thisAlt = int(prevAlt-(((prevAlt-nextAlt)/(prevDist+nextDist))*prevDist));
           if (thisAlt < 100) {
             tracer("***** [FMS] incorrect calculation!!  thisAlt: "~thisAlt);
           }
	   tracer("/autopilot/route-manager/input, @delete "~(r));
           setprop("/autopilot/route-manager/input","@delete "~(r));
           var rpIns = sprintf("@insert %i:%s@%i",(r),rtId,thisAlt);
           tracer("[FMS] update idx["~r~"] for id: "~rtId~" with alt: "~thisAlt);
           #if (rtId == "O.M" or rtId == "(T/D)" or rtId == "M.M" or rtId == "T/C") {
             insertAbsWP(rtId,r,rtLat,rtLon,thisAlt);
              var appWP = fmsWP.new();
              var existIdPos = airbusFMS.findWPName(rtId);
              if (existIdPos == nil) {
                existIdPos = tdIdx;
                appWP.wp_type = "STAR";
              } else {
                appWP = airbusFMS.getWPIdx(existIdPos);
                if (appWP.spd_cstr != nil and appWP.spd_cstr < appSpeed) {
                  appSpeed = appWP.spd_cstr;
                }
              } 
              if (thisAlt < 11000 and appSpeed > 250) {
                appSpeed = 250;
              }
              appWP.wp_name = rtId;
              appWP.alt_cstr = thisAlt;
              appWP.spd_cstr = appSpeed;
              appWP.wp_lat = rtLat;
              appWP.wp_lon = rtLon;
              appWP.wp_parent_name = getprop("instrumentation/afs/star");
              airbusFMS.replaceWPAt(appWP, existIdPos);
              tdIdx = tdIdx + 1;
           #} else {
	   #  tracer("/autopilot/route-manager/input, "~rpIns);
           #  setprop("/autopilot/route-manager/input",rpIns);
           #}
           #setprop("/autopilot/route-manager/route/wp["~r~"]/altitude-ft", thisAlt);
           #setprop("/autopilot/route-manager/route/wp["~r~"]/altitude-m", thisAlt*0.3);
           tracer("[FMS] update wp: "~rtId~", with alt: "~thisAlt);
           if (prevAlt == crzFt and thisAlt < crzFt) {
             tracer("[FMS] update thrust descent alt: "~thisAlt);
             setprop("/instrumentation/afs/thrust-descent-alt",thisAlt);
           }
         }
         if (rtAlt == crzFt) {
           crzArm = 1;
         }
       }
     }
     ## V2 version 
     if (wpMode == "V2" ) {
       var rtSize = airbusFMS.findWPName(getprop("/instrumentation/afs/TO"));
       var todIdx = airbusFMS.findWPType("T/D")+1;
       var desFPA = 2.7;
       var appSpeed = 270;
       for(var r = todIdx; r < rtSize; r=r+1) {
         var rtWp = airbusFMS.getWP(r);
         var nextWp = airbusFMS.getWP(r+1);
         var prevWp = airbusFMS.getWP(r-1);
         var nextAlt = nextWp.alt_cstr;

         tracer("[FMS] rtWp.id: "~rtWp.wp_name~", alt_cstr: "~rtWp.alt_cstr~", alt_cstr_ind: "~rtWp.alt_cstr_ind);
         if (rtWp.alt_cstr_ind == 0 and rtWp.alt_cstr == 0) {
           if (nextWp.alt_cstr != 0) {
             var prevAlt = prevWp.alt_cstr;
             var nextAlt = nextWp.alt_cstr;
             var prevDist = gcd2(prevWp.wp_lat, prevWp.wp_lon, rtWp.wp_lat, rtWp.wp_lon, "nm");
             var nextDist = gcd2(nextWp.wp_lat, nextWp.wp_lon, rtWp.wp_lat, rtWp.wp_lon, "nm");
             tracer("[FMS] prevDist: "~prevDist~"nm, nextDist: "~nextDist~"nm, prevAlt: "~prevAlt~", nextAlt: "~nextAlt);
             var thisAlt = int(prevAlt-(((prevAlt-nextAlt)/(prevDist+nextDist))*prevDist));
             tracer("[FMS] update alt - thisAlt: "~thisAlt~", prevDist: "~prevDist~" prevWp: "~prevWp.wp_name);
             rtWp.alt_cstr = thisAlt;
           } else {
             var prevDist = gcd2(prevWp.wp_lat, prevWp.wp_lon, rtWp.wp_lat, rtWp.wp_lon, "nm");
             var tmpHeight = calcHeightAtAngle2(desFPA,prevDist);
             tracer("[FMS] update alt - tmpHeight: "~tmpHeight~", desFPS: "~desFPA~", prevDist: "~prevDist~" prevWp: "~prevWp.wp_name);
             rtWp.alt_cstr = prevWp.alt_cstr-tmpHeight;
           }
         }
         if (rtWp.spd_cstr != 0 and rtWp.spd_cstr < appSpeed) {
           tracer("[FMS] rtWp.spd_cstr: "~rtWp.spd_cstr~", appSpeed: "~appSpeed);
           appSpeed = rtWp.spd_cstr;
         } 
         if (rtWp.alt_cstr > 12000 and rtWp.alt_cstr < 25000) {
           appSpeed = 260;
         }
         if (rtWp.alt_cstr > 6000 and rtWp.alt_cstr < 12000) {
           appSpeed = 250;
         }
         if (rtWp.alt_cstr > 3000 and rtWp.alt_cstr < 6000) {
           appSpeed = 210;
         }
         if (rtWp.alt_cstr < 3000) {
           appSpeed = 180;
         }
         ## update the approach speed
         if (rtWp.spd_cstr == 0) {
           tracer("[FMS] set new spd_cstr: "~appSpeed);
           rtWp.spd_cstr = appSpeed;
         }
         if (rtWp.alt_cstr < 9000) {
           desFPA = 2.0;
         }
         ## finally replace the current WP even if we haven't modified it.
         airbusFMS.replaceWPAt(rtWp, r);
       }
    }
}


###################################################
oldUpdateFunc = func() {
       for(var r= todIdx; r < rtSize; r=r+1) {
         var rtWp = airbusFMS.getWP(r);
         var nextWp = airbusFMS.getWP(r+1);
         var prevWp = airbusFMS.getWP(r-1);
         var nextAlt = nextWp.alt_cstr;
         
         var nextWpLat = 0.0;
         var nextWpLon = 0.0;
         var nextWpAlt = 0;
         if (r+2 <= rtSize) {
           nextWpAlt = nextWp.alt_cstr;
         }

         tracer("[FMS] start - r="~r~" of "~rtSize);
         tracer("[FMS] rtId="~rtWp.wp_name~" prev trans lat: "~prevWp.wp_lat~"/lon: "~prevWp.wp_lon~", next lat: "~nextWp.wp_lat~"/lon: "~nextWp.wp_lon~", this lat: "~rtWp.wp_lat~"/lon: "~rtWp.wp_lon);
         tracer("[FMS] prev trans alt: "~prevWp.alt_cstr~", next alt: "~nextAlt);
         var prevDist = gcd2(prevWp.wp_lat, prevWp.wp_lon, rtWp.wp_lat, rtWp.wp_lon, "nm");
         var nextDist = gcd2(rtWp.wp_lat, rtWp.wp_lon, nextWp.wp_lat, nextWp.wp_lon, "nm");
         if (nextWp.alt_cstr == 0) {
           var lastWpLat = nextWp.wp_lat;
           var lastWpLon = nextWp.wp_lon;
           tracer("[FMS] begin calc intermediate: nextWpAlt: "~nextWp.alt_cstr~", nextDist: "~nextDist);
           for(var rplus = r+2; rplus <= rtSize and (nextWpAlt == -1); rplus=rplus+1) {
             interWp = airbusFMS.getWP(rplus);
             nextWpAlt = interWp.alt_cstr;
             var tmpDist = gcd2(lastWpLat, lastWpLon, interWp.wp_lat, interWp.wp_lon, "nm");
             tracer("[FMS] add intermediate WP dist: "~tmpDist);
             nextDist = nextDist+tmpDist;
             lastWpLat = interWp.wp_lat;
             lastWpLon = interWp.wp_lon;
           }
           tracer("[FMS] total intermediate distance: "~nextDist~", nextAlt: "~nextAlt);
           nextAlt = nextWpAlt;
         }

         if (nextAlt == 0) {
           var angle = 3;
           if ((prevWp.alt_cstr-5000) < 11000) {
             angle = 2;
           }
           var tmpHeight = calcHeightAtAngle(angle,(prevDist+nextDist));
           nextAlt = prevWp.alt_cstr-tmpHeight;
           tracer("[FMS] invalid nextAlt recalc - nextAlt: "~nextAlt~", tmpHeight: "~tmpHeight~", angle: "~angle);
         }
         tracer("[FMS] end - prev trans Dist: "~prevDist~"nm, nextDist: "~nextDist~"nm");
         var thisAlt = int(prevWp.alt_cstr-(((prevWp.alt_cstr-nextAlt)/(prevDist+nextDist))*prevDist));
         tracer("[FMS] prevWp.alt_cstr: "~prevWp.alt_cstr~", nextAlt: "~nextAlt);
         if (thisAlt < 100) {
           tracer("***** [FMS] incorrect calculation!!  thisAlt: "~thisAlt);
         }
	   
         tracer("[FMS] update idx["~r~"] for id: "~rtWp.wp_name~" with new alt: "~thisAlt~", old alt: "~rtWp.alt_cstr);
            var appWP = rtWp;
            var existIdPos = airbusFMS.findWPName(rtWp.wp_name);
            if (appWP.spd_cstr != 0 and appWP.spd_cstr < appSpeed) {
              appSpeed = appWP.spd_cstr;
            } 
            if (thisAlt < 11000 and appSpeed > 250) {
              appSpeed = 250;
            }
            if (appWP.alt_cstr == 0) {
              appWP.alt_cstr = thisAlt;
            }
            appWP.spd_cstr = appSpeed;
            airbusFMS.replaceWPAt(appWP, existIdPos);

           tracer("[FMS] update wp: "~rtWp.wp_name~", with alt: "~thisAlt);
       }
       setprop("instrumentation/afs/thrust-descent-alt", airbusFMS.getWP(todIdx+1).alt_cstr);
     }
#########################################################


##################
## scroll more runways
scrollRwy = func(unit,direct) {
  var rwyScroll = getprop("/instrumentation/mcdu["~unit~"]/opt-scroll");
  var maxRwy    = getprop("/instrumentation/mcdu["~unit~"]/opt-size");
  if (direct == "more") {
    rwyScroll = rwyScroll+1;
  } else {
    rwyScroll = rwyScroll-1;
  }
  if (rwyScroll > int(maxRwy/8)) {
    rwyScroll = int(maxRwy/8);
  }
  if (rwyScroll < 0) {
    rwyScroll = 0;
  }
  for(r =0; r != 8; r=r+1) {
      var rwyAttr = sprintf("/instrumentation/mcdu[%i]/opt%02i",unit,r+1);
      var rwyLenAttr = sprintf("/instrumentation/mcdu[%i]/col01-opt%02i",unit,r+1);
      var rwyHdgAttr = sprintf("/instrumentation/mcdu[%i]/col02-opt%02i",unit,r+1);
     
      setprop(rwyAttr,"");
      setprop(rwyLenAttr,0);
      setprop(rwyHdgAttr,0);
  }
  setprop("/instrumentation/mcdu["~unit~"]/opt-scroll",rwyScroll);
  changePage(unit,getprop("/instrumentation/mcdu["~unit~"]/page"));
}

##############################################
## get ILS frequency from airportinfo.
var getILS = func(apt, rwy) {
   if (trace > 0) {
     debug.dump(apt);
   }
   var mhz = nil;
   ##var runways = apt["runways"];
   var runway = apt.runway(rwy);
   mhz = sprintf("%3.1f",runway.ils_frequency_mhz);
   ##var ks = keys(runways);
   ##for(var r=0; r != size(runways); r=r+1) {
   ##  var run = runways[ks[r]];
   ##  if (run.id == rwy and contains(run, "ils_frequency_mhz")) {
   ##    mhz = sprintf("%3.1f",run.ils_frequency_mhz);
   ##    return mhz;
   ##  }
   ##}
   return mhz;
}

###############################################
# create a fmsWP from airport data
#
var makeAirportWP = func(apt, rwy) {
  ##var runways = apt["runways"];
  var run = apt.runway(rwy);
  var aptWP = fmsWP.new();
  aptWP.wp_name = apt.id;
  aptWP.wp_type = "APT";
  aptWP.wp_lat = run.lat;
  aptWP.wp_lon = run.lon;
  aptWP.alt_cstr = apt.elevation;
  aptWP.hdg_radial = run.heading;
  return aptWP;
}

#####################################################
# removed from "active.departure.dep"
addMissingDeparture = func() {
  var wpLen = getprop("/autopilot/route-manager/route/num");
  var foundWp = 0;
  var strLen = size(depApt.id);
  for(w=0; w < wpLen; w=w+1) {
    var wpName = substr(getprop("/autopilot/route-manager/route/wp["~w~"]/id"),0,strLen);
    if (wpName == depApt.id) {
            foundWp = 1;
    }
  }
  if (foundWp == 0) {
    var wpIns = sprintf("%s@%i",depApt.id,depApt.elevation);
    tracer("clear route-manager, add depart airport: "~wpIns);
    tracer("/autopilot/route-manager/input, "~wpIns);
    setprop("/autopilot/route-manager/input",wpIns);
  }
}


########################################################
#  removed from active.departure.arv
addMissingArrival = func() {
var wpLen = getprop("/autopilot/route-manager/route/num");
    var foundWp = 0;
    var strLen = size(arvApt.id);
    for(w=0; w < wpLen; w=w+1) {
        var wpName = substr(getprop("/autopilot/route-manager/route/wp["~w~"]/id"),0,strLen);
        if (wpName == arvApt.id) {
          foundWp = 1;
        }
    }
    if (foundWp == 0) {
      var wpIns = sprintf("%s@%i",arvApt.id, arvApt.elevation);
      tracer("/autopilot/route-manager/input, "~wpIns);
      setprop("/autopilot/route-manager/input", wpIns);
    }
}


##############################################
# removed with V2
checkInsert = func(wp,r) {
  var wpLen = getprop("/autopilot/route-manager/route/num");
  var foundWp = nil;
  for(wt=0; wt < wpLen; wt=wt+1) {
    if (getprop("/autopilot/route-manager/route/wp["~wt~"]/id") == wp.wp_name) {
      foundWp = fmsWP.new();
      foundWp.name = getprop("/autopilot/route-manager/route/wp["~wt~"]/id");
      foundWp.wp_lat = getprop("/autopilot/route-manager/route/wp["~wt~"]/latitude-deg");
      foundWp.wp_lon = getprop("/autopilot/route-manager/route/wp["~wt~"]/longitude-deg");
      foundWp.alt_cstr = getprop("/autopilot/route-manager/route/wp["~wt~"]/altitude-ft");
      var difLat = foundWp.wp_lat - wp.wp_lat;
      var difLon = foundWp.wp_lon - wp.wp_lon;
      if (difLat < -0.001 or difLat > 0.001 or difLon < -0.001 or difLon > 0.001) {
        tracer("[chkInsert] update STAR WP, input lat: "~foundWp.wp_lat~", wp lat: "~wp.wp_lat);
        tracer("[chkInsert] update STAR WP, input lon: "~foundWp.wp_lon~", wp lon: "~wp.wp_lon);
        setprop("/autopilot/route-manager/input","@delete "~(wt));
        insertAbsWP(wp.wp_name,wt,wp.wp_lat,wp.wp_lon,foundWp.alt_cstr);
      }
    }
  }
  if (foundWp == nil) {
    if (wp.alt_cstr == 0 or wp.alt_cstr == nil) {
      wp.alt_cstr = -1;
    }
    insertAbsWP(wp.wp_name, r, wp.wp_lat, wp.wp_lon, wp.alt_cstr);
  }
}


#######################################
## calculate T/D
insertTopOfDescent = func() {
    var starVal = getprop("instrumentation/afs/star");
    var star = arvDB.getStar(starVal);
    ###var wpLen = getprop("/autopilot/route-manager/route/num");
    var crzFl = getprop("/instrumentation/afs/CRZ_FL");
    var firstStarWp = star.wpts[0];
    var starWPIdx = airbusFMS.findWPType("STAR");
    if (starWPIdx == nil) {
      print("Can't calculate T/D, no STAR.");
      return;
    }
    var starWP = airbusFMS.getWP(starWPIdx);
    var arvApt = airportinfo(getprop("/instrumentation/afs/TO"));
    var crzFt  = getprop("/instrumentation/afs/thrust-cruise-alt");
    tracer(">>>>>>>>>>>>>> current thrust-cruise-alt: "~crzFt);
     
    var prevCoord = geo.Coord.new();
    prevCoord.set_latlon(starWP.wp_lat, starWP.wp_lon, starWP.alt_cstr);
    ### calc Pythagorean Theorem of each phase
    var totalDist = 0;
    var sidebNM = calcDistAtAngle(2, 10000);
    tracer(" 2deg dist: "~sidebNM~" nm");
    totalDist = totalDist+sidebNM;
    var difAlt = (crzFt-arvApt.elevation)-10000;
    sidebNM = calcDistAtAngle(2.7, difAlt);
    tracer(" 3deg dist: "~sidebNM~" nm for: "~difAlt~"ft");
    totalDist = totalDist+sidebNM;
    var remainDist = gcd2(arvApt.lat, arvApt.lon, starWP.wp_lat, starWP.wp_lon, "nm");
    tracer("T/D is at: "~totalDist~"nm from arrival apt, first wp of STAR is: "~remainDist~"nm from airport");
    if (totalDist > remainDist) {
      tracer("totalDist: "~totalDist~" > remainDist: "~remainDist);
      var difDist = totalDist-remainDist;
      var prevWP = nil;
      for (var w = starWPIdx-1; w > 0; w=w-1) {
        prevWP = airbusFMS.getWP(w);
        if (prevWP.wp_type != "DISC" and prevWP.wp_type != "STAR" and prevWP.wp_type != "END") {
          break;
        }
      }
      var prevWpCoord = geo.Coord.new();
      prevWpCoord.set_latlon(prevWP.wp_lat, prevWP.wp_lon, crzFt);
      
      var prevHdg = prevWpCoord.course_to(prevCoord); 
      var nextCoord = geo.Coord.new();
      var nextStarWp = airbusFMS.getWP(starWPIdx+1);
      nextCoord.set_latlon(nextStarWp.wp_lat, nextStarWp.wp_lon, nextStarWp.alt_cstr);
      var starHdg = prevCoord.course_to(nextCoord);
      var difHdg = starHdg-prevHdg;
      tracer("[FMS] diff heading between enroute "~prevHdg~" and star "~starHdg~" is: "~difHdg);
      var hdg = prevHdg;
      ## invert our heading (we are looking from first STAR WP) using our en-route heading.
      if (hdg >= 180) {
        hdg = hdg-180;
      } else {
        hdg = hdg+180;
      }
      
      ## if we need to turn too much, then make new heading along starHdg
      var absHdg = math.abs(difHdg);
      if (absHdg > 80 and absHdg < 180) {
        if (difHdg < 0) {
          hdg = starHdg-80;
        } else {
          hdg = starHdg+80;
        }
      }

      #if (difHdg < 0) {
      #  difHdg = 360+difHdg;
      #}
      if (hdg > 360) {
        hdg = 360-hdg;
      }
      if (hdg < 0) {
        hdg = 360+hdg;
      }
      
     tracer("[FMS] enroute hdg: "~prevHdg~", difHdg: "~difHdg~", hdg: "~hdg~", absHdg: "~absHdg);
 
      ###var hdg = calcOrthHeadingDeg(firstStarWp.wp_lat, firstStarWp.wp_lon, prevRtLat, prevRtLon);
      tracer("[FMS] find point at course: "~hdg~", dist: "~difDist~"nm from: "~firstStarWp.wp_name);
    
      #var tdCoord = calcDistancePointDeg(hdg, difDist, starWP.lat, firstWp.wp_lon);
      var firstWpCoord = geo.Coord.new();
      firstWpCoord.set_latlon(firstStarWp.wp_lat, firstStarWp.wp_lon);
      var tdCoord = firstWpCoord.apply_course_distance(hdg, difDist*NM2MTRS);
      var tdLat = tdCoord.lat();
      var tdLon = tdCoord.lon();
      tracer("T/D lat: "~tdLat~", lon: "~tdLon);
      ##var tdIns = sprintf("@insert %i:%s,%s@%i",wpLen-1,tdLon,tdLat,int(crzFt));
      ##tracer("insert T/D: "~tdIns);
      ##setprop("/autopilot/route-manager/input",tdIns);
      ###insertAbsWP("(T/D)",wpLen-1,tdLat,tdLon,int(crzFt));
      var wp = fmsWP.new();
      wp.wp_name = "(T/D)";
      wp.wp_type = "T/D";
      wp.wp_lat =  tdLat;
      wp.wp_lon =  tdLon;
      wp.alt_cstr = crzFt;
      wp.spd_cstr = getprop("/instrumentation/afs/crz_mach");
      ###var disIdx = airbusFMS.findWPType("DISC");
      airbusFMS.clearWPType("T/D");
      var starWPIdx = airbusFMS.findWPType("STAR");
      airbusFMS.insertWP(wp, starWPIdx);
    } else {
      tracer("totalDist: "~totalDist~" !> remainDist: "~remainDist);
      var difDist = 15;
      var firstWpCoord = geo.Coord.new();
      firstWpCoord.set_latlon(firstStarWp.wp_lat, firstStarWp.wp_lon, crzFt);
      var prevHdg = firstWpCoord.course_to(prevCoord); 
      tracer("[FMS] enroute hdg: "~prevHdg);
      var hdg = prevHdg;
      tracer("[FMS] find point at course: "~hdg~", dist: "~difDist~"nm from: "~firstStarWp.wp_name);
      var tdCoord = firstWpCoord.apply_course_distance(hdg, difDist*NM2MTRS);
      var tdLat = tdCoord.lat();
      var tdLon = tdCoord.lon();
      tracer("T/D lat: "~tdLat~", lon: "~tdLon);
      #var tdIns = sprintf("@insert %i:%s,%s@%i",wpLen-1,tdLon,tdLat,int(crzFt));
      #tracer("insert T/D: "~tdIns);
      #insertAbsWP("(T/D)",wpLen-1,tdLat,tdLon,int(crzFt));
      var wp = fmsWP.new();
      wp.wp_name = "(T/D)";
      wp.wp_type = "T/D";
      wp.wp_lat =  tdLat;
      wp.wp_lon =  tdLon;
      wp.alt_cstr = crzFt;
      wp.spd_cstr = getprop("/instrumentation/afs/crz_mach");
      ##var disIdx = airbusFMS.findWPType("DISC");
      airbusFMS.clearWPType("T/D");
      var starWPIdx = airbusFMS.findWPType("STAR");
      airbusFMS.insertWP(wp, starWPIdx);
      ##wpLen = getprop("/autopilot/route-manager/route/num");
      ##tracer("wpLen now: "~wpLen);
    }
}

#################################################
#   basic mathematic functions not in Nasal :(
#################################################

var acos = func(x) { 
  math.atan2(math.sqrt(1-x*x), x) 
}

var asin = func(x) {
 math.atan2(x,math.sqrt(math.pow(2,1-x)));
}

var degMin2rad = func(deg, min) {
  var d1 = deg+(min/60);
  return d1*(math.pi/180);
}

var nm2rad = func(d) {
 return d*math.pi/(180*60);
}

var calcDistAtAngle = func(angleX, height) {
    var anglexinradians = angleX*(math.pi/180);
    # solve for side b
    var sideb = height/math.tan(anglexinradians);
    # convert ft to nautical miles
    var sidebNM = sideb/6076;
    return sidebNM;
}

var calcHeightAtAngle = func(angleX, dist) {
    ##print("math.pi: "~math.pi);
    var anglexinradians = angleX*(math.pi/180);
    var sidec = dist/math.cos(anglexinradians);
    ##print("anglexRad: "~anglexinradians~", sideC: "~sidec);
    var sidecNM = sidec/6076;
    return sidecNM;
}

var calcHeightAtAngle2 = func(angleDeg, dist) {
    var angleRad = angleDeg*(math.pi/180);
    var sidec = (math.tan(angleRad))*dist;
    ##print("sideC: "~sidec~", angleRad: "~angleRad);
    var sidecNM = sidec*6076;
    return sidecNM;
}


##################################################
#  calculate Great Circle distance between two points
#    unit = ("km", "mi", "nm")
#
var gcd2 = func(lat1, lon1, lat2, lon2, unit) {
  var earth_radius = 6372.795;
  var lng_rad0 = lon1*DEG2RAD;
  var lat_rad0 = lat1*DEG2RAD;
  var lng_rad1 = lon2*DEG2RAD;
  var lat_rad1 = lat2*DEG2RAD;

  var sin_lat0 = math.sin(lat_rad0);
  var cos_lat0 = math.cos(lat_rad0);
  var sin_lat1 = math.sin(lat_rad1);
  var cos_lat1 = math.cos(lat_rad1);

  var delta_lng = lng_rad1-lng_rad0;
  var cos_delta_lng = math.cos(delta_lng);
  var sin_delta_lng = math.sin(delta_lng);

  var central_angle = math.acos(sin_lat0 * sin_lat1 + cos_lat0 * cos_lat1 * cos_delta_lng);

  var clsdl = (cos_lat1 * sin_delta_lng);
  if (clsdl < 0) {
    clsdl = clsdl*-1.0;
  }
  var p1 = math.pow(clsdl, 2);

  var csscc = (cos_lat0 * sin_lat1 - sin_lat0 * cos_lat1 * cos_delta_lng);
  if (csscc < 0) {
    csscc = csscc*-1.0;
  }
  var p2 = math.pow(csscc, 2);
  var sq1 = math.sqrt(p1 + p2);
  var p3 = sin_lat0 * sin_lat1 + cos_lat0 * cos_lat1 * cos_delta_lng;
  var gcdx = math.atan2(sq1,p3);

  var km = gcdx*earth_radius;
  if (unit == "km") {
    km = gcdx*earth_radius;
  } 
  if (unit == "mi") {
    km = (gcdx*earth_radius)*0.621371192;
  }
  if (unit == "nm" ) {
    km = (gcdx * earth_radius) / 1.852;
  }
  return km;
}



####################################################################
# calculate great circle true course using radians and distance in nm.
####################################################################
var calcGCTrueCourse = func(d, lat1, lon1, lat2, lon2) {
  var tc1 = 0;
  if(math.sin(lon2-lon1)<0) {      
   tc1=acos((math.sin(lat2)-math.sin(lat1)*math.cos(d))/(math.sin(d)*math.cos(lat1)));
  } else {   
   var d1 = (math.sin(lat2)-math.sin(lat1)*math.cos(d));
   var d2 = (math.sin(d)*math.cos(lat1));
   var dd1 = d1/d2;
   tracer("[calcTC] d1: "~d1~", d2: "~d2~", dd1: "~dd1);
   tc1=(2*math.pi)-math.acos(dd1);
  }
  return tc1;
}

#######################################################################
#  calculate lat,lon of point that is d distance from lat,lon by tc true course in radians
#######################################################################
var calcDistancePoint = func(tc, d, lat1, lon1) {
  tracer("tc: "~tc~", d: "~d~", lat1: "~lat1~", lon1: "~lon1);
  var lat = math.asin(math.sin(lat1)*math.cos(d)+math.cos(lat1)*math.sin(d)*math.cos(tc));
  #print("lat: "~lat);
  var dlon = math.atan2(math.sin(tc)*math.sin(d)*math.cos(lat1),math.cos(d)-math.sin(lat1)*math.sin(lat));
  #print("dlon: "~dlon);
  var lon = math.mod(lon1-dlon+math.pi,2*math.pi )-math.pi;
  #print("lon: "~lon);
  var latDeg = lat*RAD2DEG;
  var lonDeg = lon*RAD2DEG;
  tracer("[calcDistPoint] latDeg: "~latDeg~", lonDeg: "~lonDeg);
  var dest = geo.Coord.new();
  dest.set_latlon(latDeg, lonDeg, 0);
  #print("final lat: "~latDeg~", lon: "~lonDeg);
  return dest;
}

var calcDistancePointDeg = func(tc, d, lat1, lon1) {
  return calcDistancePoint(tc*DEG2RAD, nm2rad(d), (lat1*DEG2RAD), (lon1*DEG2RAD));
}

######################################################################
# calc straight line course between two points
######################################################################
var calcOrthHeadingDeg = func(lat1, lon1, lat2, lon2) {
 tracer("[calcOrth] lat1: "~lat1~", lon1: "~lon1~", lat2: "~lat2~", lon2: "~lon2);
 lat1 *= DEG2RAD;
 lon1 *= DEG2RAD;
 lat2 *= DEG2RAD;
 lon2 *= DEG2RAD;
 
 sin_lat1 = math.sin(lat1);
 cos_lat1 = math.cos(lat1);
 sin_lat2 = math.sin(lat2);
 cos_lat2 = math.cos(lat2);
 dlon = lon2-lon1;
   
 Aorth = math.atan2(math.sin(dlon)*cos_lat2, cos_lat1*sin_lat2-sin_lat1*cos_lat2*math.cos(dlon));
 while ( Aorth >= TWOPI ) {Aorth -= TWOPI};
 if(Aorth<0) Aorth+= TWOPI;
 return (Aorth*RAD2DEG);
}

####################
# insertAbsWP
insertAbsWP = func(id, index, lat, lon, alt) {
  tracer("/instrumentation/gps/scratch/altitude-ft, "~alt);
  setprop("/instrumentation/gps/scratch/altitude-ft",alt);
  tracer("/instrumentation/gps/scratch/ident, "~id);
  setprop("/instrumentation/gps/scratch/ident",id);
  tracer("/instrumentation/gps/scratch/index, "~index);
  setprop("/instrumentation/gps/scratch/index",index);
  tracer("/instrumentation/gps/scratch/latitude-deg, "~lat);
  setprop("/instrumentation/gps/scratch/latitude-deg",lat);
  tracer("/instrumentation/gps/scratch/longitude-deg, "~lon);
  setprop("/instrumentation/gps/scratch/longitude-deg",lon);
  tracer("/instrumentation/gps/scratch/name, "~id);
  setprop("/instrumentation/gps/scratch/name",id);
  tracer("/instrumentation/gps/scratch/type, waypoint");
  setprop("/instrumentation/gps/scratch/type","waypoint");
  var funct = "route-insert-before";
  if (index == -1) {
    funct = "route-insert-after";
    index = 0;
  }
  tracer("/instrumentation/gps/command, "~funct);
  setprop("/instrumentation/gps/command", funct);
}

# update Vr and V2 when we change the T.O. flaps config
setlistener("instrumentation/afs/to-flaps", func(n) {
  calcVSpeeds();
});


################################
##  deep copy
##
deepcopy = func(o) {
    result = "";
    if(typeof(o) == "scalar") {
        n = num(o);
        if(n == nil) { result = result ~ '"' ~ o ~ '"'; }
        else { result = result ~ o; }
    } elsif(typeof(o) == "vector") {
        result = result ~ "[ ";
        if(size(o) > 0) { result = result ~ deepcopy(o[0]); }
        for(i=1; i<size(o); i=i+1) {
            result = result ~ ", " ~ deepcopy(o[i]);
        }
        result = result ~ " ]";
    } elsif(typeof(o) == "hash") {
        ks = keys(o);
        result = result ~ "{ ";
        if(size(o) > 0) {
            k = ks[0];
            result = result ~ k ~ ":" ~ deepcopy(o[k]);
        }
        for(i=1; i<size(o); i=i+1) {
            k = ks[i];
            result = result ~ ", " ~ k ~ " : " ~ deepcopy(o[k]);
        }
        result = result ~ " }";
    } else {
        result = result ~ "nil";
    }
    return result;
}


### Call the init_mcdu after a few seconds to give time for other systems to settle.
#  after all the function names have been parsed and are available.
# 
settimer(init_mcdu, 2);
