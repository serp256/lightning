
(* type eventType = [= DisplayObject.eventType | `TOUCH | `ENTER_FRAME ]; *)
(* type eventData = [= DisplayObject.eventData | `Touches of list Touch.t | `PassedTime of float ]; *)

open LightCommon;
open Motion;

class type tween = object method process: float -> bool; end;
value addTween: #tween -> unit;
value removeTween: #tween -> unit;

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
value onForeground: ref (option (unit -> unit));

class virtual c: [ float ] -> [ float ] ->
  object
    inherit DisplayObject.container;
    value virtual bgColor: int;
    method color: color;
    method setColor: color -> unit;
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
    method onUnload: unit -> unit;
    method dispatchBackPressedEv : unit -> bool;
    method dispatchBackgroundEv : unit -> unit;
    method dispatchForegroundEv : unit -> unit;
  end;

value instance: ref (option c);
