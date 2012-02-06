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

module type S = sig

  module D : DisplayObjectT.M;



  class c : [ Texture.c ] ->
    object
      inherit D.c; 
      value texture: Texture.c;
(*       method copyTexCoords: Bigarray.Array1.t float Bigarray.float32_elt Bigarray.c_layout -> unit; *)
      method texture: Texture.c;
      method texFlipX: bool;
      method setTexFlipX: bool -> unit;
      method texFlipY: bool;
      method setTexFlipY: bool -> unit;
      (*
      method texRotation: option [= `left | `right];
      method setTexRotation: option [= `left | `right] -> unit;
      *)
(*       method updateSize: unit -> unit; *)
      method onTextureEvent: Texture.event -> Texture.c -> unit;
      method setTexture: Texture.c -> unit;
      (*
      method setTexScale: float -> unit;
      *)
      method setColor: int -> unit;
      method color: int;
      method filters: list Filters.t;
      method setFilters: list Filters.t -> unit;
      method private render': ?alpha:float -> ~transform:bool -> option Rectangle.t -> unit;
      method boundsInSpace: !'space. option (<asDisplayObject: D.c; .. > as 'space) -> Rectangle.t;
    end;

  value cast: #D.c -> option c;

  value load: string -> c;
  value create: Texture.c -> c;
end;


module Make(D:DisplayObjectT.M) = struct
  module D = D;



  module Programs = struct (*{{{*)


  end;(*}}}*)

  (*
  module Glow = struct (*{{{*)

    type t = 
      {
        valid_size: mutable bool;
        valid_content: mutable bool;
        texture: Texture.rendered;
        image: Render.Image.t;
        gs:float;
        matrix: Matrix.t;
      };

    (* здесь кэш *)
    module GCache = WeakHashtbl.Make (struct
      type t = (Texture.c * int);
      value equal = (=);
      value hash = Hashtbl.hash;
    end);

    value cache = GCache.create 1;

    (*
    value _glowPrg = ref None;
    value glowPrg () = 
      match !_glowPrg with
      [ None -> 
        let open Render.Program in
        let prg = 
          load_force ~vertex:"Image.vsh" ~fragment:"GlowCut.fsh" 
            ~attributes:[ (AttribPosition,"a_position"); (AttribTexCoords,"a_texCoord"); (AttribColor,"a_color")  ] 
            ~uniforms:[| ("u_texture", (UInt 0)) |] 
          in
          (
            _glowPrg.val := Some prg;
            prg;
          )
      | Some prg -> prg
      ];
    *)

    value make t texture size = 
      (
        let () = debug:glow "draw glow for texture: %d" texture#textureID in
        let w = texture#width
        and h = texture#height in
        (
          if not t.valid_size
          then
            (
              let wdth = w /. 2. +. t.gs
              and hght = h /. 2. +. t.gs in
              t.texture#resize wdth hght
            )
          else ();
          (*
          let glowPrg = glowPrg () in
          let m = Matrix.create ~scale:(0.5,0.5) ~translate:{Point.x = t.gs; y = t.gs} () in
          t.texture#draw (fun () ->
            (
              Render.clear 0 0.;
              Render.Image.render m (glowPrg,None) texture#textureID texture#hasPremultipliedAlpha image;
            )
          );
          *)
          Render.Filter.glow_make t.texture#framebufferID t.texture#textureID t.texture#width t.texture#height t.texture#rootClipping (Some (texture#textureID,w,h,texture#rootClipping)) size;
          (*
          let image = Render.Image.create w h texture#rootClipping 0xFFFFFF 1. in
          let prg = glowPrg () in
          let m = Matrix.create ~translate:{Point.x = t.gs; y = t.gs} () in
          (* и теперь !!! *)
          t.texture#draw (fun () ->
(*             let () = Render.clear 0 0. in *)
            Render.Image.render m (prg,None) texture#textureID texture#hasPremultipliedAlpha image;
          )
          *)
        );
        t.valid_size := True;
        t.valid_content := True;
      );

    value create texture size = 
      let key = (texture,size) in
      let () = debug:glow "try create glow %d:%d" texture#textureID size in
      try
        let t = GCache.find cache key in
        let () = debug:glow "finded in cache" in
        t
      with [ Not_found -> 
        let t = 
          let w = texture#width 
          and h = texture#height
          in
          let gs = (2. ** (float size) -. 1.) *. 2. in
          let wdth = w /. 2.  +.  gs 
          and hght = h /. 2. +.  gs
          in
          let () = debug:glow "size of glow %f:%f" wdth hght in
          let rtexture = Texture.rendered wdth hght in
          let () = rtexture#setPremultipliedAlpha True in (* ??? *)
          let mgs = ~-.gs in
          let matrix = Matrix.create ~scale:(2.,2.) ~translate:{Point.x=mgs;y=mgs} () in 
          let image = Render.Image.create wdth hght rtexture#rootClipping 0xFFFFFF 1. in
          {valid_size=True;valid_content=False;texture=rtexture;image;gs;matrix}
        in
        (
          GCache.add cache key t;
          Gc.finalise (fun t -> (debug:glow "finalize %d:%d" t.texture#textureID size; GCache.remove cache key)) t;
          t
        )
      ];


    value invalidate_content t = t.valid_content := False;
    value invalidate_size t = t.valid_size := False;
    value is_valid t = t.valid_content && t.valid_size;

  end;(*}}}*)
  *)

  type glow = 
    {
(*       g_cmn: Glow.t; *)
(*       g_valid: mutable bool; *)
      g_texture: mutable option Texture.c;
      g_image: Render.Image.t;
(*       g_prg: Render.prg; *)
      g_matrix: mutable Matrix.t;
      g_params: Filters.glow
    };


  class _c  ?(color=0xFFFFFF)  _texture =
    object(self)
      inherit D.c as super;


      method !name = if name = ""  then Printf.sprintf "image%d" (Oo.id self) else name;

      value mutable texture: Texture.c = _texture;
      method texture = texture;


      value mutable programID = GLPrograms.ImageSimple.id;
      value mutable shaderProgram = GLPrograms.ImageSimple.create ();
      value image = Render.Image.create _texture#width _texture#height _texture#rootClipping color 1.;

      value mutable filters : list Filters.t = [];
      value mutable glowFilter: option glow = None;
      method private setGlowFilter glow = 
      (
        match glowFilter with
        [ Some {g_texture=Some gtex;_} -> gtex#release()
        | _ -> ()
        ];
(*         let gtexture = RenderFilters.glow_make texture#textureID texture#width texture#height texture#rootClipping glow in *)
        (*
        let g_cmn = Glow.create texture glow.Filters.glowSize in
        let open Glow in
        let w = g_cmn.Glow.texture#width *. 2. and h = g_cmn.Glow.texture#height *. 2. in
        let g_texture = Texture.rendered w h in
        let () = g_texture#setPremultipliedAlpha False in
        let g_image = Render.Image.create w h g_texture#rootClipping 0xFFFFFF alpha in
        let gl = {g_cmn; g_texture; g_prg = GLPrograms.ImageSimple.create (); g_valid = False; g_image; g_params = glow} in
        *)
        let g_image = Render.Image.create 1. 1. None 0xFFFFFF alpha in
        glowFilter := Some {g_image;g_matrix=Matrix.identity;g_texture=None;g_params=glow};
        self#addPrerender self#updateGlowFilter;
      );

      method filters = filters;

      method setFilters fltrs = 
      (
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


      method setColor color = Render.Image.set_color image color;
      method color = Render.Image.color image;

      method! setAlpha a =
      (
        super#setAlpha a;
        Render.Image.set_alpha image a;
        match glowFilter with
        [ Some g -> Render.Image.set_alpha g.g_image a
        | None -> ()
        ];
      );

(*       method virtual copyTexCoords: Bigarray.Array1.t float Bigarray.float32_elt Bigarray.c_layout -> unit; *)
(*       method copyTexCoords dest = (* Array.iteri (fun i a -> Bigarray.Array1.unsafe_set dest i a) texCoords; *) *)
(*         Bigarray.Array1.blit texCoords dest; *)


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

      value mutable texFlipX = False;
      method texFlipX = texFlipX;
      method setTexFlipX nv = 
        if nv <> texFlipX
        then 
        (
          Render.Image.flipTexX image;
          match glowFilter with
          [ Some g -> Render.Image.flipTexX g.g_image
          | None -> ()
          ];
          texFlipX := nv;
        )
        else ();

      value mutable texFlipY = False;
      method texFlipY = texFlipY;
      method setTexFlipY nv = 
        if nv <> texFlipY
        then 
        (
          Render.Image.flipTexY image;
          match glowFilter with 
          [ Some g -> Render.Image.flipTexY g.g_image
          | None -> ()
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
        let () = debug:glow "update glow" in
        match glowFilter with
        [ Some ({g_texture = None; g_image; g_params = glow; _ } as gf) ->
          let w = texture#width
          and h = texture#height in
          let g_texture = RenderFilters.glow_make texture#textureID w h texture#hasPremultipliedAlpha texture#rootClipping glow in 
          let gwidth = g_texture#width
          and gheight = g_texture#height in
          (
            debug:glow "g_texture: %d [%f:%f] %s" g_texture#textureID gwidth gheight (match g_texture#rootClipping with [ Some r -> Rectangle.to_string r | None -> "NONE"]);
            Render.Image.update g_image g_texture#width g_texture#height g_texture#rootClipping;
            gf.g_matrix := Matrix.create ~translate:{Point.x = (w -. gwidth) /. 2.; y = (h -. gheight) /. 2.} ();
            gf.g_texture := Some g_texture;
          )
        | _ -> ()
        ];
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
        debug "update image size: %d" texture#textureID;
        Render.Image.update image texture#width texture#height texture#rootClipping;
        if texFlipX then Render.Image.flipTexX image else ();
        if texFlipY then Render.Image.flipTexY image else ();
        self#boundsChanged();
      );

      method onTextureEvent (ev:Texture.event) _ = 
      (
        debug "[%s] texture %d changed" self#name texture#textureID;
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
          else Render.Image.update image texture#width texture#height texture#rootClipping;
          nt#addRenderer (self :> Texture.renderer);
          match glowFilter with
          [ Some g -> self#setGlowFilter g.g_params
          | None -> ()
          ];
        );

      method boundsInSpace: !'space. (option (<asDisplayObject: D.c; .. > as 'space)) -> Rectangle.t = fun targetCoordinateSpace ->  
        match targetCoordinateSpace with
        [ Some ts when ts#asDisplayObject = self#asDisplayObject -> Rectangle.create 0. 0. texture#width texture#height (* FIXME!!! when rotate incorrect optimization *)
        | _ -> 
          (*
          let open Point in
          let vertexCoords = [| {x=0.;y=0.}; {x=texture#width;y=0.}; {x=0.;y=texture#height}; {x=texture#width;y=texture#height} |] in
          *)
          let vertexCoords = Render.Image.points image in
          let () = debug "vertex coords len: %d" (Array.length vertexCoords) in
          let () = debug "vertex coords: %s - %s - %s - %s" (Point.to_string vertexCoords.(0)) (Point.to_string vertexCoords.(1)) (Point.to_string vertexCoords.(2)) (Point.to_string vertexCoords.(3)) in
          let transformationMatrix = self#transformationMatrixToSpace targetCoordinateSpace in
          let ar = Matrix.transformPoints transformationMatrix vertexCoords in
          Rectangle.create ar.(0) ar.(2) (ar.(1) -. ar.(0)) (ar.(3) -. ar.(2))
        ];

      method private render' ?alpha:(alpha') ~transform _ = 
      (
        match glowFilter with
        [ Some {g_texture=Some g_texture;g_image;g_matrix;_} -> 
          (
            (*
            if not g.valid
            then 
            (
              Render.Image.update g.image g.gtex.Glow.texture#width g.gtex.Glow.texture#height g.gtex.Glow.texture#rootClipping;
              g.valid := True
            ) else ();
            *)
            Render.Image.render 
              (if transform then Matrix.concat g_matrix self#transformationMatrix else g_matrix) 
              shaderProgram g_texture#textureID g_texture#hasPremultipliedAlpha ?alpha:alpha' g_image
          )
        | None ->
          Render.Image.render 
            (if transform then self#transformationMatrix else Matrix.identity) 
            shaderProgram texture#textureID texture#hasPremultipliedAlpha ?alpha:alpha' image
        | _ -> assert False
        ]
      ); 
  end;

  value memo : WeakMemo.c _c = new WeakMemo.c 1;

  class c texture = 
    object(self)
      inherit _c texture;
      initializer memo#add (self :> c);
    end;

  value cast: #D.c -> option c = fun x -> try Some (memo#find x) with [ Not_found -> None ];

  value load path = 
    let texture = Texture.load path in
    new c texture;

  value create = new c;

end;
