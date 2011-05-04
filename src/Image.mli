
module Make(D:DisplayObjectT.M): sig

class c : [ Texture.c ] ->
  object
    inherit (Quad.Make(D)).c; 
    method copyTexCoords: Bigarray.Array1.t float Bigarray.float32_elt Bigarray.c_layout -> unit;
    method texture: Texture.c;
    method setTexture: Texture.c -> unit;
  end;

(* value cast: #DisplayObject.c 'event_type 'event_data -> option (c 'event_type 'event_data); *)

value createFromFile: string -> c;
value create: Texture.c -> c;

end;
