
module Make(D:DisplayObjectT.M): sig

  class c : [ Texture.c ] ->
    object
      inherit (Quad.Make(D)).c; 
      value texture: Texture.c;
      method copyTexCoords: Bigarray.Array1.t float Bigarray.float32_elt Bigarray.c_layout -> unit;
      method texture: Texture.c;
      method setTexture: Texture.c -> unit;
    end;

  value cast: #D.c -> option c;

  value createFromFile: string -> c;
  value create: Texture.c -> c;

end;
