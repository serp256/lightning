
type eventType = [= Stage.eventType | `TRIGGERED ];
type eventData = Stage.eventData;

module Make(Param:sig type evType = private [> eventType ]; type evData = private [> eventData ]; end): sig
  type event = Ev.t Param.evType Param.evData;
  module DisplayObject: DisplayObjectT.S with type evType = Param.evType and type evData = Param.evData;
  module Quad: Quad.S with module D := DisplayObject;
  module Image: Image.S with module D := DisplayObject;
  module Atlas: Atlas.S with module D := DisplayObject;
  module Sprite: Sprite.S with module D :=  DisplayObject;
  module Clip: ClipT.S with module D := DisplayObject and module Image := Image and module Atlas := Atlas and module Sprite := Sprite;
  module TLF: TLFT.S with module D := DisplayObject and module Sprite := Sprite;
  module Stage: StageT.S with module D := DisplayObject;
end;

module DefaultParam: sig 
  type evType = eventType;
  type evData = eventData;
end;

value deviceIdentifier: unit -> option string;

class type stage = 
  object
    method resize: float -> float -> unit;
    method renderStage: unit -> unit;
    method run: float -> unit;
    method processTouches: list Touch.n -> unit;
    method cancelAllTouches: unit -> unit;
    method advanceTime: float -> unit;
    method name: string;
  end;

value init: (float -> float -> #stage) -> unit;
