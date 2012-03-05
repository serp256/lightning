
type eventType = [= DisplayObject.eventType | `TOUCH | `ENTER_FRAME ];
type eventData = [= DisplayObject.eventData | `Touches of list Touch.t | `PassedTime of float ];



module Make(D:DisplayObjectT.M with type evType = private [> eventType ] and type evData = private [> eventData ]) : sig
  class type tween = object method process: float -> bool; end;
  value addTween: #tween -> unit;
  value removeTween: #tween -> unit;

  value screenSize: unit -> (float * float);

  class virtual c: [ float ] -> [ float ] ->
    object
      inherit D.container;
      value virtual color: int;
      method processTouches: list Touch.n -> unit;
      method cancelAllTouches: unit -> unit;
      method advanceTime: float -> unit;
      method run: float -> unit; (* combine advanceTime and render *)
      method renderStage: unit -> unit;
      method resize: float -> float -> unit;
      method filters: list Filters.t;
      method setFilters: list Filters.t -> unit;
      method cacheAsImage: bool;
      method setCacheAsImage: bool -> unit;
    end;
end;
