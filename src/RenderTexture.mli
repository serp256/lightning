


type framebuffer;

type data = Bigarray.Array2.t int32 Bigarray.int32_elt Bigarray.c_layout;

class type c =
  object
    inherit Texture.c;
    method asTexture: Texture.c;
    method draw: ?clear:(int*float) -> ?width:float -> ?height:float -> (framebuffer -> unit) -> bool;
    method texture: Texture.c;
    method save: string -> bool;
    method data: unit -> data; 
  end;

value draw: ~filter:Texture.filter -> ?color:int -> ?alpha:float -> ?dedicated:bool -> float ->  float -> (framebuffer -> unit) -> c; 
