open LightCommon;
open Touch;
open Motion;

(* type eventType = [= DisplayObject.eventType | `TOUCH | `ENTER_FRAME  ]; *)
(* type eventData = [= DisplayObject.eventData | `Touches of list Touch.t | `PassedTime of float ]; *)

value _ACCELEROMETER_INTERVAL = 1;

value ev_TOUCH = Ev.gen_id "TOUCH";
value ev_ACCELEROMETER = Ev.gen_id "ACCELEROMETER";
value ev_BACKGROUND = Ev.gen_id "BACKGROUND";
value ev_FOREGROUND = Ev.gen_id "FOREGROUND";
value ev_UNLOAD = Ev.gen_id "UNLOAD";
value ev_BACK_PRESSED = Ev.gen_id "BACK_PRESSED";

value (data_of_touches,touches_of_data) = Ev.makeData ();
value (data_of_acmtrData,acmtrData_of_data) = Ev.makeData ();

external setupOrthographicRendering: float -> float -> float -> float -> unit = "ml_setupOrthographicRendering";

exception Restricted_operation;


module D = DisplayObject;

class type tween = object method process: float -> bool; end;
value tweens : Queue.t  tween = Queue.create ();
value addTween tween = Queue.push (tween :> tween) tweens;
value removeTween tween = 
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


value clear_tweens () = Queue.clear tweens;
Callback.register "clear_tweens" clear_tweens;



exception Touch_not_found;

value _screenSize = ref (0.,0.);
value screenSize () = !_screenSize;

value onBackground = ref None;
value on_background () = 
  (
    debug "GOING TO BACKGROUND";
    match !onBackground with
    [ Some f -> f()
    | None -> ()
    ]
  );
Callback.register "on_background" on_background;

value onForeground = ref None;
value on_foreground () = 
(
  debug "ENTER TO FOREGROUND";
  match !onForeground with
  [ Some f -> f ()
  | None -> ()
  ];
);
Callback.register "on_foreground" on_foreground;


class virtual c (_width:float) (_height:float) =
  object(self)
    inherit D.container as super;
    value virtual bgColor: int;
    method color = `NoColor;
    method setColor (_:color) = raise Restricted_operation;
    value mutable width = _width;
    value mutable height = _height;
    initializer 
    (
      self#setName "STAGE";
      setupOrthographicRendering 0. width height 0.;
      _screenSize.val := (width,height);
    );
    method cacheAsImage = False;
    method setCacheAsImage = raise Restricted_operation;
    method setFilters _ = raise Restricted_operation;
    method filters = [];
    method! width = width;
    method! setWidth _ = raise Restricted_operation;
    method! height = height;
    method! setHeight _ = raise Restricted_operation;
    method! setX _ = raise Restricted_operation;
    method! setY _ = raise Restricted_operation;
    method! setScaleX _ = raise Restricted_operation;
    method! setScaleY _ = raise Restricted_operation;
    method! setRotation _ = raise Restricted_operation;

    method resize w h = 
    (
      width := w;
      height := h;
      setupOrthographicRendering 0. w h 0.;
      _screenSize.val := (w,h);
    );

    method onUnload () = 
      let ev = Ev.create ev_UNLOAD () in
      let () = debug:unload "UNLOAD" in
      self#dispatchEvent ev;

    method! stage = Some self#asDisplayObjectContainer;

    value mutable currentTouches = []; (* FIXME: make it weak for target *)
    method processTouches (touches:list Touch.n) = (*{{{*)
      let () = debug "process touches" in
      match touchable with
      [ True -> 
        let () = debug:touches "process touches %d\n%!" (List.length touches) in
        let now = Unix.gettimeofday() in
        let cTouches = ref currentTouches in
        let processedTouches = 
          List.map begin fun nt ->
            let () = nt.n_timestamp := now in
            try
              let ((target,touch),cts) = try MList.pop_if (fun (target,eTouch) -> eTouch.n_tid = nt.n_tid) !cTouches with [ Not_found -> raise Touch_not_found ] in 
              (
                cTouches.val := cts;
                nt.n_previousGlobalX := touch.n_globalX; 
                nt.n_previousGlobalY := touch.n_globalY; 
                match target#stage with
                [ None -> 
                  match self#hitTestPoint {Point.x=nt.n_globalX;y=nt.n_globalY} True with
                  [ None -> assert False
                  | Some target -> (target,nt)
                  ]
                | Some _ -> (target,nt) 
                ]
              )
            with 
            [  Touch_not_found -> 
              match self#hitTestPoint {Point.x= nt.n_globalX;y = nt.n_globalY} True with
              [ Some target -> (target,nt)
              | None -> assert False
              ]
            ]
          end touches
        in
        let otherTouches = !cTouches in
        let () = debug:touches "Length of other touches: %d" (List.length otherTouches) in
        (
          List.iter (fun (_,tch) -> tch.n_phase := TouchPhaseStationary) otherTouches;
          let () = debug:touches
              List.iter begin fun (target,touch) ->
                debug:touches "touch: %f [%f:%f], [%F:%F], %d, %s, [ %s ]\n%!" 
                  touch.n_timestamp touch.n_globalX touch.n_globalY 
                  touch.n_previousGlobalX touch.n_previousGlobalY
                  touch.n_tapCount (string_of_touchPhase touch.n_phase)
                  target#name
              end (processedTouches @ otherTouches)
          in
          (* группируем их по таргетам и вперед - incorrect *) 
          let fireTouches = List.fold_left (fun res (target,touch) -> MList.add_assoc target (Touch.t_of_n touch) res) [] processedTouches in
          let fireTouches = 
            List.fold_left begin fun res (target,touch) -> 
              try
                let touches = List.assoc target res in
                MList.replace_assoc target (touches @ [ Touch.t_of_n touch ]) res
              with [ Not_found -> res ]
            end fireTouches otherTouches 
          in
          let event = Ev.create ~bubbles:True ev_TOUCH () in
          List.iter begin fun ((target:D.c),touches) ->
            let event = {(event) with Ev.data = data_of_touches touches} in
            target#dispatchEvent event
          end fireTouches;
          currentTouches := (List.filter (fun (_,t) -> match t.n_phase with [ TouchPhaseEnded | TouchPhaseCancelled -> False | _ -> True ]) processedTouches) @ otherTouches;
          debug "touches end";
        )
      | False -> ()
      ];(*}}}*)


    method cancelAllTouches () = 
      match currentTouches with
      [ [] -> ()
      | touches ->
        (
          currentTouches := []; (* FIXME:  не проверяем что таргет на сцене *)
          let fireTouches = List.fold_left (fun res (target,touch) -> MList.add_assoc target ({(Touch.t_of_n touch) with phase = TouchPhaseCancelled}) res) [] touches in
          let event = Ev.create ~bubbles:True ev_TOUCH () in
          List.iter begin fun ((target:D.c),touches) ->
            let event = {(event) with Ev.data = data_of_touches touches} in
            target#dispatchEvent event
          end fireTouches;
        )
      ];


    method renderStage () =
    (
(*       proftimer:perfomance "Prerender: %F" D.prerender(); *)
      Render.clear bgColor 1.;
      proftimer:perfomance "STAGE rendered %F\n=======================" (super#render None);
      (*
      debug "start render";
      debug "end render";
      *)
    );

    value runtweens = Queue.create ();

    method advanceTime (seconds:float) = 
    (
      debug "advance time: %f" seconds;
      Texture.check_async();
      proftimer:perfomance "Stage advanceTime: %F"
      (
          Timers.process seconds;
          Queue.transfer tweens runtweens;
          while not (Queue.is_empty runtweens) do
            let tween = Queue.take runtweens in
            match tween#process seconds with
            [ True -> Queue.push tween tweens
            | False -> ()
            ]
          done;
      );
      proftimer:perfomance "Enter frame: %F" D.dispatchEnterFrame seconds;
      debug "end advance time";
    );

    method !z = Some 0;
    method run seconds = 
    (
      self#advanceTime seconds;
      Render.clear bgColor 1.;
      D.prerender ();
      proftimer:perfomance "STAGE rendered %F\n=======================" (super#render None);
    );

  method! hitTestPoint localPoint isTouch =
    match isTouch && (not visible || not touchable) with
    [ True -> None 
    | False ->
        match super#hitTestPoint localPoint isTouch with
        [ None -> (* different to other containers, the stage should acknowledge touches even in empty parts. *)
          let bounds = Rectangle.create pos.Point.x pos.Point.y width height in
          match Rectangle.containsPoint bounds localPoint with
          [ True -> Some self#asDisplayObject
          | False -> None
          ]
        | res -> res
        ]
    ];

  method dispatchBackPressedEv () =
    let ev = Ev.create ev_BACK_PRESSED () in
    (
      self#dispatchEvent ev;
      ev.Ev.propagation = `Propagate;
    );
    
  initializer Timers.init 0.;
  
end;
