
open Render.Program;


module type Programs = sig
  module Normal: sig
    value id: id;
    value create: unit -> Render.prg;
  end;
  module ColorMatrix: sig
    value id: id;
    value create:  Render.filter -> Render.prg;
  end;
end;

module Shape =
  struct
    value id = gen_id ();
    value create () =
      let prg = 
        load id ~vertex:"Shape.vsh" ~fragment:"Shape.fsh" 
          ~attributes:[ (Render.Program.AttribPosition,"a_position") ] 
          ~uniforms:[| ("u_color", UNone); ("u_alpha", UNone) |]
      in
        (prg,None);
  end;

module Shadow =
  struct
    value id = gen_id ();
    value create () =
      let prg =
        load id ~vertex:"ShadowFirstPass.vsh" ~fragment:"ShadowFirstPass.fsh"
          ~attributes:[ (Render.Program.AttribPosition,"a_position"); (AttribTexCoords,"a_texCoord") ]
          ~uniforms:[| ("u_texture",(UInt 0)); ("u_radius", UNone); ("u_color", UNone); ("u_height", UNone) |]
      in
        (prg, None);
  end;

module Quad = struct

  module Normal = struct
    value id = gen_id();
    value create () = 
      let prg = 
        load id ~vertex:"Quad.vsh" ~fragment:"Quad.fsh" 
          ~attributes:[ (Render.Program.AttribPosition,"a_position"); (Render.Program.AttribColor,"a_color") ] 
          ~uniforms:[| |]
      in
      (prg,None);
  end;


  module ColorMatrix = struct
    value id = gen_id();
    value create () = assert False;
  end;

end;

module Image = struct (*{{{*)


  module Normal = struct

    value id = gen_id ();
    value cache : ref (option Render.prg) = ref None;

  (*
  value clear_cache () = cache.val := None;
  Callback.register "image_program_cache_clear" clear_cache;
  *)

    value create () = 
      match !cache with
      [ None ->
        let res = 
          let prg = 
            load id ~vertex:"Image.vsh" ~fragment:"Image.fsh"
              ~attributes:[ (AttribPosition,"a_position"); (AttribTexCoords,"a_texCoord"); (AttribColor,"a_color")  ]
              ~uniforms:[| ("u_texture",(UInt 0)) |]
          in
          (prg,None)
        in
        (
          cache.val := Some res;
          res
        )
      | Some res -> res
      ];
  end;


  module ColorMatrix = struct
    value id  = gen_id();
    value create matrix = 
      let prg = 
        load id ~vertex:"Image.vsh" ~fragment:"ImageColorMatrix.fsh"
          ~attributes:[ (AttribPosition,"a_position");  (AttribTexCoords,"a_texCoord"); (AttribColor,"a_color") ]
          ~uniforms:[| ("u_texture", (UInt 0)); ("u_matrix",UNone) |]
      in
      (prg,Some matrix);
  end;

end;(*}}}*)

module ImagePallete = struct (*{{{*)

  module Normal = struct
    value id = gen_id ();
    value create () = 
      let prg = 
        load id ~vertex:"Image.vsh" ~fragment:"ImagePallete.fsh"
          ~attributes:[ (AttribPosition,"a_position"); (AttribTexCoords,"a_texCoord"); (AttribColor,"a_color")  ]
          ~uniforms:[| ("u_texture",(UInt 0)) ; ("u_pallete",(UInt 1)) |]
      in
      (prg,None);
  end;

  module ColorMatrix = struct
    value id  = gen_id();
    value create matrix = 
      let prg = 
        load id ~vertex:"Image.vsh" ~fragment:"ImagePalleteColorMatrix.fsh"
          ~attributes:[ (AttribPosition,"a_position");  (AttribTexCoords,"a_texCoord"); (AttribColor,"a_color") ]
          ~uniforms:[| ("u_texture", (UInt 0));  ("u_matrix",UNone) ; ("u_pallete",(UInt 1)) |]
      in
      (prg,Some matrix);
  end;

end;(*}}}*)

module ImageAlpha = struct (*{{{*)


  module Normal = struct
    value id = gen_id ();
    value create () = 
      let prg = 
        load id ~vertex:"Image.vsh" ~fragment:"ImageAlpha.fsh"
          ~attributes:[ (AttribPosition,"a_position"); (AttribTexCoords,"a_texCoord"); (AttribColor,"a_color")  ]
          ~uniforms:[| ("u_texture",(UInt 0)) |]
      in
      (prg,None);
  end;

  module ColorMatrix = struct
    value id  = gen_id();
    value create matrix = 
      let prg = 
        load id ~vertex:"Image.vsh" ~fragment:"ImageAlphaColorMatrix.fsh"
          ~attributes:[ (AttribPosition,"a_position");  (AttribTexCoords,"a_texCoord"); (AttribColor,"a_color") ]
          ~uniforms:[| ("u_texture", (UInt 0)); ("u_matrix",UNone) |]
      in
      (prg,Some matrix);
  end;

end;(*}}}*)

module ImageEtcWithAlpha = struct (*{{{*)

  module Normal = struct
    value id = gen_id ();
    value create () = 
      let prg = 
        load id ~vertex:"Image.vsh" ~fragment:"ImageEtcWithAlpha.fsh"
          ~attributes:[ (AttribPosition,"a_position"); (AttribTexCoords,"a_texCoord"); (AttribColor,"a_color")  ]
          ~uniforms:[| ("u_texture",(UInt 0)) ; ("u_alpha",(UInt 1)) |]
      in
        (prg,None);
  end;

  module ColorMatrix = struct
    value id  = gen_id();
    value create matrix = 
      let prg = 
        load id ~vertex:"Image.vsh" ~fragment:"ImageEtcWithAlphaColorMatrix.fsh"
          ~attributes:[ (AttribPosition,"a_position");  (AttribTexCoords,"a_texCoord"); (AttribColor,"a_color") ]
          ~uniforms:[| ("u_texture", (UInt 0));  ("u_matrix",UNone) ; ("u_alpha",(UInt 1)) |]
      in
      (prg,Some matrix);
  end;
end; (*}}}*)

module StrokedTlfAtlas =
  struct
    module Normal =
      struct
        value id = gen_id ();
        value create () = 
          let prg = 
            load id ~vertex:"Image.vsh" ~fragment:"StrokenAtlas.fsh"
              ~attributes:[ (AttribPosition,"a_position"); (AttribTexCoords,"a_texCoord"); (AttribColor,"a_color")  ]
              ~uniforms:[| ("u_texture",(UInt 0)) |]
          in
          (prg,None);        
      end;

    module ColorMatrix = struct
      value id  = gen_id();
      value create matrix = assert False;
    end;
  end;


value select_by_texture = fun
  [ Texture.Simple _ -> (module Image:Programs)
  | Texture.Alpha -> (module ImageAlpha:Programs)
  | Texture.Pallete _ -> (module ImagePallete:Programs)
  | Texture.EtcWithAlpha _ -> (module ImageEtcWithAlpha:Programs)
  | Texture.LuminanceAlpha -> (module StrokedTlfAtlas:Programs)
  ];
