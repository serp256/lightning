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

value pattern = ref "abcdefghабвг";
value fontFile = ref "DejaVuSerif.ttf";
value sizes = ref [ 24. ; 100.0 ]; (* add support for multisize *)
value color = ref {Color.r = 255; g = 255; b = 255};
value dpi = ref 72;

value bgcolor = {Color.color = {Color.r = 0; g = 0; b = 0}; alpha = 0};

value make_size face size callback = 
(
  Freetype.set_char_size face size 0. !dpi 0;
  UTF8.iter begin fun uchar ->
  (
    let code = UChar.code uchar in
    let () = Printf.printf "process char: %d\n%!" code in
    let char_index = Freetype.get_char_index face code in
    let (xadv,yadv) = Freetype.render_glyph face char_index [] Freetype.Render_Normal in
    let bi = Freetype.get_bitmap_info face in
    (* take bitmap as is for now *)
    let open Freetype in
    let () = Printf.printf "bi.width: %d, bi.height: %d\n%!" bi.bitmap_width bi.bitmap_height in
    let img =  Rgba32.make bi.bitmap_width bi.bitmap_height bgcolor in
    (
      for y = 0 to bi.bitmap_height - 1 do
        for x = 0 to bi.bitmap_width - 1 do
          let level = read_bitmap face x y in
          Rgba32.set img x (bi.bitmap_height - y - 1) {Color.color = !color; alpha = level}
        done
      done;
(*         img#save (Printf.sprintf "%d.png" code) (Some Images.Png) []; *)
      callback code xadv bi.bitmap_left bi.bitmap_top img
    )
  )
  end !pattern;
);

type sdescr = 
  {
    id: int; xadvance: int; xoffset: int; yoffset: int; 
    width: int; height: int; x: mutable int; y: mutable int; page: mutable int
  };

(* use xmlm for writing xml *)
let t = Freetype.init () in
let (face,face_info) = Freetype.new_face t !fontFile 0 in
let chars = Hashtbl.create 1 in
(
  let imgs = ref [] in
  (
    List.iter begin fun size ->
      make_size face size begin fun code xadvance xoffset yoffset img ->
        imgs.val := [ ((size,code),Images.Rgba32 img) :: !imgs ]
      end
    end !sizes;
    let () = Printf.printf "len imgs: %d\n%!" (List.length !imgs) in
    let textures = TextureLayout.layout !imgs in
    (* save output *)
    ExtList.List.iteri begin fun i (w,h,imgs) ->
      let texture = Rgba32.make w h bgcolor in
      (
        List.iter begin fun ((size,code),(x,y,img)) ->
          let img = match img with [ Images.Rgba32 img -> img | _ -> assert False ] in
          Rgba32.blit img 0 0 texture x y img.Rgba32.width img.Rgba32.height;
        end imgs;
        Images.save (Printf.sprintf "%d.png" i) (Some Images.Png) [] (Images.Rgba32 texture);
      )
    end textures;
  );
  (*
  let xmlfname = (Filename.chop_extension !fontFile) ^ ".fnt" in
  let xmlout = Xmlm.make_output (`Channel (open_out xmlfname)) in
  (
  Xmlm.output xmlout (`Dtd None);
  print_face_info face_info;
  let fattribs = 
    [ "face" =|= face_info.Ft.family_name 
    ; "style" =|= face_info.Ft.style_name
    ; "kerning" =*= (if face_info.Ft.has_kerning then 1 else 0)
    ]
  in
  Xmlm.output xmlout (`El_start (("","Font"),fattribs));
  Xmlm.output xmlout (`El_start (("","Chars"),[ "size" =.= size ];
  *)
);


