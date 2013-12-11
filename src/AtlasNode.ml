open LightCommon;

type t = 
  {
    texture: Texture.c;
    glpoints: mutable (option (array float));
    clipping: Rectangle.t;
    width: float;
    height: float;
    pos: Point.t;
    color: color;
    alpha: float;
    flipX: bool;
    flipY: bool;
    scaleX: float;
    scaleY: float;
    rotation: float;
    bounds: mutable Rectangle.t;
    name: option string;
    transformPoint: option Point.t;
  };

value create texture rect ?transformPoint ?name ?(pos=Point.empty) ?(scaleX=1.) ?(scaleY=1.) ?rotation ?(flipX=False) ?(flipY=False) ?(color=`NoColor)  ?(alpha=1.) () = 
  let s = texture#scale in
  let tw = texture#width /. s
  and th = texture#height /. s in
  let clipping = Rectangle.create_tm (rect.Rectangle.x /. tw) (rect.Rectangle.y /. th) (rect.Rectangle.width /. tw)  (rect.Rectangle.height /. th) in
  (
    Rectangle.(begin
      adjustClipping texture where
        rec adjustClipping texture =
          match texture#clipping with
          [ None -> ()
          | Some baseClipping ->
            (
              clipping.m_x := baseClipping.x +. clipping.m_x *. baseClipping.width;
              clipping.m_y := baseClipping.y +. clipping.m_y *. baseClipping.height;
              clipping.m_width := clipping.m_width *. baseClipping.width;
              clipping.m_height := clipping.m_height *. baseClipping.height;
              match texture#base with
              [ Some baseTexture -> adjustClipping baseTexture
              | None -> ()
              ]
            )
          ];
      if flipX
      then (clipping.m_x := clipping.m_x +. clipping.m_width; clipping.m_width := ~-.(clipping.m_width))
      else ();
      if flipY
      then (clipping.m_y := clipping.m_y +. clipping.m_height; clipping.m_height := ~-.(clipping.m_height))
      else ();
    end);
    debug "node clipping: %s" (Rectangle.to_string (Obj.magic clipping));
    {
      texture;
      name;
      width=rect.Rectangle.width *. s;
      height=rect.Rectangle.height *. s;
      pos; color; alpha; flipX; flipY; scaleX; scaleY; rotation=match rotation with [ None -> 0. | Some r -> LightCommon.clamp_rotation r];
      glpoints=None;
      bounds=Rectangle.empty;
      clipping=(Obj.magic clipping);
      transformPoint
    };
  );

value pos t = t.pos;
value x t = t.pos.Point.x;
value y t = t.pos.Point.y;
value setX x t = {(t) with pos = {(t.pos) with Point.x}; glpoints = None; bounds=Rectangle.empty};
value setY y t = {(t) with pos = {(t.pos) with Point.y}; glpoints = None; bounds=Rectangle.empty};
value setPos x y t = {(t) with pos = {Point.x;y};glpoints = None; bounds=Rectangle.empty};
value setPosPoint pos t = {(t) with pos; glpoints = None; bounds=Rectangle.empty};
value update ?pos ?scale ?rotation ?flipX ?flipY ?color ?alpha t = 
  let (scaleX,scaleY) = match scale with [ None -> (t.scaleX,t.scaleY) | Some s -> (s,s) ] in
  let (flipX,clipping) = 
    match flipX with
    [ Some fx when t.flipX <> fx -> 
      let open Rectangle in
      (fx,{(t.clipping) with x = t.clipping.x +. t.clipping.width; width = ~-.(t.clipping.width)})
    | _ -> (t.flipX,t.clipping)
    ]
  in
  let (flipY,clipping) = 
    match flipY with
    [ Some fy when t.flipY <> fy -> 
      let open Rectangle in
      (fy, {(clipping) with y = clipping.y +. clipping.height; height = ~-.(clipping.height)})
    | _ -> (t.flipY,clipping)
    ]
  in
  {(t) with 
    pos = match pos with [ None -> t.pos | Some p -> p ]; scaleX; scaleY; 
    color = match color with [ None -> t.color | Some c -> c]; 
    alpha = match alpha with [ None -> t.alpha | Some a -> a];
    rotation = match rotation with [ None -> t.rotation | Some r -> LightCommon.clamp_rotation r];
    flipX; flipY; clipping;
    glpoints = None;
    bounds = Rectangle.empty
  };

value color t = t.color;
value setColor color t = {(t) with color};

value alpha t = t.alpha;
value setAlpha alpha t = {(t) with alpha};

value flipX t = t.flipX;
value setFlipX flipX  t = 
  match t.flipX <> flipX with
  [ True ->
    let open Rectangle in
    { (t) with flipX; clipping = {(t.clipping) with x = t.clipping.x +. t.clipping.width; width = ~-.(t.clipping.width) }}
  | False -> t
  ];

value flipY t = t.flipY;
value setFlipY flipY  t = 
  match t.flipY <> flipY with
  [ True ->
    let open Rectangle in
    { (t) with flipY; clipping = {(t.clipping) with y = t.clipping.y +. t.clipping.height; height = ~-.(t.clipping.height) }}
  | False -> t
  ];

value scaleX t = t.scaleX;
value setScaleX scaleX t = {(t) with scaleX; glpoints = None; bounds=Rectangle.empty};

value scaleY t = t.scaleY;
value setScaleY scaleY t = {(t) with scaleY; glpoints = None; bounds=Rectangle.empty};

value matrix t =
  let m = Matrix.create ~translate:t.pos ~scale:(t.scaleX,t.scaleY) ~rotation:t.rotation () in 
    match t.transformPoint with
    [ Some p ->
      let m' = Matrix.create ~translate:p () in
        Matrix.concat m' m
    | _ -> m
    ];

value calc_glpoints t = 
  let open Point in
  let m = matrix t in
  let p0 = Matrix.transformPoint m {x = 0.; y = 0.} 
  and p1 = Matrix.transformPoint m {x = t.width; y = 0.} 
  and p2 = Matrix.transformPoint m {x = 0.; y = t.height}
  and p3 = Matrix.transformPoint m {x = t.width; y = t.height} in
  [| p0.x; p0.y; p1.x; p1.y; p2.x; p2.y; p3.x; p3.y |];


value sync t = 
  match t.glpoints with
  [ None -> t.glpoints := Some (calc_glpoints t)
  | Some _ -> ()
  ];

value bounds t = 
  match t.bounds == Rectangle.empty with
  [ True ->
    let glpoints = match t.glpoints with [ Some glpoints -> glpoints | None -> let glpoints = calc_glpoints t in (t.glpoints := Some glpoints; glpoints) ] in
    let ar = [| max_float; ~-.max_float; max_float; ~-.max_float |] in
    (
      for i = 0 to 3 do
        let x = glpoints.(i*2)
        and y = glpoints.(i*2 + 1) in
        (
          if ar.(0) > x then ar.(0) := x else ();
          if ar.(1) < x then ar.(1) := x else ();
          if ar.(2) > y then ar.(2) := y else ();
          if ar.(3) < y then ar.(3) := y else ();
        )
      done;
      let b = Rectangle.create ar.(0) ar.(2) (ar.(1) -. ar.(0)) (ar.(3) -. ar.(2)) in
      (
        t.bounds := b;
        b
      )
    )
  | False -> t.bounds
  ];

value width t = (bounds t).Rectangle.width;
value height t = (bounds t).Rectangle.height;
value name t = t.name;
value setName name t = {(t) with name = name};

value texture t = t.texture;
