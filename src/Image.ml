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


type glowc_id = (int * Filters.glow);
type glowc = 
  {
    g_id: glowc_id;
    g_texture: RenderTexture.c;
    g_matrix: Matrix.t;
  };

module GlowCache = struct

  module Cache = WeakHashtbl.Make (struct
    type t = glowc_id;
    value equal = (=);
    value hash = Hashtbl.hash;
  end);

  value cache = Cache.create 1;

  value id tex glow = ((Oo.id tex),glow);

  value create g_id tex g_texture g_matrix = 
    let glowc = {g_id; g_texture; g_matrix } in
    (
      tex#addRenderer (object
        method onTextureEvent _ _ = Cache.remove cache g_id;
      end);
      Cache.add cache g_id glowc;
      glowc;
    );

  value get gid =
    try
      Some (Cache.find cache gid)
    with [ Not_found -> None ];

end;


type glow = 
  {
    glowc: mutable [= `g_id of glowc_id | `glowc of glowc];
    g_image: mutable option Render.Image.t;
    g_make_program: Render.prg;
    g_program: mutable Render.prg; 
  };

class virtual base texture = 
  let (programID,shaderProgram) = 
    let prgm = GLPrograms.select_by_texture texture#kind in
    let module Prg = (value prgm:GLPrograms.Programs) in
    (Prg.Normal.id,Prg.Normal.create ()) 
  in
  object(self)
    inherit DisplayObject.c as super;
    value mutable blend = None;
    method setBlend b = blend := match b with [ None -> None | Some b -> Some (Render.intblend_of_blend b) ];
    value mutable texture: Texture.c = texture;
    method texture = texture;
    value mutable programID = programID;
    value mutable shaderProgram = shaderProgram;
    value mutable filters : list Filters.t = [];
    method filters = filters;

    method virtual private setGlowFilter: Render.prg -> Filters.glow -> unit;
    method virtual private removeGlowFilter: unit -> unit;

    method virtual private updateGlowFilter: unit -> unit;
    method setFilters fltrs = 
    (
      self#forceStageRender ~reason:"image set filters" ();
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
            | _ -> c
            ]
          end `simple fltrs 
        in
        (
          let module ShaderM = (value (GLPrograms.select_by_texture texture#kind):GLPrograms.Programs) in
          match f with
          [ `simple when programID <> ShaderM.Normal.id -> 
            (
              programID := ShaderM.Normal.id;
              shaderProgram := ShaderM.Normal.create ();
            )
          (* | `cmatrix m when programID  <> ShaderM.ColorMatrix.id ->  *) (* condition removed cause when setting color matrix differ from current, program id stays the same and no referesh take place *)
          | `cmatrix m -> 
            (
              programID := ShaderM.ColorMatrix.id;
              shaderProgram := ShaderM.ColorMatrix.create m;
            )
          | _ -> ()
          ];
          match !glow with (*{{{*)
          [ None -> self#removeGlowFilter ()
          | Some glow ->
            let gprg = 
              match f with
              [ `simple -> GLPrograms.Image.Normal.create ()
              | `cmatrix m  -> GLPrograms.Image.ColorMatrix.create m
              ]
            in
            self#setGlowFilter gprg glow
            (* Move this check to setGlowFilter private method *)
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


    value image = Render.Image.create _texture#renderInfo `NoColor 1.;

    value mutable texFlipX = False;
    method texFlipX = texFlipX;

    value mutable texFlipY = False;
    method texFlipY = texFlipY;

    value mutable color = `NoColor;
    value mutable glowFilter: option glow = None;

    method setColor c =
      if c <> color
      then
        (
          self#forceStageRender ~reason:"image set color" ();
          color := c;
          Render.Image.set_color image c;
          match glowFilter with
          [ Some {g_image=Some img;_} -> Render.Image.set_color img c
          | _ -> ()
          ]
        )
      else ();

    method color = color;


    method! setAlpha a =
    (
      debug:alpha "image set alpha";
      super#setAlpha a;
      Render.Image.set_alpha image color a (match color with [ `QColors _ -> True | _ -> False ]);
      match glowFilter with
      [ Some {g_image=Some img;_} -> Render.Image.set_alpha img color a (match color with [ `QColors _ -> True | _ -> False ])
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


    method private setGlowFilter g_program glow = 
    (
      match glowFilter with
      [ Some ({glowc = (`g_id (_,g_params) | `glowc {g_id=(_,g_params);_});_} as g) when g_params = glow -> g.g_program := g_program
      | Some g -> 
        (
          g.glowc := `g_id (GlowCache.id texture glow);
          g.g_program := g_program;
          self#addPrerender self#updateGlowFilter;
        )
      | _ ->  
        let g_make_program = 
          let module Prg = (value (GLPrograms.select_by_texture texture#kind):GLPrograms.Programs) in
          Prg.Normal.create () 
        in
        (
          glowFilter := Some {glowc=`g_id (GlowCache.id texture glow);g_image=None;g_program;g_make_program};
          self#addPrerender self#updateGlowFilter;
        )
      ];
    );


    method private removeGlowFilter () = glowFilter := None;

    method private updateGlowFilter () =
      match glowFilter with
      [ Some ({glowc = `g_id (_,glow); g_make_program; g_image; _ } as gf) ->
        let () = debug:glow "update glow filter on %s" self#name in
        let glowc_id = GlowCache.id texture glow in
        let glowc = 
          match GlowCache.get glowc_id with
          [ Some glowc -> 
            let () = debug:glow "get it from cache" in
            glowc
          | None ->
              let renderInfo = texture#renderInfo in
              let w = renderInfo.Texture.rwidth
              and h = renderInfo.Texture.rheight in
              let hgs = (powOfTwo glow.Filters.glowSize) - 1 in
              let gs = hgs * 2 in
              let mhgs = float ~-hgs in
              let g_matrix = glowMatrix mhgs glow.Filters.x glow.Filters.y in
              let rw = w +. (float gs) +. (abs_float (float glow.Filters.x))
              and rh = h +. (float gs) +. (abs_float (float glow.Filters.y)) in
              let glowc = GlowCache.get glowc_id in
              let cm = Matrix.create ~translate:{Point.x = float hgs; y = float hgs} () in
              let image = Render.Image.create renderInfo `NoColor 1. in
              let drawf fb =
                (
                  Render.Image.render (glowFirstDrawMatrix cm glow.Filters.x glow.Filters.y) g_make_program image;

                  match glow.Filters.glowKind with
                  [ `linear -> proftimer:glow "linear time: %f" RenderFilters.glow_make fb glow
                  | `soft -> proftimer:glow "soft time: %f" RenderFilters.glow2_make fb glow
                  ];

                  Render.Image.render (glowLastDrawMatrix cm glow.Filters.x glow.Filters.y) g_make_program image;
                )
              in
              let tex = RenderTexture.draw rw rh drawf in
                GlowCache.create glowc_id texture tex g_matrix
          ]
        in
        (
          gf.glowc := `glowc glowc;
          match g_image with
          [ None ->
            let g_image = Render.Image.create glowc.g_texture#renderInfo color alpha in
            (
              if texFlipX then Render.Image.flipTexX g_image else ();
              if texFlipY then Render.Image.flipTexY g_image else ();
              gf.g_image := Some g_image;
            )
          | Some gimg -> Render.Image.update gimg glowc.g_texture#renderInfo ~flipX:texFlipX ~flipY:texFlipY
          ];
        )
      | _ -> ()
      ];

          (*
          match (g_texture,g_image) with
          [ (None,None) ->
            let tex = RenderTexture.draw ~filter:Texture.FilterLinear rw rh drawf in
            (
              let g_image = Render.Image.create tex#renderInfo color alpha in
              (
                if texFlipX then Render.Image.flipTexX g_image else ();
                if texFlipY then Render.Image.flipTexY g_image else ();
                gf.g_image := Some g_image;
              );
              gf.g_texture := Some tex;
            )
          | (Some gtex,Some gimg) ->
              match gtex#draw ~clear:(0,0.) ~width:rw ~height:rh drawf with
              [ True -> 
                let () = debug:glow "texture resized" in
                Render.Image.update gimg gtex#renderInfo ~flipX:texFlipX ~flipY:texFlipY
              | False -> debug:glow "texture not resized"
              ]
          | _ -> assert False
          ];
          gf.g_valid := True;
        )
        *)
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

    method onTextureEvent resized _ = 
    (
      debug "[%s] texture %ld changed" self#name (Texture.int32_of_textureID texture#textureID);
      match resized with
      [ True -> self#updateSize()
      | _ -> ()
      ];
      match glowFilter with 
      [ Some gf -> 
        (
          match gf.glowc with
          [ `glowc {g_id;_} -> (gf.glowc := `g_id g_id; self#addPrerender self#updateGlowFilter)
          | _ -> ()
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
        else
          (
            Render.Image.update image texture#renderInfo texFlipX texFlipY;
            self#forceStageRender ();
          );

        nt#addRenderer (self :> Texture.renderer);
        let module Prg = (value (GLPrograms.select_by_texture texture#kind):GLPrograms.Programs) in
        let pkind = 
          List.fold_left begin fun res -> fun
            [ `ColorMatrix m -> `matrix m
            | _ -> res
            ]
          end `simple filters
        in
        match pkind with
        [ `simple when programID <> Prg.Normal.id -> 
          (
            programID := Prg.Normal.id;
            shaderProgram := Prg.Normal.create ()
          )
        | `matrix m when programID <> Prg.ColorMatrix.id -> 
          (
            programID := Prg.ColorMatrix.id;
            shaderProgram := Prg.ColorMatrix.create m
          )
        | _ -> ()
        ];
        match glowFilter with
        [ Some ({glowc = `glowc {g_id = (_,glow);_};_} as g) -> 
          (
            g.glowc := `g_id (GlowCache.id nt glow);
            self#addPrerender self#updateGlowFilter
          )
        | Some ({glowc = `g_id (_,glow);_} as g) ->
            g.glowc := `g_id (GlowCache.id nt glow)
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
        let () = debug:matrix "call transformPoints" in
        let ar = Matrix.transformPoints transformationMatrix vertexCoords in
        Rectangle.create ar.(0) ar.(2) (ar.(1) -. ar.(0)) (ar.(3) -. ar.(2))
      ];

    method private render' ?alpha:(alpha') ~transform _ = 
    (
      match glowFilter with
      [ Some {glowc=`glowc {g_matrix;g_texture;_}; g_image = Some g_image; g_program;_} ->
        let () = debug:imgrender "111" in
        (* let () = if Sys.file_exists "/tmp/qweqweqwe.png" then () else ignore(g_texture#save "/tmp/qweqweqwe.png") in *)
          Render.Image.render (if transform then Matrix.concat g_matrix self#transformationMatrix else g_matrix) g_program ?alpha:alpha' ?blend:blend g_image
      | _ ->
        let () = debug:imgrender "222" in
          Render.Image.render (if transform then self#transformationMatrix else Matrix.identity) shaderProgram ?alpha:alpha' ?blend:blend image
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

value load ?filter path = 
  let texture = Texture.load ?filter path in
  new c texture;

value load_async path ?filter ?ecallback callback = Texture.load_async path ?filter ?ecallback (fun texture -> callback (new c texture));

value create = new c;
