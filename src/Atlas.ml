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
    end;


  value create: Texture.c -> c;

end;

module Make(D:DisplayObjectT.M) = struct
  module D = D;

  module Node = AtlasNode;

  external atlas_render: atlas -> Matrix.t -> Render.prg -> textureID -> bool -> float -> option (DynArray.t Node.t) -> unit = "ml_atlas_render_byte" "ml_atlas_render" "noalloc";

  (* сюда припиздячить glow еще нахуй *)
  class c texture =
    (* нужно сделать фсю gl хуйню *)
    object(self)
      inherit D.c as super;

      value atlas = atlas_init ();
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

      method filters = [];
      method setFilters f = assert False;

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

      method !boundsChanged() =
      (
        dirty := True;
        super#boundsChanged();
      );

      method private render' ?alpha:(alpha') ~transform rect = 
      (
        if DynArray.length children > 0
        then
          (* FIXME: calc alpha *)
          let quads = 
            if dirty 
            then (dirty := False; Some children) 
            else None 
          in
          let alpha = match alpha' with [ Some a -> a *. alpha | None -> alpha ] in
          atlas_render atlas (if transform then self#transformationMatrix else Matrix.identity) shaderProgram texture#textureID texture#hasPremultipliedAlpha alpha quads
        else 
          if dirty
          then atlas_clear_data atlas
          else ();
      );

    end;

    value create = new c;

end;
