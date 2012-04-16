open LightCommon;

(* value gl_tex_coords = make_float_array 8; *)

(*
DEFINE SWAP_TEX_COORDS(c1,c2) = 
  let tmpX = texCoords.{c1*2} 
  and tmpY = texCoords.{c1*2+1} in
  (
    texCoords.{c1*2} := texCoords.{c2*2};
    texCoords.{c1*2+1} := texCoords.{c2*2+1};
    texCoords.{c2*2} := tmpX;
    texCoords.{c2*2+1} := tmpY;
  );

DEFINE TEX_COORDS_ROTATE_RIGHT = 
  (
    SWAP_TEX_COORDS(0,2);
    SWAP_TEX_COORDS(1,2);
    SWAP_TEX_COORDS(2,3);
  );

DEFINE TEX_COORDS_ROTATE_LEFT = 
  (
    SWAP_TEX_COORDS(0,1);
    SWAP_TEX_COORDS(1,3);
    SWAP_TEX_COORDS(2,3);
  );

*)



type glow = 
  {
    g_texture: mutable option Texture.c;
    g_image: mutable option Render.Image.t;
    g_make_program: Render.prg;
    g_program: mutable Render.prg;
    g_matrix: mutable Matrix.t;
    g_params: Filters.glow
  };

class virtual base texture = 
  let (programID,shaderProgram) = 
    match texture#kind with
    [ Texture.Simple _ -> (GLPrograms.Image.id,GLPrograms.Image.create ())
    | Texture.Alpha -> (GLPrograms.ImageAlpha.id,GLPrograms.ImageAlpha.create ())
    | Texture.Pallete _ -> (GLPrograms.ImagePallete.id,GLPrograms.ImagePallete.create ())
    ]
  in
  object(self)
    inherit DisplayObject.c as super;
    value mutable texture: Texture.c = texture;
    method texture = texture;
    value mutable programID = programID;
    value mutable shaderProgram = shaderProgram;
    value mutable filters : list Filters.t = [];
    method filters = filters;

    value mutable glowFilter: option glow = None;
    method virtual private updateGlowFilter: unit -> unit;
    method private setGlowFilter g_program glow = 
    (
      match glowFilter with
      [ Some {g_texture=Some gtex;_} -> gtex#release()
      | _ ->  ()
      ];
      let g_make_program = match texture#kind with [ Texture.Simple _ -> GLPrograms.Image.create () | Texture.Alpha -> GLPrograms.ImageAlpha.create () | Texture.Pallete _ -> GLPrograms.ImagePallete.create () ] in
      glowFilter := Some {g_image=None;g_matrix=Matrix.identity;g_texture=None;g_program;g_make_program;g_params=glow};
      self#addPrerender self#updateGlowFilter;
    );

    method setFilters fltrs = 
    (
      let () = debug:filters "set filters [%s] on %s" (String.concat "," (List.map Filters.string_of_t fltrs)) self#name in
      let glow = ref None in
      (
        let f = 
          List.fold_left begin fun c -> fun
            [ `Glow g ->
              (
                glow.val := Some g;
                c
              )
            | `ColorMatrix m -> `cmatrix m
            ]
          end `simple fltrs 
        in
        (
          (* this is ugly, need rewrite *)
          match texture#kind with (*{{{*)
          [ Texture.Simple _ ->
            match f with
            [ `simple when programID <> GLPrograms.Image.id -> 
              (
                programID := GLPrograms.Image.id;
                shaderProgram := GLPrograms.Image.create ()
              )
            | `cmatrix m when programID  <> GLPrograms.ImageColorMatrix.id -> 
              (
                programID := GLPrograms.ImageColorMatrix.id;
                shaderProgram := GLPrograms.ImageColorMatrix.create m
              )
            | _ -> ()
            ]
          | Texture.Pallete _ ->
            match f with
            [ `simple when programID <> GLPrograms.ImagePallete.id -> 
              (
                programID := GLPrograms.ImagePallete.id;
                shaderProgram := GLPrograms.ImagePallete.create ()
              )
            | `cmatrix m when programID <> GLPrograms.ImagePalleteColorMatrix.id -> 
              (
                programID := GLPrograms.ImagePalleteColorMatrix.id;
                shaderProgram := GLPrograms.ImagePalleteColorMatrix.create m
              )
            | _ -> ()
            ]
          | Texture.Alpha ->
            match f with
            [ `simple when programID <> GLPrograms.ImageAlpha.id -> 
              (
                programID := GLPrograms.ImageAlpha.id;
                shaderProgram := GLPrograms.ImageAlpha.create ()
              )
            | `cmatrix m when programID <> GLPrograms.ImageAlphaColorMatrix.id -> 
              (
                programID := GLPrograms.ImageAlphaColorMatrix.id;
                shaderProgram := GLPrograms.ImageAlphaColorMatrix.create m
              )
            | _ -> ()
            ]
          ];(*}}}*)
          match !glow with (*{{{*)
          [ None ->
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
          | Some glow ->
            let gprg = 
              match f with
              [ `simple -> GLPrograms.Image.create ()
              | `cmatrix m  -> GLPrograms.ImageColorMatrix.create m
              ]
            in
            match glowFilter with
            [ Some ({g_params;_} as g) when g_params = glow -> g.g_program := gprg
            | _ -> self#setGlowFilter gprg glow
            ]
          ];(*}}}*)
        )
      );
      filters := fltrs;
    );
  end;

class _c  _texture =
  object(self)
    inherit base _texture as super;


    method !name = if name = ""  then Printf.sprintf "image%d" (Oo.id self) else name;


    value image = Render.Image.create _texture#renderInfo 0xFFFFFF 1.;

    value mutable texFlipX = False;
    method texFlipX = texFlipX;

    value mutable texFlipY = False;
    method texFlipY = texFlipY;


    method setColor color = 
    (
      Render.Image.set_color image color;
      match glowFilter with
      [ Some {g_image=Some img;_} -> Render.Image.set_color img color
      | _ -> ()
      ]
    );
    method color = Render.Image.color image;
    method setColors colors = 
    (
      Render.Image.set_colors image colors;
      match glowFilter with
      [ Some {g_image = Some img; _} -> Render.Image.set_colors img  colors
      | _ -> ()
      ]
    );

    method! setAlpha a =
    (
      super#setAlpha a;
      Render.Image.set_alpha image a;
      match glowFilter with
      [ Some {g_image=Some img;_} -> Render.Image.set_alpha img a
      | _ -> ()
      ];
    );

    (*
    value mutable texScale = 1.;
    method setTexScale s = 
      let k = s /. texScale in
      let width = vertexCoords.{2} *. k 
      and height = vertexCoords.{5} *. k in
      (
        vertexCoords.{2} := width;
        vertexCoords.{5} := height;
        vertexCoords.{6} := width;
        vertexCoords.{7} := height;
        texScale := s;
      );
    *)

    method setTexFlipX nv = 
      if nv <> texFlipX
      then 
      (
        Render.Image.flipTexX image;
        match glowFilter with
        [ Some {g_image = Some img; _ } -> Render.Image.flipTexX img
        | _ -> ()
        ];
        texFlipX := nv;
      )
      else ();

    method setTexFlipY nv = 
      if nv <> texFlipY
      then 
      (
        Render.Image.flipTexY image;
        match glowFilter with 
        [ Some {g_image = Some img; _ } -> Render.Image.flipTexY img
        | _ -> ()
        ];
        texFlipY := nv;
      )
      else ();


    (*
    value mutable texRotation : option [= `left |  `right ] = None ;
    method texRotation = texRotation;

    method setTexRotation r = 
      match texRotation with
        [ None ->
          match r with
          [ Some `right -> (TEX_COORDS_ROTATE_RIGHT; texRotation := r)
          | Some `left -> (TEX_COORDS_ROTATE_LEFT; texRotation := r)
          | None -> ()
          ]
        | Some `left -> 
            match r with
            [ None -> (TEX_COORDS_ROTATE_RIGHT; texRotation := r)
            | Some `right -> assert False
            | Some `left -> ()
            ]
        | Some `right ->
            match r with
            [ None ->  (TEX_COORDS_ROTATE_LEFT; texRotation := r)
            | Some `left -> assert False
            | Some `right -> ()
            ]
        ];
    *)


    method private updateGlowFilter () =
      match glowFilter with
      [ Some ({g_texture = None; g_make_program; g_params = glow; _ } as gf) ->
        let () = debug:glow "update glow filter on %s" self#name in
        let renderInfo = texture#renderInfo in
        let w = renderInfo.Texture.rwidth
        and h = renderInfo.Texture.rheight in
        let hgs =  (powOfTwo glow.Filters.glowSize) - 1 in
        let gs = hgs * 2 in
        let rw = w +. (float gs)
        and rh = h +. (float gs) in
        let tex = Texture.rendered rw rh in
        let cm = Matrix.create ~translate:{Point.x = float hgs; y = float hgs} () in
        let image = Render.Image.create renderInfo 0xFFFFFF 1. in
        (
          tex#activate ();
          Render.clear 0 0.;
          Render.Image.render cm g_make_program image; 
          match glow.Filters.glowKind with
          [ `linear -> proftimer:glow "linear time: %f" RenderFilters.glow_make tex#renderbuffer glow
          | `soft -> proftimer:glow "soft time: %f" RenderFilters.glow2_make tex#renderbuffer glow
          ];
          Render.Image.render cm g_make_program image; 
          tex#deactivate ();
          let g_image = Render.Image.create tex#renderInfo 0xFFFFFF alpha in
          (
            if texFlipX then Render.Image.flipTexX g_image else ();
            if texFlipY then Render.Image.flipTexY g_image else ();
            gf.g_image := Some g_image;
          );
          let mhgs = float ~-hgs in
          gf.g_matrix := Matrix.create ~translate:{Point.x = mhgs; y = mhgs} ();
          gf.g_texture := Some (tex :> Texture.c)
        )
      | _ -> ()
      ];
    (*
    method private updateGlowFilter () = 
      match glowFilter with
      [ Some ({g_texture = None; g_make_program; g_params = glow; _ } as gf) ->
        let () = debug:glow "%s update glow %d" self#name glow.Filters.glowSize in
        let renderInfo = texture#renderInfo in
        let w = renderInfo.Texture.rwidth
        and h = renderInfo.Texture.rheight in
        let g_texture = 
          match renderInfo.Texture.kind with
          [ Texture.Simple _ -> RenderFilters.glow_make renderInfo glow 
          | Texture.Alpha | Texture.Pallete _ -> (* FIXME: м.б. сразу уменьшить ? *)
            let tex = Texture.rendered w h in
            (
              tex#draw (fun () ->
                (
                  Render.clear 0 0.;
                  Render.Image.render Matrix.identity g_make_program image; 
                );
              );
              let res = RenderFilters.glow_make tex#renderInfo glow in
              (
                tex#release ();
                res
              )
            )
          ]
        in
        let g_renderInfo = g_texture#renderInfo in
        let gwidth = g_renderInfo.Texture.rwidth
        and gheight = g_renderInfo.Texture.rheight
        and g_image = Render.Image.create g_renderInfo 0xFFFFFF alpha in
        (
          debug:glow "g_texture: <%ld> [%f:%f] %s" (Texture.int32_of_textureID g_renderInfo.Texture.rtextureID) gwidth gheight (match g_renderInfo.Texture.clipping with [ Some r -> Rectangle.to_string r | None -> "NONE"]);
          if texFlipX then Render.Image.flipTexX g_image else ();
          if texFlipY then Render.Image.flipTexY g_image else ();
          gf.g_matrix := Matrix.create ~translate:{Point.x = (w -. gwidth) /. 2.; y = (h -. gheight) /. 2.} ();
          gf.g_texture := Some g_texture;
          gf.g_image := Some g_image;
        )
      | _ -> Debug.w "update non exist glow"
      ];
    *)
      (*
      match glowFilter with
      [ Some ({g_valid; g_texture; g_cmn; g_image; g_params; _ } as gf) -> 
        (
          if not (Glow.is_valid g_cmn)
          then Glow.make g_cmn texture g_params.Filters.glowSize
          else ();
          if not g_valid 
          then
          (
            let w =  g_cmn.Glow.texture#width *. 2.
            and h = g_cmn.Glow.texture#height *. 2. in
            (
              g_texture#resize w h;
              Render.Image.update g_image w h g_texture#rootClipping;
            );
            Render.Image.set_color g_cmn.Glow.image g_params.Filters.glowColor;
            Render.Image.set_alpha image 1.;
            let prg = GLPrograms.ImageSimple.create () in
            g_texture#draw begin fun () ->
              (
                Render.clear 0 0.;
                Render.Image.render (Matrix.create ~scale:(2.,2.) ()) prg g_cmn.Glow.texture#textureID False g_cmn.Glow.image;
                Render.Image.render (Matrix.create ~translate:{Point.x = g_cmn.Glow.gs;y = g_cmn.Glow.gs} ()) prg texture#textureID texture#hasPremultipliedAlpha image;
              )
            end;
            Render.Image.set_alpha image alpha;
            gf.g_valid := True
          ) else ();
        )
      | _ -> () 
      ];
      *)

    method private updateSize () = 
    (
      Render.Image.update image texture#renderInfo texFlipX texFlipY;
      self#boundsChanged();
    );

    method onTextureEvent (ev:Texture.event) _ = 
    (
      debug "[%s] texture %ld changed" self#name (Texture.int32_of_textureID texture#textureID);
      match ev with
      [ `RESIZE -> self#updateSize()
      | _ -> ()
      ];
      match glowFilter with 
      [ Some gf -> 
        (
          match gf.g_texture with
          [ Some gtex ->
            (
              gtex#release();
              gf.g_texture := None;
              self#addPrerender self#updateGlowFilter;
            )
          | None -> ()
          ]
        )
      | _ -> ()
      ];
    );

    initializer texture#addRenderer (self :> Texture.renderer);

    method setTexture nt = 
      let ot = texture in
      (
        texture := nt;
        if ot#width <> nt#width || ot#height <> nt#height
        then self#updateSize ()
        else Render.Image.update image texture#renderInfo texFlipX texFlipY;
        nt#addRenderer (self :> Texture.renderer);
        match texture#kind with
        [ Texture.Simple _ when programID = GLPrograms.ImagePallete.id ->
          (
            debug "set program to simple";
            programID := GLPrograms.Image.id;
            shaderProgram := GLPrograms.Image.create ()
          )
        | Texture.Simple _ when programID = GLPrograms.ImagePalleteColorMatrix.id -> 
          (
            programID := GLPrograms.ImageColorMatrix.id;
            match shaderProgram with
            [ (_,Some f) -> shaderProgram := GLPrograms.ImageColorMatrix.from_filter f
            | _ -> assert False
            ]
          )
        | Texture.Pallete _ when programID = GLPrograms.Image.id -> 
          (
            debug "set program to pallete";
            programID := GLPrograms.ImagePallete.id;
            shaderProgram := GLPrograms.ImagePallete.create ()
          )
        | Texture.Pallete _ when programID = GLPrograms.ImageColorMatrix.id -> 
          (
            programID := GLPrograms.ImagePalleteColorMatrix.id;
            match shaderProgram with
            [ (_,Some f) -> shaderProgram := GLPrograms.ImagePalleteColorMatrix.from_filter f
            | _ -> assert False
            ]
          )
        | _ -> ()
        ];
        match glowFilter with
        [ Some g -> self#setGlowFilter g.g_program g.g_params
        | None -> ()
        ];
      );

    method boundsInSpace: !'space. (option (<asDisplayObject: DisplayObject.c; .. > as 'space)) -> Rectangle.t = fun targetCoordinateSpace ->  
      match targetCoordinateSpace with
      [ Some ts when ts#asDisplayObject = self#asDisplayObject -> Rectangle.create 0. 0. texture#width texture#height 
      | _ -> 
        (*
        let open Point in
        let vertexCoords = [| {x=0.;y=0.}; {x=texture#width;y=0.}; {x=0.;y=texture#height}; {x=texture#width;y=texture#height} |] in
        *)
        let vertexCoords = Render.Image.points image in
(*           let () = debug "vertex coords len: %d" (Array.length vertexCoords) in *)
(*           let () = debug "vertex coords: %s - %s - %s - %s" (Point.to_string vertexCoords.(0)) (Point.to_string vertexCoords.(1)) (Point.to_string vertexCoords.(2)) (Point.to_string
*           vertexCoords.(3)) in *)
        let transformationMatrix = self#transformationMatrixToSpace targetCoordinateSpace in
        let ar = Matrix.transformPoints transformationMatrix vertexCoords in
        Rectangle.create ar.(0) ar.(2) (ar.(1) -. ar.(0)) (ar.(3) -. ar.(2))
      ];

    method private render' ?alpha:(alpha') ~transform _ = 
    (
      match glowFilter with
      [ Some {g_image=Some g_image;g_matrix;g_program;_} -> 
          Render.Image.render (if transform then Matrix.concat g_matrix self#transformationMatrix else g_matrix) g_program ?alpha:alpha' g_image
      | _ -> Render.Image.render (if transform then self#transformationMatrix else Matrix.identity) shaderProgram ?alpha:alpha' image
      ]
    ); 
end;



class c texture = 
  object(self)
    inherit _c texture;
    method ccast : [= `Image of c ] = `Image (self :> c);
  end;

(*   value memo : WeakMemo.c _c = new WeakMemo.c 1; 

class c texture = 
  object(self)
    inherit _c texture;
    initializer memo#add (self :> c);
  end;

value cast: #D.c -> option c = fun x -> try Some (memo#find x) with [ Not_found -> None ];
*)

value load path = 
  let texture = Texture.load path in
  new c texture;

value load_async path callback = Texture.load_async path (fun texture -> callback (new c texture));

value create = new c;
