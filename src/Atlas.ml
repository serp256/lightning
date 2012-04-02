open LightCommon;

type atlas;
external atlas_init: Texture.renderInfo -> atlas = "ml_atlas_init";
external atlas_clear_data: atlas -> unit = "ml_atlas_clear" "noalloc";

  module Node = AtlasNode;

  external atlas_render: atlas -> Matrix.t -> Render.prg -> float -> option (DynArray.t Node.t) -> unit = "ml_atlas_render" "noalloc";

  type glow = Image.glow ==
    {
(*       g_valid: mutable bool; *)
      g_texture: mutable option Texture.c;
      g_image: mutable option Render.Image.t;
      g_program: Render.prg;
      g_matrix: mutable Matrix.t;
      g_params: Filters.glow
    };

  class _c texture =
    (*
    let (programID,shaderProgram) = 
      match texture#kind with
      [ Texture.Simple -> (GLPrograms.Image.id,GLPrograms.Image.create ())
      | Texture.Pallete _ -> (GLPrograms.ImagePallete.id,GLPrograms.ImagePallete.create ())
      ]
    in
    *)
    object(self)
      inherit Image.base texture as super;

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
        assert(child.Node.texture = texture);
        match index with
        [ None -> DynArray.add children child
        | Some index ->
            try
              DynArray.insert children index child
            with [ DynArray.Invalid_arg _ -> raise DisplayObject.Invalid_index ]
        ];
        Node.bounds child |> ignore; (* force calc bounds *)
        self#boundsChanged();
      );

      method getChildAt idx = try DynArray.get children idx with [ DynArray.Invalid_arg _ -> raise DisplayObject.Invalid_index ];

      method removeChild idx = 
        try
          DynArray.delete children idx;
          self#boundsChanged();
        with [ DynArray.Invalid_arg _ -> raise DisplayObject.Invalid_index ];

      method updateChild idx child =
      (
        assert(child.Node.texture = texture);
        try
          DynArray.set children idx child;
        with [ DynArray.Invalid_arg _ -> raise DisplayObject.Invalid_index ];
        Node.bounds child |> ignore; (* force calc bounds *)
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
            with [ DynArray.Invalid_arg _ -> raise DisplayObject.Invalid_index ];
            self#childrenDirty();
          )
        else raise DisplayObject.Invalid_index;

(*       value mutable glowFilter = None; *)

      (*
      method private setGlowFilter glow = 
      (
        match glowFilter with
        [ Some {g_texture=Some gtex;_} -> gtex#release()
        | _ -> ()
        ];
        glowFilter := Some {g_image=None;g_matrix=Matrix.identity;g_texture=None;g_valid=False;g_params=glow};
        self#addPrerender self#updateGlowFilter;
      );
      *)

      method private updateGlowFilter () = 
        match glowFilter with
        [ Some ({g_texture = None; g_program; g_params = glow; _ } as gf) ->
          (
            let () = debug:glow "%s update glow %d" self#name glow.Filters.glowSize in
            let bounds = self#boundsInSpace (Some self) in
            if bounds.Rectangle.width <> 0. && bounds.Rectangle.height <> 0.
            then
              let tex = Texture.rendered bounds.Rectangle.width bounds.Rectangle.height in
              let ip = {Point.x = bounds.Rectangle.x;y=bounds.Rectangle.y} in
              (
                (* здесь нужно дать программу правильную *)
                tex#draw (fun () ->
                  (
                    Render.push_matrix (Matrix.create ~translate:(Point.mul ip ~-.1.) ());
                    Render.clear 0 0.;
                    self#render_quads ~program:g_program 1. False;
                    Render.restore_matrix ();
                  )
                );
                let g_texture = RenderFilters.glow_make tex#renderInfo glow  in 
                let () = tex#release() in
                let g_renderInfo = g_texture#renderInfo in
                let g_image = Render.Image.create g_renderInfo 0xFFFFFF alpha in
                let gwidth = g_renderInfo.Texture.rwidth
                and gheight = g_renderInfo.Texture.rheight in
                (
                  debug:glow "g_texture: <%ld> [%f:%f] %s" (Texture.int32_of_textureID g_renderInfo.Texture.rtextureID) gwidth gheight (match g_texture#rootClipping with [ Some r -> Rectangle.to_string r | None -> "NONE"]);
                  let dp = {Point.x=(bounds.Rectangle.width -. gwidth) /. 2.; y = (bounds.Rectangle.height -. gheight) /. 2.} in
                  gf.g_matrix := Matrix.create ~translate:(Point.addPoint ip dp) ();
                  gf.g_texture := Some g_texture;
                  gf.g_image := Some g_image;
                )
              )
            else ();
          )
        | _ -> Debug.w "update glow not need"
        ];

      (*
      value mutable filters = [];
      method filters = filters;
      method setFilters fltrs =
      (
        debug:filters "set filters [%s] on %s" (String.concat "," (List.map Filters.string_of_t fltrs)) self#name;
        let hasGlow = ref False in
        (
          let f = 
            List.fold_left begin fun c -> fun
              [ `Glow glow ->
                (
                  hasGlow.val := True;
                  match glowFilter with
                  [ Some g when g.g_params = glow -> ()
                  | _ -> self#setGlowFilter glow
                  ];
                  c
                )
              | `ColorMatrix m -> `cmatrix m
              ]
            end `simple fltrs 
          in
          match f with
          [ `simple when programID <> GLPrograms.Image.id -> 
            (
              programID := GLPrograms.Image.id;
              shaderProgram := GLPrograms.Image.create ()
            )
          | `cmatrix m -> 
            (
              programID := GLPrograms.ImageColorMatrix.id;
              shaderProgram := GLPrograms.ImageColorMatrix.create m
            )
          | _ -> ()
          ];
          if not !hasGlow 
          then 
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
            ]  
          else ();
        );
        filters := fltrs;
      );
      *)

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
        [ Some {g_image=Some img;_} -> Render.Image.set_alpha img a
        | _ -> ()
        ];
      );

      method private childrenDirty () =
        if not dirty
        then
        (
          match glowFilter with
          [ Some ({g_texture;_} as gf) -> 
            (
              match g_texture with
              [ Some tex -> (tex#release (); gf.g_texture := None)
              | None -> () 
              ];
              self#addPrerender self#updateGlowFilter;
            )
          | None -> ()
          ];
          dirty := True; 
        )
        else ();

      method !boundsChanged() =
      (
        self#childrenDirty();
        super#boundsChanged();
      );

      method private render_quads ?(program=shaderProgram) alpha transform =
        let quads = 
          if dirty 
          then (dirty := False; Some children) 
          else None 
        in
        atlas_render atlas (if transform then self#transformationMatrix else Matrix.identity) program alpha quads;
        

      method private render' ?alpha:(alpha') ~transform rect = 
      (
        if DynArray.length children > 0
        then 
          match glowFilter with
          [ Some {g_image = Some g_image; g_matrix; _ } -> 
            Render.Image.render 
              (if transform then Matrix.concat g_matrix self#transformationMatrix else g_matrix) 
              shaderProgram ?alpha:alpha' g_image
          | None -> 
              let alpha = match alpha' with [ Some a -> a *. alpha | None -> alpha ] in
              self#render_quads alpha transform
          | _ -> () (* WE NEED ASSERT HERE ?? *)
          ]
        else 
          if dirty
          then atlas_clear_data atlas
          else ();
      );

    end;

  class c texture = 
    object(self)
      inherit _c texture;
      method ccast: [= `Atlas of c ] = `Atlas (self :> c);
    end;

value create = new c;

