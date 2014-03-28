open LightCommon;

module Node = AtlasNode;

type atlas;
external atlas_init: Texture.renderInfo -> atlas = "ml_atlas_init";
external atlas_clear_data: atlas -> unit = "ml_atlas_clear" "noalloc";
external atlas_render: atlas -> Matrix.t -> Render.prg -> float -> option (DynArray.t Node.t * color) -> unit = "ml_atlas_render" "noalloc";

type glow = 
  {
    g_texture: mutable option RenderTexture.c;
    g_image: mutable option Render.Image.t;
    g_make_program: Render.prg;
    g_program: mutable Render.prg;
    g_matrix: mutable Matrix.t;
    g_valid: mutable bool;
    g_params: mutable Filters.glow
  };

DEFINE RENDER_QUADS(program,transform,color,alpha) = 
  let quads = 
    if dirty 
    then (dirty := False; Some (children,color))
    else None 
  in
  atlas_render atlas transform program alpha quads;

  (* FIXME: нужно hitTestPoint' - наверное перепиздячить нахуй *)
  class _c texture =
    object(self)
      inherit Image.base texture as super;

      value mutable color : color = `NoColor;
      value atlas = atlas_init texture#renderInfo;

      method !name = if name = ""  then Printf.sprintf "atlas%d" (Oo.id self) else name;

(*       value mutable programID = programID; *)
(*       value mutable shaderProgram = shaderProgram; *)

      value children = DynArray.make 2;
      value mutable dirty = False;
      method numChildren = DynArray.length children;
      method children = DynArray.enum children;
(*       method texture = texture; *)

      method addChild ?index child = 
      (
        assert(Node.texture child = texture);
        match index with
        [ None -> DynArray.add children child
        | Some index ->
            try
              DynArray.insert children index child
            with [ DynArray.Invalid_arg _ -> raise (DisplayObject.Invalid_index (index,DynArray.length children))]
        ];
        Node.sync child;
        self#boundsChanged();
      );

      method getChildAt idx = try DynArray.get children idx with [ DynArray.Invalid_arg _ -> raise (DisplayObject.Invalid_index (idx,DynArray.length children))];

      method childIndex node =
        try
          DynArray.index_of (fun c -> c == node) children
        with [ Not_found -> raise DisplayObject.Child_not_found ];

      method removeChild node =
        self#removeChildAt (self#childIndex node);

      method removeChildAt idx = 
        try
          DynArray.delete children idx;
          self#boundsChanged();
        with [ DynArray.Invalid_arg _ -> raise (DisplayObject.Invalid_index (idx,DynArray.length children))];

      method updateChild idx child =
      (
        assert((Node.texture child)= texture);
        try
          DynArray.set children idx child;
        with [ DynArray.Invalid_arg _ -> raise (DisplayObject.Invalid_index (idx,DynArray.length children))];
        Node.sync child; 
        self#boundsChanged();
      );

      method clearChildren () = 
      (
        if not (DynArray.empty children)
        then
        (
          DynArray.clear children;
          self#boundsChanged();
        )
        else ();
      );

      method setChildIndex idx nidx =
        if nidx < DynArray.length children 
        then
          (
            try
              let child = DynArray.get children idx in
              (
                DynArray.delete children idx;
                DynArray.insert children nidx child;
              )
            with [ DynArray.Invalid_arg _ -> raise (DisplayObject.Invalid_index (idx,DynArray.length children))];
            self#childrenDirty();
          )
        else raise (DisplayObject.Invalid_index (nidx,DynArray.length children));


      method private glowMakeProgram () = 
        let module Prg = (value (GLPrograms.select_by_texture texture#kind):GLPrograms.Programs) in
          Prg.Normal.create ();

      value mutable glowFilter = None;
      method private setGlowFilter g_program glow = 
        match glowFilter with
        [ Some ({g_params;_} as g) when g_params = glow -> g.g_program := g_program
        | Some g -> 
          (
            g.g_valid := False;
            g.g_program := g_program;
            g.g_params := glow;
            self#addPrerender self#updateGlowFilter;
          )
        | _ ->  
          (
            let g_make_program = self#glowMakeProgram () in
              glowFilter := Some {g_image=None;g_matrix=Matrix.identity;g_texture=None;g_program;g_make_program;g_params=glow;g_valid=False};
            self#addPrerender self#updateGlowFilter;
          )
        ];

      method private removeGlowFilter () = 
        match glowFilter with 
        [ Some {g_texture;_} -> 
          (
            match g_texture with
            [ Some gtex -> gtex#release() 
            | None -> ()
            ];
            glowFilter := None;
          )
        | _ -> () 
        ];  

      method private updateGlowFilter () = 
        match glowFilter with
        [ Some ({g_valid = False; g_texture; g_image; g_make_program; g_params = glow; _ } as gf) ->  
            let bounds = self#boundsInSpace (Some self) in
            if bounds.Rectangle.width <> 0. && bounds.Rectangle.height <> 0.
            then
              let hgs = (powOfTwo glow.Filters.glowSize) - 1 in
              (
                let gs = hgs * 2 in
                let rw = bounds.Rectangle.width +. (float gs) +. (abs_float (float glow.Filters.x))
                and rh = bounds.Rectangle.height +. (float gs) +. (abs_float (float glow.Filters.y)) in
                let ip = {Point.x = (float hgs) -. bounds.Rectangle.x;y= (float hgs) -. bounds.Rectangle.y} in
                let cm = Matrix.create ~translate:ip () in
                let drawf fb =
                  (
                    debug:drawf "atlas drawf";
                    Render.push_matrix (glowFirstDrawMatrix cm glow.Filters.x glow.Filters.y);
                    RENDER_QUADS(g_make_program,Matrix.identity,`NoColor,1.);

                    match glow.Filters.glowKind with
                    [ `linear -> proftimer:glow "linear time: %f" RenderFilters.glow_make fb glow
                    | `soft -> proftimer:glow "soft time: %f" RenderFilters.glow2_make fb glow
                    ];

                    Render.restore_matrix ();
                    Render.push_matrix (glowLastDrawMatrix cm glow.Filters.x glow.Filters.y);
                    RENDER_QUADS(g_make_program,Matrix.identity,`NoColor,1.);
                    Render.restore_matrix ();
                  )
                in
                match (g_texture,g_image) with
                [ (Some gtex,Some gimg) ->
                  match gtex#draw ~clear:(0,0.) ~width:rw ~height:rh drawf with
                  [ True -> Render.Image.update gimg gtex#renderInfo False False
                  | False -> ()
                  ]
                | (None,None) ->
                  let tex = RenderTexture.draw rw rh drawf in
                  let g_image = Render.Image.create tex#renderInfo color alpha in
                  (
                    gf.g_texture := Some tex;
                    gf.g_image := Some g_image;
                  )
                | _ -> assert False
                ];
                gf.g_matrix := 
                  Matrix.create 
                    ~translate:{Point.x =  (bounds.Rectangle.x -. (float hgs) +. (float glow.Filters.x)); y = (bounds.Rectangle.y -. (float hgs) +. (float glow.Filters.y))} ();
                gf.g_valid := True;
              )
            else gf.g_valid := True
        | _ -> () (* Debug.w "update glow not need" *)
        ];

      method boundsInSpace: !'space. (option (<asDisplayObject: DisplayObject.c; .. > as 'space)) -> Rectangle.t = fun targetCoordinateSpace ->  
        match DynArray.length children with
        [ 0 -> Rectangle.empty
        | _ ->
            let ar = [| max_float; ~-.max_float; max_float; ~-.max_float |] in
            (
              let open Rectangle in
              let matrix = self#transformationMatrixToSpace targetCoordinateSpace in 
              DynArray.iter begin fun child ->
                let childBounds = Matrix.transformRectangle matrix (Node.bounds child) in
                (
                  if childBounds.x < ar.(0) then ar.(0) := childBounds.x else ();
                  let rightX = childBounds.x +. childBounds.width in
                  if rightX > ar.(1) then ar.(1) := rightX else ();
                  if childBounds.y < ar.(2) then ar.(2) := childBounds.y else ();
                  let downY = childBounds.y +. childBounds.height in
                  if downY > ar.(3) then ar.(3) := downY else ();
                )
              end children;
              Rectangle.create ar.(0) ar.(2) (ar.(1) -. ar.(0)) (ar.(3) -. ar.(2))
            )
        ];

      method! setAlpha a =
      (
        super#setAlpha a;
        match glowFilter with
        [ Some {g_image=Some img;_} -> Render.Image.set_alpha img color a False
        | _ -> ()
        ];
      );

      method setColor c =
        if c <> color
        then
          (
            self#forceStageRender ~reason:"atlas set color" ();
            color := c;
            dirty := True;
          )
        else ();

      method color = color;

      method private childrenDirty () =
        if not dirty
        then
        (
          match glowFilter with
          [ Some ({g_valid=True;_} as g) -> 
            (
(*
              match g_texture with
              [ Some tex -> (tex#release (); gf.g_texture := None)
              | None -> () 
              ];
*)
              g.g_valid := False;
              self#addPrerender self#updateGlowFilter;
            )
          | _ -> ()
          ];
          dirty := True; 
        )
        else ();

      method !boundsChanged() =
      (
        self#childrenDirty();
        super#boundsChanged();
      );        
        
      method private render' ?alpha:(alpha') ~transform rect =
        (* proftimer:render "atlas render %f" *)
      (
        if DynArray.length children > 0
        then 
          match glowFilter with
          [ Some {g_valid = True; g_image = Some g_image; g_matrix; g_program; _ } -> 
            Render.Image.render (if transform then Matrix.concat g_matrix self#transformationMatrix else g_matrix) g_program ?alpha:alpha' g_image
          | _ -> 
              let alpha = match alpha' with [ Some a -> a *. alpha | None -> alpha ] in
              RENDER_QUADS(shaderProgram,(if transform then self#transformationMatrix else Matrix.identity),color,alpha)
(*           | _ -> () (* WE NEED ASSERT HERE ?? *) *)
          ]
        else ();
        (*
          if dirty
          then 
          (
            dirty := False;
            atlas_clear_data atlas
          )
          else ();
        *)
      );
    end;

  class c texture = 
    object(self)
      inherit _c texture;
      method ccast: [= `Atlas of c ] = `Atlas (self :> c);
    end;

  class tlf texture =
    object(self)
      inherit c texture as super;

      value mutable stroke = None;

      method! private glowMakeProgram () = 
        let module Prg = (value (GLPrograms.select_by_texture texture#kind):GLPrograms.Programs) in
          match stroke with
          [ Some s -> Prg.Stroke.create s
          | _ -> Prg.Normal.create ()
          ];

      method! setFilters fltrs =
        (
          stroke := try Some (ExtList.List.find_map (fun f -> match f with [ `Stroke s -> Some s | _ -> None ]) fltrs) with [ Not_found -> None ];

          super#setFilters fltrs;

          match stroke with
          [ Some s -> 
            let module Prg = (value (GLPrograms.select_by_texture texture#kind):GLPrograms.Programs) in
              (
                programID := Prg.Stroke.id;
                shaderProgram := Prg.Stroke.create s;
              )
          | _ -> ()          
          ];
        );      
    end;

value create = new c;
value tlf = new tlf;
