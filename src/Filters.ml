type glowKind = [= `linear | `soft ];

type glow = 
  {
    glowSize: int;
    glowColor: int;
    glowStrength:float;
    glowKind: glowKind;
    x:int;
    y:int;
  };

value glow ?(kind=`linear) ?(size=2) ?(strength=1.) color = `Glow {glowKind=kind;glowSize=size;glowStrength=strength;glowColor=color;x=0;y=0};
value shadow ?(x = 0) ?(y = 0) ?(kind=`linear) ?(size=2) ?(strength=1.) color = `Glow {glowKind=kind;glowSize=size;glowStrength=strength;glowColor=color;x;y};

type colorMatrix; (* = Bigarray.Array1.t float Bigarray.float32_elt Bigarray.c_layout; *)

external colorMatrix: array float -> Render.filter = "ml_filter_cmatrix";
value colorMatrix matrix = `ColorMatrix (colorMatrix matrix);

type t = 
  [= `Glow of glow
  | `ColorMatrix of Render.filter
  ];

value string_of_t = fun
  [ `Glow g -> Printf.sprintf "glow [%d:%d:%f]" g.glowSize g.glowColor g.glowStrength
  | `ColorMatrix c -> "color matrix"
  ];
