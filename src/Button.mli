
module Make
  (D:DisplayObjectT.M with 
    type evType = private [> `TRIGGERED | `TOUCH | DisplayObjectT.eventType ] and
    type evData = private [> `Touches of list Touch.t | DisplayObjectT.eventData ]
  ) 
  (Sprite: Sprite.S with module D = D)
  (Image: Image.S with module Q.D = D)
  (TextField: TextField.S with module D = D)
  
  : sig

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
