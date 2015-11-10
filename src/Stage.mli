
(* type eventType = [= DisplayObject.eventType | `TOUCH | `ENTER_FRAME ]; *)
(* type eventData = [= DisplayObject.eventData | `Touches of list Touch.t | `PassedTime of float ]; *)

open LightCommon;
open Motion;

class type tween = object method process: float -> bool; end;
value addTween: #tween -> unit;
value removeTween: #tween -> unit;
value clear_tweens: unit -> unit;

value screenSize: unit -> (float * float);


value ev_TOUCH: Ev.id;
value ev_UNLOAD: Ev.id;
value ev_BACK_PRESSED: Ev.id;
value ev_BACKGROUND: Ev.id;
value ev_FOREGROUND: Ev.id;
value touches_of_data: (Ev.data -> option (list Touch.t));
value data_of_touches: (list Touch.t -> Ev.data);

(*
value ev_ACCELEROMETER : Ev.id;
value acmtrData_of_data : (Ev.data -> option (acmtrData));
value data_of_acmtrData : (acmtrData -> Ev.data);
*)

value onBackground: ref (option (unit -> unit));
value onForeground: ref (option (float -> unit));

class virtual base:
  object
    inherit DisplayObject.container;

    method color: color;
    method setColor: color -> unit;
    method cacheAsImage: bool;
    method setCacheAsImage: bool -> unit;
    method setFilters: list Filters.t -> unit;
    method filters: list Filters.t;
  end;

class virtual c: [ float ] -> [ float ] ->
  object
    inherit base;
    value virtual bgColor: int;
    method frameRate: int;
    method processTouches: list Touch.n -> unit;
    method cancelAllTouches: unit -> unit;
    method advanceTime: float -> unit;
    (*method run: float -> unit; (* combine advanceTime and render *)*)
    method renderStage: unit -> bool;
    method resize: float -> float -> unit;
    method onUnload: unit -> unit;
    method dispatchBackPressedEv : unit -> bool;
    method dispatchBackgroundEv : unit -> unit;
    method dispatchForegroundEv : unit -> unit;
    method forceStageRender: ?reason:string -> unit -> unit;
    method forceRenderStage: unit -> unit;
    method traceFPS: (int -> DisplayObject.c) -> unit;
    method traceSharedTexNum: (int -> DisplayObject.c) -> unit;
    method _stageResized: float -> float -> unit;
  end;

value instance: unit -> c;
value setBackgroundDelayedCallback:  ~callback:(unit -> unit) -> ~delay:int -> unit -> unit;
value resetBackgroundDelayedCallback: unit -> unit;
