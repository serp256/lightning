open Printf;

module Ft = Freetype;

value print_face_info fi = 
  Printf.printf 
    "num_faces: %d, num_glyphs: %d, fname: %s, sname: %s\n" 
    fi.Ft.num_faces fi.Ft.num_glyphs fi.Ft.family_name fi.Ft.style_name
;

value (=|=) k v = (("",k),v);
value (=.=) k v = k =|= string_of_float v;
value (=*=) k v = k =|= string_of_int v;

value pattern = ref "abcdefghijklmnoprstабвгд!?.";
value fontFile = ref "DejaVuSerif.ttf";
value sizes = ref [ 24. ; 100.0 ]; (* add support for multisize *)
value dpi = ref 72;

(* use xmlm for writing xml *)
let t = Freetype.init () in
let (face,face_info) = Freetype.new_face t !fontFile 0 in
let xmlfname = (Filename.chop_extension !fontFile) ^ ".fnt" in
let xmlout = Xmlm.make_output (open_out xmlfname) in
(
   print_face_info face_info;
   let fattribs = 
     [ "face" =|= face_info.Ft.family_name
     | "style" =|= face_info.Ft.style_name
     | "kerning" =|= (string_of_bool face_info.Ft.has_kerning)
     ]
   in
   Xmlm.output xmlout (`El_start ("Font",fattribs));
   List.iter begin fun size ->
     Freetype.set_char_size face size 0. !dpi 0;
     UTF8.iter begin fun uchar ->
     (
       let code = UChar.code uchar in
       let char_index = Freetype.glyph_index_of_int code in
       let (xadv,yadv) = Freetype.render_glyph face char_index [] Freetype.Render_Normal in
       let bi = Freetype.get_bitmap_info face in
       (* take bitmap as is for now *)
       let open Freetype in
     )
     end !pattern
   end !sizes
);


