#############################################################################
#
# Airbus Auto Flight Guidance for controlling the autopilot.
#
# Based heavily on code from Syd Adams and Curtis Olson's flight director.
# 
# Modified by S.Hamilton May 2009
#
#
#   Copyright (C) 2009 Scott Hamilton
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#


#
#############################################################################
# 1 metre = 0.000539956803 nm
#
#
#############################################################################
# Global shared variables
#############################################################################

# 0 - Off: v-bars hidden
# lnav -0=off,1=HDG,2=NAV,3=APR,4=BC,5=ROUTE
# vnav - 0=off,1=GS,2=ALT SELECT,3=VS,4=IAS
# A380 modes (s-selected, m-managed)
# lnav 0=off, 1=HDG(s), 2=TRACK(s), 3=NAV1/LOC(m), 4=FMS(m), 5=RWY(m)
# vnav 0=off, 1=ALT(s), 2=V/S(s), 3=OP CLB(s), 4=FPA(s), 5=OP DES(s), 6=CLB(m), 7=ALT(m), 8=DES=(m), 9=G/S(m), 10=SRS(m),11=LEVEL
# athr 0=idle, 1=CL, 2=FLX, 3=TOGA
# spd  0=off, 1=TOGA, 2=FLEX, 3=THR CLB, 4=SPEED(s), 5=MACH(s), 6=CRZ(m), 7=THR IDL(m - DES)

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

version="V1.1.22";
trace=0;

atn = nil;  ## will get update after FDM init
airbusFMS = nil;   ## updated after FDM init

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
MSEC2KT=1.946;
FPM2MSEC=0.00508;
KT2MSEC=0.514;
MSEC2KMH=3.6;
KMH2MSEC=0.28;
NM2MTRS = 1852;
METRE2NM = 0.000539956803;
lur_koeff1 = 5.661872017348443498;   #=g*tan(30deg)


turn_radius_m = 0.0;
lur=0;
lnav = 0;
vnav=0;
lnav_last = 0;
vbar_roll = 0.0;
vbar_pitch = 0.0;
vbar_rol_propl = 0.0;
vbar_pitch_prop = 0.0;
vbar_roll_prop = 0.0;
trk_lck_mode = 0;
nav_dist = 0.0;
last_nav_dist = 0.0;
last_nav_time = 0.0;
tth_filter = 0.0;
alt_select = 0.0;
current_alt=0.0;
current_heading = 0.0;
n_offset = 0.0;
alt_offset = 0.0;
fd_on = 0;
ap_on = 0.0;
at_on=0;
alt_alert = 0.0;
course = 0.0;
course_offset=0.0;
nav_hdg_offset=0.0;
nav_mag_brg=0.0;
gs_active = 0.0;
to_flag = 0;
slaved = 0;
test = 0.0;
maxroll=0;
maxpitch=0;
nav_time=0;
nav_dt=0;
inrange=0;
nav_rate=0;
tth=0;
trk_on = 0;
current_pitch=0;
desired_course=0;
nav_adjust=0;
tgtrad=0;
bank=0;
curhdg=0;
diff=0;
roll_out_time_sec=0;
NextWP_trueCourse=0.0;
currTrack_trueCourse=0.0;
currWP_trueCourse=0.0;
spdCruiseArm=0;
clbSpdArm2=0;
spdClimbRedArm=0;
spdDesArm2=0;
spdDesArm3=0;
spdDesArm4=0;
nextTD = 0;

# track nav
US=0.0;#angle of drift
KUS=0.0;#heading angle of drift
FPU=0.0;#fact track angle
ZPU=0.0;#required track angle
We=0.0;
Wn=0.0;

trk_lck_mode = 0;
abs_z_nm = 0.0;
trk_range1 = 0.0;
trk_range2 = 0.0;
trk_range3 = 0.0;#lur 30-deg turn
trk_range4 = 0.0;#lur 5-deg turn
trk_lock_range = 0.0;#lock range = +-100 metres
intrcpt_hdg_deg = 0.0;
trk_intrcpt_hdg_err = 0.0;
trk_corr_err = 0.0;

lastNavStatus = 0;
lastGSStatus  = 0;


#waypoint
wp_id="";
wp_longitude_deg=0.0;
wp_latitude_deg=0.0;
wp_altitude_ft=0;
complete_turn = 0;
in_turn = 0;
GPS_GO=1;

TRK_M = 200;


#
####srsFlapTarget = [263.0, 220.0, 210.0, 196.0, 182.0];   #another copy in system.nas
####srsFlapTarget = [250.0, 220.0, 190.0, 170.0, 150.0];   #another copy in system.nas
srsFlapTarget = [263.0, 222.0, 210.0, 196.0, 182.0];
throttleRates = [0.0, 0.65, 0.90, 0.97];
flexTempN1 = [96.6, 96.5, 96.5, 96.5, 96.4, 96.4, 96.4, 96.3, 96.3, 96.3, 96.1, 96.0, 95.8, 95.6, 95.5, 95.3, 95.2, 95.0, 94.9, 94.7, 94.5, 94.4, 94.2, 94.1, 93.9, 93.8, 93.6, 93.5, 93.3, 93.1, 93.0, 92.8, 92.7, 92.5, 92.4, 92.2, 92.1, 91.9, 91.7, 91.6, 91.4, 91.3, 91.1, 91.0, 90.8, 90.7, 90.5, 90.3, 90.2, 90.0, 89.9, 89.7, 89.6, 89.4, 89.3, 89.1, 88.9, 88.8, 88.6, 88.5, 88.3, 88.3, 88.2, 88.1, 88.0 ];




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
    print("[AirbusFG] time: "~timeStr~" alt: "~curAltStr~", - "~msg);
    if (trace > 1) {
      print("[AirbusFG] vnav: "~vnavStr[curVnav]~", lnav: "~lnavStr[curLnav]~", spd: "~spdStr[curSpd]);
    }
  }
}



setlistener("/sim/signals/fdm-initialized", func {
    # default values
    print("Initialising Flight Guidance "~version);
    setprop("/instrumentation/flightdirector/lnav", 0.0);
    setprop("/instrumentation/flightdirector/lnav-arm", 0.0);
    setprop("/controls/autoflight/lateral-mode",0.0);
    setprop("/instrumentation/flightdirector/vnav", 0.0);
    setprop("/instrumentation/flightdirector/vnav-arm", 0.0);
    setprop("/instrumentation/flightdirector/alt-acquire-mode", 0);
    setprop("/controls/autoflight/vertical-mode",0.0);
    setprop("/instrumentation/flightdirector/athr",0);
    setprop("/instrumentation/flightdirector/flex-temp",40);
    setprop("/instrumentation/flightdirector/vbar-pitch", 0.0);
    setprop("/instrumentation/flightdirector/vbar-roll", 0.0);
    setprop("/instrumentation/flightdirector/alt-offset", 0.0);
    setprop("/instrumentation/flightdirector/autopilot-on",0.0);
    setprop("/instrumentation/flightdirector/fd-on",0.0);
    setprop("/instrumentation/flightdirector/at-on",0);
    setprop("/instrumentation/flightdirector/spd",0);
    setprop("/instrumentation/flightdirector/spd-arm",0);
    setprop("/instrumentation/flightdirector/alt-alert", alt_alert);
    setprop("/instrumentation/flightdirector/course", 0.0);
    setprop("/instrumentation/flightdirector/dtk", 0.0);
    setprop("/instrumentation/flightdirector/nav-hdg", 0.0);
    setprop("/instrumentation/flightdirector/gs-pitch", 0.0);
    setprop("/instrumentation/flightdirector/nav-mag-brg", 0.0);
    setprop("/instrumentation/flightdirector/course-offset", course_offset);
    setprop("/instrumentation/flightdirector/target-inhg", 29.92);
    setprop("/instrumentation/flightdirector/to-flag",0);
    props.globals.getNode("/instrumentation/flightdirector/to-flag").setBoolValue(0);
    setprop("/instrumentation/flightdirector/from-flag",0);
    setprop("/instrumentation/flightdirector/accel-arm",0.0);
    setprop("/instrumentation/flightdirector/climb-arm",0.0);
    setprop("/instrumentation/flightdirector/past-td", 0);
    setprop("/instrumentation/afs/flex-throttle",0.0);
    setprop("/instrumentation/afs/V1",135);
    setprop("/instrumentation/afs/Vr",140);
    setprop("/instrumentation/afs/V2",145);
    setprop("/instrumentation/afs/to-F",180);
    setprop("/instrumentation/afs/to-S",220);
    setprop("/instrumentation/afs/to-greendot",240);
    setprop("/instrumentation/afs/Vls", 180);
    setprop("/instrumentation/afs/Vapp", 195);
    setprop("/instrumentation/afs/lateral-mode",0);
    setprop("/instrumentation/afs/vertical-vs-mode",-1);
    setprop("/instrumentation/afs/vertical-alt-mode",-1);
    setprop("/instrumentation/afs/speed-mode",-1);
    setprop("/instrumentation/afs/lateral-display",0);
    setprop("/instrumentation/afs/vertical-vs-display",-1);
    setprop("/instrumentation/afs/vertical-alt-display",-1);
    setprop("/instrumentation/afs/spd-display",-1);
    setprop("/instrumentation/afs/vertical-lvl-managed-mode",0);
    setprop("/instrumentation/afs/lateral-managed-mode",0);
    setprop("/instrumentation/afs/speed-managed-mode",0);
    setprop("/instrumentation/afs/thrust-reduce-alt",1300);
    setprop("/instrumentation/afs/thrust-accel-alt",5500);
    ###  should be set from route manager at initalisation.
    setprop("/instrumentation/afs/thrust-cruise-alt",30000);
    setprop("/instrumentation/afs/decel-alt", 10000);
    setprop("/instrumentation/afs/to-flaps", 2);
    setprop("/instrumentation/afs/crz_speed", 310);
    setprop("/instrumentation/afs/crz_mach", 0.85);
    setprop("/instrumentation/afs/clb_speed", 270);
    setprop("/instrumentation/afs/clb_mach", 0.690);
    setprop("/instrumentation/afs/des_speed", 270);
    setprop("/instrumentation/afs/des_mach", 0.660);
    setprop("/instrumentation/afs/changeover-mode", 0);    ### 0 == below changeover, 1 == above changeover
    setprop("/instrumentation/afs/changeover-alt", 28000);  # to be recomputed after T.O config
    #setprop("/instrumentation/afs/thrust-descent-alt",14000);
    setprop("/instrumentation/afs/transition-ft",10000);
    setprop("/instrumentation/afs/CRZ_FL",300);
    setprop("/instrumentation/afs/acquire_cl",0);
    setprop("/instrumentation/afs/acquire_crz",0);
    setprop("/instrumentation/afs/target-altitude-ft",30000);
    setprop("/instrumentation/afs/vertical-speed-fpm",1000);
    setprop("/instrumentation/afs/heading-bug-deg",0);
    setprop("/instrumentation/afs/target-speed-kt",200);
    setprop("/instrumentation/afs/target-speed-mach", 0.85);
    setprop("/instrumentation/afs/spd-mach-display-mode", 0);   ## 0 == Kt, 1 == Mach
    setprop("/instrumentation/afs/limit-min-vs-fps", -16.67);
    setprop("/instrumentation/afs/limit-max-vs-fps", 33.33);
    setprop("/instrumentation/afs/steps[0]/at","");
    setprop("/instrumentation/afs/steps[0]/fl","300");
    setprop("/autopilot/settings/heading-bug-deg",0);
    setprop("/autopilot/settings/target-altitude-ft",0);
    setprop("autopilot/settings/vertical-speed-fpm",1000);
    setprop("/autopilot/settings/target-speed-kt",200.0);
    setprop("/autopilot/locks/altitude","");
    setprop("/autopilot/locks/heading","");
    setprop("/instrumentation/nav/slaved-to-gps",slaved);
    current_alt = getprop("/instrumentation/altimeter/indicated-altitude-ft");
    alt_select = getprop("/autopilot/settings/target-altitude-ft");
    ##setprop("/instrumentation/flightdirector/to-flag",getprop("/instrumentation/nav[0]/to-flag"));
    props.globals.getNode("/instrumentation/flightdirector/to-flag").setBoolValue(getprop("/instrumentation/nav[0]/to-flag"));
    GPS_GO=1;

    atn = A380.atnetwork;
    airbusFMS = A380.fms;
#route settings
   if(getprop("/autopilot/route-manager/route/wp/id")!=nil) {              #if waypoint present
    if(getprop("/autopilot/route-manager/route/wp/altitude-ft") < 40000) {  #setting target altitude
     setprop("/autopilot/settings/target-altitude-ft", getprop("/autopilot/route-manager/route/wp/altitude-ft"));
    }
    ##settimer(init_gps,2);
   }
});



init_gps = func {
    setprop("/instrumentation/gps/wp/wp[1]/waypoint-type", "nav");
    setprop("/instrumentation/gps/wp/wp[1]/name", "waypoint");

    wp_id = getprop("/autopilot/route-manager/route/wp/id");
    setprop("/instrumentation/gps/wp/wp[1]/ID", wp_id);
    tracer("wp_id=", wp_id);

    wp_altitude_ft = getprop("/autopilot/route-manager/route/wp/altitude-ft");
    setprop("/instrumentation/gps/wp/wp[1]/altitude-ft", wp_altitude_ft);
    tracer("wp_alt_ft=", wp_altitude_ft);

    wp_latitude_deg = getprop("/autopilot/route-manager/route/wp/latitude-deg");
    setprop("/instrumentation/gps/wp/wp[1]/latitude-deg", wp_latitude_deg);
    tracer("wp_lat_deg=", wp_latitude_deg);
#    setprop("/instrumentation/gps/wp/wp[1]/latitude-deg", getprop("/autopilot/route-manager/route/wp/latitude-deg"));

    wp_longitude_deg = getprop("/autopilot/route-manager/route/wp/longitude-deg");
    setprop("/instrumentation/gps/wp/wp[1]/longitude-deg", wp_longitude_deg);
    tracer("wp_lon_deg=", wp_longitude_deg);
#    setprop("/instrumentation/gps/wp/wp[1]/longitude-deg", getprop("/autopilot/route-manager/route/wp/longitude-deg"));
    calc_initial_track_params();
    calc_orthodromic_params();
     GPS_GO=1;
    
};


#
#changing current wp
#
gps_next_wp = func {
    setprop("/instrumentation/gps/wp/wp/waypoint-type", getprop("/instrumentation/gps/wp/wp[1]/waypoint-type"));
    setprop("/instrumentation/gps/wp/wp/name", getprop("/instrumentation/gps/wp/wp[1]/name"));
    setprop("/instrumentation/gps/wp/wp/ID", getprop("/instrumentation/gps/wp/wp[1]/ID"));
    setprop("/instrumentation/gps/wp/wp/altitude-ft", getprop("/instrumentation/gps/wp/wp[1]/altitude-ft"));
    setprop("/instrumentation/gps/wp/wp/latitude-ft", getprop("/instrumentation/gps/wp/wp[1]/latitude-ft"));
    setprop("/instrumentation/gps/wp/wp/longitude-ft", getprop("/instrumentation/gps/wp/wp[1]/longitude-ft"));


    setprop("/instrumentation/gps/wp/wp[1]/waypoint-type", "nav");
    setprop("/instrumentation/gps/wp/wp[1]/name", "waypoint");

    wp_id = getprop("/autopilot/route-manager/route/wp/id");
    setprop("/instrumentation/gps/wp/wp[1]/ID", wp_id);
    tracer("wp_id=", wp_id);

    wp_altitude_ft = getprop("/autopilot/route-manager/route/wp/altitude-ft");
    setprop("/instrumentation/gps/wp/wp[1]/altitude-ft", wp_altitude_ft);
    tracer("wp_alt_ft=", wp_altitude_ft);

    wp_latitude_deg = getprop("/autopilot/route-manager/route/wp/latitude-deg");
    setprop("/instrumentation/gps/wp/wp[1]/latitude-deg", wp_latitude_deg);
    tracer("wp_lat_deg=", wp_latitude_deg);

    wp_longitude_deg = getprop("/autopilot/route-manager/route/wp/longitude-deg");
    setprop("/instrumentation/gps/wp/wp[1]/longitude-deg", wp_longitude_deg);
    tracer("wp_lon_deg=", wp_longitude_deg);
};


gps_next_leg = func {
    wp_id = getprop("/autopilot/route-manager/route/wp/id");
    if(wp_id == nil or size(wp_id)==0) {
     tracer("It was last waypoint - nothing to do!");
     return;
    }
   if(complete_turn == 1) {
    setprop("/instrumentation/gps/wp/wp/waypoint-type", getprop("/instrumentation/gps/wp/wp[1]/waypoint-type"));
    setprop("/instrumentation/gps/wp/wp/name", getprop("/instrumentation/gps/wp/wp[1]/name"));
    setprop("/instrumentation/gps/wp/wp/ID", getprop("/instrumentation/gps/wp/wp[1]/ID"));
    setprop("/instrumentation/gps/wp/wp/altitude-ft", getprop("/instrumentation/gps/wp/wp[1]/altitude-ft"));
    setprop("/instrumentation/gps/wp/wp/latitude-deg", getprop("/instrumentation/gps/wp/wp[1]/latitude-deg"));
    setprop("/instrumentation/gps/wp/wp/longitude-deg", getprop("/instrumentation/gps/wp/wp[1]/longitude-deg"));
    complete_turn = 0;
    currTrack_trueCourse = NextWP_trueCourse;
    setprop("/instrumentation/flightdirector/currTrack_trueCourse-deg", currTrack_trueCourse);
    tracer("currTrack_trueCourse=", currTrack_trueCourse," deg");
    if(trk_on == 1) {setprop("autopilot/settings/heading-bug-deg", currTrack_trueCourse - getprop("/environment/magnetic-variation-deg"))};
   }
   else {calc_initial_track_params();};
   
    tracer("new track: ", getprop("/instrumentation/gps/wp/wp/ID"), " -> ", wp_id);
    setprop("/instrumentation/gps/wp/wp[1]/ID", wp_id);

    wp_altitude_ft = getprop("/autopilot/route-manager/route/wp/altitude-ft");
    setprop("/instrumentation/gps/wp/wp[1]/altitude-ft", wp_altitude_ft);

    wp_latitude_deg = getprop("/autopilot/route-manager/route/wp/latitude-deg");
    setprop("/instrumentation/gps/wp/wp[1]/latitude-deg", wp_latitude_deg);

    wp_longitude_deg = getprop("/autopilot/route-manager/route/wp/longitude-deg");
    setprop("/instrumentation/gps/wp/wp[1]/longitude-deg", wp_longitude_deg);

#change current track true heading    
    calc_orthodromic_params();
};




#trueCourse calculating of current waypoint
calc_wp_heading = func {
 wp1_lat = getprop("/instrumentation/gps/indicated-latitude-deg");
 wp1_lon = getprop("/instrumentation/gps/indicated-longitude-deg");
 wp2_lat = getprop("/autopilot/route-manager/route/wp/latitude-deg");
 wp2_lon = getprop("/autopilot/route-manager/route/wp/longitude-deg");

 if(wp1_lat == nil or wp1_lon == nil) {#no route
  tracer("no current position - nothing to calc!");
  return;
 };
 if(wp2_lat == nil or wp2_lon == nil) {       #end of route (last waypoint)
  tracer("[calc_wp_head] no route (waypoint) - nothing to calc!");
  tracer("disable heading AP");
  setprop("/autopilot/locks/heading","");
  return;
 };

 wp1_lat *= DEG2RAD;
 wp1_lon *= DEG2RAD;
 wp2_lat *= DEG2RAD;
 wp2_lon *= DEG2RAD;
 
 sin_lat1 = math.sin(wp1_lat);
 cos_lat1 = math.cos(wp1_lat);
 sin_lat2 = math.sin(wp2_lat);
 cos_lat2 = math.cos(wp2_lat);
 dlon = wp2_lon-wp1_lon;
   
 Aorth = math.atan2(math.sin(dlon)*cos_lat2, cos_lat1*sin_lat2-sin_lat1*cos_lat2*math.cos(dlon));
 while ( Aorth >= TWOPI ) {Aorth -= TWOPI};
 if(Aorth<0) Aorth+= TWOPI;
 currWP_trueCourse = Aorth*RAD2DEG;
 setprop("/instrumentation/flightdirector/currWP_trueCourse-deg", currWP_trueCourse);
 #tracer("currWP_trueCourse=", currWP_trueCourse," deg");
};




#calculation of orthodromic true course to next waypoint
calc_orthodromic_params = func {
 wp1_lat = getprop("/autopilot/route-manager/route/wp/latitude-deg");
 wp1_lon = getprop("/autopilot/route-manager/route/wp/longitude-deg");
 wp2_lat = getprop("/autopilot/route-manager/route/wp[1]/latitude-deg");
 wp2_lon = getprop("/autopilot/route-manager/route/wp[1]/longitude-deg");

 if(wp1_lat == nil or wp1_lon == nil) {#no route
  tracer("[calc_orth_param] no route - nothing to calc!");
  return;
 };
 if(wp2_lat == nil or wp2_lon == nil) {#end of route (last waypoint)
  tracer("end of route (last waypoint) - nothing to calc!");
  return;
 };

 wp1_lat *= DEG2RAD;
 wp1_lon *= DEG2RAD;
 wp2_lat *= DEG2RAD;
 wp2_lon *= DEG2RAD;
 
 sin_lat1 = math.sin(wp1_lat);
 cos_lat1 = math.cos(wp1_lat);
 sin_lat2 = math.sin(wp2_lat);
 cos_lat2 = math.cos(wp2_lat);
 dlon = wp2_lon-wp1_lon;
   
 Aorth = math.atan2(math.sin(dlon)*cos_lat2, cos_lat1*sin_lat2-sin_lat1*cos_lat2*math.cos(dlon));
 while ( Aorth >= TWOPI ) {Aorth -= TWOPI};
 if(Aorth<0) Aorth+= TWOPI;
 NextWP_trueCourse = Aorth*RAD2DEG;
 setprop("/instrumentation/flightdirector/NextWP_trueCourse-deg", NextWP_trueCourse);
 tracer("NextWP_trueCourse=", NextWP_trueCourse," deg");
};



#calculation of track orthodromic true course
calc_initial_track_params = func {
 wp1_lat = getprop("/instrumentation/gps/wp/wp/latitude-deg");
 wp1_lon = getprop("/instrumentation/gps/wp/wp/longitude-deg");
 wp2_lat = getprop("/autopilot/route-manager/route/wp/latitude-deg");
 wp2_lon = getprop("/autopilot/route-manager/route/wp/longitude-deg");

 if(wp1_lat == nil or wp1_lon == nil) {#no route
  tracer("[calc_init_track] no route - nothing to calc!");
  return;
 };
 if(wp2_lat == nil or wp2_lon == nil) {#end of route (last waypoint)
  tracer("end of route (last waypoint) - nothing to calc!");
  return;
 };

 wp1_lat *= DEG2RAD;
 wp1_lon *= DEG2RAD;
 wp2_lat *= DEG2RAD;
 wp2_lon *= DEG2RAD;
 
 sin_lat1 = math.sin(wp1_lat);
 cos_lat1 = math.cos(wp1_lat);
 sin_lat2 = math.sin(wp2_lat);
 cos_lat2 = math.cos(wp2_lat);
 dlon = wp2_lon-wp1_lon;
   
 Aorth = math.atan2(math.sin(dlon)*cos_lat2, cos_lat1*sin_lat2-sin_lat1*cos_lat2*math.cos(dlon));
 while ( Aorth >= TWOPI ) {Aorth -= TWOPI};
 if(Aorth<0) Aorth+= TWOPI;
 currTrack_trueCourse = Aorth*RAD2DEG;
 setprop("/instrumentation/flightdirector/currTrack_trueCourse-deg", currTrack_trueCourse);
 tracer("currTrack_trueCourse=", currTrack_trueCourse," deg");
 if(trk_on == 1) {setprop("autopilot/settings/heading-bug-deg", currTrack_trueCourse - getprop("/environment/magnetic-variation-deg"))};
};


#############################################################################
# handle KC 290 Mode Controller inputs, and compute correct mode/settings
#############################################################################


setlistener("/autopilot/route-manager/current-wp", func(n) {  
  if (getprop("/instrumentation/flightdirector/past-td") == 0) {
    tracer("check if past T/D");
    for(var p = 0; p < getprop("/autopilot/route-manager/current-wp"); p=p+1) {
      var id = getprop("/autopilot/route-manager/route/wp["~p~"]/id");
      if (id == "(T/D)") {
        setprop("/instrumentation/flightdirector/past-td",1);
        tracer("Gone past T/D");
      }
    }
  }
  ## 
  var fp = flightplan();
  var curWP = fp.getWP();
  if (curWP != nil) {
    var altCstr = curWP.alt_cstr;
    var spdCstr = curWP.speed_cstr;
    tracer("set current WP: "~curWP.wp_name);
    tracer("      alt_cstr: "~altCstr);
    tracer("      spd_cstr: "~spdCstr);
    ## work around flightplan bug..
      if (altCstr < 0) {
        var curWpIdx = (getprop("/autopilot/route-manager/current-wp"));
        var wpName = getprop("autopilot/route-manager/route/wp["~curWpIdx~"]/id");
        var wpIdx = airbusFMS.findWPName(wpName);
        var wp = airbusFMS.getWPIdx(wpIdx);
        altCstr = wp.alt_cstr;
        spdCstr = wp.spd_cstr;
      }
    if (getprop("/instrumentation/flightdirector/autopilot-on") == 1) {
      if (getprop("instrumentation/afs/vertical-alt-mode") == -1 and altCstr != 0) {
        setprop("/autopilot/settings/target-altitude-ft", altCstr);
        setprop("/instrumentation/afs/target-altitude-ft", altCstr);
      }
      if (getprop("instrumentation/afs/speed-managed-mode") == -1) {
        var newSpeed = spdCstr;
        if (newSpeed > 0 and newSpeed < 1) {
          interpolate("autopilot/settings/target-speed-mach", newSpeed, 10);
        }
        if (newSpeed > 30) {
          interpolate("autopilot/settings/target-speed-kt", newSpeed, 10);
        }
      }
    }
  }
  ## check autopilot controls match AP modes.
  var vnav = getprop("instrumentation/flightdirector/vnav");
  if (vnav != 0 and vnav != nil) {
    setprop("/instrumentation/flightdirector/vnav", vnav);
  }
});


setlistener("/controls/autoflight/autopilot[0]/engage", func(n) {
   mode = n.getValue();
   var otherAP = getprop("/controls/autoflight/autopilot[1]/engage");
   if (mode == 1 or otherAP == 1) {
     ap_on = 1;
   } else {
     ap_on = 0;
   }
   setprop("/instrumentation/flightdirector/autopilot-on", ap_on);
});

setlistener("/controls/autoflight/autopilot[1]/engage", func(n) {
   mode = n.getValue();
   var otherAP = getprop("/controls/autoflight/autopilot[0]/engage");
   if (mode == 1 or otherAP == 1) {
     ap_on = 1;
   } else {
     ap_on = 0;
   }
   setprop("/instrumentation/flightdirector/autopilot-on", ap_on);
});



setlistener("/instrumentation/flightdirector/autopilot-on", func {
    ap_on = getprop("/instrumentation/flightdirector/autopilot-on");
    if (ap_on == 1) {
      tracer("AP engaged");
      ### call to evaluate all current modes
      evaluateSPD();
      evaluateHDG();
      evaluateALT();
      evaluateVS();
    } else {
      tracer("AP dis-engaged");
      var rwyCat = getprop("instrumentation/afs/rwy-cat");
      var fltMode = getprop("instrumentation/ecam/flight-mode");
      if (rwyCat != "CAT I" and fltMode > 8) {
        setprop("instrumentation/afs/rwy-cat", "CAT I");
        setprop("instrumentation/flightdirector/mode-reversion", 1);
      }
    };
 if (ap_on == 0) {
   setprop("autopilot/locks/heading","");
   setprop("autopilot/locks/altitude","");
   setprop("autopilot/locks/speed","");
   #setprop("/instrumentation/flightdirector/lnav",0);
   #setprop("/instrumentation/flightdirector/vnav",0);
   #setprop("/instrumentation/flightdirector/spd",0);
 }
});

#
# enable FlightDirector bars
setlistener("/instrumentation/flightdirector/fd-on", func(n) {
  fd_on = n.getValue();
  if(fd_on == 1) {
    setprop("autopilot/locks/passive-mode",1);
  } else {
    setprop("autopilot/locks/passive-mode",0);
  }
});

#
# A/THR change
setlistener("/instrumentation/flightdirector/at-on", func(n) {
  at_on = n.getValue();
  tracer("AT: "~at_on);
  spdMode = getprop("/instrumentation/flightdirector/spd");
  if(at_on == 1) {
      if (spdMode == SPD_TOGA) {   #TOGA
        
      }
      if (spdMode == SPD_FLEX) {   #FLEX
      }
      if (spdMode == SPD_THRCLB) {   #THR CLB 
      }
      if (spdMode == SPD_SPEED) {   #SPEED
        setprop("autopilot/locks/speed","speed-with-throttle");
      }
      if (spdMode == SPD_MACH) {   #MACH
      }
      if (spdMode == SPD_CRZ) {   #CRZ
      }
      if (spdMode == SPD_THRDES) {   #THR DES
      }
      if (spdMode == SPD_THRIDL) {  #THR IDL
      }
    } else {
      setprop("autopilot/locks/speed","");
      for(var e=0; e < 4; e=e+1) {
        var curTh = getprop("/controls/engines/engine["~e~"]/throttle");
        setprop("/controls/engines/engine["~e~"]/thrust-lever", curTh);
      }
    }
});


#
#  set LNAV mode
setlistener("/instrumentation/flightdirector/lnav", func(n) {
  lnav = n.getValue();
  tracer("LNAV: "~lnav~" mode: "~lnavStr[lnav]);
  if(ap_on==1) {
    if(lnav == 0 or lnav ==nil) {
      setprop("autopilot/locks/heading","");
      setprop("/controls/autoflight/lateral-mode",0);
      setprop("instrumentation/afs/lateral-managed-mode", 0);
    }
    if(lnav == LNAV_HDG) {   #HDG (s)
      tracer("set lnav == 1");
      ##setprop("/autopilot/internal/true-heading-error-deg",getprop("/autopilot/settings/heading-bug-deg"));
      setprop("/autopilot/locks/heading","dg-heading-hold");
      setprop("/controls/autoflight/lateral-mode",1);
      setprop("instrumentation/afs/lateral-managed-mode", 0);
    }
    if (lnav == LNAV_TRACK) {  #TRACK (s)
    }
    if(lnav == LNAV_LOC) {   #LOC
      setprop("/instrumentation/afs/limit-min-vs-fps",-13.0);
      setprop("/instrumentation/afs/limit-max-vs-fps",13.0);
      setprop("/autopilot/locks/heading","nav1-hold");
      setprop("/controls/autoflight/lateral-mode",2);
      setprop("instrumentation/afs/lateral-managed-mode", -1);
    }
    if(lnav == LNAV_FMS) {  #NAV (fms)
      tracer("set lnav == 4");
      ##setprop("/autopilot/internal/true-heading-error-deg",getprop("/instrumentation/gps/wp/wp[1]/bearing-true-deg"));
      setprop("/autopilot/locks/heading","true-heading-hold");
      setprop("/controls/autoflight/lateral-mode",1);
      setprop("instrumentation/afs/lateral-managed-mode", -1);
    }
    if (lnav == LNAV_RWY) {  #RWY
      tracer("enable runway track");
      setprop("/autopilot/locks/heading", "runway-heading");
      setprop("instrumentation/afs/lateral-managed-mode", -1);
    }
  }
});


#
# set VNAV mode
setlistener("/instrumentation/flightdirector/vnav", func(n) {
  vnav = n.getValue();
  tracer("VNAV: "~vnav~" mode: "~vnavStr[vnav]);
  if(ap_on==1) {
    if(vnav == 0 or vnav == nil) {
      setprop("/autopilot/locks/altitude","");
      setprop("/autopilot/settings/target-pitch-deg",0);   ##TODO: double check
      #setprop("/controls/autoflight/vertical-mode",0);
    }
    if(vnav == VNAV_ALTs) {   # ALT (s)
      if (getprop("/position/altitude-ft") > 25000) {
        setprop("/instrumentation/afs/limit-min-vs-fps",-12.0);
        setprop("/instrumentation/afs/limit-max-vs-fps",14.0);
      }
      setprop("/autopilot/locks/altitude","altitude-hold");
      setprop("/instrumentation/flightdirector/alt-acquire-mode",0);
      #setprop("/controls/autoflight/vertical-mode",1);
    }
    if(vnav == VNAV_VS) {   # V/S (s)
      setprop("/autopilot/locks/altitude","vertical-speed-hold");
      #setprop("/controls/autoflight/vertical-mode",1);
      setprop("/instrumentation/flightdirector/alt-acquire-mode",1);
    }
    if(vnav == VNAV_OPCLB) {   # OP CLB  (s)
      #setprop("/autopilot/locks/speed","climb-hold");
      #setprop("/controls/autoflight/vertical-mode",2);
      setprop("/instrumentation/afs/limit-min-vs-fps", -16.67);
      setprop("/instrumentation/afs/limit-max-vs-fps", 33.33);
      setprop("/autopilot/locks/altitude","vertical-speed-hold");
      setprop("/instrumentation/flightdirector/alt-acquire-mode",1);
    }
    if(vnav == VNAV_OPDES) {   # OP DES (s)
      var desMach = getprop("instrumentation/afs/des_mach");
      var desKIAS  = getprop("instrumentation/afs/des_speed");
      var atmos = Atmos.new();
      var changeoverAlt = atmos.calculateCrossover(desKIAS, desMach);
      setprop("instrumentation/afs/changeover-alt", changeoverAlt);
      #setprop("/autopilot/locks/speed","climb-hold");
      setprop("/instrumentation/afs/limit-min-vs-fps", -16.67);
      setprop("/instrumentation/afs/limit-max-vs-fps", 33.33);
      setprop("/autopilot/locks/altitude","");
      #if (getprop("/instrumentation/afs/changeover-mode") == 1) {
      #  setprop("/autopilot/locks/speed","mach-with-pitch-trim");
      #} else {
      #  setprop("/autopilot/locks/speed","speed-with-pitch-trim");
      #}
      setprop("instrumentation/flightdirector/spd", SPD_THRIDL);
      setprop("/instrumentation/flightdirector/alt-acquire-mode",1);
    }
    if (vnav == VNAV_CLB) {  # CLB  (m)
      curAlt = getprop("/position/altitude-ft");
      redAlt = getprop("/instrumentation/afs/thrust-reduce-alt");
      accAlt = getprop("/instrumentation/afs/thrust-accel-alt");
      var clbMach = getprop("instrumentation/afs/clb_mach");
      var clbKIAS  = getprop("instrumentation/afs/clb_speed");
      var atmos = Atmos.new();
      var changeoverAlt = atmos.calculateCrossover(clbKIAS, clbMach);
      setprop("instrumentation/afs/changeover-alt", changeoverAlt);
      var curVS = getprop("/autopilot/settings/vertical-speed-fpm");
      tracer("VNAV_CLB: cur V/S: "~curVS);
      if (curAlt < accAlt and curAlt > redAlt and getprop("/fdm/jsbsim/fcs/flap-cmd-norm") == 0) {
          tracer("adjust V/S");
          var vSpeed = 2100;  
          # determine vertical-speed during inital climb based on grossWeight.
          setprop("/autopilot/settings/vertical-speed-fpm",vSpeed);
          settimer(climb_flap_adjust, 5);  #was 20 2009-06-30
      }
      if (curAlt > accAlt and curAlt < 15000 and getprop("/instrumentation/flightdirector/climb-arm") == 1) {
          tracer("Acquire CLIMB speed");
          setprop("/autopilot/settings/vertical-speed-fpm",1800);
      }
      if (curAlt > 15000 and curAlt < 24000) {
        tracer("Phase 2 CLIMB");
        setprop("/autopilot/settings/vertical-speed-fpm",1300);
      }
      if (curAlt > redAlt) {
        setprop("/autopilot/locks/altitude","vertical-speed-hold");
      }
      setprop("/instrumentation/flightdirector/alt-acquire-mode",1);
      atn.doSendFuelInfo();
    }
    if(vnav == VNAV_ALTCRZ) {   # ALT (m)
      curAlt = getprop("/position/altitude-ft");
      var nextWpAlt = getprop("/instrumentation/gps/wp/wp[1]/altitude-ft");
      var alreadyCruise = getprop("instrumentation/afs/acquire_crz");
      if (alreadyCruise != 1 and curAlt < nextWpAlt) {
        setprop("/autopilot/settings/target-altitude-ft", nextWpAlt);
        
      }
      setprop("/instrumentation/afs/limit-min-vs-fps",-12.0);
      setprop("/instrumentation/afs/limit-max-vs-fps",15.0);
      setprop("/autopilot/locks/altitude","altitude-hold");
      setprop("/instrumentation/flightdirector/alt-acquire-mode",0);
      atn.doSendFuelInfo();
      #setprop("/controls/autoflight/vertical-mode",1);
    }
    if (vnav == VNAV_DES) {  # DES
      curAlt = getprop("/position/altitude-ft");
      ##descentAlt = getprop("/autopilot/route-manager/route/wp[0]/altitude-ft");
      var curWpIdx = (getprop("/autopilot/route-manager/current-wp"));
      descentAlt = getprop("/autopilot/route-manager/route/wp["~curWpIdx~"]/altitude-ft");
      ## work around flightplan bug..
      if (descentAlt < 0) {
        var wpName = getprop("autopilot/route-manager/route/wp["~curWpIdx~"]/id");
        var wpIdx = airbusFMS.findWPName(wpName);
        var wp = airbusFMS.getWPIdx(wpIdx);
        descentAlt = wp.alt_cstr;
      }
      ##var descentAlt = getprop("/instrumentation/gps/wp/wp[1]/altitude-ft");
      var targetAlt = getprop("instrumentation/afs/target-altitude-ft");
      tracer("disable ALT ACQ mode");
      setprop("/instrumentation/flightdirector/alt-acquire-mode",0);
      if (descentAlt < targetAlt) {
        tracer("[VNAV_DES] set target = descent");
        setprop("instrumentation/afs/target-altitude-ft", descentAlt);
        setprop("autopilot/settings/target-altitude-ft", descentAlt);
        targetAlt = descentAlt;
      } else {
        setprop("autopilot/settings/target-altitude-ft", targetAlt);
        descentAlt = targetAlt;
        tracer("[VNAV_DES] set descent = target");
      }
      atn.doSendFuelInfo();
      var desMach = getprop("instrumentation/afs/des_mach");
      var desKIAS  = getprop("instrumentation/afs/des_speed");
      var atmos = Atmos.new();
      var changeoverAlt = atmos.calculateCrossover(desKIAS, desMach);
      setprop("instrumentation/afs/changeover-alt", changeoverAlt);
      diffAlt = descentAlt-curAlt;
      tracer("set to descent mode. diffAlt: "~diffAlt);
      if (diffAlt < 0) {
        var etaTime = getprop("/autopilot/route-manager/wp[0]/eta");
        var etaDist = getprop("/autopilot/route-manager/wp[0]/dist");
        if (etaTime == nil) {
          etaTime = getprop("/instrumentation/gps/wp/wp[1]/TTW");
          etaDist = getprop("/instrumentation/gps/wp/wp[1]/distance-nm");
        }
        
        etaParts = split(":",etaTime);
        var etaMin = int(etaParts[0]);
        var etaSec = int(etaParts[1]);
        if (etaMin == 0 and etaDist > 50) {
          etaMin = etaSec;
          etaSec = 0;
        }
        tracer("[VNAV] eta: "~etaTime~", ETA min: "~etaMin~", ETA sec: "~etaSec~", difAlt: "~diffAlt);
        var gap = 5;
        if (descentAlt < 10000) {
          gap = 25;
        }
        eta = (etaSec+(etaMin*60))-gap;   #reach point <gap> seconds before.
        tracer("[updateMode] eta: "~eta~", difAlt: "~diffAlt);
        if (eta <= 0) {
          if (getprop("/autopilot/locks/altitude") != "altitude-hold") {
            tracer("[VNAV] eta: "~etaTime~", ETA min: "~etaMin~", ETA sec: "~etaSec~", difAlt: "~diffAlt);
            tracer("reached alt, holding");
            setprop("autopilot/settings/target-altitude-ft", descentAlt);
            setprop("/autopilot/locks/altitude","altitude-hold");
            ##setprop("/instrumentation/flightdirector/alt-acquire-mode",1);
          }
        } else {
          tracer("ETA seconds: "~eta);
          fmsVS = (diffAlt/eta)*60;
          if (fmsVS < -3000) {
            fmsVS = -3000;
          } 
          if (fmsVS > 3000) {
            fmsVS = 3000;
          }
          tracer("Set DESCENT VNAV #2: "~fmsVS);
          setprop("/autopilot/settings/vertical-speed-fpm",fmsVS);
          setprop("/autopilot/locks/altitude","vertical-speed-hold");
          if (getprop("/instrumentation/flightdirector/spd") != SPD_THRDES) {
            setprop("/instrumentation/flightdirector/spd", SPD_THRDES);
          }
        }
      } else {
        if (getprop("/autopilot/locks/altitude") != "altitude-hold") {
          setprop("/instrumentation/afs/limit-min-vs-fps",-9.0);
          setprop("/instrumentation/afs/limit-max-vs-fps",9.0);
          tracer("descend #2: set altitude-hold");
          setprop("/autopilot/settings/target-alt-hold",descentAlt);
          setprop("/autopilot/locks/altitude","altitude-hold");
          ##setprop("/instrumentation/flightdirector/alt-acquire-mode",1);
        }
      }
    }
    if(vnav == VNAV_GS) {   # G/S
      if(getprop("/instrumentation/nav/has-gs") != 0) {
        setprop("/instrumentation/afs/limit-min-vs-fps",-13.0);
        setprop("/instrumentation/afs/limit-max-vs-fps",13.0);
        tracer("has GS, enabling gs-hold");
        setprop("/autopilot/locks/altitude","gs1-hold");
        setprop("/instrumentation/flightdirector/alt-acquire-mode",0);
        #setprop("/controls/autoflight/vertical-mode",2);
      }
    }
  }
  if (vnav == VNAV_SRS) {   # SRS
    flapPos = getprop("/fdm/jsbsim/fcs/flap-cmd-norm");
    flapConfig = 0;
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
    tracer("VNAV: SRS target: "~srsFlapTarget[flapConfig]~" with flap pos: "~flapPos);
    setprop("/autopilot/settings/target-speed-kt",srsFlapTarget[flapConfig]-10);
    setprop("/autopilot/locks/speed","speed-reference-system");
    setprop("/instrumentation/flightdirector/alt-acquire-mode",1);
  }
  if (vnav == VNAV_LEVEL) {  # pitch hold
    setprop("/autopilot/settings/target-pitch-deg",0);
    setprop("/autopilot/locks/altitude","pitch-hold");
    setprop("/instrumentation/flightdirector/alt-acquire-mode",0);
  }
});

#
# set SPEED mode
setlistener("/instrumentation/flightdirector/spd", func(n) {
  spdMode = n.getValue();
  tracer("SPD: "~spdMode~" mode: "~spdStr[spdMode]);
  atOn    = getprop("/instrumentation/flightdirector/at-on");
  if (spdMode == 0) {
    setprop("/instrumentation/flightdirector/at-on",0);
  }
  if (atOn == 1) {
      if (spdMode == SPD_TOGA) {   #TOGA
        tracer("SPD mode: TOGA");
      }
      if (spdMode == SPD_FLEX) {   #FLEX
        tracer("SPD mode: FLEX");
      }
      if (spdMode == SPD_THRCLB) {   #THR CLB 
        tracer("SPD mode: THR CLB");
        curAlt = getprop("/position/altitude-ft");
        redAlt = getprop("/instrumentation/afs/thrust-reduce-alt");
        accAlt = getprop("/instrumentation/afs/thrust-accel-alt");
        if (curAlt > accAlt and curAlt < 15000 and getprop("/instrumentation/flightdirector/climb-arm") != 1) {
          vnav = getprop("/instrumentation/flightdirector/vnav");
          if (vnav != VNAV_ALTs and vnav != VNAV_VS) {
            setprop("/instrumentation/flightdirector/vnav",VNAV_CLB);
            setprop("/instrumentation/flightdirector/vnav-arm", VNAV_OFF);
            setprop("/autopilot/settings/vertical-speed-fpm",2300);
            setprop("/autopilot/locks/altitude","vertical-speed-hold");
          }
          tracer("Acquire CLB CL speed");
          settimer(climb_thrust, 30);
          setprop("/instrumentation/flightdirector/climb-arm",1);
        }
        if (curAlt < accAlt and getprop("/autopilot/locks/altitude") != "") {
          setprop("/autopilot/locks/altitude","");
        }
      }
      if (spdMode == SPD_SPEED) {   #SPEED (s)
        setprop("/autopilot/locks/speed","speed-with-throttle");
      }
      if (spdMode == SPD_MACH) {   #MACH
        setprop("/autopilot/locks/speed","mach-with-throttle");
      }
      if (spdMode == SPD_CRZ) {   #CRZ
            #setprop("/autopilot/locks/speed","speed-with-throttle");
            setprop("/autopilot/locks/speed","mach-with-throttle");
            ##var newSpeed = 310;
            ##var newSpeed = getprop("/instrumentation/afs/crz_speed");
            var newSpeed = getprop("/instrumentation/afs/crz_mach");
            if (getprop("/autopilot/settings/target-speed-mach") < newSpeed) {
              setprop("/autopilot/settings/target-speed-kt",310);
              interpolate("/autopilot/settings/target-speed-mach", newSpeed, 10);
            }  
      }
      if (spdMode == SPD_THRDES) {   #THR DES
        var curAlt = getprop("/position/altitude-ft");
        var vnav   = getprop("instrumentation/flightdirector/vnav");
        if (getprop("/instrumentation/afs/changeover-mode") == 1) {
          if (vnav == VNAV_DES) {
            setprop("/autopilot/locks/speed","mach-with-throttle");
          }
          if (vnav == VNAV_OPDES) {
            setprop("autopilot/locks/speed","mach-with-pitch-trim");
          }
        } else {
          if (vnav == VNAV_DES) {
            setprop("/autopilot/locks/speed","speed-with-throttle");
          }
          if (vnav == VNAV_OPDES) {
            setprop("autopilot/locks/speed","speed-with-pitch-trim");
          }
        }
        var desMach = getprop("/instrumentation/afs/des_mach");
        var chngAlt = getprop("/instrumentation/afs/changeover-alt");
        if (curAlt > chngAlt and getprop("/autopilot/settings/target-speed-mach") > desMach) {
          interpolate("/autopilot/settings/target-speed-mach", desMach, 20);
        }
        if (curAlt > 15000 and curAlt <= chngAlt and getprop("/autopilot/settings/target-speed-kt") > 270) {
          interpolate("/autopilot/settings/target-speed-kt",270,90);    #was 270 in 90 SAH 2010-12-04
        }
        if (curAlt <12000 and getprop("/autopilot/settings/target-speed-kt") > 250 and spdDesArm2 == 0) {
          spdDesArm2 = 1;
          interpolate("/autopilot/settings/target-speed-kt",250,60);
        }
        if (curAlt <2000 and getprop("/autopilot/settings/target-speed-kt") > 210) {
          interpolate("/autopilot/settings/target-speed-kt",180,60);
        }
      }
      if (spdMode == SPD_THRIDL) {
        var curAlt = getprop("/position/altitude-ft");
        var chngAlt = getprop("/instrumentation/afs/changeover-alt");
        interpolate("controls/engines/engine[0]/throttle",0.1,6);
        interpolate("controls/engines/engine[3]/throttle",0.1,6);
        interpolate("controls/engines/engine[1]/throttle",0.1,6);
        interpolate("controls/engines/engine[2]/throttle",0.1,6);
        if (curAlt > chngAlt) {
          setprop("autopilot/locks/speed","mach-with-pitch-trim");
        } else {
          setprop("autopilot/locks/speed","speed-with-pitch-trim");
        }
      }
      if (spdMode == 8) { #THR CLB
        tracer("ignoring spdMode: 8");
      }
  }
});


#
# update vertical mode for animation from autopilot 
setlistener("/autopilot/locks/altitude", func(n) {
    mode = n.getValue();
    vnav = getprop("/instrumentation/flightdirector/vnav");
    tracer("afs:altitude");
    if(vnav == 0 or vnav == nil or mode == "" or mode == nil) {
      setprop("/controls/autoflight/vertical-mode",0);
    }
    if(mode == "altitude-hold") {
      #setprop("/controls/autoflight/vertical-mode",1);
    }
    if(mode == "vertical-speed-hold") {
      #setprop("/controls/autoflight/vertical-mode",1);
    }
    if(mode == "climb-hold") {
      #setprop("/controls/autoflight/vertical-mode",2);
    }
    if(mode == "gs1-hold") {
      #setprop("/controls/autoflight/vertical-mode",2);
    }
    var vmode = getprop("/controls/autoflight/vertical-mode");
    tracer("afs:alt vmode: "~vmode~", vnav: "~vnav~", altitude: "~mode);
});


#
# update lateral mode for animation from autopilot
setlistener("/autopilot/locks/heading", func(n) {
    mode = n.getValue();
    lnav = getprop("/instrumentation/flightdirector/lnav");
    tracer("afs:heading");
    if(lnav == 0 or lnav == nil or mode == "" or mode == nil) {
      setprop("/controls/autoflight/lateral-mode",0);
    }
    if(mode == "dg-heading-hold") {
      setprop("/controls/autoflight/lateral-mode",1);
    }
    if(mode == "nav1-hold") {
      setprop("/controls/autoflight/lateral-mode",2);
    }
    if(mode == "true-heading-hold") {
      setprop("/controls/autoflight/lateral-mode",1);
    }
    var lmode = getprop("/controls/autoflight/lateral-mode");
    tracer("afs:hdg lmode: "~lmode~", lnav: "~lnav~", heading: "~mode);
});

setlistener("/autopilot/locks/speed", func(n) {
    mode = n.getValue();
    var spd = getprop("/instrumentation/flightdirector/spd");
    if (spd == nil) {
      spd = "nil"
    }
    tracer("afs:speed");
    #var smode = getprop("/controls/autoflight/speed-mode");
    #tracer("afs:spd, spd: "~spd~", speed: "~mode);
});

#
#  A/THR
setlistener("/instrumentation/flightdirector/athr", func(n) {
  mode = n.getValue();
  var at = getprop("/instrumentation/flightdirector/at");
  if (at == 1) {
    if (mode == 0) {
      tracer("Change A/THR to Idle");
      if (getprop("/instrumentation/flightdirector/spd") != SPD_THRIDL) {
        ##setprop("/instrumentation/flightdirector/spd", SPD_THRIDL);
      }
    }
    if (mode == 1) {
      tracer("Change A/THR to CL");
    }
    if (mode == 2) {
      tracer("Change A/THR to FLX");
    }
    if (mode == 3) {
      tracer("Change A/THR to TOGA");
    }
  }
});


setlistener("/instrumentation/flightdirector/track-mode-on", func {
  trk_on = getprop("/instrumentation/flightdirector/track-mode-on");
  if(ap_on == 1 and lnav == 5) {   #
   trk_lck_mode = 0; 
   if(trk_on == 1) {
    setprop("autopilot/locks/heading","track-hold");
    setprop("autopilot/settings/heading-bug-deg", currTrack_trueCourse - getprop("/environment/magnetic-variation-deg"));
   } else {
    setprop("autopilot/locks/heading","true-heading-hold");
   };
 }
});

setlistener("/instrumentation/nav[0]/in-range", func(n) {
   var range = n.getValue();
   var apMode = getprop("/instrumentation/flightdirector/autopilot-on");
   if (apMode == 1) {
     if (range != lastNavStatus) {
       tracer("[NAV0] NAV0 range status: "~range);
       lastNavStatus = range;
       var lnavMode = getprop("/instrumentation/flightdirector/lnav");
       var lnavArm = getprop("/instrumentation/flightdirector/lnav-arm");
       var crzAcq = getprop("instrumentation/afs/acquire_crz");
       var fltMode = getprop("/instrumentation/ecam/flight-mode");
       var locMode = getprop("instrumentation/nav[0]/nav-loc");
       var alt = getprop("position/altitude-ft");
       tracer("[NAV0] locMode: "~locMode~", crzAcq: "~crzAcq~", alt: "~alt);
       if (range == 1) {
         if (locMode == 1 and crzAcq == 1 and alt < 15000) {
           var ilsCat = getILSCategory(getprop("instrumentation/afs/TO"), getprop("instrumentation/afs/arv-rwy"));
           tracer("ils cat: "~ilsCat);
           setprop("instrumentation/afs/rwy-cat", ilsCat);
           
           if (lnavMode != LNAV_LOC and alt < 8000 ) {
             setprop("/instrumentation/flightdirector/lnav-arm", LNAV_LOC);
           } else {
             if (lnavArm == LNAV_LOC) {
               setprop("/instrumentation/flightdirector/lnav-arm", VNAV_OFF);
               setprop("/instrumentation/flightdirector/lnav", LNAV_LOC);
             }
           }
         }
       } else {
         setprop("instrumentation/afs/rwy-cat", "");
         if (lnavMode == LNAV_LOC) {
           ## revert lateral mode if we loose LOC while active.
           if (fltMode > 8) {
             setprop("instrumentation/flightdirector/vnav", LNAV_FMS);
             setprop("instrumentation/flightdirector/mode-reversion", 1);
           }
           setprop("instrumentation/annunciator/master-caution", 1);
         }
         if (lnavArm == LNAV_LOC) {
           setprop("/instrumentation/flightdirector/lnav-arm", LNAV_OFF);
         }
       }
     }
   }
});

setlistener("/instrumentation/nav[0]/gs-in-range", func(n) {
   var range = n.getValue();
   var vnavMode = getprop("/instrumentation/flightdirector/vnav");
   var vnavArm  = getprop("/instrumentation/flightdirector/vnav-arm");
   var apMode = getprop("/instrumentation/flightdirector/autopilot-on");
   if (apMode == 1) {
     if (range != lastGSStatus) {
       tracer("[NAV1] GS range status: "~range);
       lastGSStatus = range;
     
       if (range == 1) {
         var alt = getprop("position/altitude-ft");
         if (vnavMode != VNAV_GS and alt < 8000) {
           setprop("/instrumentation/flightdirector/vnav-arm", VNAV_GS);
         } else {
            if (vnavArm == VNAV_GS) {
              setprop("/instrumentation/flightdirector/vnav", VNAV_GS);
              setprop("/instrumentation/flightdirector/vnav-arm", VNAV_OFF);
            }
         }
       } else {
         if (vnavMode == VNAV_GS) {
           ### we should disable AP if we loose GS while active...
         }
         if (vnavArm == VNAV_GS) {
           setprop("/instrumentation/flightdirector/vnav-arm", VNAV_OFF);
         }
       }
     }
   }
});


## get ILS frequency from airportinfo.
var getILS = func(apt, rwy) {
   if (trace > 1) {
     debug.dump(apt);
   }
   var mhz = nil;
   ##var runways = apt["runways"];
   var runways = apt.runways();
   var ks = keys(runways);
   for(var r=0; r != size(runways); r=r+1) {
     var run = runways[ks[r]];
     if (run.id == rwy and contains(run, "ils_frequency_mhz")) {
       mhz = sprintf("%3.1f",run.ils_frequency_mhz);
       return mhz;
     }
   }
   return mhz;
}

## get ILS category from nav db
# 
var getILSCategory = func(aptId, arvRunway) {
  var retCat = "CAT-I";
  if (aptId != nil) {
    var apt = airportinfo(aptId);
    ###var arvRunway = getprop("instrumentation/afs/arv-rwy");
    ###var navList = navinfo(apt.lat(), apt.lon(), "ils");
    var navList = findNavaidsWithinRange(apt.lat, apt.lon, 1);
    var navListSize = size(navList);
    print("size navList: "~navListSize);
    foreach(var ils; navList) {
      debug.dump(ils);
      if (ils.runway == arvRunway) {
        var nmeStr = ils.name;
        var parts = split(" ", nmeStr);
        print("rwy: "~nmeStr~", parts[0]: "~parts[0]~", parts[1]: "~parts[1]~", parts[2]: "~parts[2]~", parts[3]: "~parts[3]);
        retCat = string.uc(substr(parts[3],4));
      }
    }
    var dh = 200;
    if (retCat == "CAT-I") {
      dh = 200;
    }
    if (retCat == "CAT-II") {
      dh = 100;
    }
    if (retCat == "CAT-III") {
      dh = 50;
    }
    dh = dh + apt.elevation;
    setprop("/instruments/mk-viii/inputs/arinc429/decision-height", dh);
    
  }
  return retCat;
}


#
# if we add/remove waypoints we might need to update stuff?
setlistener("/autopilot/route-manager/route/num", func(n) {
    var wpLen = n.getValue();
    if (wpLen == nil) {
      wpLen = 0;
    }
    ceilingFt = 0.0;
    descentFt  = 0.0;
    var spdMode = getprop("/instrumentation/flightdirector/spd");
    var vnav    = getprop("/instrumentation/flightdirector/vnav");
    if (spdMode == nil) {
      spdMode = 0;
    }
    if (vnav == nil) {
      vnav = 0;
    }
    tracer("change in route manager: "~wpLen);
    tracer(" spdMode: "~spdMode);
    if (spdMode != SPD_CRZ and vnav != VNAV_DES) {
      for(w=0; w < wpLen; w=w+1) {
        asl = getprop("/autopilot/route-manager/route/wp["~w~"]/altitude-ft");
        if (asl > ceilingFt and asl > 0) {
          ceilingFt = asl;
        }
        if (ceilingFt > 20000 and asl < ceilingFt and asl > descentFt and asl > 0) {
          descentFt = asl;
        }
      }
      if (ceilingFt > 18000) {
        setprop("/instrumentation/afs/thrust-cruise-alt", ceilingFt);
        tracer("set thrust-cruise-alt: "~ceilingFt);
        var crzFL = int(ceilingFt/100);
        setprop("/instrumentation/afs/CRZ_FL",crzFL);
        tracer("set CRZ_FL: "~crzFL);
        var atmos = Atmos.new();
        var Pcr = atmos.convertAltitudePressure("feet",ceilingFt,"psi");
        setprop("/controls/pressurisation/outside-cruise-ft", ceilingFt);
        setprop("/controls/pressurisation/outside-pressure-cruise-psi", Pcr);
        setprop("/controls/pressurisation/cabin-cruise-ft", 6500);
        var Pcc = atmos.convertAltitudePressure("feet",6800,"psi");
        setprop("/controls/pressurisation/cabin-pressure-cruise-psi", Pcc);
      }
      
      setprop("/instrumentation/afs/thrust-descent-alt", descentFt);
      tracer("afs: cruz alt: "~ceilingFt~", descent alt: "~descentFt);
    }
    var managedAlt = 0;
    if (getprop("/instrumentation/afs/vertical-alt-mode") == -1 or getprop("/instrumentation/afs/vertical-vs-mode") == -1) {
      managedAlt = 1;
    }
    #  if we are in managed mode, we re-evaluate the FG autopilot settings by calling the VNAV and SPD calculations again..
    if (managedAlt) {
      setprop("/instrumentation/flightdirector/vnav",getprop("/instrumentation/flightdirector/vnav"));
    }
    if (getprop("/instrumentation/afs/speed-mode") == -1) {
      setprop("/instrumentation/flightdirector/spd",getprop("/instrumentation/flightdirector/spd"));
    }
},1);

# 30 seconds after accel alt, we increase thrust
#
climb_thrust = func() {
    var managedAlt = 0;
    if (getprop("/instrumentation/afs/vertical-alt-mode") == -1 or getprop("/instrumentation/afs/vertical-vs-mode") == -1) {
      managedAlt = 1;
    }
    if (managedAlt == 1) {
      tracer("afs: increase CL speed");
      var targetVS = 2000;
      # if grossWgt > 500000kg then set vs=1800;
      if (getprop("/instrumentation/afs/thrust-cruise-alt") > 28000) {
      ###if (getprop("/instrumentation/mcdu/CRZ_FL") > 28000) {
        targetVS = 2200;
      }
      if (getprop("/fdm/jsbsim/inertia/weight-kg") > 480000) {
        targetVS = 2000;
      }
      if (getprop("/fdm/jsbsim/inertia/weight-kg") > 500000) {
        targetVS = 1800;
      }
    
      interpolate("/autopilot/settings/vertical-speed-fpm",targetVS,30);
      interpolate("/autopilot/settings/target-speed-kt",230,20);
      setprop("/autopilot/locks/speed","speed-with-throttle");
    }
};


#
#
handle_inputs = func {
  var crzAlt = getprop("/instrumentation/afs/thrust-cruise-alt");
  var fltMode    = getprop("/instrumentation/ecam/flight-mode");
  ###var crzAlt  = getprop("/instrumentation/mcdu/CRZ_FL");
  var curAlt = getprop("/position/altitude-ft");
  var spdMode = getprop("/instrumentation/flightdirector/spd");
  var vnav = getprop("/instrumentation/flightdirector/vnav");
  if(ap_on==1) {
    
    maxroll = getprop("/orientation/roll-deg");
    if(maxroll > 45 or maxroll < -45) {
      ap_on = 0;
      setprop("/instrumentation/flightdirector/autopilot-on",ap_on);
      setprop("/controls/autoflight/autopilot[0]/engage",0);
      setprop("/controls/autoflight/autopilot[1]/engage",0);
      setprop("instrumentation/afs/flight-control-law", "direct");
      setprop("instrumentation/flightdirector/mode-reversion", 1);
    }
    maxpitch = getprop("/orientation/pitch-deg");
    if(maxpitch > 45 or maxpitch < -45){
      ap_on = 0;
      setprop("/instrumentation/flightdirector/autopilot-on",ap_on);
      setprop("/controls/autoflight/autopilot[0]/engage",0);
      setprop("/controls/autoflight/autopilot[1]/engage",0);
      setprop("instrumentation/afs/flight-control-law", "direct");
      setprop("instrumentation/flightdirector/mode-reversion", 1);
    }
      #if(getprop("/position/altitude-agl-ft") < 50){ap_on = 0;}
  }
  if (spdMode == SPD_THRCLB) {
      if (getprop("/instrumentation/flightdirector/spd-arm") == SPD_THRCLB) {
        setprop("/instrumentation/flightdirector/spd-arm",0);
      }
      var redAlt = getprop("/instrumentation/afs/thrust-reduce-alt");
      var accAlt = getprop("/instrumentation/afs/thrust-accel-alt");
      ####if (vnav == VNAV_CLB) {
        if (curAlt < accAlt and curAlt > redAlt and (vnav == VNAV_SRS or vnav == VNAV_CLB)) {
          afSpeed = getprop("/autopilot/locks/speed");
          flapPos = getprop("/fdm/jsbsim/fcs/flap-cmd-norm");
          if (flapPos == 0 and getprop("/instrumentation/flightdirector/accel-arm") != 1) {
            tracer("Flaps retracted, arm elevator and accel..");
            setprop("/instrumentation/flightdirector/vnav",VNAV_CLB);
            setprop("/instrumentation/flightdirector/vnav-arm",VNAV_OFF);
            setprop("/instrumentation/flightdirector/accel-arm",1);
          }
        }
        if (curAlt > accAlt and getprop("/instrumentation/afs/acquire_cl") != 1) {
          tracer("above accel alt, set climb thrust");
          setprop("/instrumentation/flightdirector/spd",SPD_THRCLB);
          setprop("/instrumentation/afs/acquire_cl",1);
        }
      ####}
      if (vnav == VNAV_SRS) {
        flapPos = getprop("/fdm/jsbsim/fcs/flap-cmd-norm");
        if (curAlt > redAlt and flapPos == 0) {
          tracer("flaps retracted and in climb phase, set vnav CLB");
          setprop("/instrumentation/flightdirector/vnav",VNAV_CLB);
          var curSpeed = getprop("/instrumentation/airspeed-indicator/indicated-speed-kt");
          if (curSpeed < 210) {
            curSpeed = 210;
          }
          setprop("/autopilot/settings/target-speed-kt", curSpeed);
          setprop("/autopilot/locks/speed","speed-with-throttle");
          setprop("/instrumentation/flightdirector/vnav-arm", VNAV_OFF);
          if (getprop("/controls/flight/elevator") > 0.1) {
            settimer(climb_flap_adjust, 5);
          }
        }
      }
  }

  if (spdMode == SPD_TOGA or spdMode == SPD_FLEX) {
     var redAlt = getprop("/instrumentation/afs/thrust-reduce-alt");
     if (curAlt >= redAlt) {
       setprop("/instrumentation/flightdirector/spd-arm",SPD_THRCLB);
     }
  }
  
  if (fltMode > 6 and int(curAlt) > int(crzAlt-200) and spdMode != SPD_CRZ and spdCruiseArm == 0 and getprop("/instrumentation/afs/speed-mode") == -1) {
        tracer("arm SPD_CRZ");
        settimer(delay_cruise_speed, 30);
        setprop("/instrumentation/flightdirector/vnav",VNAV_ALTCRZ);
        setprop("/instrumentation/afs/acquire_crz",1);
        setprop("/instrumentation/flightdirector/vnav-arm", VNAV_OFF);
        spdCruiseArm += 1;
  }
  var vSpd = int(getprop("/autopilot/settings/vertical-speed-fpm"));
  if (curAlt > 20000 and spdMode == SPD_THRCLB and vnav == VNAV_CLB and spdClimbRedArm == 0) {
    tracer("reduce CL V/S");
    spdClimbRedArm += 1;
    settimer(delay_climb_reduce_rate, 1);
  }
  var currMach = getprop("/instrumentation/airspeed-indicator/indicated-mach");
  var currTAS  = getprop("/instrumentation/airspeed-indicator/true-speed-kt");
  var clbMach = getprop("/instrumentation/afs/clb_mach");
  var desMach = getprop("/instrumentation/afs/des_mach");
  var desSpeed = getprop("/instrumentation/afs/des_speed");
  var changeoverMode = getprop("/instrumentation/afs/changeover-mode");
  var changeoverAlt  = getprop("instrumentation/afs/changeover-alt");
  if (spdMode == SPD_THRCLB and changeoverMode == 0 and curAlt > changeoverAlt) {
    tracer("currMach: "~currMach~" changeover level on");
    setprop("/instrumentation/afs/changeover-mode", 1);
    setprop("/instrumentation/afs/spd-mach-display-mode", 1);
    setprop("/autopilot/settings/target-speed-mach", clbMach);
    setprop("/autopilot/locks/speed", "mach-with-throttle");
    setprop("/instrumentation/afs/target-speed-mach", clbMach);
    setprop("instrumentation/flightdirector/vnav",vnav);
  }
  # don't retrieve the current changeover mode again, otherwise we could oscilate 
  if (spdMode == SPD_THRDES and changeoverMode == 1 and curAlt < changeoverAlt) {
    tracer("currTAS: "~currTAS~" changeover level off");
    setprop("/instrumentation/afs/changeover-mode",0);
    setprop("/instrumentation/afs/spd-mach-display-mode", 0);
    setprop("/autopilot/settings/target-speed-kt", desSpeed);
    setprop("/autopilot/settings/target-speed-mach", desMach);
    setprop("/instrumentation/afs/target-speed-mach", desMach);
    setprop("/autopilot/locks/speed", "speed-with-throttle");
    setprop("instrumentation/flightdirector/vnav",vnav);
  }

  var vAltMode = getprop("/instrumentation/afs/vertical-alt-mode");
  if (vAltMode == 0 and ap_on == 1) {
    #tracer("set ALT hold value");
    setprop("/autopilot/settings/target-altitude-ft",getprop("/instrumentation/afs/target-altitude-ft"));
  }
  
  var vVSMode = getprop("/instrumentation/afs/vertical-vs-mode");
  if (vVSMode == 0 and ap_on == 1) {
    #tracer("set V/S value");
    setprop("/autopilot/settings/vertical-speed-fpm",getprop("/instrumentation/afs/vertical-speed-fpm"));
  }
  var vHdgMode = getprop("/instrumentation/afs/lateral-mode");
  if (vHdgMode == 0 and ap_on == 1) {
    #tracer("set HDG value");
    setprop("/autopilot/settings/heading-bug-deg",getprop("/instrumentation/afs/heading-bug-deg"));
  }

  var spdMode = getprop("/instrumentation/afs/speed-mode");
  var machSpdMode = getprop("/instrumentation/afs/spd-mach-display-mode");
  if (spdMode == 0 and ap_on == 1) {
    if (machSpdMode == 0) {
      setprop("/autopilot/settings/target-speed-kt",getprop("/instrumentation/afs/target-speed-kt"));
    }
    if (machSpdMode == 1) {
      setprop("/autopilot/settings/target-speed-mach", getprop("/instrumentation/afs/target-speed-mach"));
    }
  }
};

delay_climb_reduce_rate = func() {
      #spdClimbRedArm -= 1;
      tracer("spdClimbRedArm: "~spdClimbRedArm);
      if (spdClimbRedArm == 1) {
        setprop("/autopilot/locks/altitude","vertical-speed-hold");
        interpolate("/autopilot/settings/vertical-speed-fpm",1300,10);
        settimer(delay_climb_inc_speed, 15);
      }
};

delay_climb_inc_speed = func() {
    var clbSpeed = getprop("/instrumentation/afs/clb_speed");
    var clbMach  = getprop("/instrumentation/afs/clb_mach");
    tracer("delayed increase climb speed to: "~clbSpeed);
    interpolate("/autopilot/settings/target-speed-kt",clbSpeed,30);
    setprop("/autopilot/settings/target-speed-mach", clbMach);
};

delay_cruise_speed = func() {
  #spdCruiseArm -= 1;
  tracer("spdCruiseArm: "~spdCruiseArm);
  setprop("/instrumentation/flightdirector/spd",SPD_CRZ);
};

climb_flap_adjust = func() {
    tracer("adjust elevator");
    interpolate("/controls/flight/elevator",0,60);
    #tracer("done elevator adjust");
};


#############################################################################
# track and update mode
#############################################################################

update_mode = func {
 #   lnav = getprop("/instrumentation/flightdirector/lnav");

    # compute elapsed time since last iteration
    nav_time = getprop("/sim/time/elapsed-sec");
    nav_dt = nav_time - last_nav_time;
    last_nav_time = nav_time;

    inrange = getprop("/instrumentation/nav/in-range");
    if ( inrange ) {
        # compute distance to nav heading intercept
        nav_dist = getprop("/instrumentation/nav/crosstrack-error-m");

        # compute time to heading (tth)
        nav_rate = (last_nav_dist - nav_dist) / nav_dt;
        if ( abs(nav_rate) > 0.00001 ) {
            tth = nav_dist / nav_rate;
        } else {
            tth = 9999.9;
        }
        #tracer("[update_mode] nav-dist = "~nav_dist~" tth = "~tth);

        tth_filter = 0.9 * tth_filter + 0.1 * tth;
        last_nav_dist = nav_dist;
    }        

    if ( lnav == LNAV_TRACK ) {
        curhdg = getprop("/orientation/heading-magnetic-deg");
        tgtrad = getprop("/instrumentation/flightdirector/nav-hdg");
        if ( tgtrad == nil or tgtrad == "" ) {
            tgtrad = 0.0;
        }
        diff = tgtrad - curhdg;
        if ( diff < -180.0 ) {
            diff += 360.0;
        } elsif ( diff > 180.0 ) {
            diff -= 180.0;
        }

        # standard rate turn is 3 dec/sec
        roll_out_time_sec = abs(diff) / 3.0;

      #  tracer("tth = ", tth_filter, " hdgdiff = ", diff, " rollout = ", roll_out_time_sec );
        if ( roll_out_time_sec >= abs(tth_filter) ) {
            # switch from arm to cpld
           # lnav = 3;
        }
    }

    var fp = flightplan();
    var curWP = fp.getWP();
    var nextWpAlt = 0;
    if (curWP != nil) {
      nextWpAlt = curWP.alt_cstr;
    } 
    ##var nextWpAlt = getprop("/autopilot/route-manager/route/wp[0]/altitude-ft");
    ##var nextWpAlt = getprop("/instrumentation/gps/wp/wp[1]/altitude-ft");
    var nextAlt = getprop("instrumentation/afs/target-altitude-ft");
    var descentAlt = getprop("/instrumentation/afs/thrust-descent-alt");
    var cruiseAlt  = getprop("/instrumentation/afs/thrust-cruise-alt");
    ###var cruiseAlt  = getprop("/instrumentation/mcdu/CRZ_FL");
    var vnav = getprop("/instrumentation/flightdirector/vnav");
    var spd  = getprop("instrumentation/flightdirector/spd");
    var curAlt = getprop("/position/altitude-ft");
    var managedVert = 0;
    if (getprop("/instrumentation/afs/vertical-alt-mode") == -1 and getprop("/instrumentation/afs/vertical-vs-mode") == -1 and getprop("/instrumentation/flightdirector/autopilot-on") == 1) {
        managedVert = 1;
    } 
 
    var distToTD = getprop("/autopilot/route-manager/wp[0]/dist");
    var nextId   = getprop("/autopilot/route-manager/wp[0]/id");
    #####var nextId   = getprop("/instrumentation/gps/wp/wp[1]/ID");

    if (nextId == "(T/D)" and nextTD == 0) {
      nextTD = 1;
      tracer("[update_mode] next WPT is T/D");
    }
    var pastTD = getprop("/instrumentation/flightdirector/past-td");
    
    #if (nextWpAlt == descentAlt or nextTD == 1) {
    #  tracer("[update_mode] distToWp: "~distToTD~", nextWpAlt: "~nextWpAlt~", descentAlt: "~descentAlt~", cruiseAlt: "~cruiseAlt~", curAlt: "~curAlt~", managedVert: "~managedVert);
    #}
    if (nextTD == 1 and vnav == VNAV_ALTCRZ and distToTD < 4 and getprop("/instrumentation/flightdirector/vnav-arm") == VNAV_OFF) {
      tracer("[update_mode] ARM DES - distToWp: "~distToTD~", nextWpAlt: "~nextWpAlt~", descentAlt: "~descentAlt~", cruiseAlt: "~cruiseAlt~", curAlt: "~curAlt~", managedVert: "~managedVert);
      var desMach = getprop("/instrumentation/afs/des_mach");
      setprop("/instrumentation/flightdirector/vnav-arm", VNAV_DES);
      interpolate("/autopilot/settings/target-speed-mach", desMach, 20);
      setprop("/autopilot/settings/vertical-speed-fpm",0);
      setprop("autopilot/locks/altitude","vertical-speed-hold");
      interpolate("autopilot/settings/vertical-speed-fpm", -500, 10);
    }

    if (pastTD == 1 and vnav == VNAV_ALTCRZ and managedVert == 1) {
      vnav = VNAV_DES;
      tracer("[update_mode] enable DES/THRDES - distToWp: "~distToTD~", nextWpAlt: "~nextWpAlt~", descentAlt: "~descentAlt~", cruiseAlt: "~cruiseAlt~", curAlt: "~curAlt~", managedVert: "~managedVert);
      setprop("/instrumentation/flightdirector/vnav",vnav);  # DES
      setprop("/instrumentation/flightdirector/vnav-arm", VNAV_OFF); 
      if (getprop("/instrumentation/flightdirector/spd") != SPD_THRDES) {
        setprop("/instrumentation/flightdirector/spd", SPD_THRDES);  # THR DES
      }
    }
    if (vnav == VNAV_DES and nextAlt <= 10000 and managedVert == 1 and spd == SPD_THRDES and spdDesArm3 == 0) {
      spdDesArm3 = 1;
      interpolate("/autopilot/settings/target-speed-kt",250,60);
    }
    if (vnav == VNAV_DES and nextAlt <= 4000 and managedVert == 1 and spd == SPD_THRDES and spdDesArm4 == 0) {
      spdDesArm4 = 1;
      interpolate("/autopilot/settings/target-speed-kt",220,60);
    }
    if (vnav == VNAV_DES and nextWpAlt > 0 and managedVert == 1) {
      ##diffAlt = nextWpAlt-curAlt;
      diffAlt = nextAlt-curAlt;
      if (diffAlt < 0) {
        var etaParts = split(":",getprop("/autopilot/route-manager/wp[0]/eta"));
        var etaDist  = getprop("/autopilot/route-manager/wp[0]/dist");
        var etaMin = int(etaParts[0]);
        var etaSec = int(etaParts[1]);
        if (etaMin == 0 and etaDist > 50) {
          etaMin = etaSec;
          etaSec = 0;
        }
        ##tracer("[updateMode] ETA min: "~etaMin~", ETA sec: "~etaSec~", difAlt: "~diffAlt);
        var gap = 10;
        if (nextAlt < 15000) {
          gap = 20;
        }
        eta = (etaSec+(etaMin*60))-gap;
        ##tracer("[updateMode] eta: "~eta~", difAlt: "~diffAlt);
        if (eta <= 0 ) { 
          if (getprop("/autopilot/locks/altitude") != "altitude-hold") {
            ##tracer("[updateMode] ETA min: "~etaMin~", ETA sec: "~etaSec~", difAlt: "~diffAlt);
            ##tracer("reached alt, holding");
            setprop("autopilot/settings/target-altitude-ft", nextAlt);
            setprop("/autopilot/locks/altitude","altitude-hold");
          }
        } else {
          ##tracer("ETA seconds: "~eta);
          fmsVS = (diffAlt/eta)*60;
          if (fmsVS < -3000) {
            fmsVS = -3000;
          }
          if (fmsVS > 3000) {
            fmsVS = 3000;
          }
          ##tracer("Set DESCENT VNAV #1: "~fmsVS);
          setprop("/autopilot/settings/vertical-speed-fpm",fmsVS);
          if (getprop("/autopilot/locks/altitude") != "vertical-speed-hold") {
            setprop("/autopilot/locks/altitude","vertical-speed-hold");
          }
        }
      } else {
        if (getprop("/autopilot/locks/altitude") != "altitude-hold") {
          ##tracer("else; set alt-hold");
          setprop("autopilot/settings/target-altitude-ft", nextAlt);
          setprop("/autopilot/locks/altitude","altitude-hold");
        }
      }
    }
    if (vnav == VNAV_DES and nextWpAlt == 0) {
      if (getprop("/autopilot/locks/altitude") != "altitude-hold") {
        tracer("holding current altitude: "~getprop("/autopilot/settings/target-altitude-ft")~", no FMS guidance");
        setprop("/autopilot/locks/altitude","altitude-hold");
      }
    }
    if (nextWpAlt == cruiseAlt and getprop("/position/altitude-ft") >= (cruiseAlt-25) and spd == SPD_THRCLB) {    ## remove "and spd == 8"  (SPD_THRIDL) 
      tracer("next WP is cruise alt, set speed");
      setprop("/instrumentation/flightdirector/spd",SPD_CRZ);   #there is more than one place we test to see if we reached cruise alt...
    }
    if (spd == SPD_THRCLB and vnav == VNAV_CLB and curAlt > getprop("/instrumentation/afs/transition-ft") and getprop("/autopilot/settings/target-speed-kt") < 250 and clbSpdArm2 == 0) {
        tracer("above 10000ft spd constraint and in climb, increase speed!");
        clbSpdArm2 = 1;
        interpolate("/autopilot/settings/target-speed-kt",250,60);
    }
    if (spd == SPD_THRCLB and vnav == VNAV_SRS and managedVert == 1 and curAlt < getprop("/instrumentation/afs/thrust-accel-alt")) {
      var fpm = getprop("/instrumentation/vertical-speed-indicator/indicated-speed-fpm");
      var grossWgt = getprop("/fdm/jsbsim/inertia/weight-lbs")*0.45359237;
      var grndSpeed = getprop("/velocities/groundspeed-kt");
      if (fpm < 500 and grossWgt > 510000 and grndSpeed < 200) {
        print("WARN: slow vertical speed, "~fpm~" ,use vertical-trim!");
        var newThrottle = 0.7;
        for(e=0; e <4; e=e+1) {
          var curTh = getprop("/controls/engines/engine["~e~"]/throttle");
          tracer("Set throttle: "~newThrottle~", engine: "~e~", curTh: "~curTh);
          if (newThrottle > curTh) {
            interpolate("/controls/engines/engine["~e~"]/throttle",newThrottle,2);
          } 
        }
      }
    }
};


#############################################################################
#get pitch from autopilot altitude setting
#############################################################################

get_altpitch = func() {
  var vnav = getprop("/instrumentation/flightdirector/vnav");
  current_pitch = getprop("/orientation/pitch-deg");
  if(vnav == 0) {
    return(current_pitch);
  }
  alt_offset = 0.0;

  if(vnav == VNAV_CLB) {
    return(5.0);
  }
  if(vnav == VNAV_OPDES) {
    return(0.0);
  }
  if(vnav == VNAV_FPA) {
    return(0.0);
  }
  if(vnav == VNAV_OPCLB) {
    return(getprop("/autopilot/settings/vertical-speed-fpm"));
  }
     ###if(vnav == 1){alt_select = getprop("/autopilot/settings/target-alt-hold");} 
  if(vnav == VNAV_GS) {    #calculation of glideslope altitude for current glideslope distance from NAV1
    #metres to feet 
    alt_select=((getprop("/instrumentation/nav[0]/gs-distance")*FD_TAN3DEG) + getprop("/environment/ground-elevation-m"))*3.281;
    #tracer("vbar GS#1 alt select: "~alt_select);
    # alt_select = alt_select + getprop("/environment/ground-elevation-m")*3.281;
  }
  if(vnav == VNAV_VS) {
    alt_select = getprop("/autopilot/settings/target-altitude-ft");
    #tracer("vbar GS#2 alt select: "~alt_select);
  }

  if ( alt_select == nil or alt_select == "" ) {
    alt_select = 0.0;
    return(current_pitch);
  }

  current_alt = getprop("/position/altitude-ft");
  if(current_alt == nil) {
    current_alt = 0.0;
  }
  alt_offset = (alt_select-current_alt);
  setprop("/instrumentation/flightdirector/alt-alert",alt_offset);
  if(alt_offset > 500.0)  {
    alt_offset = 500.0;
  }
  if(alt_offset < -500.0) {
    alt_offset = -500.0;
  }
  ## tracer("vbar alt_offset*0.012: "~(alt_offset*0.012));
  return(alt_offset * 0.012);
};

#############################################################################
#update nav gps or nav setting - orig
#############################################################################

update_nav_orig = func () {
  slaved = getprop("/instrumentation/primus1000/dc550/fms");
  current_heading = getprop("/orientation/heading-magnetic-deg");
  if(slaved == nil) {
    slaved = 0
  };

  if(slaved == 0) {
        #setlistener("/sim/signals/fdm-initialized", func {
        # setprop("/instrumentation/flightdirector/to-flag",getprop("/instrumentation/nav/to-flag"));
        #});
    desired_course = getprop("/instrumentation/nav/radials/selected-deg");
    course_offset = getprop("/instrumentation/nav/heading-needle-deflection");
    nav_mag_brg = getprop("/instrumentation/nav/heading-deg");
    if (getprop("/instrumentation/nav/has-gs") != 0) {
      gs_offset=getprop("/instrumentation/nav/gs-needle-deflection");
      if(gs_offset == nil) {
        gs_offset = 0
      };
      gs_active = gs_offset *1.0; 
      if(gs_active > 30.0) {
        gs_active = 30.0
      };
      if(gs_active < -30.0) {
        gs_active = -30.0
      };
      setprop("/instrumentation/flightdirector/gs-pitch",gs_active * 100);
    }
  } else {
    setprop("/instrumentation/flightdirector/to-flag",getprop("/instrumentation/gps/wp/wp[1]/to-flag"));
    desired_course = getprop("/instrumentation/gps/wp/wp[1]/desired-course-deg");
    if(desired_course == nil) {
      desired_course=0;
    }
    desired_course -= getprop("/environment/magnetic-variation-deg");
    nav_mag_brg = getprop("/instrumentation/gps/wp/wp[1]/bearing-mag-deg");
    if(desired_course < 0) {
      desired_course += 360;
    } elsif(desired_course > 360) {
      desired_course -= 360;
    }
    course_offset = getprop("/instrumentation/gps/wp/wp[1]/course-deviation-deg");
    if(course_offset > 10.0) {
      course_offset = 10.0;
    }
    if(course_offset < -10.0) {
      course_offset = -10.0;
    }
  }
  setprop("/instrumentation/flightdirector/dtk",desired_course);

  if(nav_mag_brg == nil) {
    nav_mag_brg = 0;
  }
  nav_mag_brg -= current_heading;
  if(nav_mag_brg > 180) {
    nav_mag_brg -= 360
  };
  if(nav_mag_brg < -180) {
    nav_mag_brg += 360
  };
#########    set radial offset from current heading ###########
  desired_course -= current_heading;
  if(desired_course < -180) {
    desired_course += 360;
  } elsif(desired_course > 180) {
    desired_course -= 360;
  }
  setprop("/instrumentation/flightdirector/course",desired_course);

##### adjust autopilot nav heading with deviation ###########
  nav_adjust = ( course_offset * 4.5);
  nav_hdg_offset = desired_course + nav_adjust;
  if(nav_hdg_offset < -180) {
    nav_hdg_offset += 360;
  } elsif(nav_hdg_offset > 180) {
    nav_hdg_offset -= 360;
  }


  setprop("/instrumentation/flightdirector/nav-mag-brg",nav_mag_brg);
  setprop("/instrumentation/flightdirector/course-offset",course_offset);
  setprop("/instrumentation/flightdirector/nav-hdg",nav_hdg_offset);

     #turn_radius_m = getprop("/instrumentation/gps/indicated-ground-speed-kt")*KT2MSEC;
     #turn_radius_m = (turn_radius_m*turn_radius_m)/lur_koeff1;
     #diff = 
     #lur = getprop("/autopilot/route-manager/wp/dist");

};


#############################################################################
#update nav gps or nav setting
#############################################################################

update_nav = func () {
  slaved = getprop("/instrumentation/primus1000/dc550/fms");
  current_heading = getprop("/orientation/heading-magnetic-deg");
  if(slaved == nil){slaved = 0};

  if(slaved == 0) {
    desired_course = getprop("/instrumentation/nav/radials/selected-deg");
    course_offset = getprop("/instrumentation/nav/heading-needle-deflection");
    nav_mag_brg = getprop("/instrumentation/nav/heading-deg");
    if (getprop("/instrumentation/nav/has-gs") != 0){
      gs_offset=getprop("/instrumentation/nav/gs-needle-deflection");
      if(gs_offset == nil){gs_offset = 0};
      gs_active = gs_offset *1.0; 
      if(gs_active > 30.0){gs_active = 30.0};
      if(gs_active < -30.0){gs_active = -30.0};
      setprop("/instrumentation/flightdirector/gs-pitch",gs_active * 100);
    }
  }else{
    setprop("/instrumentation/flightdirector/to-flag",getprop("/instrumentation/gps/wp/wp[1]/to-flag"));
    desired_course = getprop("/instrumentation/gps/wp/wp[1]/desired-course-deg");
    if(desired_course == nil){desired_course=0;}
    desired_course -= getprop("/environment/magnetic-variation-deg");
    nav_mag_brg = getprop("/instrumentation/gps/wp/wp[1]/bearing-mag-deg");
    if(desired_course < 0){
      desired_course += 360;
    } elsif(desired_course > 360){desired_course -= 360;}
    course_offset = getprop("/instrumentation/gps/wp/wp[1]/course-deviation-deg");
    if(course_offset > 10.0){course_offset = 10.0;}
    if(course_offset < -10.0){course_offset = -10.0;}
  }
  setprop("/instrumentation/flightdirector/dtk",desired_course);

  if(nav_mag_brg == nil){nav_mag_brg = 0;}
  nav_mag_brg -= current_heading;
  if(nav_mag_brg > 180){nav_mag_brg -= 360};
  if(nav_mag_brg < -180){nav_mag_brg += 360};
#########    set radial offset from current heading ###########
  desired_course -= current_heading;
  if(desired_course < -180){
    desired_course += 360;
  } elsif(desired_course > 180){desired_course -= 360;}
  setprop("/instrumentation/flightdirector/course",desired_course);

##### adjust autopilot nav heading with deviation ###########
  nav_adjust = ( course_offset * 4.5);
  nav_hdg_offset = desired_course + nav_adjust;
  if(nav_hdg_offset < -180){
    nav_hdg_offset += 360;
  }elsif(nav_hdg_offset > 180){nav_hdg_offset -= 360;}


  setprop("/instrumentation/flightdirector/nav-mag-brg",nav_mag_brg);
  setprop("/instrumentation/flightdirector/course-offset",course_offset);
  setprop("/instrumentation/flightdirector/nav-hdg",nav_hdg_offset);

#calculating true ground speed from navigation speed-triangle
#FIX ME! Here must TAS, not IAS!!!
#calculating TAS with linear interpolation of airspeed indicator error-model
  H760_m = getprop("/position/altitude-ft")*0.305;
  if(H760_m <= 6000) {
    tas_koeff = 0.05*(H760_m/1000);
  }
  if(H760_m > 6000) {
    tas_koeff = 0.3 + 0.1*((H760_m-6000)/1000);
  }
#  W_kt = getprop("/instrumentation/airspeed-indicator/indicated-speed-kt");
#  setprop("/instrumentation/flightdirector/IAS-kt", W_kt);
#  W_kt += (W_kt*tas_koeff);
#  setprop("/instrumentation/flightdirector/TAS-kt", W_kt);
#  if(W_kt == nil) {W_kt=0;}
  wind_angle = (getprop("/environment/wind-from-heading-deg") + 180 - getprop("/orientation/heading-deg"));#heading wind-angle
  if(wind_angle > 180) {wind_angle -= 360;};
  if(wind_angle < -180) {wind_angle += 360;};
#wind_angle = (getprop("/environment/wind-from-heading-deg") + 180 - currTrack_trueCourse);#wind-angle
  setprop("/instrumentation/flightdirector/wind-angle-deg", wind_angle);
  wind_angle *= DEG2RAD;
  wind_speed_kt = getprop("/environment/wind-speed-kt");
  if(wind_speed_kt == nil) {wind_speed_kt = 0;}
  setprop("/instrumentation/flightdirector/wind-speed-kt", wind_speed_kt);
#  W_kt += (wind_speed_kt*math.cos(wind_angle));#true ground speed from navigation speed-triangle

  W_kt = getprop("/velocities/groundspeed-kt");
  setprop("/instrumentation/flightdirector/ground-speed-kt", W_kt);

  We = getprop("/velocities/speed-east-fps");
  Wn = getprop("/velocities/speed-north-fps");
  Ue = getprop("/environment/wind-from-east-fps");
  Un = getprop("/environment/wind-from-north-fps");
  Ve = We + Ue;
  Vn = Wn + Un;
  if(Ve == nil) {Ve=0.0;};
  if(Vn == nil) {Vn=0.0;};
  V = math.sqrt(Ve*Ve+Vn*Vn);#ft/sec
  V *= 60;#ft/min
  V *= FPM2MSEC;#msec
  V *= MSEC2KT;#kt
  setprop("/instrumentation/flightdirector/TAS-kt", V);
#  V = 90 - math.atan2(Vn,Ve)*RAD2DEG;
#  if(V < 0) {V += 360;};
  if(We == nil) {We=0.0;};
  if(Wn == nil) {Wn=0.0;};
  FPU = 90 - math.atan2(Wn,We)*RAD2DEG;
  if(FPU < 0) {FPU += 360;};
  US = FPU - getprop("/orientation/heading-deg");
  if(US > 180) {US -= 360;};
  if(US < -180) {US += 360;};
#  kUS = FPU - V;
#  if(kUS > 180) {kUS -= 360;};
#  if(kUS < -180) {kUS += 360;};
  modUS = math.sqrt(US*US);
  setprop("/instrumentation/flightdirector/currTrueHdg-deg", FPU);
  setprop("/instrumentation/flightdirector/currUS-deg", US);
  setprop("/instrumentation/flightdirector/abs-US-deg", modUS);
#  setprop("/instrumentation/flightdirector/currkUS-deg", kUS);

  if(lnav == LNAV_FMS) { #in LNAV mode only
    if(GPS_GO == 1) {
      calc_wp_heading();
      turn_radius_m = W_kt*KT2MSEC;
      turn_radius_m = (turn_radius_m*turn_radius_m)/lur_koeff1;
      setprop("/instrumentation/flightdirector/curr-turn-radius-nm", turn_radius_m/1852);
#  diff = NextWP_trueCourse - getprop("/orientation/heading-deg");
      diff = NextWP_trueCourse - FPU;
      if(diff<0) {diff += 360;}
      if(diff>180) {diff -= 360;}
      if(diff<0) {diff *= -1;}
      if(diff == 180) {diff = 179.9;}
      setprop("/instrumentation/flightdirector/next-heading-diff-deg", diff);
      diff *= DEG2RAD; 
      diff /= 2;
      lur_m = turn_radius_m*(math.sin(diff)/math.cos(diff))+TRK_M;    #in metres
#  lur_m = turn_radius_m*(math.sin(diff)/math.cos(diff));   #in metres
      lur_nm = lur_m/1852;
      setprop("/instrumentation/flightdirector/turn-distance-m", lur_m);
      setprop("/instrumentation/flightdirector/turn-distance-nm", lur_nm);
  
      #####turn_dist = getprop("/autopilot/route-manager/wp/dist");
      turn_dist  = getprop("/instrumentation/gps/wp/wp[1]distance-nm");
      if(turn_dist == nil) {turn_dist = 0; return;}
#calculate side error from track 
      diff = currWP_trueCourse - currTrack_trueCourse;
      diff *= DEG2RAD;
      z_nm = turn_dist*math.sin(diff);
      setprop("/instrumentation/flightdirector/curr-z-nm", z_nm);
#======================= TRACK HOLD MODE ===============================================================================
      abs_z_nm = math.sqrt(z_nm*z_nm);
      trk_range1 = 2*(turn_radius_m/1852);
      trk_range2 = turn_radius_m/1852;
      trk_lock_range = TRK_M/1852;#lock range = +-200 metres
      trk_range3 = (turn_radius_m*FD_TAN15DEG)/1852;#lur 30-deg turn
      trk_range4 = (turn_radius_m*FD_TAN2_5DEG)/1852;#lur 5-deg turn
      if(in_turn == 1) { #make turn
        diff = currTrack_trueCourse - FPU;
        if(diff >= -2 and diff <= 2 ) {#+-2 degrees - turn finished
          in_turn = 0;
          setprop("/instrumentation/flightdirector/curr-in-turn", in_turn);
        }
      } else {#on track
        if(abs_z_nm > trk_range1 and trk_lck_mode==0) {#make 2 90-degree turns
          if(z_nm > 0) {#make right turn
            intrcpt_hdg_deg = currTrack_trueCourse + 90;
          };
          if(z_nm < 0) {#make left turn
            intrcpt_hdg_deg = currTrack_trueCourse - 90;
          };
          if(trk_on == 1) {trk_lck_mode = 1;}
        } elsif(abs_z_nm < trk_range1 and abs_z_nm > trk_range2 and trk_lck_mode == 0) {#entering with 30-degree heading diff
          if(z_nm > 0) {#make right turn
            intrcpt_hdg_deg = currTrack_trueCourse + 30;
          };
          if(z_nm < 0) {#make left turn
            intrcpt_hdg_deg = currTrack_trueCourse - 30;
          };
          if(trk_on == 1) {trk_lck_mode = 2;}
        } elsif(abs_z_nm > (2*trk_lock_range) and abs_z_nm < trk_range2  and trk_lck_mode == 0) {#entering with 5-degree heading diff
          if(z_nm > 0) {#make right turn
            intrcpt_hdg_deg = currTrack_trueCourse + 5;
          };
          if(z_nm < 0) {#make left turn
            intrcpt_hdg_deg = currTrack_trueCourse - 5;
          };
          if(trk_on == 1) {trk_lck_mode = 3;}
        } elsif(abs_z_nm > trk_lock_range and abs_z_nm < (2*trk_lock_range)  and trk_lck_mode == 0) {#entering with 1-degree heading diff
          if(z_nm > 0) {#make right turn
            intrcpt_hdg_deg = currTrack_trueCourse + 2;
          };
          if(z_nm < 0) {#make left turn
            intrcpt_hdg_deg = currTrack_trueCourse - 2;
          };
          if(trk_on == 1) {trk_lck_mode = 4;}
        } elsif(abs_z_nm <= (trk_lock_range/2)) { #locking track
          intrcpt_hdg_deg = currTrack_trueCourse;
          if(trk_on == 1) {trk_lck_mode = 5;}
        }
      }
      if(trk_lck_mode == 1) {
        if(abs_z_nm <= trk_range2) { intrcpt_hdg_deg = currTrack_trueCourse; }
        diff = currTrack_trueCourse - FPU;
        if((diff >= -2 and diff <= 2) and abs_z_nm > (2*trk_lock_range)) {#+-2 degrees - turn finished, but track not locked
          trk_lck_mode = 0;#reset
        }
      } elsif(trk_lck_mode == 2) {
        if((abs_z_nm/FD_SIN30DEG) <= trk_range3) {intrcpt_hdg_deg = currTrack_trueCourse;}
        diff = currTrack_trueCourse - FPU;
        if((diff >= -2 and diff <= 2) and abs_z_nm > (2*trk_lock_range)) {#+-2 degrees - turn finished, but track not locked
          trk_lck_mode = 0;#reset
        }
        if(abs_z_nm > trk_range1) {trk_lck_mode=0;}
      } elsif(trk_lck_mode == 3) {
        if((abs_z_nm/FD_SIN5DEG) <= trk_range4) {intrcpt_hdg_deg = currTrack_trueCourse;}
        diff = currTrack_trueCourse - FPU;
        if((diff >= -1 and diff <= 1) and abs_z_nm > trk_lock_range) {#+-2 degrees - turn finished, but track not locked
          trk_lck_mode = 0;#reset
        }
        if(abs_z_nm > trk_range2) {trk_lck_mode=0;}
      } elsif(trk_lck_mode == 4) {
        if(abs_z_nm <= (trk_lock_range/2)) {intrcpt_hdg_deg = currTrack_trueCourse;}
        if( abs_z_nm > (2*trk_lock_range)) {trk_lck_mode = 0; }
      } elsif(trk_lck_mode == 5 and abs_z_nm > trk_lock_range) {#loss track - restart
        trk_lck_mode = 0;
      }

      if(intrcpt_hdg_deg >= 360) {intrcpt_hdg_deg -= 360};
      if(intrcpt_hdg_deg < 0) {intrcpt_hdg_deg += 360};
      setprop("/instrumentation/flightdirector/curr-trk-lck-mode", trk_lck_mode);
      setprop("/instrumentation/flightdirector/curr-intrcpt-hdg-deg", intrcpt_hdg_deg);
      trk_intrcpt_hdg_err =  intrcpt_hdg_deg - FPU;
      if(trk_lck_mode == 5) {#in lock mode
        trk_intrcpt_hdg_err =  intrcpt_hdg_deg - FPU + 10*z_nm;
        trk_corr_err = 0;#-1*z_nm;
      } else {
        trk_corr_err = 0.0;
        if(ap_on==1) { 
          setprop("/controls/flight/rudder", 0.0);
        }
      }
      if(trk_intrcpt_hdg_err > 180) {trk_intrcpt_hdg_err -= 360;};
      if(trk_intrcpt_hdg_err < -180) {trk_intrcpt_hdg_err += 360;};
      setprop("/instrumentation/flightdirector/curr-intrcpt-hdg-err", trk_intrcpt_hdg_err);
      setprop("/instrumentation/flightdirector/curr-trk-corr-err", trk_corr_err);
#=============================================================================================================================
      if(trk_on==1) {   #in this mode standard FG autopilot not working - we pop waypoint always
        if(lur_m < 50000) {
          if( (turn_dist != 0) and (turn_dist <= lur_nm) ) { #turn distance - begin turn
            tracer("Begin turn#1 -> lur_m="~lur_m~" lur_nm ="~lur_nm~" dist="~getprop("/instrumentation/gps/wp/wp[1]/distance-nm"));
            complete_turn = 1;
            tracer("turn complete - pop WP");
            var curSeq = getprop("/autopilot/route-manager/current-wp");
            var nextSeq = int(curSeq+1);
            ##setprop("/autopilot/route-manager/input", "@pop");
            setprop("/autopilot/route-manager/current-wp",nextSeq);
            print("[Guidance] completed turn anticipation #1");
            trk_lck_mode=0;  #next leg - reset track mode
          }
        }
      } else {
        ##tracer("check turn#2 dist: lur_m="~lur_m~" lur_nm ="~lur_nm~" dist="~turn_dist);
        if(lur_m > 200 and lur_m < 10000) {   #blocking standart FG autopilot - it pop waypoint if distance to waypoint <= 200 metres
          if( (turn_dist != 0) and (turn_dist <= lur_nm) ) {   #turn distance - begin turn
            tracer("Begin turn#2 -> lur_m="~lur_m~" lur_nm ="~lur_nm~" dist="~turn_dist);              ##getprop("/instrumentation/gps/wp/wp[1]/distance-nm")
            complete_turn = 1;
            tracer("turn complete - pop WP");
            var curSeq = getprop("/autopilot/route-manager/current-wp");
            var nextSeq = int(curSeq+1);
            ##setprop("/autopilot/route-manager/input", "@pop");
            setprop("/autopilot/route-manager/current-wp",nextSeq);
            print("[Guidance] completed turn anticipation #2");
          }
        }
      }
    }
  }
};





#############################################################################
# update the FD vbar position for the various modes
#############################################################################

update_vbar = func {
    if ( lnav == LNAV_OFF ) {
        # wings level maintain pitch at time of mode activation
        if ( lnav_last != 0 ) {
            vbar_roll = 0.0;
           vbar_pitch = getprop("/orientation/pitch-deg");
        }
    } elsif ( lnav == LNAV_HDG) {
        #Heading bug 
        # FIXME: at what angle off of the hdg bug do we start the rollout?
        # bank to track heading bug

        tgtrad = getprop("/autopilot/settings/heading-bug-deg");
        if ( tgtrad == nil or tgtrad == "" ) {
            tgtrad = 0.0;
        }
        curhdg = getprop("/orientation/heading-magnetic-deg");
        diff = tgtrad - curhdg;
        if ( diff < -180.0 ) {
            diff += 360.0;
        } elsif ( diff > 180.0 ) {
            diff -= 180.0;
        }
        # max bank = 30, so this means roll out begins at 15 dgs off target hdg
        bank = 2 * diff;
        if ( bank < -30.0 ) {
            bank = -30.0;
        }
        if ( bank > 30.0 ) {
            bank = 30.0;
        }
        vbar_roll = bank;
#        tracer("diff = ", diff);
    } elsif ( lnav == LNAV_LOC) {
          #NAV and APR
          #tgtrad = getprop("/instrumentation/flightdirector/nav-hdg") * 3;
        tgtrad = (getprop("/instrumentation/nav/radials/target-auto-hdg-deg") - getprop("/orientation/heading-deg"))*3;

        if(tgtrad > 30) {
            tgtrad = 30;
        } 
        if(tgtrad < -30) {
            tgtrad = -30;
        } 

        vbar_roll = tgtrad;
    } elsif (lnav == LNAV_TRACK) {
        tgtrad = getprop("/autopilot/internal/true-heading-error-deg") * 3;
        
        if(tgtrad > 30){
            tgtrad = 30;
        } 
        if(tgtrad < -30){
          tgtrad = -30;
        } 

        vbar_roll = tgtrad;
   } else {
        # assume off if nothing else specified, and hide vbars
        vbar_roll = 0.0;
   }
   vnav = getprop("/instrumentation/flightdirector/vnav");
   if (vnav != 0 or vnav !=nil) {
       vbar_pitch =  get_altpitch();
   }

   lnav_last = lnav;
   vbar_pitch_prop = (vbar_pitch - getprop("/orientation/pitch-deg"));
   vbar_roll_prop = (getprop("/orientation/roll-deg") - vbar_roll);
   if(vbar_roll_prop > 30.0){
     vbar_roll_prop = 30.0;
   }
   if(vbar_roll_prop < -30.0){
     vbar_roll_prop = -30.0;
   }
   if(vbar_pitch_prop > 15.0){
     vbar_pitch_prop = 15.0;
   }
   if(vbar_pitch_prop < -15.0){
     vbar_pitch_prop = -15.0;
   }
 setprop("/instrumentation/flightdirector/vbar-pitch",vbar_pitch_prop);
 setprop("/instrumentation/flightdirector/vbar-roll", vbar_roll_prop);

}


#############################################################################
# evaluate functions, try to work out each selected/managed mode
#############################################################################

evaluateSPD = func {
  var fdMode = getprop("/instrumentation/flightdirector/spd");
  var afsMode = getprop("instrumentation/afs/speed-mode");
  var apMode = getprop("/instrumentation/flightdirector/autopilot-on");
}


evaluateHDG = func {
  var fdMode = getprop("instrumentation/flightdirector/lnav");
  var afsMode = getprop("instrumentation/afs/lateral-mode");
  var apMode = getprop("/instrumentation/flightdirector/autopilot-on");
}


evaluateALT = func {
  var fdMode = getprop("/instrumentation/flightdirector/vnav");
  var afsMode = getprop("/instrumentation/afs/vertical-alt-mode");
  var apMode = getprop("/instrumentation/flightdirector/autopilot-on");
}


evaluateVS = func {
  var fdMode = getprop("instrumentation/flightdirector/vnav");
  var afsMode = getprop("instrumentation/afs/vertical-vs-mode");
  var apMode = getprop("/instrumentation/flightdirector/autopilot-on");
  var altMode = getprop("/instrumentation/afs/vertical-alt-mode");
}


#############################################################################
# main update function to be called each frame
#############################################################################

update = func {
    handle_inputs();
    update_mode();
    ###update_nav_orig();
    update_nav();       ## new NAV from 787...
    update_vbar();
 
    registerTimer();
}



#############################################################################
# Use the nasal timer to call ourselves again
#############################################################################

registerTimer = func {
    settimer(update, 0.5);
}
registerTimer();



#################################################
#   basic mathematic functions not in Nasal :(
#################################################
#var pow = func(x, y) { 
#  math.exp(y * math.ln(x))
#}

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


################################################################
#  calculate great circle distance using degrees
################################################################
var calcGCDistanceDeg = func(plat1, plon1, plat2, plon2) {
 var lat1 = plat1*DEG2RAD;
 var lon1 = plon1*DEG2RAD;
 var lat2 = plat2*DEG2RAD;
 var lon2 = plon2*DEG2RAD;
 #print("lat1: "~lat1~", lon1: "~lon1~", lat2: "~lat2~", lon2: "~lon2);
 return calcGCDistance(lat1, lon1, lat2, lon2);
}

####################################################################
# calc Great Circle distance using radians, returns NM
##################################################################
var calcGCDistance =func(lat1, lon1, lat2, lon2) {
 d1 = math.sin((lat1-lat2)/2);
 #print("d1: "~d1);
 p1 = math.pow(2, d1);
 #print("p1: "~p1);
 dd2 = (math.sin((lon1-lon2)/2));
 d2 = math.cos(lat1)*math.cos(lat2)*dd2;
 #print("d2: "~d2);
 p2 = math.pow(2, d2);
 #print("p2: "~p2);
 d3 = math.sqrt(p1 + p2);
 #print("d3: "~d3);
 as4 = asin(d3);
 #print("as4: "~as4);
 das4rad = 2*as4;
 das4nm = das4rad*180*60/math.pi;
 ### d=2*asin(sqrt((sin((lat1-lat2)/2))^2 + cos(lat1)*cos(lat2)*(sin((lon1-lon2)/2))^2))
 return das4nm;
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
   tc1=2*math.pi-math.acos(dd1);
  }
  return tc1;
}

#######################################################################
#  calculate lat,lon of point that is d distance from lat,lon by tc true course in radians
#######################################################################
var calcDistancePoint = func(tc, d, lat1, lon1) {
  print("tc: "~tc~", d: "~d~", lat1: "~lat1~", lon1: "~lon1);
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

