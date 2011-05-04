
module Make(D:DisplayObjectT.M): sig

class c :  [ ?fontName:string ] -> [ ?fontSize:float ] -> [ ?color:int ] -> [ ~width:float ] -> [ ~height:float ] -> [ string ] ->
  object
    inherit D.container;
    method setText: string -> unit;
    method setFontName: string -> unit;
    method setFontSize: option float -> unit;
    method setBorder: bool -> unit;
    method setColor: int -> unit;
    method setHAlign: LightCommon.halign -> unit;
    method setVAlign: LightCommon.valign -> unit;
    method textBounds: Rectangle.t;
  end;


  value create: ?fontName:string -> ?fontSize:float -> ?color:int -> ~width:float -> ~height:float -> string -> c;
end;
