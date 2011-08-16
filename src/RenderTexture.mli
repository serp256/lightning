
class type renderObject =
  object
    method render: option Rectangle.t -> unit;
    method transformGLMatrix: unit -> unit;
  end;

value create: ?color:int -> ?alpha:float -> ?scale:float -> float -> float ->
  <
    texture: Texture.c;
    drawObject: !'ro. (#renderObject as 'ro) -> unit;
    clear: int -> float -> unit;
  >;
