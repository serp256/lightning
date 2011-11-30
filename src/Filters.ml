

type glow = 
  {
    glowSize: int;
    glowStrenght:float;
    glowColor: int;
  };


value glow ?(size=1.) ?(strenght=0.5) color = `Glow {glowSize=size;glowStrenght=strenght;glowColor=color};

type colorMatrix = Bigarray.Array1.t float Bigarray.float32_elt Bigarray.c_layout;

type t = 
  [= `Glow of glow 
  | `ColorMatrix of colorMatrix
  ];
