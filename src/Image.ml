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

  module Programs = struct
    open Render.Program;

    module Simple = struct

      value id = gen_id ();
      value create () = 
        let prg = 
          load id ~vertex:"Image.vsh" ~fragment:"Image.fsh"
              ~attributes:[ (AttribPosition,"a_position");(AttribColor,"a_color") ; (AttribTexCoords,"a_texCoord") ]
              ~other_uniforms:[| |]
        in
        (prg,None);

    end;

    module Glow = struct

      value id  = gen_id();
      value create blur = 
        let prg = 
          load id ~vertex:"Image.vsh" ~fragment:"ImageGlow.fsh"
            ~attributes:[ (AttribPosition,"a_position"); (AttribColor,"a_color") ; (AttribTexCoords,"a_texCoord") ]
            ~other_uniforms:[| "u_glowSize" ; "u_glowStrenght"; "u_glowColor" |]
        in
        let f = Render.Filter.glow blur in
        (prg,Some f);
        

    end;

    module ColorMatrix = struct

      value id  = gen_id();
      value create matrix = 
        let prg = 
          load id ~vertex:"Image.vsh" ~fragment:"ImageColorMatrix.fsh"
            ~attributes:[ (AttribPosition,"a_position"); (AttribColor,"a_color") ; (AttribTexCoords,"a_texCoord") ]
            ~other_uniforms:[| "u_matrix" |]
        in
        let f = Render.Filter.color_matrix matrix in
        (prg,Some f);
        

    end;

    module ColorMatrixGlow = struct

      value id  = gen_id();
      value create matrix glow = 
        let prg = 
          load id ~vertex:"Image.vsh" ~fragment:"ImageColorMatrixGlow.fsh"
            ~attributes:[ (AttribPosition,"a_position"); (AttribColor,"a_color") ; (AttribTexCoords,"a_texCoord") ]
            ~other_uniforms:[| "u_matrix"; "u_glowSize"; "u_glowStrenght"; "u_glowColor" |]
        in
        let f = Render.Filter.cmatrix_glow matrix glow in
        (prg,Some f);
        

    end;

  end;

  (*
  value flushTexCoords res = 
  (
    Bigarray.Array1.fill res 0.;
    res.{2} := 1.0; res.{5} := 1.0;
    res.{6} := 1.0; res.{7} := 1.0;
  );
  *)

  class _c  ?(color=0xFFFFFF)  _texture =
    object(self)
      inherit D.c as super;


      value mutable texture: Texture.c = _texture;
      method texture = texture;


      value mutable shaderProgram = Programs.Simple.create ();

      value mutable filters : list Filters.t = [];
      method filters = filters;
      method setFilters fltrs = 
      (
        let f = 
          List.fold_left begin fun c -> fun
            [ `Glow glow ->
              match c with
              [ `simple -> `glow glow
              | `glow p as g -> g
              | `cmatrix m -> `cmatrix_glow (m,glow)
              | `cmatrix_glow (m,_) -> `cmatrix_glow (m,glow)
              ]
            | `ColorMatrix m ->
                match c with
                [ `simple -> `cmatrix m
                | `glow glow -> `cmatrix_glow (m,glow)
                | `cmatrix m -> `cmatrix m
                | `cmatrix_glow (_,glow) -> `cmatrix_glow(m,glow)
                ]
            ]
          end `simple fltrs 
        in
        let prg = 
          match f with
          [ `simple -> Programs.Simple.create ()
          | `glow glow -> Programs.Glow.create glow
          | `cmatrix m -> Programs.ColorMatrix.create m
          | `cmatrix_glow m glow -> Programs.ColorMatrixGlow.create m glow
          ]
        in
        shaderProgram := prg;
        filters := fltrs;
      );

      value image = Render.Image.create _texture#width _texture#height _texture#rootClipping color 1.;

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
      (*
      method private applyTexFlipX () = 
      (
        SWAP_TEX_COORDS(0,1);
        SWAP_TEX_COORDS(2,3);
      );
      *)
      method setTexFlipX nv = 
        if nv <> texFlipX
        then 
        (
          Render.Image.flipTexX image;
          texFlipX := nv;
        )
        else ();

      value mutable texFlipY = False;
      method texFlipY = texFlipY;
      (*
      method private applyTexFlipY () = 
      (
        SWAP_TEX_COORDS(0,2);
        SWAP_TEX_COORDS(1,3);
      );
      *)

      method setTexFlipY nv = 
        if nv <> texFlipY
        then 
        (
          Render.Image.flipTexY image;
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
        );

      (*
      method setTexture nt = 
      (
        self#updateSize nt#width nt#height;
        texture := nt;
        flushTexCoords texCoords;
        texture#adjustTextureCoordinates texCoords;
        if texFlipX then self#applyTexFlipX() else ();
        if texFlipY then self#applyTexFlipY() else ();
        match texRotation with
        [ None -> ()
        | Some `left -> TEX_COORDS_ROTATE_LEFT
        | Some `right -> TEX_COORDS_ROTATE_RIGHT
        ];
      );
      *)


      method boundsInSpace: !'space. (option (<asDisplayObject: D.c; .. > as 'space)) -> Rectangle.t = fun targetCoordinateSpace ->  
        match targetCoordinateSpace with
        [ Some ts when ts#asDisplayObject = self#asDisplayObject -> Rectangle.create 0. 0. texture#width texture#height (* FIXME!!! optimization *)
        | _ -> 
          let vertexCoords = Render.Image.points image in
          let transformationMatrix = self#transformationMatrixToSpace targetCoordinateSpace in
          let ar = Matrix.transformPoints transformationMatrix vertexCoords in
          Rectangle.create ar.(0) ar.(2) (ar.(1) -. ar.(0)) (ar.(3) -. ar.(2))
        ];

      method private render' ?alpha ~transform _ = Render.Image.render (if transform then self#transformationMatrix else Matrix.identity) shaderProgram texture#textureID texture#hasPremultipliedAlpha ?alpha image;

      (*
      method! private render' _ = 
      (
        RenderSupport.bindTexture texture;
        Array.iteri (fun i c -> Quad.gl_quad_colors.{i} := RenderSupport.convertColor c alpha) vertexColors;
        glEnableClientState gl_texture_coord_array;
        glEnableClientState gl_vertex_array;
        glEnableClientState gl_color_array;
        glTexCoordPointer 2 gl_float 0 texCoords;
        glVertexPointer 2 gl_float 0 vertexCoords;
        glColorPointer 4 gl_unsigned_byte 0 Quad.gl_quad_colors;
        glDrawArrays gl_triangle_strip 0 4;
        glDisableClientState gl_texture_coord_array;
        glDisableClientState gl_vertex_array;
        glDisableClientState gl_color_array;
      );
      *)

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
