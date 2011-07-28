open Printf;

module Ft = Freetype;

value print_face_info fi = 
  Printf.printf 
    "num_faces: %d, num_glyphs: %d, fname: %s, sname: %s\n" 
    fi.Ft.num_faces fi.Ft.num_glyphs fi.Ft.family_name fi.Ft.style_name
;

value pattern = ref "abcdefghijklmnoprstабвгд!?.";
value fontFile = ref "DejaVuSerif.ttf";
value size = ref 100.0; (* add support for multisize *)
value dpi = ref 72;

(* use xmlm for writing xml *)
let t = Freetype.init () in
let (face,face_info) = Freetype.new_face t !fontFile 0 in
(
   print_face_info face_info;
   Freetype.set_char_size face !size 0. !dpi 0;
   UTF8.iter begin fun uchar ->
   (
     let code = UChar.code uchar in
     let char_index = Freetype.glyph_index_of_int code in
     let (xadv,yadv) = Freetype.render_glyph face char_index [] Freetype.Render_Normal in
     let bi = Freetype.get_bitmap_info face in
     (* take bitmap as is for now *)
     let open Freetype in
   )
   end !pattern;
);


