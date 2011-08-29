open Gl;
open LightCommon;

type cmd =
  [ Fill of (float * float * float * float) 
  | EndFill
  | LineStyle of (float * float * float * float * float)
  | Circle of int
  | RoundRect of int
  ];

type t = Queue.t cmd;

value clear t = 
(
  let buffers = 
    Queue.fold begin fun res -> fun
      [ Circle buffer_id -> [ buffer_id :: res ]
      | RoundRect buffer_id -> [ buffer_id :: res ]
      | _ -> res
      ]
    end [] t
  in
  match buffers with 
  [ [] -> ()
  | _ -> 
    let buffers = Array.of_list buffers in
    glDeleteBuffers (Array.length buffers) buffers
  ];
  Queue.clear t;
);

value create () = 
  let res = Queue.create () in
  (
    Gc.finalise clear res;
    res;
  );

value beginFill t color alpha = 
  let (r,g,b) = RenderSupport.floats_of_color color in
  Queue.push (Fill  (r,g,b,alpha)) t;

value lineStyle t thickness color alpha (* pixelHinting:Boolean = false, scaleMode:String = "normal", caps:String = null, joints:String = null, miterLimit:Number = 3 *) = 
  let (r,g,b) = RenderSupport.floats_of_color color in
  Queue.push (LineStyle (thickness,r,g,b,alpha)) t;

value drawEllipse t x y width height = assert False;

value drawCircle t x y r = 
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
    let bfrs = Array.make 1 0 in
    (
      glGenBuffers 1 bfrs;
      glBindBuffer gl_array_buffer bfrs.(0);
      let verts = Bigarray.Array1.of_array Bigarray.float32 Bigarray.c_layout verticies in
      glBufferData gl_array_buffer (Array.length verticies * 4) verts gl_static_draw;
      glBindBuffer gl_array_buffer 0;
      Queue.push (Circle bfrs.(0)) t;
    );
  );

value drawRect t x y width height = assert False;

value drawRoundRect t x y width height ellipseWidth ellipseHeight = 
(*   let vtxs = Array.make 360 0. in *)
  let rectVerts =
    [|
      x; y +. ellipseHeight; x; y +. height -. ellipseHeight;
      x +. ellipseWidth; y; x +. width -. ellipseWidth; y;
      x +. width -. ellipseWidth; y +. height; x +. ellipseWidth; y +. height;
      x +. width; y +. height -. ellipseHeight; x +. width; y +. ellipseHeight;
      x +. width -. ellipseWidth; y; x; y +. height -. ellipseHeight;
      x +. width; y +. ellipseHeight; x +. ellipseWidth; y +. height
    |] 
  in
  let vtxs = Array.make ((Array.length rectVerts) + 364*2) 0. in
  (
    (* rectangle *)
    Array.blit rectVerts 0 vtxs 0 (Array.length rectVerts);
    (* пытаемся нарисовать уголки нах  *)
    let segs = 90 in
    let coef = half_pi /. (float segs) in
    let offset = ref (Array.length rectVerts) in
    (
      (* право верх *)
      let rx = x +. width -. ellipseWidth
      and ry = y +. ellipseHeight in
      for i = 0 to segs do
        let rads = (float i) *. coef in
        let j = ellipseWidth *. (cos rads) +. rx
        and k = ry -. ellipseHeight *. (sin rads)
        in
        (
          vtxs.(!offset) := j;
          vtxs.(!offset + 1) := k;
          offset.val := !offset + 2;
        )
      done;
      (* лево верх *)
      let rx = x +. ellipseWidth
      and ry = y +. ellipseHeight in
      for i = 0 to segs do
        let rads = (float i) *. coef in
        let j = rx -. ellipseWidth *. (cos rads) 
        and k = ry -. ellipseHeight *. (sin rads)
        in
        (
          vtxs.(!offset) := j;
          vtxs.(!offset + 1) := k;
          offset.val := !offset + 2;
        )
      done;
      (* лево низ *)
      let rx = x +. ellipseWidth
      and ry = y +. height -. ellipseHeight in
      for i = 0 to segs do
        let rads = (float i) *. coef in
        let j = rx -. ellipseWidth *. (cos rads) 
        and k = ry +. ellipseHeight *. (sin rads) 
        in
        (
          vtxs.(!offset) := j;
          vtxs.(!offset + 1) := k;
          offset.val := !offset + 2;
        )
      done;
      (* право низ *)
      let rx = x +. width -. ellipseWidth
      and ry = y +. height -. ellipseHeight in
      for i = 0 to segs do
        let rads = (float i) *. coef in
        let j = rx +. ellipseWidth *. (cos rads) 
        and k = ry +. ellipseHeight *. (sin rads) 
        in
        (
          vtxs.(!offset) := j;
          vtxs.(!offset + 1) := k;
          offset.val := !offset + 2;
        )
      done;
    );
    let bfrs = Array.make 1 0 in
    (
      glGenBuffers 1 bfrs;
      glBindBuffer gl_array_buffer bfrs.(0);
      let verts = Bigarray.Array1.of_array Bigarray.float32 Bigarray.c_layout vtxs in
      glBufferData gl_array_buffer ((Array.length vtxs) * 4) verts gl_static_draw;
      Queue.push (RoundRect bfrs.(0)) t;
    )
  );

(*   Queue.push (RoundRect x y width height ellipseWidth ellipseHeight) t; *)

value lineTo t x y = assert False;

value moveTo t x y = assert False;

value endFill t = Queue.push EndFill t;


value render t = 
  if not (Queue.is_empty t) 
  then
  (
    glDisable gl_texture_2d;
    glEnable gl_line_smooth;
    glEnableClientState gl_vertex_array;
    glColor4f 1. 1. 1. 1.;
    glBlendFunc gl_src_alpha gl_one_minus_src_alpha;
    let isFill = ref False in
    Queue.iter begin fun 
      [ Fill (red,green,blue,alpha) -> 
        (
          isFill.val := True;
          glColor4f red green blue alpha;
        )
      | LineStyle (thickness,red,green,blue,alpha) ->
        (
          glLineWidth thickness;
          glColor4f red green blue alpha;
        )
      | Circle buffer_id ->
        (
          glBindBuffer gl_array_buffer buffer_id;
          glVertexPointer 2 gl_float 0 0;
          glDrawArrays (if !isFill then gl_triangle_fan else gl_line_loop) 0 361;
          glBindBuffer gl_array_buffer 0;
        )
      | RoundRect buffer_id -> 
        (
          glBindBuffer gl_array_buffer buffer_id;
          glVertexPointer 2 gl_float 0 0;
          let rectOff = 16 + 8 in
          match !isFill with
          [ True ->
            (
              glDrawArrays gl_triangle_strip 0 4;
              glVertexPointer 2 gl_float 0 32;
              glDrawArrays gl_triangle_strip 0 4;
              glVertexPointer 2 gl_float 0 64;
              glDrawArrays gl_triangle_strip 0 4;
              glVertexPointer 2 gl_float 0 (rectOff * 4);
              glDrawArrays gl_triangle_fan 0 91;
              glVertexPointer 2 gl_float 0 ((rectOff + 182) * 4);
              glDrawArrays gl_triangle_fan 0 91;
              glVertexPointer 2 gl_float 0 ((rectOff + 182 * 2) * 4);
              glDrawArrays gl_triangle_fan 0 91;
              glVertexPointer 2 gl_float 0 ((rectOff + 182 * 3) * 4);
              glDrawArrays gl_triangle_fan 0 91;
            )
          | False -> 
            (
              glDrawArrays gl_lines 0 8;
              glVertexPointer 2 gl_float 0 (rectOff* 4);
              glDrawArrays gl_line_strip 0 91;
              glVertexPointer 2 gl_float 0 ((rectOff + 182) * 4);
              glDrawArrays gl_line_strip 0 91;
              glVertexPointer 2 gl_float 0 ((rectOff + 182*2) * 4);
              glDrawArrays gl_line_strip 0 91;
              glVertexPointer 2 gl_float 0 ((rectOff + 182*3) * 4);
              glDrawArrays gl_line_strip 0 91;
            )
          ];
        )
      | EndFill -> 
        (
          isFill.val := False;
          glColor4f 1. 1. 1. 1.;
        )
      ]
    end t;
    glBindBuffer gl_array_buffer 0;
    glDisableClientState gl_vertex_array;
    glDisable gl_line_smooth;
    glEnable gl_texture_2d;
  )
  else ();
