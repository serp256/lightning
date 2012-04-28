open LightCommon;

type t = 
  {
    texture: Texture.c;
    bounds: mutable Rectangle.t;
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
  };

value create texture rect ?(pos=Point.empty) ?(scaleX=1.) ?(scaleY=1.) ?(color=`NoColor) ?(flipX=False) ?(flipY=False) ?(alpha=1.) () = 
  let tw = texture#width
  and th = texture#height in
  let clipping = Rectangle.create_tm (rect.Rectangle.x /. tw) (rect.Rectangle.y /. th) (rect.Rectangle.width /. tw)  (rect.Rectangle.height /. th) in
  (
    Rectangle.( begin
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
    end );
    debug "node clipping: %s" (Rectangle.to_string (Obj.magic clipping));
    {
      texture;
      width=rect.Rectangle.width;
      height=rect.Rectangle.height;
      pos; color; alpha; flipX; flipY; scaleX; scaleY; rotation=0.;
      bounds=Rectangle.empty;
      clipping=(Obj.magic clipping)
    };
  );

value pos t = t.pos;
value x t = t.pos.Point.x;
value y t = t.pos.Point.y;
value setX x t = {(t) with pos = {(t.pos) with Point.x}; bounds=Rectangle.empty};
value setY y t = {(t) with pos = {(t.pos) with Point.y}; bounds=Rectangle.empty};
value setPos x y t = {(t) with pos = {Point.x;y};bounds=Rectangle.empty};
value setPosPoint pos t = {(t) with pos;bounds=Rectangle.empty};
value update ?pos ?scale ?color ?alpha t = 
  let (scaleX,scaleY) = match scale with [ None -> (t.scaleX,t.scaleY) | Some s -> (s,s) ] in
  {(t) with 
    pos = match pos with [ None -> t.pos | Some p -> p ]; scaleX; scaleY; 
    color = match color with [ None -> t.color | Some c -> c]; 
    alpha = match alpha with [ None -> t.alpha | Some a -> a];
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
value setScaleX scaleX t = {(t) with scaleX; bounds=Rectangle.empty};


value scaleY t = t.scaleY;
value setScaleY scaleY t = {(t) with scaleY; bounds=Rectangle.empty};

value bounds t = 
  match t.bounds == Rectangle.empty with
  [ True ->
    let m = Matrix.create ~translate:t.pos ~scale:(t.scaleX,t.scaleY) ~rotation:t.rotation () in
    let b = 
      let ar = Matrix.transformPoints m [| Point.empty; {Point.x=0.;y=t.height}; {Point.x=t.width;y=0.}; {Point.x=t.width;y=t.height} |] in
      Rectangle.create ar.(0) ar.(2) (ar.(1) -. ar.(0)) (ar.(3) -. ar.(2))
    in
    (
      t.bounds := b;
      b
    )
  | False -> t.bounds
  ];

value width t = (bounds t).Rectangle.width;
value height t = (bounds t).Rectangle.height;

value texture t = t.texture;
