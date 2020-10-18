togglereverser = func {
  r1 = "/fdm/jsbsim/propulsion/engine[1]";
  r2 = "/fdm/jsbsim/propulsion/engine[2]";
  r3 = "/controls/engines/engine[1]"; 
  r4 = "/controls/engines/engine[2]"; 
  r5 = "/sim/input/selected";
  rv1 = "/engines/engine[1]/reverser-pos-norm"; 
  rv2 = "/engines/engine[2]/reverser-pos-norm"; 

  val = getprop(rv1);
  if (val == 0 or val == nil) {
    interpolate(rv1, 1.0, 1.4); 
    interpolate(rv2, 1.0, 1.4);  
    setprop(r1,"reverser-angle-rad","180");
    setprop(r2,"reverser-angle-rad","180");
    setprop(r3,"reverser", "true");
    setprop(r4,"reverser", "true");
    setprop(r5,"engine[0]", "false");
    setprop(r5,"engine[1]", "true");
    setprop(r5,"engine[2]", "true");
    setprop(r5,"engine[3]", "false");
  } else {
    if (val == 1.0){
      interpolate(rv1, 0.0, 1.4);
      interpolate(rv2, 0.0, 1.4);   
      setprop(r1,"reverser-angle-rad",0);
      setprop(r2,"reverser-angle-rad",0);
      setprop(r3,"reverser",0);
      setprop(r4,"reverser",0);
      setprop(r5,"engine[0]", "true");
      setprop(r5,"engine[1]", "true");
      setprop(r5,"engine[2]", "true");
      setprop(r5,"engine[3]", "true");
    }
  }
}
