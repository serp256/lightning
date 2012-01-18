

type glow = 
  {
    glowSize: int;
    glowColor: int;
    glowStrength:int;
  };


value glow ?(size=2) ?(strength=2) color = `Glow {glowSize=size;glowStrength=strength;glowColor=color};

type colorMatrix = Bigarray.Array1.t float Bigarray.float32_elt Bigarray.c_layout;

type t = 
  [= `Glow of glow 
  | `ColorMatrix of colorMatrix
  ];
