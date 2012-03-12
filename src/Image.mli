
module type S = sig

  module D : DisplayObjectT.S;

  class c : [ Texture.c ] ->
    object
      inherit D.c; 
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
(*       method updateSize: unit -> unit; *)
      method onTextureEvent: Texture.event -> Texture.c -> unit;
      method setTexture: Texture.c -> unit;
      method filters: list Filters.t;
      method setFilters: list Filters.t -> unit;

(*       method setTexScale: float -> unit; *)

      method private render': ?alpha:float -> ~transform:bool -> option Rectangle.t -> unit;
      method boundsInSpace: !'space. option (<asDisplayObject: D.c; .. > as 'space) -> Rectangle.t;

    end;

  value cast: #D.c -> option c;

  value load: string -> c;
  value create: Texture.c -> c;
end;

module Make(D:DisplayObjectT.S) : S with module D = D;
