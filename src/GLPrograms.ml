
open Render.Program;

module Quad = struct
  value id = gen_id();
  value create () = 
    let prg = 
      load id ~vertex:"Quad.vsh" ~fragment:"Quad.fsh" 
        ~attributes:[ (Render.Program.AttribPosition,"a_position"); (Render.Program.AttribColor,"a_color") ] 
        ~uniforms:[| |]
    in
    (prg,None);

end;

module Image = struct (*{{{*)

  value id = gen_id ();
  value create () = 
    let prg = 
      load id ~vertex:"Image.vsh" ~fragment:"Image.fsh"
        ~attributes:[ (AttribPosition,"a_position"); (AttribTexCoords,"a_texCoord"); (AttribColor,"a_color")  ]
        ~uniforms:[| ("u_texture",(UInt 0)) |]
    in
    (prg,None);

end;(*}}}*)

module ImagePallete = struct
  value id = gen_id ();
  value create () = 
    let prg = 
      load id ~vertex:"Image.vsh" ~fragment:"ImagePallete.fsh"
        ~attributes:[ (AttribPosition,"a_position"); (AttribTexCoords,"a_texCoord"); (AttribColor,"a_color")  ]
        ~uniforms:[| ("u_texture",(UInt 0)) ; ("u_pallete",(UInt 1)) |]
    in
    (prg,None);

end;


module ImageColorMatrix = struct (*{{{*)

  value id  = gen_id();
  value create matrix = 
    let prg = 
      load id ~vertex:"Image.vsh" ~fragment:"ImageColorMatrix.fsh"
        ~attributes:[ (AttribPosition,"a_position");  (AttribTexCoords,"a_texCoord"); (AttribColor,"a_color") ]
        ~uniforms:[| ("u_texture", (UInt 0)); ("u_matrix",UNone) |]
    in
    let f = Render.Filter.color_matrix matrix in
    (prg,Some f);
    
  value from_filter filter =
    let prg = 
      load id ~vertex:"Image.vsh" ~fragment:"ImageColorMatrix.fsh"
        ~attributes:[ (AttribPosition,"a_position");  (AttribTexCoords,"a_texCoord"); (AttribColor,"a_color") ]
        ~uniforms:[| ("u_texture", (UInt 0)); ("u_matrix",UNone) |]
    in
    (prg,Some filter);

end;(*}}}*)

module ImagePalleteColorMatrix = struct (*{{{*)

  value id  = gen_id();
  value create matrix = 
    let prg = 
      load id ~vertex:"Image.vsh" ~fragment:"ImagePalleteColorMatrix.fsh"
        ~attributes:[ (AttribPosition,"a_position");  (AttribTexCoords,"a_texCoord"); (AttribColor,"a_color") ]
        ~uniforms:[| ("u_texture", (UInt 0));  ("u_matrix",UNone) ; ("u_pallete",(UInt 1)) |]
    in
    let f = Render.Filter.color_matrix matrix in
    (prg,Some f);

  value from_filter filter =
    let prg = 
      load id ~vertex:"Image.vsh" ~fragment:"ImagePalleteColorMatrix.fsh"
        ~attributes:[ (AttribPosition,"a_position");  (AttribTexCoords,"a_texCoord"); (AttribColor,"a_color") ]
        ~uniforms:[| ("u_texture", (UInt 0));  ("u_matrix",UNone) ; ("u_pallete",(UInt 1)) |]
    in
    (prg,Some filter);
    
end;(*}}}*)
