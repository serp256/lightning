
type bc = 
  {
    charID:int;
    xOffset:float;
    yOffset:float;
    xAdvance: float;
    charTexture: Texture.c;
  };

type t = 
  {
(*     texture: Texture.c; *)
    chars: Hashtbl.t int bc;
(*     name: string; *)
    scale: float;
    baseLine: float;
    lineHeight: float;
  };
value register: string -> unit;
value registern: string -> unit;
value exists: string -> bool;
value get: ?applyScale:bool -> ?size:int -> string -> t;

module type Creator = sig
  module Sprite: Sprite.S;
  value createText: t -> ~width:float -> ~height:float -> ~color:int -> ?border:bool -> ?hAlign:LightCommon.halign -> ?vAlign:LightCommon.valign -> string -> Sprite.c;
end;

module MakeCreator(Image:Image.S)(Sprite:Sprite.S with module D = Image.D): Creator with module Sprite = Sprite;
