
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
    chars: Hashtbl.t int bc;
    scale: float;
    baseLine: float;
    lineHeight: float;
    space:float;
  };
value register: string -> unit;
value registern: string -> unit;
value exists: string -> bool;
value get: ?applyScale:bool -> ?size:int -> string -> t;

module type Creator = sig
  module CompiledSprite: CompiledSprite.S;
  value createText: t -> ~width:float -> ~height:float -> ~color:int -> ?border:bool -> ?hAlign:LightCommon.halign -> ?vAlign:LightCommon.valign -> string -> CompiledSprite.c;
end;

module MakeCreator(Image:Image.S)(CompiledSprite:CompiledSprite.S with module Sprite.D = Image.Q.D): Creator with module CompiledSprite = CompiledSprite;
