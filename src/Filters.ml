

type glow = 
  {
    glowSize: float;
    glowStrenght:float;
    glowColor: int;
  };

type t = 
  [= `Glow of glow (* возможно еще третий параметр затухание въебать *)
  | `ColorMatrix of (Bigarray.Array2.t Bigarray.float32_elt float Bigarray.c_layout)
  ];
