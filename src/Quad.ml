open LightCommon;

(* value gl_quad_colors = make_word_array 4; *)

  class c ?(color=0xFFFFFF) width height = (*{{{*)
    object(self)
      inherit DisplayObject.c as super;

      value shaderProgram = GLPrograms.Quad.create ();
      value quad = Render.Quad.create width height color 1.;
      method! setAlpha a =
      (
        super#setAlpha a;
        Render.Quad.set_alpha quad a;
      );

      (*
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
        if (vertexCoords.{2} <> width || vertexCoords.{5} <> height) 
        then
        (
          vertexCoords.{2} := width;
          vertexCoords.{5} := height;
          vertexCoords.{6} := width;
          vertexCoords.{7} := height;
          self#boundsChanged();
        )
        else ();

      method copyVertexCoords dest = Bigarray.Array1.blit vertexCoords dest;
      *)

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
        
(*       value vertexColors = Array.make 4 color; *)
  (*     method vertexColors = vertexColors; *)
(*       method vertexColors = ExtArray.Array.enum vertexColors; *)
      method vertexColors: Enum.t int = Enum.empty ();

      method setColor color = Render.Quad.set_color quad color;
      method color = Render.Quad.color quad;

      method boundsInSpace: !'space. (option (<asDisplayObject: DisplayObject.c; .. > as 'space)) -> Rectangle.t = fun targetCoordinateSpace ->  (*       let () = Printf.printf "bounds in space %s\n" name in *)
        match targetCoordinateSpace with
        [ Some ts when ts#asDisplayObject = self#asDisplayObject -> Rectangle.create 0. 0. width height (* optimization *)
        | _ -> 
          let vertexCoords = Render.Quad.points quad in
          let transformationMatrix = self#transformationMatrixToSpace targetCoordinateSpace in
          let ar = Matrix.transformPoints transformationMatrix vertexCoords in
          Rectangle.create ar.(0) ar.(2) (ar.(1) -. ar.(0)) (ar.(3) -. ar.(2))
        ];

      method filters = [];
      method setFilters _ = assert False;

      method private render' ?alpha ~transform _ = Render.Quad.render (if transform then self#transformationMatrix else Matrix.identity) shaderProgram ?alpha quad;
      
    end;(*}}}*)

(*   value memo : WeakMemo.c _c = new WeakMemo.c 1;

  class c ?(color=color_white) width height = (*{{{*)
    object(self)
      inherit _c color width height;
      initializer let () = debug:quad "add to memo: %s" name in memo#add (self :> c);
    end; (*}}}*)

  value cast: #DisplayObject.c -> option c = fun x -> try Some (memo#find x) with [ Not_found -> None ];
*)

  value create ?color width height = new c ?color width height;

