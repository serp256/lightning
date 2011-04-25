
open Touch;


type eventType = [= DisplayObject.eventType | `TOUCH ];
type eventData 'event_type 'event_data = [= Event.dataEmpty | `Touch of (list (Touch.et 'event_type 'event_data)) ];

exception Restricted_operation;

class c ['event_type,'event_data ] (width:float) (height:float) = (*{{{*)
  object(self)
    inherit DisplayObject.container ['event_type,'event_data ] as super;
    method! width = width;
    method! setWidth _ = raise Restricted_operation;
    method! height = height;
    method! setHeight _ = raise Restricted_operation;
    method! setX _ = raise Restricted_operation;
    method! setY _ = raise Restricted_operation;
    method! setScaleX _ = raise Restricted_operation;
    method! setScaleY _ = raise Restricted_operation;
    method! setRotation _ = raise Restricted_operation;

    value mutable currentTouches = [];

    method! isStage = True;

    method processTouches (touches:list Touch.t) =
      let processedTouches = 
        List.fold_left begin fun processedTouches touch ->
          (*let () = 
            Printf.printf "touch: %f [%f:%f], [%f:%f], %d, %s\n%!" 
              touch.timestamp touch.globalX touch.globalY 
              touch.previousGlobalX touch.previousGlobalY
              touch.tapCount (string_of_touchPhase touch.phase)
          in*)
          let touch = 
            try
              let existingTouch =
                List.find begin fun existingTouch ->
                  (existingTouch.touch.globalX = touch.previousGlobalX && existingTouch.touch.globalY = touch.previousGlobalY) ||
                  (existingTouch.touch.globalX = touch.globalX && existingTouch.touch.globalY = touch.globalY)
                end currentTouches
              in
              match existingTouch.target with
              [ None -> {touch; target = self#hitTestPoint (touch.globalX,touch.globalY) True}
              | Some target when target#stage = None -> {touch; target = self#hitTestPoint (touch.globalX,touch.globalY) True} 
              | _ -> let () = print_endline "this is exists touch" in {touch; target = existingTouch.target}
              ]
            with [ Not_found -> {touch; target = self#hitTestPoint (touch.globalX,touch.globalY) True} ]
          in
          [ touch :: processedTouches ]
        end [] touches
      in
      (
        List.iter begin fun t ->
          let touch = t.touch in
          Printf.printf "touch: %f [%f:%f], [%f:%f], %d, %s, [ %s ]\n%!" 
            touch.timestamp touch.globalX touch.globalY 
            touch.previousGlobalX touch.previousGlobalY
            touch.tapCount (string_of_touchPhase touch.phase)
            (match t.target with [ None -> "none" | Some t -> t#name ])
        end processedTouches;
        let event = Event.create `TOUCH ~bubbles:True ~data:(`Touch processedTouches) () in
        List.iter begin fun touch ->
          match touch.target with
          [ Some t -> t#dispatchEvent event
          | None -> ()
          ]
        end processedTouches;
        currentTouches := processedTouches;
      );

    method !render () =
    (
      RenderSupport.clearTexture ();
      RenderSupport.clearWithColorAlpha 0x0 1.0;
      RenderSupport.setupOrthographicRendering 0. width height 0.;
      super#render();
      ignore(RenderSupport.checkForOpenGLError());
      (*
      #if DEBUG
      [SPRenderSupport checkForOpenGLError];
      #endif
      *)
    );
    method advanceTime (seconds:float) = 
    (
      (* jugler here *)
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
    
  end;(*}}}*)
