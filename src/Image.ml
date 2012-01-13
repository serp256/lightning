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
      method updateSize: unit -> unit;
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
    open Render.Program;

    module Simple = struct (*{{{*)

      value id = gen_id ();
      value create () = 
        let prg = 
          load id ~vertex:"Image.vsh" ~fragment:"Image.fsh"
            ~attributes:[ (AttribPosition,"a_position"); (AttribTexCoords,"a_texCoord"); (AttribColor,"a_color")  ]
            ~uniforms:[| ("u_texture",(UInt 0)) |]
        in
        (prg,None);

    end;(*}}}*)

    (*
    module Glowing = struct (*{{{*)

      value id  = gen_id();
      value create () = 
        let prg = 
          load id ~vertex:"Image.vsh" ~fragment:"ImageGlow.fsh"
            ~attributes:[ (AttribPosition,"a_position"); (AttribTexCoords,"a_texCoord"); (AttribColor,"a_color")  ]
            ~uniforms:[| ("u_texture", (UInt 0)) |]
        in
        (prg,None);
        
    end;(*}}}*)
  *)

    module Glow = struct (*{{{*)

      value id  = gen_id();
      value create glow = 
        let prg = 
          load id ~vertex:"Image.vsh" ~fragment:"Glow.fsh"
            ~attributes:[ (AttribPosition,"a_position"); (AttribTexCoords,"a_texCoord"); (AttribColor,"a_color")  ]
            ~uniforms:[| ("u_texture", (UInt 0)) ; ("u_color",UNone) ; ("u_strength",UNone) |]
        in
        let f = Render.Filter.glow glow.Filters.glowColor glow.Filters.glowStrength in
        (prg,Some f);
        
    end;(*}}}*)


    module ColorMatrix = struct (*{{{*)

      value id  = gen_id();
      value create matrix = 
        let prg = 
          load id ~vertex:"Image.vsh" ~fragment:"ImageColorMatrix.fsh"
            ~attributes:[ (AttribPosition,"a_position");  (AttribTexCoords,"a_texCoord"); (AttribColor,"a_color") ]
            ~uniforms:[| ("u_matrix",UNone) |]
        in
        let f = Render.Filter.color_matrix matrix in
        (prg,Some f);
        
    end;(*}}}*)

  end;(*}}}*)

  module Glow = struct

    type t = 
      {
        texture: Texture.rendered;
        matrix: mutable Matrix.t;
      };

    (* здесь кэш *)
    module GCache = WeakHashtbl.Make (struct
      type t = (Texture.c * int);
      value equal = (=);
      value hash = Hashtbl.hash;
    end);

    value cache = GCache.create 1;

    value _glowPrg = ref None;
    value glowPrg () = 
      match !_glowPrg with
      [ None -> 
        let open Render.Program in
        let prg = 
          load_force ~vertex:"Image.vsh" ~fragment:"ImageGlow.fsh" 
            ~attributes:[ (AttribPosition,"a_position"); (AttribTexCoords,"a_texCoord"); (AttribColor,"a_color")  ] 
            ~uniforms:[| ("u_texture", (UInt 0)) |] 
          in
          (
            _glowPrg.val := Some prg;
            prg;
          )
      | Some prg -> prg
      ];

    value gmake texture size rtexcreate = 
      let w = texture#width 
      and h = texture#height 
      in
      let hw = w /. 2.
      and hh = h /. 2. in
      let hgs = 2. ** (float size) -. 1. in
      let gs = hgs *. 2. in
      let wdth = hw  +. gs 
      and hght = hh  +. gs
      in
      let rtexture = rtexcreate wdth hght in
      let mgs = ~-.gs in
      let matrix = Matrix.create ~scale:(2.,2.) ~translate:{Point.x=mgs;y=mgs} () in 
      (
        let image = Render.Image.create w h texture#rootClipping 0xFFFFFF 1. in
        let glowPrg = glowPrg () in
        let m = Matrix.create ~scale:(0.5,0.5) ~translate:{Point.x = hgs; y = hgs} () in
        rtexture#draw (fun () ->
          Render.Image.render m (glowPrg,None) texture#textureID texture#hasPremultipliedAlpha image;
        );
        if size > 1 then Render.Filter.glow_resize rtexture#framebufferID rtexture#textureID rtexture#realWidth rtexture#realHeight size else ();
        {texture=rtexture;matrix}
      );


    value create texture size = 
      let key = (texture,size) in
      let () = debug:glow "try create glow %d:%d" texture#textureID size in
      try
        let t = GCache.find cache key in
        let () = debug:glow "finded in cache" in
        let image = Render.Image.create t.texture#width t.texture#height t.texture#rootClipping 0 1. in
        (t,image)
      with [ Not_found -> 
        let t = gmake texture size Texture.rendered in
        let lid =
          texture#addOnChangeListener begin fun texture ->
            let () = debug:glow "texture changed remake glow" in
            let t = GCache.find cache (texture,size) in
            let t' = gmake texture size (fun w h -> (t.texture#resize w h; t.texture)) in
            t.matrix := t'.matrix
          end
        in
        (
          GCache.add cache key t;
          Gc.finalise (fun t -> (debug:glow "finalize %d:%d" t.texture#textureID size; GCache.remove cache key; (fst key)#removeOnChangeListener lid)) t;
          let image = Render.Image.create t.texture#width t.texture#height t.texture#rootClipping 0 1. in
          (t,image)
        )
      ];


  end;

  type glow = 
    {
      gtex: Glow.t;
      image: Render.Image.t;
      prg: Render.prg;
      params: Filters.glow
    };


  class _c  ?(color=0xFFFFFF)  _texture =
    object(self)
      inherit D.c as super;


      value mutable texture: Texture.c = _texture;
      method texture = texture;


      value mutable programID = Programs.Simple.id;
      value mutable shaderProgram = Programs.Simple.create ();
      value image = Render.Image.create _texture#width _texture#height _texture#rootClipping color 1.;

      value mutable filters : list Filters.t = [];
      value mutable glowFilter: option glow = None;

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
                  (*
                  match glowFilter with
                  [ Some g when g.params = glow -> ()
                  | _ -> 
                      let (gtex,image) = Glow.create texture glow.Filters.glowSize in
                      let gl = { gtex; image; prg = Programs.Glow.create glow; params = glow} in
                      glowFilter := Some gl
                  ];
                  *)
                  c
                )
              | `ColorMatrix m -> `cmatrix m
              ]
            end `simple fltrs 
          in
          match f with
          [ `simple when programID <> Programs.Simple.id -> 
            (
              programID := Programs.Simple.id;
              shaderProgram := Programs.Simple.create ()
            )
          | `cmatrix m -> 
            (
              programID := Programs.ColorMatrix.id;
              shaderProgram := Programs.ColorMatrix.create m
            )
          | _ -> ()
          ];
          if not !hasGlow && glowFilter <> None then glowFilter := None else ();
        );
        filters := fltrs;
      );


      method setColor color = Render.Image.set_color image color;
      method color = Render.Image.color image;

      method! setAlpha a =
      (
        super#setAlpha a;
        Render.Image.set_alpha image a;
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
          [ Some g -> Render.Image.flipTexX g.image
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
          [ Some g -> Render.Image.flipTexY g.image
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

      method updateSize () = 
      (
        Render.Image.update image texture#width texture#height texture#rootClipping;
        if texFlipX then Render.Image.flipTexX image else ();
        if texFlipY then Render.Image.flipTexY image else ();
        self#boundsChanged();
      );

      method setTexture nt = 
        let ot = texture in
        (
          texture := nt;
          if ot#width <> nt#width || ot#height <> nt#height
          then self#updateSize ()
          else Render.Image.update image texture#width texture#height texture#rootClipping;
          match glowFilter with
          [ Some g -> 
            let (gtex,image) = Glow.create texture g.params.Filters.glowSize in
            let gl = { (g) with gtex; image } in
            glowFilter := Some gl
          | None -> ()
          ];
        );

      method boundsInSpace: !'space. (option (<asDisplayObject: D.c; .. > as 'space)) -> Rectangle.t = fun targetCoordinateSpace ->  
        match targetCoordinateSpace with
        [ Some ts when ts#asDisplayObject = self#asDisplayObject -> Rectangle.create 0. 0. texture#width texture#height (* FIXME!!! optimization *)
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

      method private render' ?alpha ~transform _ = 
      (
        match glowFilter with
        [ Some g -> Render.Image.render (if transform then Matrix.concat g.gtex.Glow.matrix self#transformationMatrix else g.gtex.Glow.matrix) g.prg g.gtex.Glow.texture#textureID g.gtex.Glow.texture#hasPremultipliedAlpha ?alpha g.image
        | None -> ()
        ];
        Render.Image.render (if transform then self#transformationMatrix else Matrix.identity) shaderProgram texture#textureID texture#hasPremultipliedAlpha ?alpha image
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
