

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

value string_of_t = fun
  [ `Glow g -> Printf.sprintf "glow [%d:%d:%d]" g.glowSize g.glowColor g.glowStrength
  | `ColorMatrix c -> "color matrix"
  ];
