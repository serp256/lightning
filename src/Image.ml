open Gl;
open LightCommon;

value gl_tex_coords = make_float_array 8;

module type S = sig

  module Q: Quad.S;

  class c : [ Texture.c ] ->
    object
      inherit Q.c; 
      value texture: Texture.c;
      method copyTexCoords: Bigarray.Array1.t float Bigarray.float32_elt Bigarray.c_layout -> unit;
      method texture: Texture.c;
      method setTexture: Texture.c -> unit;
    end;

  value cast: #Q.D.c -> option c;

  value createFromFile: string -> c;
  value create: Texture.c -> c;
end;

module Make(Q:Quad.S) = struct

  module Q = Q;
  print_endline "Make NEW Image module";

  class _c  texture =
    object(self)
      inherit Q.c texture#width texture#height as super;
      value mutable texture: Texture.c = texture;
      method texture = texture;
      method setTexture nt = 
      (
        self#updateSize nt#width nt#height;
        texture := nt;
      );

      value texCoords = 
        let res = Array.make 8 0. in
        (
          res.(2) := 1.0; res.(5) := 1.0;
          res.(6) := 1.0; res.(7) := 1.0;
          res
        );
      method virtual copyTexCoords: Bigarray.Array1.t float Bigarray.float32_elt Bigarray.c_layout -> unit;
      method copyTexCoords dest = Array.iteri (fun i a -> Bigarray.Array1.unsafe_set dest i a) texCoords;

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
        Array.iteri (fun i a -> Bigarray.Array1.unsafe_set gl_tex_coords i a) texCoords;
        texture#adjustTextureCoordinates gl_tex_coords;
        glEnableClientState gl_texture_coord_array;
        glEnableClientState gl_vertex_array;
        glEnableClientState gl_color_array;
        glTexCoordPointer 2 gl_float 0 gl_tex_coords;
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

  (*
  value cast: #DisplayObject.c 'event_type 'event_data -> option (c 'event_type 'event_data) = 
    fun q ->
      match ObjMemo.mem memo (q :> < >) with
      [ True -> Some ((Obj.magic q) : c 'event_type 'event_data)
      | False -> None
      ];
    *)

  value createFromFile path = 
    let texture = Texture.createFromFile path in
    new c texture;

  value create = new c;

end;
