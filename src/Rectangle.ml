
type t = {x:float; y:float; width:float; height:float;};
type tm = {m_x:mutable float; m_y: mutable float; m_width: mutable float; m_height: mutable float };
value empty = {x=0.;y=0.;width=0.;height=0.};
value create x y width height = {x;y;width;height};

value tm_of_t r = {m_x=r.x;m_y=r.y;m_width=r.width;m_height=r.height};
value create_tm x y width height = {m_x=x;m_y=y;m_width=width;m_height=height};
value empty_tm () = tm_of_t empty;

value containsPoint rect {Point.x=x;y=y} = 
  x >= rect.x && y >= rect.y && x <= rect.x +. rect.width && y <= rect.y +. rect.height;

value points r = [| {Point.x=r.x;y=r.y} ; {Point.x=r.x; y=r.y +. r.height}; {Point.x = r.x +. r.width; y = r.y}; {Point.x = r.x +. r.width; y = r.y +. r.height} |];

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

value join r1 r2 =
  let xr1 = r1.x +. r2.width
  and yr1 = r1.y +. r1.height
  and xr2 = r2.x +. r2.width
  and yr2 = r2.y +. r2.height
  in
  let xr = max xr1 xr2
  and yr = max yr1 yr2
  and x = min r1.x r2.x
  and y = min r1.y r2.y
  in
  {x;y;width=xr-.x;height=yr-.y};


value to_ints r = (int_of_float r.x, int_of_float r.y, int_of_float r.width, int_of_float r.height);
value to_string {x=x;y=y;width=width;height=height} = Printf.sprintf "[x=%f,y=%f,width=%f,height=%f]" x y width height;
value offset rect dx dy = {(rect) with x = rect.x +. dx; y = rect.x +. dy};  

value isEmpty rect = (rect.width = 0.) || (rect.height = 0.);
value inside inner outer = (outer.x <= inner.x) && (outer.y <= inner.y)
  && (inner.x +. inner.width <= outer.x +. outer.width) && (inner.y +. inner.height <= outer.y +. outer.height);
value cutOut from rect =
  let (from, rect) = if inside rect from then (from, rect) else (rect, from)
  and checkRect rects rect = if isEmpty rect then rects else [ rect :: rects] in
    List.fold_left checkRect [] [
      create from.x from.y (rect.x -. from.x) from.height;
      create rect.x from.y rect.width (rect.y -. from.y);
      create rect.x (rect.y +. rect.height) rect.width (from.y +. from.height -. rect.y -. rect.height);
      create (rect.x +. rect.width) from.y (from.x +. from.width -. rect.x -. rect.width) from.height
    ];
