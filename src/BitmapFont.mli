
type bc = 
  {
    charID:int;
    xOffset:float;
    yOffset:float;
    xAdvance: float;
    atlasNode: AtlasNode.t;
  };

type t = 
  {
    chars: Hashtbl.t int bc;
    scale: float;
    ascender: float;
    descender: float;
    lineHeight: float;
    space:float;
    texture: Texture.c;
    isDynamic: bool;
  };

(* value register: string -> unit; *)
value register: string -> unit;
value registerXML: string -> unit;
value exists: ?style:string -> string -> bool;
value get: ?applyScale:bool -> ?style:string -> ?size:int -> string -> t;

value registerDynamic: list int -> string  -> (string * string);
value registerSystemFont: ?scale:float -> ?stroke:int -> list int -> (string * string);
value getBitmapChar: (string * string * int) -> int -> option (bc * float * float * float);
value dynamicFontComplete: unit -> unit;
value getSystemFonts: unit -> string;
value show: unit -> Image.c;
(*
module type Creator = sig
  module Sprite: Sprite.S;
  value createText: t -> ~width:float -> ~height:float -> ~color:int -> ?border:bool -> ?hAlign:LightCommon.halign -> ?vAlign:LightCommon.valign -> string -> Sprite.c;
end;

module MakeCreator(Image:Image.S)(Sprite:Sprite.S with module D = Image.D): Creator with module Sprite = Sprite;
*)
