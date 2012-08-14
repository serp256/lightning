open LightCommon;


value make_idle_func frameRate stage = 
  let time = ref (Unix.gettimeofday()) in
  let fps = 1. /. (float frameRate) in 
  fun () ->
    let now = Unix.gettimeofday () in
    let diff = now -. !time in
    if diff >= fps
    then 
    (
      time.val := now;
      stage#advanceTime diff;
      print_endline "redisplay";
      Glut.postRedisplay ();
    )
    else print_endline "wait";

value make_mouse_funcs stage = 
  let currentTouch = ref None in
  let touchid = ref 0 in
  let mouse = 
    fun mouse ->
      match !currentTouch with
      [ None when mouse.Glut.button_state = Glut.BUTTON_DOWN ->
        let globalX = float mouse.Glut.mouse_x
        and globalY = float mouse.Glut.mouse_y
        in
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
          currentTouch.val := Some touch;
        )
      | Some cTouch when mouse.Glut.button_state = Glut.BUTTON_UP ->
        let touch = 
          {(cTouch) with 
            Touch.n_globalX = float mouse.Glut.mouse_x; 
            n_globalY = float mouse.Glut.mouse_y; 
            n_phase = Touch.TouchPhaseEnded
          } 
        in
        (
          stage#processTouches [ touch ];
          currentTouch.val := None;
        )
      | None -> print_endline "CurrentTouch None but this is not DOWN"
      | Some _ -> print_endline "CurrentTouch Some but this is not UP"
      ]
  and motion = 
    fun x y -> 
      match !currentTouch with
      [ Some touch ->
        let touch = {(touch) with Touch.n_globalX = float x; n_globalY = float y; n_phase = Touch.TouchPhaseMoved} in
        (
          stage#processTouches [ touch ];
          currentTouch.val := Some touch;
        )
      | None -> print_endline "Motion while currentTouch is None"
      ]
  in
  (mouse,motion);

value start_cycle frameRate stage = 
  let fps = 1. /. (float frameRate) in
  let time = ref (Unix.gettimeofday ()) in
  let rec advanceTime () =
    let () = Gc.compact () in
    let () = URLLoader.run () in
    let now = Unix.gettimeofday () in
    (
      let diff = now -. !time in
      stage#advanceTime diff;
      time.val := now;
      Glut.postRedisplay ();
      Glut.timerFunc fps advanceTime;
    )
  in
  Glut.timerFunc fps advanceTime;


value run stage_create = 
  let width = ref 768 and height = ref 1024 and frameRate = ref 30
  and setDeviceType = fun s -> internalDeviceType.val := match s with [ "pad" -> Pad | "phone" -> Phone | _ -> failwith "unknown device type"] in
  (
    Arg.parse [
      ("-w",Arg.Set_int width,"width");("-h",Arg.Set_int height,"height");("-fps",Arg.Set_int frameRate,"frame rate");
      ("-dt",Arg.String setDeviceType,"Set deviceType [phone | pad] default pad");
      ("-um",Arg.Set_int Hardware.internal_user_memory,"Set Hardware.user_memory (default 0)")
    ] (fun _ -> ()) "";
    Glut.init ();
    Glut.initWindowSize !width !height;
    Glut.initDisplayMode [ Glut.GLUT_RGB ; Glut.GLUT_DOUBLE ];
    Glut.creatWindow "LIGHTNING";
    let stage = stage_create (float !width) (float !height) in
    (
      Glut.displayFunc (fun () -> (stage#renderStage (); Glut.swapBuffers ()));
      start_cycle !frameRate stage;
(*       Glut.idleFunc (make_idle_func !frameRate stage); *)
      let (mouse_func,motion_func) = make_mouse_funcs stage in
      (
        Glut.mouseFunc mouse_func;
        Glut.motionFunc motion_func;
      );
      stage#renderStage ();
    );
    Glut.mainLoop ();
  );
