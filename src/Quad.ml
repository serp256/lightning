open Gl;
open LightCommon;

(* value gl_quad_colors = make_ubyte_array 16; *)
value gl_quad_colors = make_word_array 4;

module type S = sig

  module D : DisplayObjectT.M;

  class c: [ ?color:int] -> [ float ] -> [ float ] ->
    object
      inherit D.c; 
      value vertexColors: array int;
      value vertexCoords: Bigarray.Array1.t float Bigarray.float32_elt Bigarray.c_layout;
      method updateSize: float -> float -> unit;
      method copyVertexCoords: Bigarray.Array1.t float Bigarray.float32_elt Bigarray.c_layout -> unit;
      method setColor: int -> unit;
      method color: int;
      method vertexColors: Enum.t int;
      method boundsInSpace: !'space. option (<asDisplayObject: D.c; ..> as 'space) -> Rectangle.t;
      method private render': option Rectangle.t -> unit;
    end;

  value cast: #D.c -> option c; 
  value create: ?color:int -> float -> float -> c;

end;

module Make(D:DisplayObjectT.M) = struct

  module D = D;
  print_endline "Make NEW Quad module";

  class _c color width height = (*{{{*)
    object(self)
      inherit D.c as super;

      value vertexCoords = 
        let a = make_float_array 8 in
        let () = Bigarray.Array1.fill a 0. in
        (
          a.{2} := width;
          a.{5} := height;
          a.{6} := width;
          a.{7} := height;
          a
        );

      method updateSize width height = 
      (
        vertexCoords.{2} := width;
        vertexCoords.{5} := height;
        vertexCoords.{6} := width;
        vertexCoords.{7} := height;
      );

      method copyVertexCoords dest = Bigarray.Array1.blit vertexCoords dest;

        (*
        let a = Array.make 8 0. in
        (
          a.(2) := width;
          a.(5) := height;
          a.(6) := width;
          a.(7) := height;
          a
        );
        *)
        
      value vertexColors = Array.make 4 color;
  (*     method vertexColors = vertexColors; *)
      method vertexColors = ExtArray.Array.enum vertexColors;

      method setColor color =
        for i = 0 to 3 do
          vertexColors.(i) := color;
        done;

      method color = vertexColors.(0);

      method boundsInSpace: !'space. (option (<asDisplayObject: D.c; .. > as 'space)) -> Rectangle.t = fun targetCoordinateSpace ->  (*       let () = Printf.printf "bounds in space %s\n" name in *)
        match targetCoordinateSpace with
        [ Some ts when ts#asDisplayObject = self#asDisplayObject -> Rectangle.create 0. 0. vertexCoords.{6} vertexCoords.{7} (* optimization *)
        | _ -> 
          let transformationMatrix = self#transformationMatrixToSpace targetCoordinateSpace in
          let ar = [| max_float; ~-.max_float; max_float; ~-.max_float |] in
          (
            for i = 0 to 3 do
              let p = (vertexCoords.{2*i},vertexCoords.{2*i+1}) in
              let (tx,ty) = Matrix.transformPoint transformationMatrix p in
              (
                if ar.(0) > tx then ar.(0) := tx else ();
                if ar.(1) < tx then ar.(1) := tx else ();
                if ar.(2) > ty then ar.(2) := ty else ();
                if ar.(3) < ty then ar.(3) := ty else ();
              )
            done;
            Rectangle.create ar.(0) ar.(2) (ar.(1) -. ar.(0)) (ar.(3) -. ar.(2));
          )
        ];


      method private render' _ = 
      (
        RenderSupport.clearTexture();
        (* optimize it!  
        for i = 0 to 3 do
          RenderSupport.convertColors vertexColors.(i) alpha (Bigarray.Array1.sub gl_quad_colors (i*4) 4)
        done;
        *)
  (*
        let alphaBits =  Int32.shift_left (Int32.of_float (alpha *. 255.)) 24 in
        Array.iteri (fun i c -> gl_quad_colors.{i} := Int32.logor (Int32.of_int c) alphaBits) vertexColors;
  *)
        Array.iteri (fun i c -> gl_quad_colors.{i} := RenderSupport.convertColor c alpha) vertexColors;
        glEnableClientState gl_vertex_array;
        glEnableClientState gl_color_array;
        glVertexPointer 2 gl_float 0 vertexCoords;
        glColorPointer 4 gl_unsigned_byte 0 gl_quad_colors;
        glDrawArrays gl_triangle_strip 0 4;
        glDisableClientState gl_vertex_array;
        glDisableClientState gl_color_array;
      );

      
    end;(*}}}*)

  value memo : WeakMemo.c _c = new WeakMemo.c 1;

  class c ?(color=color_white) width height = (*{{{*)
    object(self)
      inherit _c color width height;
      initializer let () = debug:quad "add to memo: %s" name in memo#add (self :> c);
    end;

  value cast: #D.c -> option c = fun x -> try Some (memo#find x) with [ Not_found -> None ];

  (*
  value cast: #DisplayObject.c 'event_type 'event_data -> option (c 'event_type 'event_data) = 
    fun q ->
      match ObjMemo.mem memo (q :> < >) with
      [ True -> Some ((Obj.magic q) : c 'event_type 'event_data)
      | False -> None
      ];
    *)

  value create ?color width height = new c ?color width height;

end;
