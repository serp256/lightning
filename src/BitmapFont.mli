
type t;
value register: string -> unit;
value exists: string -> bool;
value get: string -> t;


module Make(D:DisplayObjectT.M): sig
  value createText: t -> ~width:float -> ~height:float -> ?size:float -> ~color:int -> ?border:bool -> ?hAlign:LightCommon.halign -> ?vAlign:LightCommon.valign -> string -> (Sprite.Make(D)).c;
end;
