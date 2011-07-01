
module Make
  (D:DisplayObjectT.M with 
    type evType = private [> `TRIGGERED | `TOUCH | DisplayObjectT.eventType ] and
    type evData = private [> `Touches of list Touch.t | DisplayObjectT.eventData ]
  ) 
  (Sprite: Sprite.S with module D = D)
  (Image: Image.S with module Q.D = D)
  (TextField: TextField.S with module D = D)
  
  : sig

  class c:  [?disabled:Texture.c] -> [?downstate:Texture.c] -> [?text:string] -> [Texture.c] ->
    object
      inherit D.container;
      method setText: string -> unit;
      method setFontName: string -> unit;
      method setFontColor: int -> unit;
      method setDisabledFontColor: int -> unit;
      method setFontSize: option float -> unit;
      method setTextBounds: Rectangle.t -> unit;
      method isEnabled: bool;
      method setEnabled: bool -> unit;
      method setTextOffsetX : float -> unit;
      method setTextOffsetY : float -> unit;
    end;


  value create: ?disabled:Texture.c -> ?downstate:Texture.c -> ?text:string -> Texture.c -> c;

end;
