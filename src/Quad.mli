
value gl_quad_colors: Bigarray.Array1.t int32 Bigarray.int32_elt Bigarray.c_layout;

module Make(D:DisplayObjectT.M) : sig

  class c: [ ?color:int] -> [ float ] -> [ float ] ->
    object
      inherit D.c; 
      value vertexColors: array int;
      value vertexCoords: Bigarray.Array1.t float Bigarray.float32_elt Bigarray.c_layout;
      method copyVertexCoords: Bigarray.Array1.t float Bigarray.float32_elt Bigarray.c_layout -> unit;
      method setColor: int -> unit;
      method color: int;
      method vertexColors: Enum.t int;
      method boundsInSpace: option D.c -> Rectangle.t;
      method private render': unit -> unit;
    end;

  value cast: #D.c -> option c; 
  value create: ?color:int -> float -> float -> c;
end;
