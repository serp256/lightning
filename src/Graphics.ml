open Gl;
open LightCommon;

type cmd =
  [= `Color of (int * float) 
  | `Rect of (float*float*float*float)
  | `Circle of (float*float*float)
  | `Ellipse of (float*float*float*float)
  ];

type t = Queue.t cmd;

value create () = Queue.create ();

value beginFill t color alpha = Queue.push (`Color  color alpha) t;

value lineStyle t thickness color alpha (* pixelHinting:Boolean = false, scaleMode:String = "normal", caps:String = null, joints:String = null, miterLimit:Number = 3 *) = assert False;

value drawEllipse t x y width height = assert False;

value drawCircle t x y radius = Queue.push (`Circle x y radius) t;

value drawRect t x y width height = Queue.push (`Rect x y width height) t;

value lineTo t x y = assert False;

value moveTo t x y = assert False;

value endFill t = assert False;

value clear t = Queue.clear t;

value render t = 
  Queue.iter begin fun 
    [ `Color _ -> ()
    | `Rect _ -> ()
    | `Circle x y r ->
        let segs = 360 in
        let verticies = Array.make (segs*2 + 2) 0. in
        (
          let coef = two_pi /. (float segs) in
          for i = 0 to segs do
            let rads = (float i) *. coef in
            let j = r *. (cos rads) +. x
            and k = r *. (sin rads) +.  y
            in
            (
              verticies.(i*2) := j;
              verticies.(i*2 + 1) := k;
            )
          done;
          glDisable gl_texture_2d;
(*           glColor4f 1. 1. 1. 1.; *)
          glLineWidth 2.;
          glEnable gl_line_smooth;
          glEnableClientState gl_vertex_array;
          let verts = Bigarray.Array1.of_array Bigarray.float32 Bigarray.c_layout verticies in
          glVertexPointer 2 gl_float 0 verts;
          glDrawArrays gl_line_loop 0 (segs+1);
          glDisableClientState gl_vertex_array;
          glDisable gl_line_smooth;
          glEnable gl_texture_2d;
        )
    ]
  end t;
