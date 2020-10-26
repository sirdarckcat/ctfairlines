 #############################################################################
#
# Citation Bravo Flight Director/Autopilot controller.
#
# Written by Syd Adams
#Modification of Curtis Olson's flight director.
# Started 30 Jan 2006.
#Modified by AirAlex
#Modified by S.Hamilton May 2009


#
#############################################################################
# 1 meter = 0.000539956803 nm
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
# vnav 0=off, 1=ALT(s), 2=V/S(s), 3=OP CLB(s), 4=FPA(s), 5=OP DES(s), 6=CLB(m), 7=ALT(m), 8=DES=(m), 9=G/S(m), 10=SRS(m)
# athr 0=idle, 1=CL, 2=FLX, 3=TOGA
# spd  0=off, 1=TOGA, 2=FLEX, 3=THR CLB, 4=SPEED(s), 5=MACH(s), 6=CRZ(m), 7=THR IDL(m - DES)


#trigonometric values for glideslope calculations
FD_TAN3DEG = 0.052407779283;
FD_SIN3DEG = 0.052335956243;
FD_COS3DEG = 0.998629534755;

DEG2RAD = 0.01745329251994329509;
RAD2DEG = 57.29577951308232311;
MSEC2KT=1.946;
KT2MSEC=0.514;
MSEC2KMH=3.6;
KMH2MSEC=0.28;
NM2MTRS = 1852;
lur_koeff1 = 5.661872017348443498;#=g*tan(30deg)

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
current_pitch=0;
desired_course=0;
nav_adjust=0;
tgtrad=0;
bank=0;
curhdg=0;
diff=0;
roll_out_time_sec=0;

#waypoint
wp_id="";
wp_longitude_deg=0.0;
wp_latitude_deg=0.0;
wp_altitude_ft=0;

#############################################################################
# Use tha nasal timer to call the initialization function once the sim is
# up and running
#############################################################################

init_gps = func {
#setting gps
    setprop("/instrumentation/gps/wp/wp[1]/waypoint-type", "nav");
    setprop("/instrumentation/gps/wp/wp[1]/name", "waypoint");

    wp_id = getprop("/autopilot/route-manager/route/wp/id");
    setprop("/instrumentation/gps/wp/wp[1]/ID", wp_id);
    print("wp_id=", wp_id);

    wp_altitude_ft = getprop("/autopilot/route-manager/route/wp/altitude-ft");
    setprop("/instrumentation/gps/wp/wp[1]/altitude-ft", wp_altitude_ft);
    print("wp_alt_ft=", wp_altitude_ft);

    wp_latitude_deg = getprop("/autopilot/route-manager/route/wp/latitude-deg");
    setprop("/instrumentation/gps/wp/wp[1]/latitude-deg", wp_latitude_deg);
    print("wp_lat_deg=", wp_latitude_deg);
#    setprop("/instrumentation/gps/wp/wp[1]/latitude-deg", getprop("/autopilot/route-manager/route/wp/latitude-deg"));

    wp_longitude_deg = getprop("/autopilot/route-manager/route/wp/longitude-deg");
    setprop("/instrumentation/gps/wp/wp[1]/longitude-deg", wp_longitude_deg);
    print("wp_lon_deg=", wp_longitude_deg);
#    setprop("/instrumentation/gps/wp/wp[1]/longitude-deg", getprop("/autopilot/route-manager/route/wp/longitude-deg"));
};

setlistener("/sim/signals/fdm-initialized", func {
    # default values
    print("Initializing Flight Director");
    setprop("/instrumentation/flightdirector/lnav", 0.0);
    setprop("/controls/autoflight/lateral-mode",0.0);
    setprop("/instrumentation/flightdirector/vnav", 0.0);
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
    setprop("/instrumentation/flightdirector/alt-alert", alt_alert);
    setprop("/instrumentation/flightdirector/course", 0.0);
    setprop("/instrumentation/flightdirector/dtk", 0.0);
    setprop("/instrumentation/flightdirector/nav-hdg", 0.0);
    setprop("/instrumentation/flightdirector/gs-pitch", 0.0);
    setprop("/instrumentation/flightdirector/nav-mag-brg", 0.0);
    setprop("/instrumentation/flightdirector/course-offset", course_offset);
    setprop("/instrumentation/flightdirector/target-inhg", 29.92);
    setprop("/instrumentation/flightdirector/to-flag",0);
    setprop("/instrumentation/flightdirector/from-flag",0);
    setprop("/instrumentation/afs/lateral-mode",0);
    setprop("/instrumentation/afs/vertical-vs-mode",0);
    setprop("/instrumentation/afs/vertical-alt-mode",0);
    setprop("/instrumentation/afs/thrust-reduce-alt",1500);
    setprop("/instrumentation/afs/thrust-accel-alt",3500);
    setprop("/instrumentation/afs/thrust-cruise-alt",35000);
    setprop("/autopilot/settings/heading-bug-deg",0);
    setprop("/autopilot/settings/target-altitude-ft",0);
    setprop("autopilot/settings/vertical-speed-fpm",0);
    setprop("autopilot/settings/target-speed-kt",200);
    setprop("/autopilot/locks/altitude","");
    setprop("/autopilot/locks/heading","");
    setprop("/instrumentation/nav/slaved-to-gps",slaved);
    current_alt = getprop("/instrumentation/altimeter/indicated-altitude-ft");
    alt_select = getprop("/autopilot/settings/target-altitude-ft");
    setprop("/instrumentation/flightdirector/to-flag",getprop("/instrumentation/nav/to-flag"));
#route settings
   if(getprop("/autopilot/route-manager/route/wp/id")!=nil) {#if waypoint present
    if(getprop("/autopilot/route-manager/route/wp/altitude-ft") < 40000) {#setting target altitude
     setprop("/autopilot/settings/target-altitude-ft", getprop("/autopilot/route-manager/route/wp/altitude-ft"));
     setprop("/instrumentation/afs/thrust-cruise-alt", getprop("/autopilot/route-manager/route/wp/altitude-ft"));
    }
    settimer(init_gps,2);
   }
});

gps_next_wp = func {
#changing current wp
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
    print("wp_id=", wp_id);

    wp_altitude_ft = getprop("/autopilot/route-manager/route/wp/altitude-ft");
    setprop("/instrumentation/gps/wp/wp[1]/altitude-ft", wp_altitude_ft);
    print("wp_alt_ft=", wp_altitude_ft);

    wp_latitude_deg = getprop("/autopilot/route-manager/route/wp/latitude-deg");
    setprop("/instrumentation/gps/wp/wp[1]/latitude-deg", wp_latitude_deg);
    print("wp_lat_deg=", wp_latitude_deg);

    wp_longitude_deg = getprop("/autopilot/route-manager/route/wp/longitude-deg");
    setprop("/instrumentation/gps/wp/wp[1]/longitude-deg", wp_longitude_deg);
    print("wp_lon_deg=", wp_longitude_deg);
};

#############################################################################
# handle KC 290 Mode Controller inputs, and compute correct mode/settings
#############################################################################
setlistener("/instrumentation/flightdirector/autopilot-on", func(n) {
    ap_on = n.getValue();
if(ap_on == 1) {
 lnav = getprop("/instrumentation/flightdirector/lnav");
 if(lnav == 0 or lnav ==nil){setprop("autopilot/locks/heading","wing-leveler");}
}
else {
 setprop("autopilot/locks/heading","");
 setprop("autopilot/locks/altitude","");
 setprop("autopilot/locks/speed","");
}
});

setlistener("/instrumentation/flightdirector/at-on", func(n) {
  at_on = n.getValue();
  if(ap_on == 1) {
    if(at_on) {
      setprop("autopilot/locks/speed","speed-with-throttle");
    } else {
      setprop("autopilot/locks/speed","");
    }
  }
});

setlistener("/instrumentation/flightdirector/fd-on", func(n) {
  fd_on = n.getValue();
  if(fd_on == 1) {
    setprop("autopilot/locks/passive-mode",1);
  } else {
    setprop("autopilot/locks/passive-mode",0);
  }
});

setlistener("/instrumentation/flightdirector/lnav", func(n) {
  lnav = n.getValue();
  if(ap_on==1) {
    if(lnav == 0 or lnav ==nil) {
      setprop("autopilot/locks/heading","wing-leveler");
      setprop("/controls/autoflight/lateral-mode",0);
    }
    if(lnav == 1) {
      print("set lnav == 1");
      ##setprop("/autopilot/internal/true-heading-error-deg",getprop("/autopilot/settings/heading-bug-deg"));
      setprop("autopilot/locks/heading","dg-heading-hold");
      setprop("/controls/autoflight/lateral-mode",1);
    }
    if(lnav == 3) {
      setprop("autopilot/locks/heading","nav1-hold");
      setprop("/controls/autoflight/lateral-mode",2);
    }
    if(lnav == 4) {
      print("set lnav == 4");
      setprop("/autopilot/internal/true-heading-error-deg",getprop("/instrumentation/gps/wp/wp[1]/bearing-true-deg"));
      setprop("autopilot/locks/heading","true-heading-hold");
      setprop("/controls/autoflight/lateral-mode",1);
    }
  }
});

setlistener("/instrumentation/flightdirector/vnav", func(n) {
  vnav = n.getValue();
  if(ap_on==1) {
    if(vnav == 0 or vnav == nil) {
      setprop("autopilot/locks/altitude","");
      setprop("autopilot/settings/target-pitch-deg",0);   ##TODO: double check
      setprop("/controls/autoflight/vertical-mode",0);
    }
    if(vnav == 1) {
      setprop("autopilot/locks/altitude","altitude-hold");
      setprop("/controls/autoflight/vertical-mode",1);
    }
    if(vnav == 2) {
      setprop("autopilot/locks/altitude","vertical-speed-hold");
      setprop("/controls/autoflight/vertical-mode",1);
    }
    if(vnav == 3) {
      setprop("autopilot/locks/speed","climb-hold");
      setprop("/controls/autoflight/vertical-mode",2);
    }
    if(vnav == 7) {
      setprop("/autopilot/settings/target-alt-hold",getprop("/instrumentation/gps/wp/wp[1]/altitude-ft"));
      setprop("autopilot/locks/altitude","altitude-hold");
      setprop("/controls/autoflight/vertical-mode",1);
    }
    if(vnav == 9) {
      if(getprop("/instrumentation/nav/has-gs") != 0) {
        setprop("autopilot/locks/altitude","gs1-hold");
        setprop("/controls/autoflight/vertical-mode",2);
      }
    }
  }
});


setlistener("/autopilot/locks/altitude", func(n) {
    mode = n.getValue();
    vnav = getprop("/instrumentation/flightdirector/vnav");
    print("afs:altitude");
    if(vnav == 0 or vnav == nil or mode == "" or mode == nil) {
      setprop("/controls/autoflight/vertical-mode",0);
    }
    if(mode == "altitude-hold") {
      setprop("/controls/autoflight/vertical-mode",1);
    }
    if(mode == "vertical-speed-hold") {
      setprop("/controls/autoflight/vertical-mode",1);
    }
    if(mode == "climb-hold") {
      setprop("/controls/autoflight/vertical-mode",2);
    }
    if(mode == "gs1-hold") {
      setprop("/controls/autoflight/vertical-mode",2);
    }
    vmode = getprop("/controls/autoflight/vertical-mode");
    print("afs:alt vmode: "~vmode);
});



setlistener("/autopilot/locks/heading", func(n) {
    mode = n.getValue();
    lnav = getprop("/instrumentation/flightdirector/lnav");
    print("afs:heading");
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
    lmode = getprop("/controls/autoflight/lateral-mode");
    print("afs:hdg lmode: "~lmode);
});


handle_inputs = func {
# Autopilot  activate

  if(ap_on==1) {
    maxroll = getprop("/orientation/roll-deg");
    if(maxroll > 45 or maxroll < -45) {
      ap_on = 0;
      setprop("/instrumentation/flightdirector/autopilot-on",ap_on);
    }
    maxpitch = getprop("/orientation/pitch-deg");
    if(maxpitch > 45 or maxpitch < -45){
      ap_on = 0;
      setprop("/instrumentation/flightdirector/autopilot-on",ap_on);
    }
      #if(getprop("/position/altitude-agl-ft") < 50){ap_on = 0;}
  }
}


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
      #print("[update_mode] nav-dist = ", nav_dist, " tth = ", tth);

        tth_filter = 0.9 * tth_filter + 0.1 * tth;
        last_nav_dist = nav_dist;
    }        

    if ( lnav == 2 ) {
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

      #  print("tth = ", tth_filter, " hdgdiff = ", diff, " rollout = ", roll_out_time_sec );
        if ( roll_out_time_sec >= abs(tth_filter) ) {
            # switch from arm to cpld
           # lnav = 3;
        }

    }
    currDetent = getprop("/instrumentation/flightdirector/athr");
    ## FLEX/MCT
    if (currDetent == 2) {

    }
    

#setlistener("/sim/signals/fdm-initialized", func {
#    setprop("/instrumentation/flightdirector/lnav", lnav);
#});
}

#############################################################################
#get pitch from autopilot altitude setting
#############################################################################

get_altpitch = func(){
  #vnav = getprop("/instrumentation/flightdirector/vnav");
  current_pitch = getprop("/orientation/pitch-deg");
  if(vnav == 0) {
    return(current_pitch);
  }
  alt_offset = 0.0;

  if(vnav == 6){
    return(5.0);
  }
  if(vnav == 5){
    return(0.0);
  }
  if(vnav == 4){
    return(0.0);
  }
  if(vnav == 3){return(getprop("/autopilot/settings/vertical-speed-fpm"));
  }
     ###if(vnav == 1){alt_select = getprop("/autopilot/settings/target-alt-hold");} 
  if(vnav == 1) {    #calculation of glideslope altitude for current glideslope distance from NAV1
    #metres to feet
    alt_select=((getprop("/instrumentation/nav/gs-distance")*FD_TAN3DEG) + getprop("/environment/ground-elevation-m"))*3.281;
    # alt_selest = alt_select + getprop("/environment/ground-elevation-m")*3.281;
  }
  if(vnav == 2){alt_select = getprop("/autopilot/settings/target-altitude-ft");
  }
    #if(lnav == 3){test=getprop("/instrumentation/flightdirector/gs-pitch");
    #if(vnav == 1){test=(getprop("/instrumentation/nav/gs-rate-of-climb")-getprop("/instrumentation/vertical-speed-indicator/indicated-speed-fpm"))*0.01;
    #if(test == nil) {test = 0.0;}
    #return(test);
    #}

  if ( alt_select == nil or alt_select == "" ){ 
    alt_select = 0.0;
    return(current_pitch);
  }

  current_alt = getprop("/position/altitude-ft");
  if(current_alt == nil){
    current_alt = 0.0;
  }
  alt_offset = (alt_select-current_alt);
  setprop("/instrumentation/flightdirector/alt-alert",alt_offset);
  if(alt_offset > 500.0) {
    alt_offset = 500.0;
  }
  if(alt_offset < -500.0) {
    alt_offset = -500.0;
  }
  return(alt_offset * 0.012);
}

#############################################################################
#update nav gps or nav setting
#############################################################################

update_nav = func () {
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

}


#############################################################################
# update the FD vbar position for the various modes
#############################################################################

update_vbar = func {
    if ( lnav == 0 ) {
        # wings level maintain pitch at time of mode activation
        if ( lnav_last != 0 ) {
            vbar_roll = 0.0;
           vbar_pitch = getprop("/orientation/pitch-deg");
        }
    } elsif ( lnav == 1) {
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
#        print("diff = ", diff);
    } elsif ( lnav == 3) {
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
    } elsif (lnav == 2) {
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


#setlistener("/sim/signals/fdm-initialized", func {
 setprop("/instrumentation/flightdirector/vbar-pitch",vbar_pitch_prop);
 setprop("/instrumentation/flightdirector/vbar-roll", vbar_roll_prop);
# setprop("/instrumentation/flightdirector/alt-offset", alt_offset);
# setprop("/instrumentation/flightdirector/current-alt", current_alt);
#});
}


setlistener("/instrumentation/flightdirector/athr", func(n) {
  mode = n.getValue();
  if (mode == 0) {
    print("Change A/THR to Idle");
  }
  if (mode == 1) {
    print("Change A/THR to CL");
  }
  if (mode == 2) {
    print("Change A/THR to FLX");
  }
  if (mode == 3) {
    print("Change A/THR to TOGA");
  }
});

#############################################################################
# main update function to be called each frame
#############################################################################

update = func {
    handle_inputs();
    update_mode();
    update_nav();
    update_vbar();
 
    registerTimer();
}



#############################################################################
# Use tha nasal timer to call ourselves every frame
#############################################################################

registerTimer = func {
    settimer(update, 0);
}
registerTimer();
