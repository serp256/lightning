

type glow = 
  {
    glowSize: float;
    glowStrenght:float;
    glowColor: int;
  };

type colorMatrix = Bigarray.Array1.t float Bigarray.float32_elt Bigarray.c_layout;

type t = 
  [= `Glow of glow (* возможно еще третий параметр затухание въебать *)
  | `ColorMatrix of colorMatrix
  ];
