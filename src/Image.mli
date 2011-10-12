
module type S = sig

  module D : DisplayObjectT.M;

  class c : [ Texture.c ] ->
    object
      inherit D.c; 
      value texture: Texture.c;
      (*
      method texFlipX: bool;
      method setTexFlipX: bool -> unit;
      method texFlipY: bool;
      method setTexFlipY: bool -> unit;
      method texRotation: option [= `left | `right];
      method setTexRotation: option [= `left | `right] -> unit;
      method copyTexCoords: Bigarray.Array1.t float Bigarray.float32_elt Bigarray.c_layout -> unit;
      *)
      method texture: Texture.c;
(*       method setTexture: Texture.c -> unit; *)
(*       method setTexScale: float -> unit; *)
      method private render': option Rectangle.t -> unit;
      method boundsInSpace: !'space. option (<asDisplayObject: D.c; .. > as 'space) -> Rectangle.t;
    end;

  value cast: #D.c -> option c;

  value load: string -> c;
  value create: Texture.c -> c;
end;

module Make(D:DisplayObjectT.M) : S with module D = D;
