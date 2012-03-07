open LightCommon;
type atlas;
external atlas_init: unit -> atlas = "ml_atlas_init";
external atlas_clear_data: atlas -> unit = "ml_atlas_clear" "noalloc";

module type S = sig

  module D : DisplayObjectT.M;

  class c: [ Texture.c ] -> 
    object
      inherit D.c;
      method texture: Texture.c;
      method filters: list Filters.t;
      method setFilters: list Filters.t -> unit;
      method private render': ?alpha:float -> ~transform:bool -> option Rectangle.t -> unit;
      method boundsInSpace: !'space. option (<asDisplayObject: D.c; .. > as 'space) -> Rectangle.t;
      method addChild: ?index:int -> AtlasNode.t -> unit;
      method children: Enum.t AtlasNode.t;
      method clearChildren: unit -> unit;
      method getChildAt: int -> AtlasNode.t;
      method numChildren: int;
      method updateChild: int -> AtlasNode.t -> unit;
      method removeChild: int -> unit;
      method setChildIndex: int -> int -> unit;
    end;


  value create: Texture.c -> c;

end;

module Make(D:DisplayObjectT.M) = struct
  module D = D;

  module Node = AtlasNode;

  external atlas_render: atlas -> Matrix.t -> Render.prg -> textureID -> bool -> float -> option (DynArray.t Node.t) -> unit = "ml_atlas_render_byte" "ml_atlas_render" "noalloc";

  type glow = 
    {
      g_valid: mutable bool;
      g_texture: mutable option Texture.c;
      g_image: Render.Image.t;
      g_matrix: mutable Matrix.t;
      g_params: Filters.glow
    };

  (* сюда припиздячить glow еще нахуй *)
  class c texture =
    (* нужно сделать фсю gl хуйню *)
    object(self)
      inherit D.c as super;

      value atlas = atlas_init ();

      method !name = if name = ""  then Printf.sprintf "atlas%d" (Oo.id self) else name;

      value mutable programID = GLPrograms.ImageSimple.id;
      value mutable shaderProgram = GLPrograms.ImageSimple.create ();

      (* ну вообще не принципиально нихуя чайлды это просто ректы нахуй *)
      value children = DynArray.make 2;
      value mutable dirty = False;
      method numChildren = DynArray.length children;
      method children = DynArray.enum children;
      method texture = texture;

      method addChild ?index child = 
      (
        assert(child.Node.texture = texture);
        match index with
        [ None -> DynArray.add children child
        | Some index ->
            try
              DynArray.insert children index child
            with [ DynArray.Invalid_arg _ -> raise D.Invalid_index ]
        ];
        Node.bounds child |> ignore; (* force calc bounds *)
        self#boundsChanged();
      );

      method getChildAt idx = try DynArray.get children idx with [ DynArray.Invalid_arg _ -> raise D.Invalid_index ];

      method removeChild idx = 
        try
          DynArray.delete children idx;
          self#boundsChanged();
        with [ DynArray.Invalid_arg _ -> raise D.Invalid_index ];

      method updateChild idx child =
      (
        assert(child.Node.texture = texture);
        try
          DynArray.set children idx child;
        with [ DynArray.Invalid_arg _ -> raise D.Invalid_index ];
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
            with [ DynArray.Invalid_arg _ -> raise D.Invalid_index ];
            self#childrenDirty();
          )
        else raise D.Invalid_index;

      value mutable glowFilter = None;

      method private setGlowFilter glow = 
      (
        match glowFilter with
        [ Some {g_texture=Some gtex;_} -> gtex#release()
        | _ -> ()
        ];
        let g_image = Render.Image.create 1. 1. None 0xFFFFFF alpha in
        glowFilter := Some {g_image;g_matrix=Matrix.identity;g_texture=None;g_valid=False;g_params=glow};
        self#addPrerender self#updateGlowFilter;
      );

      method private updateGlowFilter () = 
        let () = debug:glow "update glow" in
        match glowFilter with
        [ Some ({g_texture = None; g_image; g_params = glow; _ } as gf) ->
          (
            let bounds = self#boundsInSpace (Some self) in
            if bounds.Rectangle.width <> 0. && bounds.Rectangle.height <> 0.
            then
              let tex = Texture.rendered bounds.Rectangle.width bounds.Rectangle.height in
              let ip = {Point.x = bounds.Rectangle.x;y=bounds.Rectangle.y} in
              (
                tex#draw (fun () ->
                  (
                    Render.push_matrix (Matrix.create ~translate:(Point.mul ip ~-.1.) ());
                    Render.clear 0 0.;
                    self#render_quads 1. False;
                    Render.restore_matrix ();
                  )
                );
                let g_texture = RenderFilters.glow_make tex#textureID bounds.Rectangle.width bounds.Rectangle.height tex#hasPremultipliedAlpha tex#rootClipping glow in 
                let gwidth = g_texture#width
                and gheight = g_texture#height in
                (
                  debug:glow "g_texture: %d [%f:%f] %s" g_texture#textureID gwidth gheight (match g_texture#rootClipping with [ Some r -> Rectangle.to_string r | None -> "NONE"]);
                  Render.Image.update g_image g_texture#width g_texture#height g_texture#rootClipping False False;
                  let dp = {Point.x=(bounds.Rectangle.width -. gwidth) /. 2.; y = (bounds.Rectangle.height -. gheight) /. 2.} in
                  gf.g_matrix := Matrix.create ~translate:(Point.addPoint ip dp) ();
                  gf.g_texture := Some g_texture;
                  tex#release();
                )
              )
            else ();
            gf.g_valid := True;
          )
        | _ -> ()
        ];

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
          [ `simple when programID <> GLPrograms.ImageSimple.id -> 
            (
              programID := GLPrograms.ImageSimple.id;
              shaderProgram := GLPrograms.ImageSimple.create ()
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

      method boundsInSpace: !'space. (option (<asDisplayObject: D.c; .. > as 'space)) -> Rectangle.t = fun targetCoordinateSpace ->  
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

      method private render_quads alpha transform =
        let quads = 
          if dirty 
          then (dirty := False; Some children) 
          else None 
        in
        atlas_render atlas (if transform then self#transformationMatrix else Matrix.identity) shaderProgram texture#textureID texture#hasPremultipliedAlpha alpha quads;
        

      method private render' ?alpha:(alpha') ~transform rect = 
      (
        if DynArray.length children > 0
        then 
          match glowFilter with
          [ Some {g_texture=Some g_texture; g_image; g_matrix; _ } -> 
            Render.Image.render 
              (if transform then Matrix.concat g_matrix self#transformationMatrix else g_matrix) 
              shaderProgram g_texture#textureID g_texture#hasPremultipliedAlpha ?alpha:alpha' g_image
          | None -> 
              let alpha = match alpha' with [ Some a -> a *. alpha | None -> alpha ] in
              self#render_quads alpha transform
          | _ -> ()
          ]
        else 
          if dirty
          then atlas_clear_data atlas
          else ();
      );

    end;

    value create = new c;

end;
