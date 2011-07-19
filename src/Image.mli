
module type S = sig

  module Q: Quad.S;

  class c : [ Texture.c ] ->
    object
      inherit Q.c; 
      value texture: Texture.c;
      method flipX: bool;
      method setFlipX: bool -> unit;
      method copyTexCoords: Bigarray.Array1.t float Bigarray.float32_elt Bigarray.c_layout -> unit;
      method texture: Texture.c;
      method setTexture: Texture.c -> unit;
    end;

  value cast: #Q.D.c -> option c;

  value load: string -> c;
  value create: Texture.c -> c;
end;

module Make(Q:Quad.S) : S with module Q = Q;
