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

module SetD = Set.Make (struct type t = D.dispObj; value compare d1 d2 = compare d1 d2; end);

exception Touch_not_found;

value _screenSize = ref (0.,0.);
value screenSize () = !_screenSize;
value _instance = ref None;
value instance () = match !_instance with [ Some s -> s | None -> failwith "Stage not created" ];

value onBackground = ref None;
value on_background () = 
  (
    debug "GOING TO BACKGROUND";
    match !onBackground with
    [ Some f -> f()
    | None -> ()
    ];

    match !_instance with
    [ Some s -> s#cancelAllTouches ()
    | _ -> ()
    ];
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
    method! private defaultName = "stage";
    method frameRate = 60;
    method color = `NoColor;
    method setColor (_:color) = raise Restricted_operation;
    value mutable width = _width;
    value mutable height = _height;
    initializer 
    (
      stage := Some (self :> D.container);
      setupOrthographicRendering 0. width height 0.;
      _screenSize.val := (width,height);
      match !_instance with
      [ None -> _instance.val := Some (self :> c)
      | Some _ -> failwith "Stage alredy created"
      ];
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
    method! setVisible _ = raise Restricted_operation;


    value mutable renderNeeded = True;

    method _stageResized w h = (
      self#resize w h;
      self#stageResized ();
    );

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

    value mutable currentTouches = []; (* FIXME: make it weak for target *)
    method processTouches (touches:list Touch.n) = (*{{{*)
      let () = debug "process touches" in
      proftimer(0.005) "processTouches %F" with
      match touchable with
      [ True -> 
        let () = debug:touches "process touches %d\n%!" (List.length touches) in
        let now = Unix.gettimeofday() in
        let cTouches = ref currentTouches in
        let processedTouches = 
          List.map begin fun nt ->
            let () = nt.n_timestamp := now in
            try
              let ((target,touch),cts) = 
                try 
                  MList.pop_if (fun (target,eTouch) -> eTouch.n_tid = nt.n_tid) !cTouches 
                with [ Not_found -> raise Touch_not_found ] 
              in 
              (
                cTouches.val := cts;
                nt.n_previousGlobalX := touch.n_globalX; 
                nt.n_previousGlobalY := touch.n_globalY; 
                match target#stage with
                [ None -> 
                  match self#hitTestPoint {Point.x=nt.n_globalX;y=nt.n_globalY} True with
                  [ Some target -> (target,nt)
                  | None -> assert False (* FIXME: it's impossible case, but ... *)
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
        (* let () = debug:touches "Length of other touches: %d" (List.length otherTouches) in *)
        (
          List.iter (fun (_,tch) -> tch.n_phase := TouchPhaseStationary) otherTouches;
          let () = debug:touches
              List.iter begin fun (target,touch) ->
                debug:touches "touch: %ld %f [%f:%f], [%F:%F], %d, %s, [ %s ]\n%!" touch.n_tid
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
          currentTouches := []; (* FIXME: не проверяем что таргет на сцене *)
          let fireTouches = List.fold_left (fun res (target,touch) -> MList.add_assoc target ({(Touch.t_of_n touch) with phase = TouchPhaseCancelled}) res) [] touches in
          let event = Ev.create ~bubbles:True ev_TOUCH () in
          List.iter begin fun ((target:D.c),touches) ->
            let event = {(event) with Ev.data = data_of_touches touches} in
            target#dispatchEvent event
          end fireTouches;
        )
      ];


    value mutable fpsTrace : option DisplayObject.c = None;
    value mutable sharedTexNum: option DisplayObject.c = None;

    method! forceStageRender ?reason () =
      (
        debug:forcerendereason "forceStageRender call, reason %s" (match reason with [ Some r -> r | _ -> "_" ]);
        renderNeeded := True;
      );

    value mutable skipCount = 0;
    (* used by all actual versions (pc, android, ios) *)
    method renderStage () =
      if renderNeeded
      then
        let () = debug:forcerendereason "stage render" in
        proftimer(0.015):prof "renderStage %f" with
          (
            renderNeeded := False;
            Render.clear bgColor 1.;
            super#render None;
            match fpsTrace with [ None -> () | Some fps -> fps#render None ];
            match sharedTexNum with [ None -> let () = debug:stn "sharedTexNum is none" in () | Some sharedTexNum -> let () = debug:stn "render sharedTexNum" in sharedTexNum#render None ];
            debug:render "skipped %d frames before render" skipCount;
            skipCount := 0;
            let () = debug:render "---renderstage done" in
            True;
          )
      else
        (
          skipCount := skipCount + 1;
          let () = debug:render "---renderstage done" in
          False;
        );

    value runtweens = Queue.create ();


    method advanceTime (seconds:float) =
      proftimer(0.015):prof "advanceTime %f" with
        (
          proftimer(0.005):prof "Texture.check_async %F" with Texture.check_async();
          proftimer(0.005):prof "Process timers %F" with Timers.process seconds;
          proftimer(0.005):prof "Process tweens %F" with
          (
              Queue.transfer tweens runtweens;
              while not (Queue.is_empty runtweens) do
                let tween = Queue.take runtweens in
                match tween#process seconds with
                [ True -> Queue.push tween tweens
                | False -> ()
                ]
              done;
          );
          proftimer(0.015):prof "dispatchEnterFrame %F" with
          self#stageDispatchEnterFrame seconds;
        );

    method traceFPS (show:(int -> #DisplayObject.c)) = 
      let f =
        object
          value mutable frames = 0;
          value mutable time = 0.;
          method process dt = 
            let osecs = int_of_float time in
            (
              time := time +. dt;
              let seconds = (int_of_float time) - osecs in
              match seconds with
              [ 0 ->  frames := frames + 1
              | _ -> 
                (
                  fpsTrace := Some (show (frames / seconds));
                  frames := 1;
                )
              ];
              True;
            );
        end
      in
      addTween f;

    method traceSharedTexNum (show:(int -> #DisplayObject.c)) =
      let f =
        object
          method process dt = 
            let () = debug:stn "!!!!pizdalalalallaal" in
            (* let dobj = show (RenderTexture.sharedTexsNum ()) in *)
            let dobj = show 0 in
            let m = Matrix.create ~translate:(Point.create 150. 0.) () in (
              dobj#setTransformationMatrix m;
              sharedTexNum := Some dobj;
              True;
            );
        end
      in
        addTween f;

    method !z = Some 0;
    (* used by outdated android version, ios and pc versions uses renderStage method *)
(*     method run seconds = 
    (
      debug:steam "-------------------------------";

      proftimer:steam "advence %f" (self#advanceTime seconds);
      proftimer:steam "prerender %f" (D.prerender ());
      Render.clear bgColor 1.;
      Render.checkErrors "before render";
      proftimer:steam "render %f" (super#render None);
      match fpsTrace with [ None -> () | Some fps -> fps#render None ];
      match sharedTexNum with [ None -> () | Some sharedTexNum -> sharedTexNum#render None ];
    ); *)

  method! hitTestPoint localPoint isTouch =
    (*
    match isTouch && (not touchable) with
    [ True -> None 
    | False ->
        *)
        match super#hitTestPoint localPoint isTouch with
        [ None -> Some self#asDisplayObject(* different to other containers, the stage should acknowledge touches even in empty parts. *)
          (*
            let bounds = Rectangle.create pos.Point.x pos.Point.y width height in
            match Rectangle.containsPoint bounds localPoint with
            [ True -> 
            | False -> None
            ]
          *)
        | res -> res
        ];
(*     ]; *)

  method dispatchBackPressedEv () =
    let ev = Ev.create ev_BACK_PRESSED () in
    (
      self#dispatchEvent ev;
      ev.Ev.propagation = `Propagate;
    );

(*   method dispatchBackgroundEv () = self#dispatchEvent (Ev.create ev_BACKGROUND ());
  method dispatchForegroundEv () = self#dispatchEvent (Ev.create ev_FOREGROUND ()); *)

  method dispatchBackgroundEv () =
    (
      self#forceStageRender ~reason:"background" ();
      on_background ();
    );

  method dispatchForegroundEv = on_foreground;

  method! boundsChanged () =
    (
      self#forceStageRender ~reason:"bounds changed" ();
      super#boundsChanged ();
    );

  value mutable prerender_locked = None;
  value prerender_objects = RefList.empty ();

  method! stageAddPrerenderObj o = 
    let () = debug:prerender "add_prerender: %s" o#name in
    match prerender_locked with
    [ Some waits -> RefList.push waits o
    | None -> RefList.push prerender_objects o
    ];
    
  method! stageRunPrerender () =
    proftimer(0.005):prof "prerender %f" with
      match RefList.is_empty prerender_objects with
      [ True -> ()
      | False ->
        (
          debug:prerender "start prerender";
          let locked_prerenders = RefList.empty () in
          (
            debug:perfomance "PRERENDER CNT: %d" (RefList.length prerender_objects);
            prerender_locked := Some locked_prerenders;
            let cmp ((z1:int),_) (z2,_) = compare z1 z2 in
            let sorted_objects = RefList.empty () in
            (
              proftimer:pprerender "SORT OBJECTS %F" with
              (RefList.iter (fun o -> 
                match o#z with
                [ Some z -> RefList.add_sort ~cmp sorted_objects (z,o)
                | None -> o#prerender False
                ]
              ) prerender_objects);
              proftimer:pprerender "EXECUTE %F" with (RefList.iter (fun (_,o) -> o#prerender True) sorted_objects);
            );
            RefList.copy prerender_objects locked_prerenders;
            prerender_locked := None;
          );
          debug:prerender "end prerender";
        )
      ];

  value mutable onEnterFrameObjects = SetD.empty;

  method! stageDispatchEnterFrame seconds = 
    let () = debug:stageenterframe "stageDispatchEnterFrame call %f" seconds in
    let enterFrameEvent = Ev.create DisplayObject.ev_ENTER_FRAME ~data:(Ev.data_of_float seconds) () in
      SetD.iter (fun obj ->
        let () = debug:stageenterframe "\tstageDispatchEnterFrame %s" obj#name in
        proftimer(0.005):prof "dispatch enter frame on: %s = %F" obj#name with obj#dispatchEvent enterFrameEvent
      ) onEnterFrameObjects;

  method! stageAddEnterFrameObj o =
    let () = debug:stageenterframe "stageAddEnterFrameObj %s" o#name in
      onEnterFrameObjects := SetD.add o onEnterFrameObjects;

  method! stageRmEnterFrameObj o =
    let () = debug:stageenterframe "stageRmEnterFrameObj %s" o#name in
      onEnterFrameObjects := SetD.remove o onEnterFrameObjects;


  initializer
    (
      Timers.init 0.;
    );
  
end;
