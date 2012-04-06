exception Symbol_not_found of string;

value default_fps: ref int;

class type virtual c = 
  object
    inherit DisplayObject.c;
    method ccast: [= `Image of Image.c | `Sprite of Sprite.c | `Atlas of Atlas.c | `Clip of Clip.c ];
  end;


type lib;

value load: ?filter:Texture.filter -> ?loadTextures:bool -> string -> lib;
value load_async: ?filter:Texture.filter -> string -> (lib -> unit) -> unit;
value loadxml: ?filter:Texture.filter -> ?loadTextures:bool -> string -> lib;

(*
value image: string -> c;
value image_from_texture : Texture.c -> c;
value image_async: string -> (c -> unit) -> unit;
*)

value release: lib -> unit;

value symbols: lib -> Enum.t string;
value get_symbol: lib -> string -> c;
value get_symbol_async: lib -> string -> (c -> unit) -> unit;
