open Gl;

module type S = sig

  module Sprite: Sprite.S;

  class c:
    object
      inherit Sprite.c;
      method compile: unit -> unit;
      method invalidate: unit -> unit;
    end;


  value create: unit -> c;

end;

module Make(Image:Image.S)(Sprite:Sprite.S with module D = Image.Q.D) = struct
  module Sprite = Sprite;
  module Quad = Image.Q;

  value collectInfo obj = (*{{{*)
    let scratchBuf = Gl.make_float_array 8 
    and vertexData = IO.output_string () 
    and colorData = IO.output_string () 
    and texCoordData = IO.output_string () 
    in
    let rec loop obj currentMatrix alpha textures = 
      match obj#alpha = 0.0 || not obj#visible with
      [ True -> textures
      | False -> 
        match obj#dcast with
        [ `Container cont ->
          let () = cont#renderPrepare () in
          Enum.fold begin fun child textures ->
            let childMatrix = child#transformationMatrix in
            loop child (Matrix.concat childMatrix currentMatrix) (alpha *. child#alpha) textures
          end textures cont#children 
        | `Object obj ->
            match Quad.cast obj with
            [ Some quad ->
              (
                (* Vertexes *)
                quad#copyVertexCoords scratchBuf;
                for i = 0 to 3 do
                  let x = scratchBuf.{2*i}
                  and y = scratchBuf.{2*i+1}
                  in
                  let (x,y) = Matrix.transformPoint currentMatrix (x,y) in
                  (
                    IO.write_real_i32 vertexData (Int32.bits_of_float x);
                    IO.write_real_i32 vertexData (Int32.bits_of_float y);
                  )
                done;
                (* Colors *)
                let alphaBits =  Int32.shift_left (Int32.of_float (alpha *. 255.)) 24 in
                Enum.iter begin fun c ->
                  let c = Int32.logor (Int32.of_int c) alphaBits in
                  IO.write_real_i32 colorData c
                end quad#vertexColors;
                (* and textures *)
                match Image.cast quad with
                [ Some image ->
                  let texture = image#texture in
                  let textures = 
                    match textures with
                    [ [ (Some last_texture,count) :: tl ] when last_texture#textureID = texture#textureID -> [ (Some texture,count + 4) :: tl]
                    | _ -> [ (Some texture,4) :: textures ]
                    ]
                  in
                  ( (*  texture vertexes  *)
                    image#copyTexCoords scratchBuf;
                    texture#adjustTextureCoordinates scratchBuf;
                    for i = 0 to 3 do
                      IO.write_real_i32 texCoordData (Int32.bits_of_float scratchBuf.{2*i});
                      IO.write_real_i32 texCoordData (Int32.bits_of_float scratchBuf.{2*i + 1});
                    done;
                    textures
                  )
                | None -> 
                  (
                    (* we need to push fake texCoords *)
                    IO.nwrite texCoordData "00000000000000000000000000000000";
                    match textures with
                    [ [ (None, count) :: tl ] -> [ (None,count + 4) :: tl]
                    | _ -> [ (None,4) :: textures ]
                    ];
                  )
                ]
              )
            | None -> assert False
            ]
        ]
      ]
    in
    let textures = loop obj#asDisplayObject Matrix.identity 1.0 [] in
    (IO.close_out vertexData,IO.close_out colorData,IO.close_out texCoordData,List.rev textures);
  (*}}}*)

  class c =
    object(self)
      inherit Sprite.c;

      value buffers = Array.make 4 0;
      value mutable textureSwitches = [];
      value mutable colorData = "";
      value mutable compiled = False;
      value mutable colorsUpdated = False;
      initializer Gc.finalise (fun _ -> self#deleteBuffers()) self;

      method private deleteBuffers () = 
        match ExtArray.Array.for_all (fun x -> x = 0) buffers with
        [ True -> ()
        | False -> 
          (
            prerr_endline "delete buffers";
            glDeleteBuffers 4 buffers;
            for i = 0 to 3 do buffers.(i) := 0; done;
          )
        ];

      method invalidate () = compiled := False;

      method compile () = (*{{{*)
      (
        self#deleteBuffers();
        textureSwitches := [];
        colorData := "";
        colorsUpdated := False;
        let (vertexData,colorData',texCoordData,textures) = collectInfo self in
        (
          glGenBuffers 4 buffers;
  (*         let () = Printf.eprintf "buffers: [ %s ]\n" (String.concat ";" (List.map string_of_int (Array.to_list buffers))) in *)
          let numVerticies = String.length vertexData / 4 / 2 in
          let numQuads = numVerticies / 4 in
          let indexBufferSize = numQuads * 6 in (*  4 + 2 for degenerate triangles *)
          let indices = Gl.make_ushort_array indexBufferSize in
          (
            let pos = ref 0 in
            for i = 0 to numQuads - 1 do
              indices.{!pos} := i*4; incr pos;
              for j = 0 to 3 do
                indices.{!pos} := i*4 + j; incr pos;
              done;
              indices.{!pos} := i*4 + 3; incr pos;
            done;


            (* index buffer *)
            glBindBuffer gl_element_array_buffer buffers.(0);
            glBufferData gl_element_array_buffer (indexBufferSize * 2) indices gl_static_draw;
            glBindBuffer gl_element_array_buffer 0;
          );

          (* vertex buffer *)
          glBindBuffer gl_array_buffer buffers.(1);
  (*         Printf.eprintf "vertexData: %d=[%s]\n" (String.length vertexData) (String.concat "," (ExtString.String.fold_right (fun x res -> [ string_of_int (int_of_char x) :: res ]) vertexData [])); *)
          glBufferData gl_array_buffer (String.length vertexData) vertexData gl_static_draw;

          (* color buffer *)
          glBindBuffer gl_array_buffer buffers.(2);
  (*         Printf.eprintf "colorData: %d=[%s]\n" (String.length colorData') (String.concat "," (ExtString.String.fold_right (fun x res -> [ string_of_int (int_of_char x) :: res ]) colorData' [])); *)
          glBufferData gl_array_buffer (String.length colorData') colorData' gl_dynamic_draw;

          (* texture coordinate buffer *)
          glBindBuffer gl_array_buffer buffers.(3);
  (*         Printf.eprintf "texCoordData: %d\n" (String.length texCoordData); *)
          glBufferData gl_array_buffer (String.length texCoordData) texCoordData gl_static_draw;

          glBindBuffer gl_array_buffer 0;

  (*         Printf.eprintf "textures len: %d\n" (List.length textures); *)
          textureSwitches := textures;
          colorData := colorData';
  (*         prerr_endline "compiled"; *)
          compiled := True;
        );
      ); (*}}}*)

      method private updateColorData () = (*{{{*)
        let currentColors = IO.output_string () (* String.create (String.length colorData) *) (* TODO: may be optimize this allocation? *) in
        (
          let offset = ref 0 in
          List.iter begin fun (texture,numVerticies) ->
            (
  (*             let () = Printf.eprintf "texture:%d,num:%d\n%!" (match texture with [ None -> 0 | Some t -> t#textureID ]) numVerticies in *)
              let pma = 
                match texture with
                [ Some texture -> texture#hasPremultipliedAlpha
                | None -> False 
                ]
              in
              for i = 0 to numVerticies - 1 do
                let j = offset.val + i * 4 in
                let vertexAlpha = (float_of_int (int_of_char colorData.[j + 3])) /. 255. *. alpha in
                let blue = int_of_char colorData.[j] and green = int_of_char colorData.[j+1] and red = int_of_char colorData.[j+2] in
                let newColors = 
                  let c = 
                    match pma with
                    [ True ->
                        (int_of_float ((float red) *. vertexAlpha)) lor
                        (int_of_float ((float green) *. vertexAlpha) lsl 8) lor
                        (int_of_float ((float blue) *. vertexAlpha) lsl 16)
                    | False -> red lor (green lsl 8) lor (blue lsl 16)
                    ]
                  in
                  Int32.logor (Int32.of_int c) (Int32.shift_left (Int32.of_float (vertexAlpha *. 255.)) 24)
                in
                IO.write_real_i32 currentColors newColors;
              done;
              offset.val := !offset + (numVerticies * 4)
            )
          end textureSwitches;

          (* update buffer *)
          glBindBuffer gl_array_buffer buffers.(2);
          let currentColors = IO.close_out currentColors in
  (*         let () = Printf.eprintf "currentColors: [%s]\n%!" (String.concat "," (ExtString.String.fold_right (fun x res -> [ string_of_int (int_of_char x) :: res ]) currentColors [])) in *)
          glBufferSubData gl_array_buffer 0 (String.length currentColors) currentColors;
          glBindBuffer gl_array_buffer 0;
          colorsUpdated := True;
        );(*}}}*)

      method! private render' _ = 
      (
        if not compiled then self#compile () else ();
        if not colorsUpdated then self#updateColorData () else ();
        glBindBuffer gl_element_array_buffer buffers.(0);

        let vertexOffset = ref 0 in
        List.iter begin fun (texture,numVertices) ->
          let renderedVertices = (numVertices / 4 ) * 6 in
  (*         let () = Printf.eprintf "rendered vertices: %d\n" renderedVertices in *)
          (
            match texture with
            [ None -> RenderSupport.clearTexture ()
            | Some texture -> 
              (
                RenderSupport.bindTexture texture;
                glBindBuffer gl_array_buffer buffers.(3);
                glEnableClientState gl_texture_coord_array;
                glTexCoordPointer 2 gl_float 0 0;
              )
            ];

            glBindBuffer gl_array_buffer buffers.(1);
            glEnableClientState gl_vertex_array;
            glVertexPointer 2 gl_float 0 0;

            glBindBuffer gl_array_buffer buffers.(2);
            glEnableClientState gl_color_array;
            glColorPointer 4 gl_unsigned_byte 0 0;

            glDrawElements gl_triangle_strip renderedVertices gl_unsigned_short (!vertexOffset * 2);

            glDisableClientState gl_vertex_array;
            glDisableClientState gl_color_array;
            glDisableClientState gl_texture_coord_array;

            vertexOffset.val := !vertexOffset + renderedVertices;
          )
        end textureSwitches;
        glBindBuffer gl_array_buffer 0;
        glBindBuffer gl_element_array_buffer 0;
      );


      
        
    end;



  value create () = new c;

end;
