
external init: unit -> unit = "ml_glutInit" "noalloc";
external initWindowSize: int -> int -> unit = "ml_glutInitWindowSize" "noalloc";

type display_mode = 
  [ GLUT_RGB | GLUT_RGBA | GLUT_INDEX 
  | GLUT_SINGLE | GLUT_DOUBLE | GLUT_ACCUM 
  | GLUT_ALPHA | GLUT_DEPTH | GLUT_STENCIL 
  | GLUT_MULTISAMPLE | GLUT_STEREO | GLUT_LUMINANCE ];


external initDisplayMode: list display_mode -> unit = "ml_glutInitDisplayMode";
external creatWindow: string -> unit = "ml_glutCreateWindow" "noalloc";
external reshapeFunc: (int -> int -> unit) -> unit = "ml_glutReshapeFunc";
external displayFunc: (unit -> unit) -> unit = "ml_glutDisplayFunc";

type mouse_button = [ BUTTON_LEFT | BUTTON_RIGHT | BUTTON_MIDDLE ];
type button_state = [  BUTTON_DOWN | BUTTON_UP ];
type mouse = 
  {
    mouse_button: mouse_button;
    button_state: button_state;
    mouse_x: int;
    mouse_y: int;
  };

external mouseFunc: (mouse -> unit) -> unit = "ml_glutMouseFunc";
external motionFunc: (int -> int -> unit) -> unit = "ml_glutMotionFunc";
external idleFunc: (unit -> unit) -> unit = "ml_glutIdleFunc";

external timerFunc: float -> int -> unit = "ml_glutTimerFunc";

value timer_id = ref 1;
value timers : Hashtbl.t int (unit -> unit) = Hashtbl.create 0;
value timerFunc time f = 
  (
    Hashtbl.add timers !timer_id f;
    timerFunc time !timer_id;
    incr timer_id;
  );
exception Timer_not_found;
value on_timer timer_id = 
  let f = try Hashtbl.find timers timer_id with [ Not_found -> raise Timer_not_found ] in
  f ();

Callback.register "glut_on_timer" on_timer;




external postRedisplay: unit -> unit = "ml_glutPostRedisplay";
external swapBuffers: unit -> unit = "ml_glutSwapBuffers" "noalloc";

external mainLoop: unit -> unit = "ml_glutMainLoop";
