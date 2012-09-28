


type framebuffer;


class type c =
  object
    inherit Texture.c;
    method draw: ?clear:(int*float) -> ?width:float -> ?height:float -> (framebuffer -> unit) -> bool;
  end;

value draw: ~filter:Texture.filter -> ?color:int -> ?alpha:float -> float ->  float -> (framebuffer -> unit) -> c; 
