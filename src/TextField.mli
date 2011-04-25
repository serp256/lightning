

class c [ 'event_type, 'event_data ]:  [ ?fontName:string ] -> [ ?fontSize:float ] -> [ ?color:int ] -> [ ~width:float ] -> [ ~height:float ] -> [ string ] ->
  object
    inherit DisplayObject.container ['event_type,'event_data];
    method setText: string -> unit;
    method setFontName: string -> unit;
    method setFontSize: option float -> unit;
    method setBorder: bool -> unit;
    method setColor: int -> unit;
    method setHAlign: LightCommon.halign -> unit;
    method setVAlign: LightCommon.valign -> unit;
    method textBounds: Rectangle.t;
  end;


value create: ?fontName:string -> ?fontSize:float -> ?color:int -> ~width:float -> ~height:float -> string -> c _ _;
