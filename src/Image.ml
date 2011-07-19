open Gl;
open LightCommon;

(* value gl_tex_coords = make_float_array 8; *)

module type S = sig

  module Q: Quad.S;

  class c : [ Texture.c ] ->
    object
      inherit Q.c; 
      value texture: Texture.c;
      method copyTexCoords: Bigarray.Array1.t float Bigarray.float32_elt Bigarray.c_layout -> unit;
      method texture: Texture.c;
      method flipX: bool;
      method setFlipX: bool -> unit;
      method setTexture: Texture.c -> unit;
    end;

  value cast: #Q.D.c -> option c;

  value load: string -> c;
  value create: Texture.c -> c;
end;

module Make(Q:Quad.S) = struct

  module Q = Q;

  value flushTexCoords res = 
  (
    Bigarray.Array1.fill res 0.;
    res.{2} := 1.0; res.{5} := 1.0;
    res.{6} := 1.0; res.{7} := 1.0;
  );

  class _c  _texture =
    object(self)
      inherit Q.c _texture#width _texture#height as super;


      value texCoords = 
        let a = make_float_array 8 in
        (
          flushTexCoords a;
          (* {{{ remove it
          res.(0) := 1.0; res.(1) := 0.;
          res.(2) := 1.0; res.(3) := 1.0;
          res.(4) := 0.; res.(5) := 0.;
          res.(6) := 0.; res.(7) := 1.;
          *)
          (*
          res.(0) := 0.; res.(1) := 1.;
          res.(2) := 1.0; res.(3) := 1.0;
          res.(4) := 0.; res.(5) := 0.;
          res.(6) := 1.; res.(7) := 0.;
          *)
          (*
          res.(0) := 1.0; res.(1) := 0.;
          res.(2) := 0.; res.(3) := 0.;
          res.(4) := 1.; res.(5) := 1.;
          res.(6) := 0.; res.(7) := 1.;
          }}}*)
          _texture#adjustTextureCoordinates a;
          a
        );

      value mutable texture: Texture.c = _texture;
      method texture = texture;

      method virtual copyTexCoords: Bigarray.Array1.t float Bigarray.float32_elt Bigarray.c_layout -> unit;
      method copyTexCoords dest = (* Array.iteri (fun i a -> Bigarray.Array1.unsafe_set dest i a) texCoords; *)
        Bigarray.Array1.blit texCoords dest;


      value mutable flipX = False;
      method flipX = flipX;
      method private applyFlipX () = 
      (
        let tmpX = texCoords.{0} 
        and tmpY = texCoords.{1} in
        (
          texCoords.{0} := texCoords.{2};
          texCoords.{1} := texCoords.{3};
          texCoords.{2} := tmpX;
          texCoords.{3} := tmpY;
        );
        let tmpX = texCoords.{4} 
        and tmpY = texCoords.{5} in
        (
          texCoords.{4} := texCoords.{6};
          texCoords.{5} := texCoords.{7};
          texCoords.{6} := tmpX;
          texCoords.{7} := tmpY;
        )
      );
      method setFlipX nv = 
        if nv <> flipX
        then 
        (
          self#applyFlipX ();
          flipX := nv;
        )
        else ();

      method setTexture nt = 
      (
        self#updateSize nt#width nt#height;
        texture := nt;
        flushTexCoords texCoords;
        texture#adjustTextureCoordinates texCoords;
        if flipX then self#applyFlipX() else ();
      );

      method! private render' _ = 
      (
        RenderSupport.bindTexture texture;
  (*
        for i = 0 to 3 do
          RenderSupport.convertColors vertexColors.(i) alpha (Bigarray.Array1.sub Quad.gl_quad_colors (i*4) 4);
         done;
  *)
  (*
        let alphaBits =  Int32.shift_left (Int32.of_float (alpha *. 255.)) 24 in
        Array.iteri (fun i c -> Quad.gl_quad_colors.{i} := Int32.logor (Int32.of_int c) alphaBits) vertexColors;
  *)
        Array.iteri (fun i c -> Quad.gl_quad_colors.{i} := RenderSupport.convertColor c alpha) vertexColors;
(*         Array.iteri (fun i a -> Bigarray.Array1.unsafe_set gl_tex_coords i a) texCoords; *)
(*         texture#adjustTextureCoordinates gl_tex_coords; *)
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

    end;

  value memo : WeakMemo.c _c = new WeakMemo.c 1;

  class c texture = 
    object(self)
      inherit _c texture;
      initializer memo#add (self :> c);
    end;

  value cast: #Q.D.c -> option c = fun x -> try Some (memo#find x) with [ Not_found -> None ];

  value load path = 
    let texture = Texture.load path in
    new c texture;

  value create = new c;

end;
