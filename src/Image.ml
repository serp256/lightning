open Gl;
open LightCommon;

value memo = ObjMemo.create 1;
value gl_tex_coords = make_float_array 8;

class c [ 'event_type, 'event_data ] texture =
  object(self)
    inherit Quad.c ['event_type,'event_data ] texture#width texture#height as super;
    initializer ObjMemo.add memo (self :> < >);
    value mutable texture: Texture.c = texture;
    method texture = texture;
    method setTexture nt = texture := nt;
    value texCoords = 
      let res = Array.make 8 0. in
      (
        res.(2) := 1.0; res.(5) := 1.0;
        res.(6) := 1.0; res.(7) := 1.0;
        res
      );
    method virtual copyTexCoords: Bigarray.Array1.t float Bigarray.float32_elt Bigarray.c_layout -> unit;
    method copyTexCoords dest = Array.iteri (fun i a -> Bigarray.Array1.unsafe_set dest i a) texCoords;

    method! render () = 
    (
      RenderSupport.bindTexture texture;
(*
      for i = 0 to 3 do
        RenderSupport.convertColors vertexColors.(i) alpha (Bigarray.Array1.sub Quad.gl_quad_colors (i*4) 4);
       done;
*)
      let alphaBits =  Int32.shift_left (Int32.of_float (alpha *. 255.)) 24 in
      Array.iteri (fun i c -> Quad.gl_quad_colors.{i} := Int32.logor (Int32.of_int c) alphaBits) vertexColors;
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


value cast: #DisplayObject.c 'event_type 'event_data -> option (c 'event_type 'event_data) = 
  fun q ->
    match ObjMemo.mem memo (q :> < >) with
    [ True -> Some ((Obj.magic q) : c 'event_type 'event_data)
    | False -> None
    ];

value createFromFile path = 
  let texture = Texture.createFromFile path in
  new c texture;

value create = new c;
