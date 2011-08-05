DEFINE SQ(x) = x *. x;
DEFINE SP_FLOAT_EPSILON = 0.0001;
DEFINE SP_IS_FLOAT_EQUAL(f1, f2) = abs_float(f1-.f2) < SP_FLOAT_EPSILON;

type t = (float*float);
value length (x,y) = sqrt(SQ(x) +. SQ(y));
value angle (x,y) =  atan2 y x;
value addPoint (x1,y1) (x2,y2) = (x1+.x2,y1+.y2);
value subtractPoint (x1,y1) (x2,y2) = (x1-.x2,y1-.y2);
value scaleBy (x,y) scalar = (x*.scalar,y*.scalar);
value mul (x,y) k = (x*.k,y*.k);
value div (x,y) k = (x/.k,y/.k);
value normalize ((x,y) as p) = 
  match (x,y) with
  [ (0.,0.) -> raise (Invalid_argument "Point normalize")
  | _ -> 
      let inverseLength = 1.0 /. (length p) in
      (x *. inverseLength, y *. inverseLength)
  ];


value isEqual (x1,y1) (x2,y2) = SP_IS_FLOAT_EQUAL(x1, x2) && SP_IS_FLOAT_EQUAL(y1, y2);

value description (x,y) = Printf.sprintf "(x=%f, y=%f)" x y;
value distanceFromPoint (x1,y1) (x2,y2) = sqrt(SQ(x2 -. x1) +. SQ(y2 -. y1));
value intrepolateFromPoint (x1,y1) (x2,y2) ratio = 
  let invRatio = 1.0 -. ratio in
  (invRatio *. x1 +. ratio *. x2, invRatio *. y1 +. ratio *. y2);

value to_string (x,y) = Printf.sprintf "[%f:%f]" x y;
