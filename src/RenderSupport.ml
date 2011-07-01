open Gl;
open LightCommon;

DEFINE SP_COLOR_PART_ALPHA(color) = (color lsr 24) land 0xff;
DEFINE SP_COLOR_PART_RED(color) = (color lsr 16) land 0xff;
DEFINE SP_COLOR_PART_GREEN(color) = (color lsr  8) land 0xff;
DEFINE SP_COLOR_PART_BLUE(color) =  color land 0xff;
DEFINE SP_R2D(rad) = (rad /. pi *. 180.0);

value boundTextureID = ref None;
value premultiplyAlpha = ref False;

value checkForOpenGLError () = 
  let error = glGetError() in
  (
    if error <> 0 then Debug.e "Warning: There was an OpenGL error: #%x\n%!" error else ();
    error
  );

value bindTexture texture = 
  let newTextureID = texture#textureID
  and newPMA = texture#hasPremultipliedAlpha in
  DEFINE bind = glBindTexture gl_texture_2d newTextureID IN
  DEFINE apply_pma =
    match newPMA with
    [ True -> glBlendFunc gl_one gl_one_minus_src_alpha
    | False -> glBlendFunc gl_src_alpha gl_one_minus_src_alpha
    ]
  IN
  match !boundTextureID with
  [ None -> 
    (
      bind;
      apply_pma;
      boundTextureID.val := Some newTextureID;
      premultiplyAlpha.val := newPMA;
    )
  | Some textureID when textureID <> newTextureID ->
    (
      bind;
      boundTextureID.val := Some newTextureID;
      if newPMA <> !premultiplyAlpha
      then 
        (
          premultiplyAlpha.val := newPMA;
          apply_pma
        )
      else ()
    )
  | _ -> ()
  ];


value clearTexture () = 
  match boundTextureID.val with
  [ Some texture ->
    (
      glBindTexture gl_texture_2d 0;
      boundTextureID.val := None;
      if !premultiplyAlpha
      then
      (
        glBlendFunc gl_src_alpha gl_one_minus_src_alpha;
        premultiplyAlpha.val := False;
      )
      else ()
    )
  | None -> ()
  ];

(*
value transformMatrixForObject obj = 
  let x = obj#x
  and y = obj#y 
  and rotation = obj#rotation
  and scaleX = obj#scaleX
  and scaleY = obj#scaleY
  in
  (
    if x <> 0.0 || y <> 0.0 then glTranslatef x  y 0. else ();
    if rotation <> 0.0 then glRotatef (SP_R2D(rotation)) 0. 0. 1.0 else ();
    if scaleX <> 0.0 || scaleY <> 0.0 then glScalef scaleX scaleY 1.0 else ();
  );
*)

value clear color alpha = 
  let red = SP_COLOR_PART_RED(color)
  and green = SP_COLOR_PART_GREEN(color)
  and blue = SP_COLOR_PART_BLUE(color)
  in
  (
    glClearColor ((float red) /. 255.) ((float green) /. 255.) ((float blue) /. 255.) alpha;
    glClear gl_color_buffer_bit;
  );

value setupOrthographicRendering left right bottom top = 
(
  glDisable gl_cull_face;
  glDisable gl_lighting;
  glDisable gl_depth_test;
  glEnable gl_texture_2d;
  glEnable gl_blend;
  
  glMatrixMode gl_projection;
  glLoadIdentity();
  IFDEF GLES THEN
    glOrthof left right bottom top ~-.1.0 1.0
  ELSE
    glOrtho left right bottom top ~-.1.0 1.0
  END;
  glMatrixMode gl_modelview;
  glLoadIdentity();
);


value convertColors red green blue alpha pma = 
  let c = 
    match pma with
    [ True ->
        (int_of_float ((float red) *. alpha)) lor
        (int_of_float ((float green) *. alpha) lsl 8) lor
        (int_of_float ((float blue) *. alpha) lsl 16)
    | False -> red lor (green lsl 8) lor (blue lsl 16)
    ]
  in
  Int32.logor (Int32.of_int c) (Int32.shift_left (Int32.of_float (alpha *. 255.)) 24);

value convertColor ?(pma=premultiplyAlpha.val) color alpha =
  let c = 
    match pma with
    [ True ->
        (int_of_float (float (SP_COLOR_PART_RED(color)) *. alpha)) lor
        (int_of_float (float (SP_COLOR_PART_GREEN(color)) *. alpha) lsl 8) lor
        (int_of_float (float (SP_COLOR_PART_BLUE(color)) *. alpha) lsl 16)
    | False -> 
        (SP_COLOR_PART_RED(color)) lor
        (SP_COLOR_PART_GREEN(color) lsl 8) lor
        (SP_COLOR_PART_BLUE(color) lsl 16)
    ]
  in
  Int32.logor (Int32.of_int c) (Int32.shift_left (Int32.of_float (alpha *. 255.)) 24);


(*
value convertColors ?(pma=premultiplyAlpha.val) color alpha dest = 
  match pma with
  [ True -> 
    (
      dest.{0} := int_of_float (float (SP_COLOR_PART_RED(color)) *. alpha);
      dest.{1} := int_of_float (float (SP_COLOR_PART_GREEN(color)) *. alpha);
      dest.{2} := int_of_float (float (SP_COLOR_PART_BLUE(color)) *. alpha);
      dest.{3} := int_of_float (alpha *. 255.) 
    )
  | False ->
    (
      dest.{0} := SP_COLOR_PART_RED(color);
      dest.{1} := SP_COLOR_PART_GREEN(color);
      dest.{2} := SP_COLOR_PART_BLUE(color);
      dest.{3} := int_of_float (alpha *. 255.);
    )
  ];
*)


