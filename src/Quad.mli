
value gl_quad_colors: Bigarray.Array1.t int32 Bigarray.int32_elt Bigarray.c_layout;

class c ['event_type,'event_data ]: [ ?color:int] -> [ float ] -> [ float ] ->
  object
    inherit DisplayObject.c ['event_type,'event_data ];
    value vertexColors: array int;
    value vertexCoords: Bigarray.Array1.t float Bigarray.float32_elt Bigarray.c_layout;
    method copyVertexCoords: Bigarray.Array1.t float Bigarray.float32_elt Bigarray.c_layout -> unit;
    method setColor: int -> unit;
    method color: int;
    method vertexColors: Enum.t int;
    method boundsInSpace: option (DisplayObject.c _ _ ) -> Rectangle.t;
    method render: unit -> unit;
  end;

value cast: #DisplayObject.c 'event_type 'event_data -> option (c 'event_type 'event_data);
value create: ?color:int -> float -> float -> c 'event_type 'event_data;
