


type framebuffer;


class type c =
  object
    inherit Texture.c;
    method draw: ?clear:(int*float) -> ?width:float -> ?height:float -> (framebuffer -> unit) -> bool;
    method texture: Texture.c;
    method save: string -> bool;
  end;

value draw: ~filter:Texture.filter -> ?color:int -> ?alpha:float -> float ->  float -> (framebuffer -> unit) -> c; 
