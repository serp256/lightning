

type glow = 
  {
    glowSize: int;
    glowColor: int;
    glowStrength:float;
    glowKind: [= `linear | `soft ];
  };


value glow ?(kind=`linear) ?(size=2) ?(strength=1.) color = `Glow {glowKind=kind;glowSize=size;glowStrength=strength;glowColor=color};

type colorMatrix = Bigarray.Array1.t float Bigarray.float32_elt Bigarray.c_layout;

type t = 
  [= `Glow of glow 
  | `ColorMatrix of colorMatrix
  ];

value string_of_t = fun
  [ `Glow g -> Printf.sprintf "glow [%d:%d:%f]" g.glowSize g.glowColor g.glowStrength
  | `ColorMatrix c -> "color matrix"
  ];
