
open Touch;

type eventType = [= DisplayObject.eventType | `TOUCH | `ENTER_FRAME | `TIMER  | `TIMER_COMPLETE ];
type eventData = [= DisplayObject.eventData | `Touches of list Touch.t | `PassedTime of float ];


exception Restricted_operation;


module Make(D:DisplayObjectT.M with type evType = private [> eventType ] and type evData = private [> eventData ]) = struct (*{{{*)


  class type tween = object method process: float -> bool; end;
  value tweens : Queue.t  tween = Queue.create ();
  value addTween tween = Queue.push (tween :> tween) tweens;

  class type inner_timer =
    object
      inherit Timer.c [ D.evType, D.evData ]; 
      method private asEventTarget: Timer.c D.evType D.evData;
      method fire: unit -> unit;
    end;

  module TimersQueue = PriorityQueue.Make (struct type t = (float*inner_timer); value order (t1,_) (t2,_) = t1 <= t2; end);

  class virtual c (width:float) (height:float) =
    object(self)
      inherit D.container as super;
      value virtual color: int;
      method! width = width;
      method! setWidth _ = raise Restricted_operation;
      method! height = height;
      method! setHeight _ = raise Restricted_operation;
      method! setX _ = raise Restricted_operation;
      method! setY _ = raise Restricted_operation;
      method! setScaleX _ = raise Restricted_operation;
      method! setScaleY _ = raise Restricted_operation;
      method! setRotation _ = raise Restricted_operation;


      method! isStage = True;

      value mutable time = 0.;
      value mutable timerID = 0;
      value timersQueue = TimersQueue.make ();
(*       value timers (* : Hashtbl.t int (inner_timer 'event_type 'event_data) *) = Hashtbl.create 0; *)

      method createTimer ?(repeatCount=0) delay = (*{{{*)
        let o = 
          object(timer)
            type 'timer = Timer.c 'event_type 'event_data;
            inherit EventDispatcher.simple ['event_type,'event_data,'timer];
(*             value id = let id = timerID in (timerID := timerID + 1; id); *)
            value mutable running = False;
            method running = running;
            value mutable currentCount = 0;
            method delay = delay;
            method repeatCount = repeatCount;
            method currentCount = currentCount;
            method fire () = 
            (
              prerr_endline "fire timer";
              let event = Event.create `TIMER () in
              timer#dispatchEvent event; 
              currentCount := currentCount + 1;
              match running with
              [ True -> 
                if repeatCount <= 0 || currentCount < repeatCount
                then
                  TimersQueue.add timersQueue ((time +. delay),(timer :> inner_timer))
                else 
                  (
                    running := False;
(*                     Hashtbl.remove timers id; *)
                    let event = Event.create `TIMER_COMPLETE () in
                    timer#dispatchEvent event
                  )
              | False -> ()
              ]
            );
            method start () = 
              match running with
              [ False ->
                (
(*                   Printf.eprintf "add timers for time: %F\n%!" (time +. delay); *)
                  TimersQueue.add timersQueue ((time +. delay),(timer :> inner_timer));
(*                   Hashtbl.add timers id timer; *)
                  currentCount := 0;
                  running := True
                )
              | True -> failwith "Timer alredy started"
              ];
            method stop () = 
              match running with
              [ True -> 
                (
                  TimersQueue.remove_if (fun (_,o) -> o = timer) timersQueue;
(*                   Hashtbl.remove timers id; *)
                  running := False;
                )
              | False -> failwith "Timer alredy stopped"
              ];
            method private asEventTarget = (timer : inner_timer :> Timer.c _ _);
            method reset () = assert False;
          end
        in
        (o :> Timer.c _ _ );(*}}}*)

      value mutable currentTouches = []; (* FIXME: make it weak for target *)
      method processTouches (touches:list Touch.t) = (*{{{*)
(*         let () = Printf.eprintf "process touches %d\n%!" (List.length touches) in *)
        let processedTouches = 
          List.fold_left begin fun processedTouches touch ->
            (*let () = 
              Printf.printf "touch: %f [%f:%f], [%f:%f], %d, %s\n%!" 
                touch.timestamp touch.globalX touch.globalY 
                touch.previousGlobalX touch.previousGlobalY
                touch.tapCount (string_of_touchPhase touch.phase)
            in*)
            try
              let (target,_) =
                List.find begin fun (target,eTouch) ->
                  (eTouch.globalX = touch.previousGlobalX && eTouch.globalY = touch.previousGlobalY) ||
                  (eTouch.globalX = touch.globalX && eTouch.globalY = touch.globalY) (* - ЭТО НЕ ОЧЕНЬ ПОНЯТНО ПОЧЕМУ *)
                end currentTouches
              in
              match target#stage with
              [ None -> 
                match self#hitTestPoint (touch.globalX,touch.globalY) True with
                [ None -> processedTouches
                | Some target -> [ (target,touch) :: processedTouches ]
                ]
              | Some _ -> let () = print_endline "this is exists touch" in [ (target,touch) :: processedTouches ]
              ]
            with 
              [ Not_found -> 
                match self#hitTestPoint (touch.globalX,touch.globalY) True with
                [ Some target -> [ (target,touch) :: processedTouches ]
                | None -> processedTouches
                ]
              ]
          end [] touches
        in
        (
          (*
          List.iter begin fun (target,touch) ->
            Printf.printf "touch: %f [%f:%f], [%f:%f], %d, %s, [ %s ]\n%!" 
              touch.timestamp touch.globalX touch.globalY 
              touch.previousGlobalX touch.previousGlobalY
              touch.tapCount (string_of_touchPhase touch.phase)
              target#name
          end processedTouches;
          *)
          let fireTouches = 
            (* группируем их по таргетам и вперед *)
            List.fold_left (fun res (target,touch) -> MList.add_assoc target touch res) [] processedTouches
          in
          let event = Event.create `TOUCH ~bubbles:True () in
          List.iter begin fun (target,touches) ->
            let event = {(event) with Event.data = `Touches touches} in
            target#dispatchEvent event
          end fireTouches;
          currentTouches := processedTouches;
        );(*}}}*)

      method !render () =
      (
        RenderSupport.clearTexture ();
        RenderSupport.clear color 1.0;
        RenderSupport.setupOrthographicRendering 0. width height 0.;
        super#render();
        ignore(RenderSupport.checkForOpenGLError());
        (*
        #if DEBUG
        [SPRenderSupport checkForOpenGLError];
        #endif
        *)
      );

      value tmptweens = Queue.create ();

      method advanceTime (seconds:float) = 
      (
        debug "advance time";
        time := time +. seconds;
(*         Printf.eprintf "%F. timers length: %d\n%!" time (TimersQueue.length timersQueue); *)
        (* timers *)
        if not (TimersQueue.is_empty timersQueue)
        then
          let rec run_timers () = 
            match TimersQueue.first timersQueue with
            [ (t,timer) when t <= time ->
              (
                TimersQueue.remove_first timersQueue;
(*                 let timer = Hashtbl.find timers id in *)
                timer#fire();
                match TimersQueue.is_empty timersQueue with
                [ True -> ()
                | False -> run_timers ()
                ]
              )
            | _ -> ()
            ]
          in
          run_timers ()
        else ();
        (* jugler here *)
        while not (Queue.is_empty tweens) do
          let tween = Queue.take tweens in
          match tween#process seconds with
          [ True -> Queue.push tween tmptweens
          | False -> ()
          ]
        done;
        Queue.transfer tmptweens tweens;
        (* dispatch EnterFrameEvent *)
        let enterFrameEvent = Event.create `ENTER_FRAME ~data:(`PassedTime seconds) () in
        self#dispatchEventOnChildren enterFrameEvent;
      );

    method! hitTestPoint localPoint isTouch =
      match isTouch && (not visible || not touchable) with
      [ True -> None 
      | False ->
          match super#hitTestPoint localPoint isTouch with
          [ None -> (* different to other containers, the stage should acknowledge touches even in empty parts. *)
            let bounds = Rectangle.create x y width height in
            match Rectangle.containsPoint bounds localPoint with
            [ True -> Some self#asDisplayObject
            | False -> None
            ]
          | res -> res
          ]
      ];
    
  end;

end; (*}}}*)
