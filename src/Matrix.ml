
DEFINE W = 1.;
type t = { a:mutable float; b:mutable float; c:mutable float; d: mutable float; tx: mutable float; ty: mutable float};
value create () = {a=1.0;b=0.;c=0.;d=1.;tx=0.;ty=0.};
value scaleByXY m sx sy = 
(
  m.a := m.a *. sx;
  m.b := m.b *. sy;
  m.c := m.c *. sx;
  m.d := m.d *. sy;
  m.tx := m.tx *. sx;
  m.ty := m.ty *. sy;
);

value concat m matrix =
  let (a,b,c,d,tx,ty) = (m.a,m.b,m.c,m.d,m.tx,m.ty) in
  (
    m.a := matrix.a *. a +. matrix.c *. b;
    m.b := matrix.b *. a +. matrix.d *. b;
    m.c := matrix.a *. c +. matrix.c *. d;
    m.d := matrix.b *. c +. matrix.d *. d;
    m.tx := matrix.a *. tx +. matrix.c *. ty +. matrix.tx *. W;
    m.ty := matrix.b *. tx +. matrix.d *. ty +. matrix.ty *. W;
  );

value rotate m angle = 
  let c = cos(angle)
  and s = sin(angle)
  in
  let rotm = { a = c; b = s; c = ~-.s; d = c ; tx = 0.; ty = 0. } in
  concat m rotm;

value translateByXY m dx dy = 
(
  m.tx := m.tx +. dx;
  m.ty := m.ty +. dy;
);

value transformPoint m (x,y) = 
(
  m.a*.x +. m.c*.y +. m.tx,
  m.b*.x +. m.d*.y +. m.ty
);

(* value identity () = {a=1.0; b = 0.0; c=0.0; d=1.0; tx=0.0; ty=0.0}; *)

value determinant m = m.a *. m.d -. m.c *. m.b;

value invert m = 
  let det = determinant m in
  let a = m.d/.det
  and b = ~-.(m.b/.det)
  and c = ~-.(m.c/.det)
  and d = m.a/.det
  and tx = (m.c*.m.ty-.m.d*.m.tx)/.det
  and ty = (m.b*.m.tx-.m.a*.m.ty)/.det
  in
  ( m.a :=  a; m.b := b; m.c := c; m.d := d; m.tx := tx; m.ty := ty);

value to_string m = Printf.sprintf "[a:%f,b:%f,c:%f,d:%f,tx:%f,ty:%f]" m.a m.b m.c m.d m.tx m.ty;
