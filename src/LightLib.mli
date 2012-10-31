exception Symbol_not_found of string;

value default_fps: ref int;

class type virtual c = 
  object
    inherit DisplayObject.c;
    method ccast: [= `Image of Image.c | `Sprite of Sprite.c | `Atlas of Atlas.c | `Clip of Clip.c ];
  end;

type img = (int * Rectangle.t);
type child = (Rectangle.t * option string * Point.t); 
type bchildren = [ CBox of (string * Point.t) | CImage of (img * option string * Point.t) | CAtlas of (int * list child) ];
type children = list child;
type clipcmd = 
  [ ClpPlace of (int * Rectangle.t * option string * Point.t) 
  | ClpClear of (int * int) 
  | ClpChange of (int * list [= `posX of float | `posY of float | `move of int]) 
  ];

type frame = (children * option (list clipcmd)); 
type iframe = 
  {
    hotpos: Point.t;
    image: (int * Rectangle.t);
  };
type element = 
  [ Image of img
  | Sprite of list bchildren
  | Atlas of (int * list child)
  | Clip of (int * (array (Clip.cFrame frame)) * Clip.labels)
  | ImageClip of ((array (Clip.cFrame iframe)) * Clip.labels)
  ];

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

(* value get_symbol_data: lib -> string -> element; *)
