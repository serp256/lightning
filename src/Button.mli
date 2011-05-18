
module Make(D:DisplayObjectT.M with 
  type evType = private [> `TRIGGERED | `TOUCH | DisplayObjectT.eventType ] and
  type evData = private [> `Touches of list Touch.t | DisplayObjectT.eventData ]
) : sig

  class c:  [?downstate:Texture.c] -> [?text:string] -> [Texture.c] ->
    object
      inherit D.container;
      method setText: string -> unit;
      method setFontName: string -> unit;
      method setFontColor: int -> unit;
      method setFontSize: option float -> unit;
      method setTextBounds: Rectangle.t -> unit;
    end;


  value create: ?downstate:Texture.c -> ?text:string -> Texture.c -> c;

end;
