FROM ubuntu:latest
RUN apt update && apt install -y flightgear
RUN apt update && apt install -y xvfb
RUN apt update && apt install -y build-essential libxml2-dev

COPY fg_connector_linux /fgcl
RUN cd /fgcl && make

COPY A380 /usr/share/games/flightgear/Aircraft/

RUN apt update && apt install -y socat iproute2 binutils strace net-tools

CMD (DBUS_FATAL_WARNINGS=0 xvfb-run /usr/games/fgfs --aircraft=A380 --altitude=13337 --mach=0.8 --wp=LSZH --wp=ZBAA --prop:autopilot/settings/target-altitude-ft=31337 --prop:autopilot/settings/target-speed-kt=500 --prop:/autopilot/locks/altitude=altitude-hold --prop:/autopilot/locks/speed=speed-with-throttle --prop:/autopilot/route-manager/airborne=true --prop:/autopilot/route-manager/active=true --prop:/controls/gear/gear-down=0 --prop:/autopilot/locks/heading=true-heading-hold --prop:/autopilot/settings/true-heading-deg=0 --prop:/autopilot/route-manager/airborne=true --prop:/autopilot/route-manager/active=true --disable-real-weather-fetch --metar=SKC --prop:/engines/engine[0]/running=1 --prop:/engines/engine[1]/running=1 --prop:/engines/engine[2]/running=1 --prop:/engines/engine[3]/running=1 --prop:/consumables/fuel/tank[0]/level-gal_us=7179 --prop:/consumables/fuel/tank[3]/level-gal_us=7179 --prop:/consumables/fuel/tank[1]/level-gal_us=7534 --prop:/consumables/fuel/tank[2]/level-gal_us=7534 --prop:/consumables/fuel/tank[4]/level-gal_us=11847  --prop:/consumables/fuel/tank[5]/level-gal_us=11847 --prop:/consumables/fuel/tank[6]/level-gal_us=9362 --prop:/consumables/fuel/tank[7]/level-gal_us=9362 --prop:/consumables/fuel/tank[8]/level-gal_us=2700 --prop:/consumables/fuel/tank[9]/level-gal_us=2700 --prop:/consumables/fuel/tank[10]/level-gal_us=6082 --prop:/fdm/jsbsim/inertia/pointmass-weight-lbs[3]=0  --prop:/fdm/jsbsim/inertia/pointmass-weight-lbs[4]=0 --prop:/fdm/jsbsim/inertia/pointmass-weight-lbs[5]=0 --disable-sound --disable-splash-screen --generic=socket,out,30,127.0.0.1,8000,udp,playback --enable-fuel-freeze --random-wind --turbulence=1 &); (LD_LIBRARY_PATH=/fgcl/lib/linux-x86_64/shared strace /fgcl/fg_receiver -v /fgcl/conf/fgc.xml);
