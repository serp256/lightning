

class _c : [ Texture.c ] ->
  object
    inherit DisplayObject.c; 
    value texture: Texture.c;
    method setColor: int -> unit;
    method color: int;
    method setColors: array int -> unit;

    method texFlipX: bool;
    method setTexFlipX: bool -> unit;
    method texFlipY: bool;
    method setTexFlipY: bool -> unit;

    (*
    method texRotation: option [= `left | `right];
    method setTexRotation: option [= `left | `right] -> unit;
    method copyTexCoords: Bigarray.Array1.t float Bigarray.float32_elt Bigarray.c_layout -> unit;
    *)

    method texture: Texture.c;
    method onTextureEvent: Texture.event -> Texture.c -> unit;
    method setTexture: Texture.c -> unit;
    method filters: list Filters.t;
    method setFilters: list Filters.t -> unit;

(*       method setTexScale: float -> unit; *)

    method private render': ?alpha:float -> ~transform:bool -> option Rectangle.t -> unit;
    method boundsInSpace: !'space. option (<asDisplayObject: DisplayObject.c; .. > as 'space) -> Rectangle.t;

  end;

(* value cast: #DisplayObject.c -> option c; *)

class c : [ Texture.c ] ->
  object
    inherit _c;
    method ccast: [= `Image of c ];
  end;

value create: Texture.c -> c;
value load: string -> c;
value load_async: string -> (c -> unit) -> unit;
