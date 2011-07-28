
type eventType = [= DisplayObject.eventType | `TOUCH | `ENTER_FRAME ];
type eventData = [= DisplayObject.eventData | `Touches of list Touch.t | `PassedTime of float ];



module Make(D:DisplayObjectT.M with type evType = private [> eventType ] and type evData = private [> eventData ]) : sig
  class type tween = object method process: float -> bool; end;
  value addTween: #tween -> unit;
  value removeTween: #tween -> unit;

  class virtual c: [ float ] -> [ float ] ->
    object
      inherit D.container;
      value virtual color: int;
      method processTouches: list Touch.n -> unit;
      method advanceTime: float -> unit;
      method run: float -> unit; (* combine advanceTime and processTouches *)
    end;
end;
