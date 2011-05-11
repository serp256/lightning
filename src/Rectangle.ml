
type t = {x:mutable float; y:mutable float; width:mutable float; height:mutable float;};
value create x y width height = {x;y;width;height};
value copy r = {x=r.x;y=r.y;width=r.width;height=r.height};
value containsPoint rect (x,y) = 
  x >= rect.x && y >= rect.y && x <= rect.x +. rect.width && y <= rect.y +. rect.height;


value to_ints r = (int_of_float r.x, int_of_float r.y, int_of_float r.width, int_of_float r.height);
value to_string {x=x;y=y;width=width;height=height} = Printf.sprintf "[x=%f,y=%f,width=%f,height=%f]" x y width height;
