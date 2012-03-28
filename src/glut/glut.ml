
external init: unit -> unit = "ml_glutInit" "noalloc";
external initWindowSize: int -> int -> unit = "ml_glutInitWindowSize" "noalloc";

type display_mode = 
  [ GLUT_RGB | GLUT_RGBA | GLUT_INDEX 
  | GLUT_SINGLE | GLUT_DOUBLE | GLUT_ACCUM 
  | GLUT_ALPHA | GLUT_DEPTH | GLUT_STENCIL 
  | GLUT_MULTISAMPLE | GLUT_STEREO | GLUT_LUMINANCE ];


external initDisplayMode: list display_mode -> unit = "ml_glutInitDisplayMode" "noalloc";
external creatWindow: string -> unit = "ml_glutCreateWindow" "noalloc";
external displayFunc: (unit -> unit) -> unit = "ml_glutDisplayFunc";

type mouse_button = [ BUTTON_LEFT | BUTTON_RIGHT | BUTTON_MIDDLE ];
type button_state = [ BUTTON_UP | BUTTON_DOWN ];
type mouse = 
  {
    mouse_button: mouse_button;
    button_state: button_state;
    mouse_x: int;
    mouse_y: int;
  };

external mouseFunc: (mouse -> unit) -> unit = "ml_glutMouseFunc";


external motionFunc: ((int*int) -> unit) -> unit = "ml_glutMotionFunc";
external idleFunc: (unit -> unit) -> unit = "ml_glutIdleFunc";
external postRedisplay: unit -> unit = "ml_glutPostRedisplay" "noalloc";
external swapBuffers: unit -> unit = "ml_glutSwapBuffers" "noalloc";
