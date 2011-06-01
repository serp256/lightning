
type t;
value register: string -> unit;
value exists: string -> bool;
value get: string -> t;

module type Creator = sig
  module CompiledSprite: CompiledSprite.S;
  value createText: t -> ~width:float -> ~height:float -> ?size:float -> ~color:int -> ?border:bool -> ?hAlign:LightCommon.halign -> ?vAlign:LightCommon.valign -> string -> CompiledSprite.c;
end;

module MakeCreator(Image:Image.S)(CompiledSprite:CompiledSprite.S with module Sprite.D = Image.Q.D): Creator with module CompiledSprite = CompiledSprite;
