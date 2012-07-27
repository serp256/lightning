DEFINE SQ(x) = x *. x;
DEFINE SP_FLOAT_EPSILON = 0.0001;
DEFINE SP_IS_FLOAT_EQUAL(f1, f2) = abs_float(f1-.f2) < SP_FLOAT_EPSILON;

type t = {x:float;y:float};
value empty = {x=0.;y=0.};
value length {x=x;y=y} = sqrt(SQ(x) +. SQ(y));
value angle {x=x;y=y} =  atan2 y x;
value addPoint {x=x1;y=y1} {x=x2;y=y2} = {x=x1+.x2;y=y1+.y2};
value subtractPoint {x=x1;y=y1} {x=x2;y=y2} = {x=x1-.x2;y=y1-.y2};
value scaleBy {x=x;y=y} scalar = {x=x*.scalar;y=y*.scalar};
value mul {x=x;y=y} k = {x=x*.k;y=y*.k};
value div {x=x;y=y} k = {x=x/.k;y=y/.k};
value normalize ({x=x;y=y} as p) = 
  match p with
  [ {x=0.;y=0.} -> raise (Invalid_argument "Point normalize")
  | _ -> 
      let inverseLength = 1.0 /. (length p) in
      {x= x *. inverseLength; y = y *. inverseLength}
  ];


value isEqual {x=x1;y=y1} {x=x2;y=y2} = SP_IS_FLOAT_EQUAL(x1, x2) && SP_IS_FLOAT_EQUAL(y1, y2);

value description {x=x;y=y} = Printf.sprintf "(x=%f, y=%f)" x y;
value distanceFromPoint {x=x1;y=y1} {x=x2;y=y2} = sqrt(SQ(x2 -. x1) +. SQ(y2 -. y1));
(*
value intrepolateFromPoint (x1,y1) (x2,y2) ratio = 
  let invRatio = 1.0 -. ratio in
  (invRatio *. x1 +. ratio *. x2, invRatio *. y1 +. ratio *. y2);
*)

value to_string {x=x;y=y} = Printf.sprintf "[%f:%f]" x y;
value create x y = { x = x; y = y };