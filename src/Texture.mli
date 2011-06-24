
class type c = 
  object
    method width: float;
    method height: float;
    method hasPremultipliedAlpha:bool;
    method scale: float;
    method textureID: int;
    method base : option (c * Rectangle.t);
    method adjustTextureCoordinates: Gl.float_array -> unit;
  end;


value load: string -> c;
value createSubTexture: Rectangle.t -> c -> c;
