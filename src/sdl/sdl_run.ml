open Sdl;
open Video;
open Window;
open Gl;


value init_gl width height =
  glViewport 0 0 width height;




value touchid = ref 0;

value handle_events frameRate stage =
  let ticksRate = 1000 / frameRate in
  let open Event in
  loop 0 None False where
    rec loop lastTicks touch quit = 
    (
      let dticks = (Sdl.Timer.get_ticks())  - lastTicks in
      if dticks < ticksRate then Sdl.Timer.delay (ticksRate - dticks) else ();
      let ticks = Sdl.Timer.get_ticks () in
      (
        stage#advanceTime ((float (ticks - lastTicks)) /. 1e3);
        stage#render None;
        SDLGL.swap_buffers();
        match quit with
        [ True -> ()
        | False ->
            let rec event_loop touch = 
              match Event.poll_event () with
              [ Quit -> loop ticks touch True
              | NoEvent -> loop ticks touch False
              | Button ({Event.mousebutton = LEFT;_} as mb) -> 
                  match touch with
                  [ None when mb.buttonstate = PRESSED -> (* tap begin *)
                    let touch = 
                      {
                        Touch.tid = (let r = !touchid in (touchid.val := r + 1; Int32.of_int r));
                        timestamp = float (Sdl.Timer.get_ticks()); (* FIXME *)
                        globalX = float mb.bx; globalY = float mb.by;
                        previousGlobalX = float mb.bx; previousGlobalY = float mb.by;
                        tapCount = 1; phase = Touch.TouchPhaseBegan;
                      }
                    in
                    (
                      stage#processTouches [touch];
                      event_loop (Some touch)
                    )
                  | Some touch when mb.buttonstate = RELEASED -> (* FIXME: what about multi touch ? *)
                      let touch = 
                        {(touch) with Touch.timestamp = float (Sdl.Timer.get_ticks()); globalX = float mb.bx; globalY = float mb.by; previousGlobalX = touch.Touch.globalX; previousGlobalY = touch.Touch.globalY; phase = Touch.TouchPhaseEnded} in
                      (
                        stage#processTouches [ touch ];
                        event_loop None
                      )
                  | _ -> let () = prerr_endline "fixme Button event" in loop ticks touch False
                  ]
              | Event.Motion mm -> 
                  match touch with
                  [ Some touch ->
                    let touch = {(touch) with Touch.timestamp = float (Sdl.Timer.get_ticks()); globalX = float mm.mx; globalY = float mm.my; previousGlobalX = touch.Touch.globalX; previousGlobalY = touch.Touch.globalY; phase = Touch.TouchPhaseMoved} in
                    (
                      stage#processTouches [ touch ];
                      event_loop (Some touch)
                    )
                  | None -> event_loop None (* FIXME проверить выход за границы *)
                  ]
              | _ -> event_loop touch
              ]
            in
            event_loop touch
        ];
      )
    );
  

value run stage_create = 
  let width = ref 768 and height = ref 1024 and frameRate = ref 30 in
  (
    Arg.parse [("-w",Arg.Set_int width,"width");("-h",Arg.Set_int height,"height");("-frame-rate",Arg.Set_int frameRate,"frame rate")] (fun _ -> ()) "";
    init [VIDEO];
    Sdl_image.init [ Sdl_image.PNG ]; 
    let bpp = 32 in
    (
      ignore(set_video_mode !width !height bpp [ OPENGL ]);
      init_gl !width !height;
      let stage = stage_create (float !width) (float !height) in
      (
        set_caption stage#name "";
        handle_events !frameRate stage;
      )
    );
    quit();
  );
