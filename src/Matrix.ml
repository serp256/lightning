
DEFINE W = 1.;
DEFINE SIGN(x) = if x < 0. then ~-.1. else 1.;

type t = { a:float; b:float; c:float; d: float; tx: float; ty: float};

value identity = {a=1.0;b=0.;c=0.;d=1.;tx=0.;ty=0.};

value create ?(rotation=0.) ?(scale=(1.,1.)) ?(translate=(0.,0.)) () : t = 
  let (tx,ty) = translate in 
  let ar = [| 1.; 0.; 0.; 1.; tx; ty |] in
  (
    if rotation <> 0.0 
    then 
      let c = cos(rotation)
      and s = sin(rotation) in
      (
        ar.(0) := c;
        ar.(1) := s;
        ar.(2) := ~-.s;
        ar.(3) := c;
      )
    else ();
    let (sx,sy) = scale in
    if sx <> 1.0 || sy <> 1.0 
    then
    (
      ar.(0) := ar.(0) *. sx;
      ar.(1) := ar.(1) *. sy;
      ar.(2) := ar.(2) *. sx;
      ar.(3) := ar.(3) *. sy;
    )
    else ();
    Obj.magic ar;
  );

value scale m (sx,sy) = 
  {
    a = m.a *. sx;
    b = m.b *. sy;
    c = m.c *. sx;
    d = m.d *. sy;
    tx = m.tx *. sx;
    ty = m.ty *. sy;
  };

value concat m1 m2 =
  {
    a = m2.a *. m1.a +. m2.c *. m1.b;
    b = m2.b *. m1.a +. m2.d *. m1.b;
    c = m2.a *. m1.c +. m2.c *. m1.d;
    d = m2.b *. m1.c +. m2.d *. m1.d;
    tx = m2.a *. m1.tx +. m2.c *. m1.ty +. m2.tx; 
    ty = m2.b *. m1.tx +. m2.d *. m1.ty +. m2.ty;
  };

value rotate m angle = 
  let c = cos(angle)
  and s = sin(angle)
  in
  let rotm = { a = c; b = s; c = ~-.s; d = c ; tx = 0.; ty = 0. } in
  concat m rotm;

value translate m (dx,dy) = 
  { (m) with
    tx = m.tx +. dx;
    ty = m.ty +. dy;
  };

value transformPoint m (x,y) = 
  (
    m.a*.x +. m.c*.y +. m.tx,
    m.b*.x +. m.d*.y +. m.ty
  );


value transformPoints matrix points = 
  let ar = [| max_float; ~-.max_float; max_float; ~-.max_float |] in
  (
    for i = 0 to (Array.length points) - 1 do
      let p = points.(i) in
      let (tx,ty) = transformPoint matrix p in
      (
        if ar.(0) > tx then ar.(0) := tx else ();
        if ar.(1) < tx then ar.(1) := tx else ();
        if ar.(2) > ty then ar.(2) := ty else ();
        if ar.(3) < ty then ar.(3) := ty else ();
      )
    done;
    ar
  );
  

value transformRectangle m rect = 
  let points = Rectangle.points rect in
  let ar = [| max_float; ~-.max_float; max_float; ~-.max_float |] in
  (
    for i = 0 to 3 do
      let p = points.(i) in
      let (tx,ty) = transformPoint m p in
      (
        if ar.(0) > tx then ar.(0) := tx else ();
        if ar.(1) < tx then ar.(1) := tx else ();
        if ar.(2) > ty then ar.(2) := ty else ();
        if ar.(3) < ty then ar.(3) := ty else ();
      )
    done;
    Rectangle.create ar.(0) ar.(2) (ar.(1) -. ar.(0)) (ar.(3) -. ar.(2));
  );

value determinant m = m.a *. m.d -. m.c *. m.b;

value invert m = 
  let det = determinant m in
  {
    a = m.d/.det;
    b = ~-.(m.b/.det);
    c = ~-.(m.c/.det);
    d = m.a/.det;
    tx = (m.c*.m.ty-.m.d*.m.tx)/.det;
    ty = (m.b*.m.tx-.m.a*.m.ty)/.det
  };

value scaleX m = SIGN(m.a) *. sqrt(m.a *. m.a +. m.b *. m.b);
value scaleY m = SIGN(m.d) *. sqrt(m.c *. m.c +. m.d *. m.d);
value rotation m = atan2 m.b m.a;

value to_string m = Printf.sprintf "[a:%f,b:%f,c:%f,d:%f,tx:%f,ty:%f]" m.a m.b m.c m.d m.tx m.ty;




