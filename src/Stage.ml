
open Touch;

type eventType = [= DisplayObject.eventType | `TOUCH | `ENTER_FRAME  ];
type eventData = [= DisplayObject.eventData | `Touches of list Touch.t | `PassedTime of float ];


exception Restricted_operation;


module Make(D:DisplayObjectT.M with type evType = private [> eventType ] and type evData = private [> eventData ]) = struct (*{{{*)


  class type tween = object method process: float -> bool; end;
  value tweens : Queue.t  tween = Queue.create ();
  value addTween tween = Queue.push (tween :> tween) tweens;
  value removeTween tween = (* Not best for perfomance realisation *)
    let tween = (tween :> tween) in
    let tmpqueue = Queue.create () in
    (
      while not (Queue.is_empty tweens) do
        let t = Queue.pop tweens in
        match t = tween with
        [ False -> Queue.push t  tmpqueue 
        | True -> ()
        ]
      done;
      Queue.transfer tmpqueue tweens;
    );


  class virtual c (width:float) (height:float) =
    object(self)
      inherit D.container as super;
      initializer self#setName "STAGE";
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


      method! stage = Some self#asDisplayObjectContainer;
      (*
      value mutable time = 0.;
      value mutable timerID = 0;
      value timersQueue = TimersQueue.make ();
      *)
(*       value timers (* : Hashtbl.t int (inner_timer 'event_type 'event_data) *) = Hashtbl.create 0; *)

      (*
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

            method private start' () = 
            (
                TimersQueue.add timersQueue ((time +. delay),(timer :> inner_timer));
                running := True
            );

            method start () = 
              match running with
              [ False -> timer#start'()
              | True -> failwith "Timer alredy started"
              ];

            method private stop' () = 
             (
               TimersQueue.remove_if (fun (_,o) -> o = timer) timersQueue;
               running := False;
             );

            method stop () = 
              match running with
              [ True -> timer#stop'()
              | False -> failwith "Timer alredy stopped"
              ];

            method private asEventTarget = (timer : inner_timer :> Timer.c _ _);

            method reset () = 
            (
              currentCount := 0;
              match running with
              [ False -> ()
              | True -> timer#stop'() 
              ];
            );

            method restart ~reset = 
            (
              match running with
              [ True -> 
                (
                  match reset with
                  [ True -> currentCount := 0
                  | False -> ()
                  ];
                  timer#stop'()
                )
              | False -> ()
              ];
              timer#start'();
            );


          end
        in
        (o :> Timer.c _ _ );(*}}}*)
      *)

      value mutable currentTouches = []; (* FIXME: make it weak for target *)
      method processTouches (touches:list Touch.t) = (*{{{*)
(*         let () = Printf.eprintf "process touches %d\n%!" (List.length touches) in *)
        let processedTouches = 
          List.fold_left begin fun processedTouches touch ->
            let () = 
              debug "touch: %ld, %f [%f:%f], [%f:%f], %d, %s\n%!" touch.tid
                touch.timestamp touch.globalX touch.globalY 
                touch.previousGlobalX touch.previousGlobalY
                touch.tapCount (string_of_touchPhase touch.phase)
            in
            try
              let (target,_) =
                List.find begin fun (target,eTouch) -> eTouch.tid = touch.tid
                (*
                  (eTouch.globalX = touch.previousGlobalX && eTouch.globalY = touch.previousGlobalY) ||
                  (eTouch.globalX = touch.globalX && eTouch.globalY = touch.globalY) (* - ЭТО НЕ ОЧЕНЬ ПОНЯТНО ПОЧЕМУ *)
                *)
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
          let fireTouches = (* группируем их по таргетам и вперед *)
            List.fold_left (fun res (target,touch) -> MList.add_assoc target touch res) [] processedTouches
          in
          let event = Event.create ~bubbles:True `TOUCH () in
          List.iter begin fun ((target:D.c),touches) ->
            let event = {(event) with Event.data = `Touches touches} in
            target#dispatchEvent event
          end fireTouches;
          currentTouches := List.filter (fun (_,t) -> match t.phase with [ TouchPhaseEnded -> False | _ -> True ]) processedTouches;
        );(*}}}*)

      method !render _ =
        (
          RenderSupport.clearTexture ();
          RenderSupport.clear color 1.0;
          RenderSupport.setupOrthographicRendering 0. width height 0.;
          proftimer:render "STAGE rendered %F" (super#render None);
          ignore(RenderSupport.checkForOpenGLError());
        (*
        #if DEBUG
        [SPRenderSupport checkForOpenGLError];
        #endif
        *)
      );

      value tmptweens = Queue.create ();

      method advanceTime (seconds:float) = 
        proftimer "Stage advanceTime: %F"
        (
          Timers.run seconds;
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
          (*
          let enterFrameEvent = Event.create `ENTER_FRAME ~data:(`PassedTime seconds) () in
          self#dispatchEventOnChildren enterFrameEvent;
          *)
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

    initializer Timers.init 0.;
    
  end;

end; (*}}}*)
