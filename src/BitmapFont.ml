
open LightCommon;
open ExtLib;


type bc = 
  {
    charID:int;
    xOffset:float;
    yOffset:float;
    xAdvance: float;
    atlasNode: AtlasNode.t;
  };

type t = 
  {
    chars: Hashtbl.t int bc;
    scale: float;
    ascender: float;
    descender: float;
    lineHeight: float;
    space:float;
    texture: Texture.c;
    isDynamic: bool;
  };

module MapInt = Map.Make (struct type t = int; value compare (k1:int) k2 = compare k1 k2; end);
value fonts = Hashtbl.create 0;
value exists ?(style="regular") name = Hashtbl.mem fonts (name,style);
exception Font_not_found of (string*string);
Printexc.register_printer (fun [ Font_not_found name style -> Some (Printf.sprintf "Font_not_found %s:%s" name style) | _ -> None ]);
value clear () = Hashtbl.clear fonts;
Callback.register "clear_fonts" clear;

value get ?(applyScale=False) ?(style="regular") ?size name =
  let sizes = try Hashtbl.find fonts (name,style) with [ Not_found -> raise (Font_not_found (name,style)) ] in
  match size with
  [ None -> 
    let (fsize,font) = MapInt.choose sizes in
    font
  | Some size ->
    let (l,f,r) = MapInt.split size sizes in
    match f with
    [ Some f -> f
    | None -> 
        (* let () = Debug.e "SCALE FONT: %s:%s:%d" name style size in *)
        let (fsize,font) = 
          match MapInt.is_empty r with
          [ False -> MapInt.min_binding r
          | True -> MapInt.max_binding l
          ]
        in
        match applyScale with
        [ True -> 
          let scale = (float size) /. (float fsize) in
          {(font) with scale = scale; space = font.space *. scale; ascender = font.ascender *. scale; descender = font.descender *. scale; lineHeight = font.lineHeight *. scale }
        | False -> {(font) with scale = (float size) /. (float fsize) }
        ]
    ]
  ];

DEFINE CHAR_NEWLINE = 10;
DEFINE CHAR_SPACE = 32;
DEFINE CHAR_TAB = 9;


(*
value register xmlpath = (*{{{*)
  let module XmlParser = MakeXmlParser(struct value path = xmlpath; end) in
  let floats = XmlParser.floats in
  let () = XmlParser.accept (`Dtd None) in
  let parse_info () = 
    match XmlParser.parse_element "info" [ "face"; "size"] with
    [ Some [ face; size ] _ -> (face,XmlParser.ints size)
    | None -> XmlParser.error "font->info not found"
    | _ -> assert False
    ]
  and parse_common () = 
    match XmlParser.parse_element "common" ["space";"lineHeight";"base"] with
    [ Some [ space; lineHeight; base ] _ -> (floats space, floats lineHeight, floats base)
    | None -> XmlParser.error "font->common not found"
    | _ -> assert False
    ]
  and parse_page () = 
    match XmlParser.next () with
    [ `El_start ((_,"pages"),_) ->
      match XmlParser.parse_element "page" [ "file"] with
      [ Some [ file ] _ -> 
        let () = XmlParser.accept `El_end in
        file
      | None -> XmlParser.error "font->pages->page not found"
      | _ -> assert False
      ]
    | _ -> XmlParser.error "font->pages not found"
    ]
  and parse_chars texture = 
    match XmlParser.next () with
    [ `El_start ((_,"chars"),attributes) ->
      let count = match XmlParser.get_attribute "count" attributes with [ Some count -> int_of_string count | None -> 0] in
      let chars = Hashtbl.create count in
      let rec loop () =
        match XmlParser.parse_element "char" ["id";"x";"y";"width";"height";"xoffset";"yoffset";"xadvance"] with
        [ Some [ id;x;y;width;height;xoffset;yoffset;xadvance ] _ ->
          (
            let charID = int_of_string id in
            let bc = 
              let region = Rectangle.create (floats x) (floats y) (floats width) (floats height) in
              let atlasNode = AtlasNode.create texture region () in
              { charID ; xOffset = floats xoffset; yOffset = floats yoffset; xAdvance = floats xadvance; atlasNode }
            in
            Hashtbl.add chars charID bc;
            loop ()
          )
        | None -> chars
        | _ -> assert False
        ]
      in
      loop ()
    | _ -> XmlParser.error "font->chars not found"
    ]
  in
  match XmlParser.next () with
  [ `El_start ((_,"font"),_) -> 
    let (name,size) = parse_info () in
    let (space,lineHeight,baseLine) = parse_common () in
    let imgFile = parse_page () in
    let texture = Texture.load imgFile in
    let chars = parse_chars texture in
    let bf = { texture; chars; (* name; *) scale=1.; baseLine; lineHeight; space } in
    try
      let sizes = Hashtbl.find fonts name in
      let sizes = MapInt.add size bf sizes in
      Hashtbl.replace fonts name sizes
    with [ Not_found -> Hashtbl.add fonts name (MapInt.singleton size bf) ]
  | _ -> XmlParser.error "font not found"
  ];(*}}}*)
*)

value register binpath =
  let dirname = match Filename.dirname binpath with [ "." -> "" | dir -> dir ] in
  let inp = open_resource_unsafe binpath in
  let bininp = IO.input_channel inp in
  let parse_pages () =
    let rec loop n res = 
      match n with
      [ 0 -> res
      | _ ->
          let file = IO.read_string bininp in
          let () = debug "texture load" in
            (
              loop (n - 1) [  Texture.load ~with_suffix:False (Filename.concat dirname file) :: res  ];
            )
      ]
    in
    Array.of_list ((loop (IO.read_ui16 bininp) []))
  in
    (
      let face = IO.read_string bininp in
      let style = String.uncapitalize (IO.read_string bininp) in
      let kerning = IO.read_byte bininp in
      let pages = parse_pages () in
      let rec parse_chars n res =
        match n with
        [ 0 -> res 
        | _ ->
            let space = IO.read_double bininp in
            let size = IO.read_ui16 bininp in
            let lineHeight = IO.read_double bininp in
            let ascender = IO.read_double bininp in
            let descender = IO.read_double bininp in
            let ts = pages.(0)#scale in
            let chars = Hashtbl.create 9 in
            let rec loop n =
              match n with
              [ 0 -> ()
              | _ -> 
                  (
                    let charID = IO.read_i32 bininp in
                    let xAdvance = IO.read_ui16 bininp in
                    let xOffset = IO.read_i16 bininp in
                    let yOffset = IO.read_i16 bininp in
                    let x = IO.read_ui16 bininp in
                    let y = IO.read_ui16 bininp in
                    let width = IO.read_ui16 bininp in
                    let height = IO.read_ui16 bininp in
                    let page = IO.read_ui16 bininp in
                     let bc = 
                       let region = Rectangle.create (float x) (float y) (float width) (float height) in
                       let tex = pages.(page) in
                       let atlasNode = AtlasNode.create tex region () in
                       let s = tex#scale in
                       { charID; xOffset = (float xOffset) *. s; yOffset = (float yOffset) *. s; xAdvance = (float xAdvance) *. s; atlasNode }
                     in
                     Hashtbl.add chars charID bc;
                     loop (n-1)
                   )
              ]
            in
              (
                loop (IO.read_ui16 bininp);
                let bf = 
                  let ts = pages.(0)#scale in
                  { chars; texture = pages.(0); scale=1.; ascender = ascender *. ts; descender = descender *. ts; space = space *. ts; lineHeight = lineHeight *. ts; isDynamic=False} 
                in
                let res = MapInt.add size bf res in
                parse_chars (n-1) res
              )
        ]
      in
      let sizes = parse_chars (IO.read_ui16 bininp) (try Hashtbl.find fonts (face,style) with [ Not_found -> MapInt.empty ]) in
      let () = debug "register %s %s" face style in
      Hashtbl.replace fonts (face,style) sizes;

      close_in inp;
    );

value registerXML xmlpath =
  let dirname = match Filename.dirname xmlpath with [ "." -> "" | dir -> dir ] in
  let module XmlParser = MakeXmlParser(struct value path = xmlpath; value with_suffix = True; end) in
  let () = XmlParser.accept (`Dtd None) in
  let floats = XmlParser.floats in
  let parse_pages () = 
    let () = debug "parse pages" in
    match XmlParser.next () with
    [ `El_start ((_,"Pages"),_) ->
      let () = debug "this is pages" in
      let rec loop res = 
        let () = debug "parse pages looop" in
        match XmlParser.parse_element "page" [ "file"] with
        [ Some [ file ] _ -> loop [ Texture.load ~with_suffix:False (Filename.concat dirname file) :: res ]
        | None -> res 
        | _ -> assert False
        ]
      in
      Array.of_list (List.rev (loop []))
    | _ -> XmlParser.error "Font->Pages not found"
    ]
  in
  match XmlParser.next () with
  [ `El_start ((_,"Font"),attributes) -> 
    match XmlParser.get_attributes "Font" ["face"; "style"; "kerning"] attributes with
    [ [ face;style;kernign] ->
      let pages = parse_pages () in
      let style = String.uncapitalize style in
      let rec parse_chars res = 
        match XmlParser.next () with
        [ `El_start ((_,"Chars"),attributes) ->
          match XmlParser.get_attributes "Chars" [ "space"; "size"; "lineHeight"; "ascender" ; "descender" ] attributes with
          [ [ space; size; lineHeight; ascender; descender ] ->
            let chars = Hashtbl.create 9 in
            let rec loop () = 
              match XmlParser.parse_element "char" [ "id";"x";"y";"width";"height";"xoffset";"yoffset";"xadvance";"page" ] with
              [ Some [ id;x;y;width;height;xOffset;yOffset;xAdvance;page] _ -> (* запихнуть *)
                (
                  let charID = XmlParser.ints id in
                   let bc = 
                     let region = Rectangle.create (floats x) (floats y) (floats width) (floats height) in
                     let atlasNode = AtlasNode.create pages.(XmlParser.ints page) region  () in
                     { charID; xOffset = (!Texture.scale *. floats (xOffset)); yOffset = (!Texture.scale *. floats (yOffset)); xAdvance = (!Texture.scale *. floats (xAdvance)); atlasNode }
                   in
                   Hashtbl.add chars charID bc;
                   loop ()
                )
              | None -> ()
              | _ -> assert False
              ]
            in
            (
              loop ();
              let bf = { chars; texture = pages.(0); scale=1.; ascender =  floats ascender; descender = floats descender; space = floats space; lineHeight = floats lineHeight; isDynamic=False} in
              let res = MapInt.add (XmlParser.ints size) bf res in
              parse_chars res
            )
          | _ -> assert False
          ]
        | `El_end -> res
        | _ -> XmlParser.error "unknown signal"
        ]
      in
      let sizes = parse_chars (try Hashtbl.find fonts (face,style) with [ Not_found -> MapInt.empty ]) in
      Hashtbl.replace fonts (face,style) sizes
    | _ -> assert False
    ]
  | _ -> XmlParser.error "Font not found"
  ];

module UnicodeRanges = struct
(*{{{*)
  value bit_ranges = [
    (0, [(0x0000,0x007F)]); (* Basic Latin *)
    (1, [(0x0080,0x00FF)]); (* Latin-1 Supplement *)
    (2, [(0x0100,0x017F)]); (* Latin Extended-A *)
    (3, [(0x0180,0x024F)]); (* Latin Extended-B *)
    (4, [(0x0250,0x02AF);(0x1D00,0x1D7F);(0x1D80,0x1DBF)]); (* Phonetic Extensions Supplement *)
    (5, [(0x02B0,0x02FF);(0xA700,0xA71F)]); (* Modifier Tone Letters *)
    (6, [(0x0300,0x036F);(0x1DC0,0x1DFF)]); (* Combining Diacritical Marks Supplement *)
    (7, [(0x0370,0x03FF)]); (* Greek and Coptic *)
    (8, [(0x2C80,0x2CFF)]); (* Coptic *)
    (9, [(0x0400,0x04FF);(0x0500,0x052F);(0x2DE0,0x2DFF);(0xA640,0xA69F)]); (* Cyrillic Extended-B *)
    (10, [(0x0530,0x058F)]); (* Armenian *)
    (11, [(0x0590,0x05FF)]); (* Hebrew *)
    (12, [(0xA500,0xA63F)]); (* Vai *)
    (13, [(0x0600,0x06FF);(0x0750,0x077F)]); (* Arabic Supplement *)
    (14, [(0x07C0,0x07FF)]); (* NKo *)
    (15, [(0x0900,0x097F)]); (* Devanagari *)
    (16, [(0x0980,0x09FF)]); (* Bengali *)
    (17, [(0x0A00,0x0A7F)]); (* Gurmukhi *)
    (18, [(0x0A80,0x0AFFF)]); (* Gujarati *)
    (19, [(0x0B00,0x0B7F)]); (* Oriya *)
    (20, [(0x0B80,0x0BFF)]); (* Tamil *)
    (21, [(0x0C00,0x0C7F)]); (* Telugu *)
    (22, [(0x0C80,0x0CFF)]); (* Kannada *)
    (23, [(0x0D00,0x0D7F)]); (* Malayalam *)
    (24, [(0x0E00,0x0E7F)]); (* Thai *)
    (25, [(0x0E80,0x0EFF)]); (* Lao *)
    (26, [(0x10A0,0x10FF);(0x2D00,0x2D2F)]); (* Georgian Supplement *)
    (27, [(0x1B00,0x1B7F)]); (* Balinese *)
    (28, [(0x1100,0x11FF)]); (* Hangul Jamo *)
    (29, [(0x1E00,0x1EFF);(0x2C60,0x2C7F);(0xA720,0xA7FF)]); (* Latin Extended-D *)
    (30, [(0x1F00,0x1FFF)]); (* Greek Extended *)
    (31, [(0x2000,0x206F);(0x2E00,0x2E7F)]); (* Supplemental Punctuation *)
    (32, [(0x2070,0x209F)]); (* Superscripts And Subscripts *)
    (33, [(0x20A0,0x20CF)]); (* Currency Symbols *)
    (34, [(0x20D0,0x20FF)]); (* Combining Diacritical Marks For Symbols *)
    (35, [(0x2100,0x214F)]); (* Letterlike Symbols *)
    (36, [(0x2150,0x218F)]); (* Number Forms *)
    (37, [(0x2190,0x21FF);(0x27F0,0x27FF);(0x2900,0x297F);(0x2B00,0x2BFF)]); (* Miscellaneous Symbols and Arrows *)
    (38, [(0x2200,0x22FF);(0x2A00,0x2AFF);(0x27C0,0x27EF);(0x2980,0x29FF)]); (* Miscellaneous Mathematical Symbols-B *)
    (39, [(0x2300,0x23FF)]); (* Miscellaneous Technical *)
    (40, [(0x2400,0x243F)]); (* Control Pictures *)
    (41, [(0x2440,0x245F)]); (* Optical Character Recognition *)
    (42, [(0x2460,0x24FF)]); (* Enclosed Alphanumerics *)
    (43, [(0x2500,0x257F)]); (* Box Drawing *)
    (44, [(0x2580,0x259F)]); (* Block Elements *)
    (45, [(0x25A0,0x25FF)]); (* Geometric Shapes *)
    (46, [(0x2600,0x26FF)]); (* Miscellaneous Symbols *)
    (47, [(0x2700,0x27BF)]); (* Dingbats *)
    (48, [(0x3000,0x303F)]); (* CJK Symbols And Punctuation *)
    (49, [(0x3040,0x309F)]); (* Hiragana *)
    (50, [(0x30A0,0x30FF);(0x31F0,0x31FF)]); (* Katakana Phonetic Extensions *)
    (51, [(0x3100,0x312F);(0x31A0,0x31BF)]); (* Bopomofo Extended *)
    (52, [(0x3130,0x318F)]); (* Hangul Compatibility Jamo *)
    (53, [(0xA840,0xA87F)]); (* Phags-pa *)
    (54, [(0x3200,0x32FF)]); (* Enclosed CJK Letters And Months *)
    (55, [(0x3300,0x33FF)]); (* CJK Compatibility *)
    (56, [(0xAC00,0xD7AF)]); (* Hangul Syllables *)
    (57, [(0xD800,0xDFFF)]); (* Non-Plane 0 * *)
    (58, [(0x10900,0x1091F)]); (* Phoenician *)
    (59, [(0x4E00,0x9FFF);(0x2E80,0x2EFF);(0x2F00,0x2FDF);(0x2FF0,0x2FFF);(0x3400,0x4DBF);(0x20000,0x2A6DF);(0x3190,0x319F)]); (* Kanbun *)
    (60, [(0xE000,0xF8FF)]); (* Private Use Area (plane 0) *)
    (61, [(0x31C0,0x31EF);(0xF900,0xFAFF);(0x2F800,0x2FA1F)]); (* CJK Compatibility Ideographs Supplement *)
    (62, [(0xFB00,0xFB4F)]); (* Alphabetic Presentation Forms *)
    (63, [(0xFB50,0xFDFF)]); (* Arabic Presentation Forms-A *)
    (64, [(0xFE20,0xFE2F)]); (* Combining Half Marks *)
    (65, [(0xFE10,0xFE1F);(0xFE30,0xFE4F)]); (* CJK Compatibility Forms *)
    (66, [(0xFE50,0xFE6F)]); (* Small Form Variants *)
    (67, [(0xFE70,0xFEFF)]); (* Arabic Presentation Forms-B *)
    (68, [(0xFF00,0xFFEF)]); (* Halfwidth And Fullwidth Forms *)
    (69, [(0xFFF0,0xFFFF)]); (* Specials *)
    (70, [(0x0F00,0x0FFF)]); (* Tibetan *)
    (71, [(0x0700,0x074F)]); (* Syriac *)
    (72, [(0x0780,0x07BF)]); (* Thaana *)
    (73, [(0x0D80,0x0DFF)]); (* Sinhala *)
    (74, [(0x1000,0x109F)]); (* Myanmar *)
    (75, [(0x1200,0x137F);(0x1380,0x139F);(0x2D80,0x2DDF)]); (* Ethiopic Extended *)
    (76, [(0x13A0,0x13FF)]); (* Cherokee *)
    (77, [(0x1400,0x167F)]); (* Unified Canadian Aboriginal Syllabics *)
    (78, [(0x1680,0x169F)]); (* Ogham *)
    (79, [(0x16A0,0x16FF)]); (* Runic *)
    (80, [(0x1780,0x17FF);(0x19E0,0x19FF)]); (* Khmer Symbols *)
    (81, [(0x1800,0x18AF)]); (* Mongolian *)
    (82, [(0x2800,0x28FF)]); (* Braille Patterns *)
    (83, [(0xA000,0xA48F);(0xA490,0xA4CF)]); (* Yi Radicals *)
    (84, [(0x1700,0x171F);(0x1720,0x173F);(0x1740,0x175F);(0x1760,0x177F)]); (* Tagbanwa *)
    (85, [(0x10300,0x1032F)]); (* Old Italic *)
    (86, [(0x10330,0x1034F)]); (* Gothic *)
    (87, [(0x10400,0x1044F)]); (* Deseret *)
    (88, [(0x1D000,0x1D0FF);(0x1D100,0x1D1FF);(0x1D200,0x1D24F)]); (* Ancient Greek Musical Notation *)
    (89, [(0x1D400,0x1D7FF)]); (* Mathematical Alphanumeric Symbols *)
    (90, [(0xFF000,0xFFFFD);(0x100000,0x10FFFD)]); (* Private Use (plane 16) *)
    (91, [(0xFE00,0xFE0F);(0xE0100,0xE01EF)]); (* Variation Selectors Supplement *)
    (92, [(0xE0000,0xE007F)]); (* Tags *)
    (93, [(0x1900,0x194F)]); (* Limbu *)
    (94, [(0x1950,0x197F)]); (* Tai Le *)
    (95, [(0x1980,0x19DF)]); (* New Tai Lue *)
    (96, [(0x1A00,0x1A1F)]); (* Buginese *)
    (97, [(0x2C00,0x2C5F)]); (* Glagolitic *)
    (98, [(0x2D30,0x2D7F)]); (* Tifinagh *)
    (99, [(0x4DC0,0x4DFF)]); (* Yijing Hexagram Symbols *)
    (100, [(0xA800,0xA82F)]); (* Syloti Nagri *)
    (101, [(0x10000,0x1007F);(0x10080,0x100FF);(0x10100,0x1013F)]); (* Aegean Numbers *)
    (102, [(0x10140,0x1018F)]); (* Ancient Greek Numbers *)
    (103, [(0x10380,0x1039F)]); (* Ugaritic *)
    (104, [(0x103A0,0x103DF)]); (* Old Persian *)
    (105, [(0x10450,0x1047F)]); (* Shavian *)
    (106, [(0x10480,0x104AF)]); (* Osmanya *)
    (107, [(0x10800,0x1083F)]); (* Cypriot Syllabary *)
    (108, [(0x10A00,0x10A5F)]); (* Kharoshthi *)
    (109, [(0x1D300,0x1D35F)]); (* Tai Xuan Jing Symbols *)
    (110, [(0x12000,0x123FF);(0x12400,0x1247F)]); (* Cuneiform Numbers and Punctuation *)
    (111, [(0x1D360,0x1D37F)]); (* Counting Rod Numerals *)
    (112, [(0x1B80,0x1BBF)]); (* Sundanese *)
    (113, [(0x1C00,0x1C4F)]); (* Lepcha *)
    (114, [(0x1C50,0x1C7F)]); (* Ol Chiki *)
    (115, [(0xA880,0xA8DF)]); (* Saurashtra *)
    (116, [(0xA900,0xA92F)]); (* Kayah Li *)
    (117, [(0xA930,0xA95F)]); (* Rejang *)
    (118, [(0xAA00,0xAA5F)]); (* Cham *)
    (119, [(0x10190,0x101CF)]); (* Ancient Symbols *)
    (120, [(0x101D0,0x101FF)]); (* Phaistos Disc *)
    (121, [(0x102A0,0x102DF);(0x10280,0x1029F);(0x10920,0x1093F)]); (* Lydian *)
    (122, [(0x1F030,0x1F09F);(0x1F000,0x1F02F)]) (* Mahjong Tiles *)
   ];    
(*}}}*)

  value parsedFonts = ref [];

  value unicodeRangeFaceHash = Hashtbl.create 3;

  value addRangeFace ranges face =
    (
      List.iter (fun r ->
        (
          let l =
            try 
              Hashtbl.find unicodeRangeFaceHash r
            with [Not_found -> []]
          in
          Hashtbl.replace unicodeRangeFaceHash r [face :: l]
      )) ranges;
    );
  value getRanges () = Hashtbl.keys unicodeRangeFaceHash;
  value getFaces range =
    try 
      Hashtbl.find unicodeRangeFaceHash range
    with [Not_found -> []];

  value parseFace face unicodeRange1 unicodeRange2 unicodeRange3 unicodeRange4 =
  (

    if List.mem face !parsedFonts then ()
    else 
      (
        debug (
          let binary i =
          let rec _binary i res =
            (
              let two = Int64.of_int 2 in
              let s =(Printf.sprintf "%Ld%s" (Int64.rem i two)) res in
              let new_i = Int64.div i two in
              if new_i > Int64.zero  then _binary new_i s
              else s
            ) in
              _binary i "" in
          debug "parseFace %s (%Ld;%Ld;%Ld;%Ld) %s %s %s %s" face ( unicodeRange1)( unicodeRange2)( unicodeRange3)  ( unicodeRange4)
          (binary unicodeRange1)(binary unicodeRange2)(binary unicodeRange3)  (binary unicodeRange4);
        );

        parsedFonts.val := (!parsedFonts) @ [face];

        let getRangeByBit bit =
          if bit < 32 then 
            unicodeRange1
          else if bit < 64 then
            unicodeRange2
          else if bit < 96 then
            unicodeRange3
          else 
            unicodeRange4 in
        List.iter (fun (bit, ranges) ->
          let range = getRangeByBit bit in
          match range with
          [zero when (zero = Int64.zero)  -> ()
          | _ ->
              let bit = bit mod 32 in
              (
                let isSet = (Int64.logand range (Int64.of_int(1 lsl bit))) > Int64.zero in
                (
                  if isSet then 
                    (
                      debug "check range %Ld  bit: %d =  %b" range bit isSet;
                      addRangeFace ranges face
                    )
                  else ();
                )

              )
          ]
        ) bit_ranges
      );
  );

  value getDefaultLatin () =
    let (_,lst) = List.hd bit_ranges in
    List.hd (getFaces (List.hd lst));
end;

module Freetype = struct
  type dynamic_font= 
    {
      face: string;
      style: string;
      scale: float;
      ascender: float;
      descender: float;
      lineHeight: float;
      space:float;
      texInfo: option Texture.textureInfo;
    };
  type bc = 
    {
      charID:int;
      x: float;
      y: float;
      width: float;
      height: float;
      xOffset:float;
      yOffset:float;
      xAdvance: float;
      face: string;
    };
  external getFont: string-> int -> dynamic_font = "ml_freetype_getFont"; 
  external checkChar: int -> string -> int-> string = "ml_freetype_checkChar"; 
  external _getChar: int -> string -> int-> option bc = "ml_freetype_getChar"; 
  external _complete: unit -> unit = "ml_freetype_bindTexture";
  external setStroke: int -> unit = "ml_freetype_setStroke";
  external setScale: float -> unit = "ml_freetype_setScale";
  external setTextureSize: int -> unit = "ml_freetype_setTextureSize";

 
  value default_style = "Regular";
  class c =
    object(self)
      value mutable texture = Texture.zero;
      method setTex tx = texture := tx;
      method texture = texture;
      value mutable needCompletion = False;
      method setNeedCompletion flag = needCompletion := flag;
      method needCompletion = needCompletion;
      value mutable fonts : list ((string*string) * (list int))= [];
      method fonts = fonts;
      method addFont (face,style) sizes = fonts := [((face,style),sizes):: fonts];
      value mutable defaultTTF = "";
      method setDefaultTTF path = defaultTTF := path;
      method defaultTTF = defaultTTF;
    end;

  value _instance = Lazy.from_fun (fun () -> new c);
  value instance () : c = Lazy.force _instance;

  value charFaceHash = Hashtbl.create 10;

  value complete () =
    (
      debug "complete";
      _complete();

      (*
      List.iter (fun ((name,style), sizes) ->
        List.iter (fun size ->
          let font = get ~style ~size name in
          Hashtbl.clear font.chars;
        ) sizes;
      ) (instance())#fonts;
      Hashtbl.clear charFaceHash;
      *)
      (instance())#setNeedCompletion False;
    );
  value needCompletion () = (instance())#needCompletion;

  value createBc bf bc =
        let atlasNode =
          let region = Rectangle.create bc.x bc.y bc.width bc.height in
          AtlasNode.create bf.texture region () in
        {charID=bc.charID; xOffset=bc.xOffset; yOffset = bc.yOffset; xAdvance = bc.xAdvance; atlasNode};


  value addCharFace code face = 
    Hashtbl.add charFaceHash code face;
  
  exception FoundRange of (int * int);

  value getCharTTF code =
    let () = debug "getCharFace %d" code in
      let ranges = UnicodeRanges.getRanges () in
      try
        Enum.iter (fun (start,finish) ->
          if (code <= finish) && (code >= start) then
            (
              raise (FoundRange (start,finish))
            )
          else ();
        ) ranges;
        debug "not found range";
        [];
      with [FoundRange range -> UnicodeRanges.getFaces range];

  value getCharFace code = 
    try
      Some (Hashtbl.find charFaceHash code)
    with [Not_found -> None];

  value tex = ref Texture.zero;

  value getBc code path size =
    (
      let bc = _getChar code path size in
      match bc with
      [Some bc -> 
        (
          try
            let () = debug "face %s" bc.face in
            let sizes = Hashtbl.find fonts (bc.face, default_style) in
            (*
            let () = debug "face %s" bc.face in
            let sizes = Hashtbl.find fonts (def_face, style) in
            *)
            let bf = MapInt.find size sizes in
            let bchar = createBc bf bc in
            (
              addCharFace code (bc.face, path);
              tex.val := bf.texture;
              debug "add %d, size %d" bchar.charID size;
              Hashtbl.add bf.chars bchar.charID bchar;
              (instance())#setNeedCompletion True;
              Some (bchar, bf.ascender, bf.descender, bf.lineHeight)
            )
          with [excp ->let ()= debug "%s" (Printexc.to_string excp) in  None]
        )
      | _ -> 
          (
            addCharFace code ("default","default");
            None;
          )
      ];
    );
  value getBitmapChar (def_face,style,size) code =
    let () = Debug.d "getBitmapChar %s" (UTF8.init 1 (fun i -> UChar.chr code)) in
    let path =
      let rec getFaceRec paths =
        match paths with
        [[ttfpath::tl] ->
          let () =debug "check [%s]" ttfpath in
          let face_family = checkChar code ttfpath size in
          let () =debug "face family [%s]" face_family in
          if  face_family <> "" then ttfpath
          else getFaceRec tl 
        | [] ->
          let () =debug "defaultttf" in
            (instance())#defaultTTF
        ] in
      let ttfs = getCharTTF code in
      let () = Debug.d "ttf %s" (String.concat "," ttfs) in
      getFaceRec ttfs
    in
    getBc code path size;

  value saveFontInfo (face,style) sizes = (instance())#addFont (face,style) sizes;

  Callback.register "add_font_ranges" UnicodeRanges.parseFace;
end;

value getBitmapChar (face,style,size) code = 
  match Freetype.getCharFace code with
  [Some (face,path) -> 
    try
      debug "has face %s" face;
          let sizes = Hashtbl.find fonts (face, Freetype.default_style) in
          (*
          let () = debug "face %s" bc.face in
          let sizes = Hashtbl.find fonts (def_face, style) in
          *)
          try
            let bf = MapInt.find size sizes in
            (
              try
                Some (Hashtbl.find bf.chars code, bf.ascender, bf.descender, bf.lineHeight)
              with [Not_found -> Freetype.getBc code path size]
            )
          with [_ -> let () = debug ("no size:%d" size) in None]
        with [Not_found -> let () = debug ("no font %s" face) in None]
  | None -> Freetype.getBitmapChar (face,style,size) code
  ];



value registerDynamic (sizes:list int) ttfpath =
  let open Freetype in
    let (face,style,sizesMap,_) =
      List.fold_left (fun (face,style,res, texInfo) size ->
      let info = 
        let  () = debug  "getFont [%s]" ttfpath in
        Freetype.getFont ttfpath size in
      let face = info.face in
      let style = (*info.style*) Freetype.default_style in
      let scale = info.scale in
      let texture= 
        match info.texInfo with 
        [ Some t -> 
          let tx = Texture.make t in
          (
            (Freetype.instance())#setTex tx;
            tx
          )
        | None -> (Freetype.instance())#texture 
        ] in
        let bf = { chars=Hashtbl.create 0; texture; scale; ascender = info.ascender; descender = info.descender; space = info.space ; lineHeight = info.lineHeight; isDynamic = True} in
        let () = debug "(%s;%s) size %d ascender %f descender %f height %f space %f %f" face style size info.ascender info.descender info.lineHeight info.space scale in
        let sizes= MapInt.add size bf res in
        (face,style,sizes, Some texture);
      ) ("","",MapInt.empty,None) sizes in
    (

      Hashtbl.replace fonts (face,style) sizesMap;
      Freetype.saveFontInfo (face,style) sizes;
      (face,style);
    );



  value lumalInfo = ref None;
value show () =
  (
    Image.create !Freetype.tex;
    (*
    match !lumalInfo with 
    [Some i -> Image.create(Texture.make i)
    | _ -> failwith "non"
    ];
    *)
  );

value dynamicFontComplete () = 
  (
    match Freetype.needCompletion () with
    [True -> 
      ( 
        Freetype.complete (); 
      )
    |False -> ()
    ];
  );

IFPLATFORM(android ios)
  external getSystemFonts: unit -> string = "ml_getSystemFonts";
  external getSystemDefaultFont: unit -> string = "ml_getSystemDefaultFont";
ELSE 
  value getSystemFonts () = "";
  value getSystemDefaultFont () = "";
ENDPLATFORM;
(*
  external lumal: unit -> Texture.textureInfo = "ml_lumal";
  *)
value registerSystemFont ?textureSize ?(scale=1.) ?(stroke=0) (sizes: list int) = 
  (
    Freetype.setStroke stroke;
    Freetype.setScale scale;
    match textureSize with 
    [Some s -> Freetype.setTextureSize s
    | _ -> ()
    ];

    try
      let systemFonts = ExtLib.String.nsplit (getSystemFonts()) ";" in
      match systemFonts with
      [ [hd::tl] ->
        (
          let default = getSystemDefaultFont () in
          let () = Debug.d "fonts count %d" (List.length systemFonts) in
          (*
          let (systemFonts,_) = ExtLib.List.split_nth 30 systemFonts in
          let () = Debug.d "fonts count %d" (List.length systemFonts) in
          *)
          let found = ref False in
          (
            debug "System fonts count: %d" (List.length systemFonts);
            let (face,style,foundDefault) =
              List.fold_left (fun (face,style,foundDefault) ttfpath -> 
                if ttfpath = "" then (face,style,foundDefault)
                else
                  (
                    let isDefault = (ttfpath = default)in
                    let flag = if not foundDefault then isDefault else foundDefault in
                    let (face,style) = if not isDefault  then registerDynamic sizes ttfpath else (face,style) in
                    let () = debug "!!!!!!!%s (%s,%s)" ttfpath face style in
                    (face,style,flag)
                  )
              ) ("","",False) systemFonts in
            (
              if foundDefault then (
                (Freetype.instance())#setDefaultTTF default;
              )
              else (
                (Freetype.instance())#setDefaultTTF (UnicodeRanges.getDefaultLatin());
              );
              if foundDefault then registerDynamic sizes default
              else (face,style)
            )
          )
        )
      | _ -> ("","")
      ]
    with [ExtLib.Invalid_string -> ("","")];
  );
