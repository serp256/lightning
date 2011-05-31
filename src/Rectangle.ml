
type t = {x:mutable float; y:mutable float; width:mutable float; height:mutable float;};
value empty () = {x=0.;y=0.;width=0.;height=0.};
value create x y width height = {x;y;width;height};
value copy r = {x=r.x;y=r.y;width=r.width;height=r.height};
value containsPoint rect (x,y) = 
  x >= rect.x && y >= rect.y && x <= rect.x +. rect.width && y <= rect.y +. rect.height;


value intersection rect1 rect2 = 
  let left = max rect1.x rect2.x
  and right = min (rect1.x +. rect1.width) (rect2.x +. rect2.width) in
  if left > right
  then None
  else
    let top = max rect1.y rect2.y
    and bottom = min (rect1.y +. rect1.height) (rect2.y +. rect2.height) in
    if top > bottom
    then None
    else
      Some (create left top (right -. left) (bottom -. top))
;
  


value to_ints r = (int_of_float r.x, int_of_float r.y, int_of_float r.width, int_of_float r.height);
value to_string {x=x;y=y;width=width;height=height} = Printf.sprintf "[x=%f,y=%f,width=%f,height=%f]" x y width height;
