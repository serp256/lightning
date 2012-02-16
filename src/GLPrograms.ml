
open Render.Program;

module QuadSimple = struct
  value id = gen_id();
  value create () = 
    let prg = 
      load id ~vertex:"Quad.vsh" ~fragment:"Quad.fsh" 
        ~attributes:[ (Render.Program.AttribPosition,"a_position"); (Render.Program.AttribColor,"a_color") ] 
        ~uniforms:[| |]
    in
    (prg,None);

end;

module ImageSimple = struct (*{{{*)

  value id = gen_id ();
  value create () = 
    let prg = 
      load id ~vertex:"Image.vsh" ~fragment:"Image.fsh"
        ~attributes:[ (AttribPosition,"a_position"); (AttribTexCoords,"a_texCoord"); (AttribColor,"a_color")  ]
        ~uniforms:[| ("u_texture",(UInt 0)) |]
    in
    (prg,None);

end;(*}}}*)

(*
module ImageGlow = struct (*{{{*)

  value id  = gen_id();
  value create glow = 
    let prg = 
      load id ~vertex:"Image.vsh" ~fragment:"Glow.fsh"
        ~attributes:[ (AttribPosition,"a_position"); (AttribTexCoords,"a_texCoord"); (AttribColor,"a_color")  ]
        ~uniforms:[| ("u_texture", (UInt 0)) ; ("u_color",UNone) ; ("u_strength",UNone) |]
    in
    let f = Render.Filter.glow glow.Filters.glowColor glow.Filters.glowStrength in
    (prg,Some f);
    
end;(*}}}*)
*)



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
    
end;(*}}}*)
