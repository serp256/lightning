open Sdl;
open Video;
open Window;
open LightCommon;


(*
value init_gl width height =
  glViewport 0 0 width height;
*)




value touchid = ref 0;

value handle_events window frameRate stage =
  let ticksRate = 1000 / frameRate in
  let open Event in
  loop 0 None False where
    rec loop lastTicks touch quit = 
    (
      let dticks = (Sdl.Timer.get_ticks())  - lastTicks in
      if dticks < ticksRate then Sdl.Timer.delay (ticksRate - dticks) else ();
      let ticks = Sdl.Timer.get_ticks () in
      (
        stage#run ((float (ticks - lastTicks)) /. 1e3);
        SDLGL.swap_window window;
        match quit with
        [ True -> ()
        | False ->
          (
            URLLoader.run();
            let rec next_event touch ticks =
              let cticks = Sdl.Timer.get_ticks() in
              if cticks - ticks < ticksRate 
              then event_loop touch cticks
              else loop cticks touch False
            and event_loop touch ticks = 
              match Event.poll_event () with
              [ Window {wevent=WINDOWEVENT_CLOSE;_} | Quit -> loop ticks touch True
              | NoEvent -> loop ticks touch False
              | Button ({Event.mousebutton = LEFT;_} as mb) -> 
                  match touch with
                  [ None when mb.buttonstate = PRESSED -> (* tap begin *)
                    let globalX = float mb.bx
                    and globalY = float mb.by in
                    let touch = 
                      {
                        Touch.n_tid = (let r = !touchid in (touchid.val := r + 1; Int32.of_int r));
                        n_timestamp = 0.;
                        n_globalX = globalX; n_globalY = globalY;
                        n_previousGlobalX = globalX; n_previousGlobalY = globalY;
                        n_tapCount = 1; n_phase = Touch.TouchPhaseBegan;
                      }
                    in
                    (
                      stage#processTouches [touch];
                      next_event (Some touch) ticks
                    )
                  | Some touch when mb.buttonstate = RELEASED -> (* FIXME: what about multi touch ? *)
                      let touch = {(touch) with Touch.n_globalX = float mb.bx; n_globalY = float mb.by; n_phase = Touch.TouchPhaseEnded} in
                      (
                        stage#processTouches [ touch ];
                        next_event None ticks
                      )
                  | _ -> let () = prerr_endline "fixme Button event" in loop ticks touch False
                  ]
              | Event.Motion mm -> 
                  match touch with
                  [ Some touch ->
                    let touch = {(touch) with Touch.n_globalX = float mm.mx; n_globalY = float mm.my; n_phase = Touch.TouchPhaseMoved} in
                    (
                      stage#processTouches [ touch ];
                      event_loop (Some touch) ticks
                    )
                  | None -> next_event None ticks
                  ]
              | _ -> next_event touch ticks
              ]
            in
            event_loop touch ticks
          )
        ];
      )
    );
  

value run stage_create = 
  let width = ref 768 and height = ref 1024 and frameRate = ref 30
  and setDeviceType = fun s -> internalDeviceType.val := match s with [ "pad" -> Pad | "phone" -> Phone | _ -> failwith "unknown device type"] in
  (
    Arg.parse [
      ("-w",Arg.Set_int width,"width");("-h",Arg.Set_int height,"height");("-fps",Arg.Set_int frameRate,"frame rate");
      ("-dt",Arg.String setDeviceType,"Set deviceType [phone | pad] default pad");
      ("-um",Arg.Set_int Hardware.internal_user_memory,"Set Hardware.user_memory (default 0)")
    ] (fun _ -> ()) "";
    init [VIDEO];
    Sdl_image.init [ Sdl_image.PNG ]; 
    (
      SDLGL.set_attribute SDLGL.CONTEXT_MAJOR_VERSION 2;
      SDLGL.set_attribute SDLGL.CONTEXT_MINOR_VERSION 0;
      SDLGL.set_attribute SDLGL.DOUBLEBUFFER 1;
      SDLGL.set_attribute SDLGL.DEPTH_SIZE 24;
      let window = Window.create "TEST WINDOW NAME" Window.PosCentered Window.PosCentered !width !height [ Window.SHOWN ; Window.OPENGL ] in
      let context = SDLGL.create_context window in
      (
        SDLGL.set_swap_interval 1;
        Printf.printf "SDL ATTRIBUTES: DOUBLEBUFFER:%d,GLMV:%d,GLMV:%d\n%!" (SDLGL.get_attribute SDLGL.DOUBLEBUFFER) (SDLGL.get_attribute SDLGL.CONTEXT_MAJOR_VERSION) (SDLGL.get_attribute SDLGL.CONTEXT_MINOR_VERSION);
        Printf.printf "GL_EXTENSTIONS: %s\n%!" (Render.get_gl_extensions ());
        let stage = stage_create (float !width) (float !height) in
        handle_events window !frameRate stage;
        SDLGL.delete_context context;
        Window.destroy window;
      );
    );
    quit();
  );
