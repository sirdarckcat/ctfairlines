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

  if(lnav == LNAV_FMS) {#in LNAV mode only
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
      lur_m = turn_radius_m*(math.sin(diff)/math.cos(diff))+TRK_M;#in metres
#  lur_m = turn_radius_m*(math.sin(diff)/math.cos(diff));#in metres
      lur_nm = lur_m/1852;
      setprop("/instrumentation/flightdirector/turn-distance-m", lur_m);
      setprop("/instrumentation/flightdirector/turn-distance-nm", lur_nm);
  
      turn_dist = getprop("/autopilot/route-manager/wp/dist");
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
      trk_lock_range = TRK_M/1852;#lock range = +-200 meters
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
      if(trk_on==1) {   #in this mode standart FG autopilot not working - we pop waypoint always
        if(lur_m < 50000) {
          if( (turn_dist != 0) and (turn_dist <= lur_nm) ) { #turn distance - begin turn
            ##print("Begin turn -> lur_m="~lur_m~" lur_nm ="~lur_nm~" dist="~getprop("/autopilot/route-manager/wp/dist"));
            complete_turn = 1;
            setprop("/autopilot/route-manager/input", "@pop");
            trk_lck_mode=0;  #next leg - reset track mode
          }
        }
      } else {
        if(lur_m > 200 and lur_m < 50000) {   #blocking standart FG autopilot - it pop waypoint if distance to waypoint <= 200 meters
          if( (turn_dist != 0) and (turn_dist <= lur_nm) ) {#turn distance - begin turn
            ###print("Begin turn -> lur_m="~lur_m~" lur_nm ="~lur_nm~" dist="~getprop("/autopilot/route-manager/wp/dist"));
            complete_turn = 1;
            setprop("/autopilot/route-manager/input", "@pop");
          }
        }
      }
    }
  }
};

