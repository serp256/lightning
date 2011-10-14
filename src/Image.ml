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



  module Programs = 

    module Simple = 

      value id = Render.Program.get_id ();

      value create () = 
          Redner.Program.load
            id
            ~vertex:"Image.vsh" ~fragment:"Image.fsh"
            ~attributes:[ AttribPosition; AttribColor ; AttribTexCoords ]
            ~uniforms: [| "u_texture" |];

    end;

    module Glow = 

      value id  = Render.Program.get_id ();
      value create (blurSize:float) (blurColor:int) = 
        Render.Program.load
          id
          ~vertes:"Image.vsh" ~fragment:"Image.fsh"
          ~attributes:[ AttribPosition; AttribColor ; AttribTexCoords ]
          ~uniforms: [| "u_texture"; "blurSize" ; "blurColor" |]
        in (* может быть здесь сразу запиздючить эту дрочь нахуй ? *)
        (
        );
        

    end;

  end;

  class c : [ Texture.c ] ->
    object
      inherit D.c; 
      value texture: Texture.c;
(*       method copyTexCoords: Bigarray.Array1.t float Bigarray.float32_elt Bigarray.c_layout -> unit; *)
      method texture: Texture.c;
      (*
      method texFlipX: bool;
      method setTexFlipX: bool -> unit;
      method texFlipY: bool;
      method setTexFlipY: bool -> unit;
      method texRotation: option [= `left | `right];
      method setTexRotation: option [= `left | `right] -> unit;
      *)
      method setTexture: Texture.c -> unit;
      (*
      method setTexScale: float -> unit;
      *)
      method setColor: int -> unit;
      method color: int;
      method private render': option Rectangle.t -> unit;
      method boundsInSpace: !'space. option (<asDisplayObject: D.c; .. > as 'space) -> Rectangle.t;
    end;

  value cast: #D.c -> option c;

  value load: string -> c;
  value create: Texture.c -> c;
end;

module Make(D:DisplayObjectT.M) = struct
  module D = D;

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


      (*
      value texCoords = 
        let a = make_float_array 8 in
        (
          flushTexCoords a;
          _texture#adjustTextureCoordinates a;
          a
        );
      *)

      value mutable texture: Texture.c = _texture;
      method texture = texture;


      value shaderProgram = 
        Render.Program.load "Image.vsh" "Image.fsh" 
          [ (Render.Program.AttribPosition,"a_position"); (Render.Program.AttribColor,"a_color") ; (Render.Program.AttribTexCoords, "a_texCoord") ]
          [ (`UniformMVPMatrix, "u_MVPMatrix"); (`UniformSampler,"u_texture") ];



      method setFilters filtes = 
        List.fold_left begin fun c
          [ `Glow (glowSize,glowColor) ->
          | 
          ]
        end;

      value image = Render.Image.create _texture#width _texture#height _texture#clipping color 1.;

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

      value mutable texFlipX = False;
      method texFlipX = texFlipX;
      method private applyTexFlipX () = 
      (
        SWAP_TEX_COORDS(0,1);
        SWAP_TEX_COORDS(2,3);
      );
      method setTexFlipX nv = 
        if nv <> texFlipX
        then 
        (
          self#applyTexFlipX ();
          texFlipX := nv;
        )
        else ();

      value mutable texFlipY = False;
      method texFlipY = texFlipY;
      method private applyTexFlipY () = 
      (
        SWAP_TEX_COORDS(0,2);
        SWAP_TEX_COORDS(1,3);
      );

      method setTexFlipY nv = 
        if nv <> texFlipY
        then 
        (
          self#applyTexFlipY ();
          texFlipY := nv;
        )
        else ();


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


      method setTexture nt = 
      (
        Render.Image.update image texture#width texture#height texture#clipping;
        texture := nt;
        (* modified нах *)
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


      method boundsInSpace: !'space. (option (<asDisplayObject: D.c; .. > as 'space)) -> Rectangle.t = fun targetCoordinateSpace ->  (*       let () = Printf.printf "bounds in space %s\n" name in *)
        Rectangle.empty;
      method private render' _ = Render.Image.render self#transformationMatrix shaderProgram texture#textureID texture#hasPremultipliedAlpha image;

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
