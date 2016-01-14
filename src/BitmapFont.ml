
open LightCommon;


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
                let () = debug "size %d ascender %f descender %f height %f space %f" size ascender descender lineHeight space in
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
    };
  external getFont: string-> int -> dynamic_font = "ml_freetype_getFont"; 
  external _getChar: int -> int-> option bc = "ml_freetype_getChar"; 
  external _complete: unit -> unit = "ml_freetype_bindTexture";

 
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
    end;

  value _instance = Lazy.from_fun (fun () -> new c);
  value instance () : c = Lazy.force _instance;

  value complete () =
    (
      _complete();
      List.iter (fun ((name,style), sizes) ->
        List.iter (fun size ->
          let font = get ~style ~size name in
          Hashtbl.clear font.chars;
        ) sizes;
      ) (instance())#fonts;
      (instance())#setNeedCompletion False;
    );
  value needCompletion () = (instance())#needCompletion;

  value createBc bf bc =
        let atlasNode =
          let region = Rectangle.create bc.x bc.y bc.width bc.height in
          AtlasNode.create bf.texture region () in
        {charID=bc.charID; xOffset=bc.xOffset; yOffset = bc.yOffset; xAdvance = bc.xAdvance; atlasNode};

  value getChar (face,style,size) code =
    let bc = _getChar code size in
    match bc with
    [Some bc -> 
      (
        let sizes = Hashtbl.find fonts (face, style) in
        try
          let bf = MapInt.find size sizes in
          let bchar = createBc bf bc in
          (
            debug "add %d, size %d" bchar.charID size;
            Hashtbl.add bf.chars bchar.charID bchar;
            (instance())#setNeedCompletion True;
            Some bchar
          )
        with [_ ->let ()= debug "b" in  None]
      )
    | _ -> let () = debug "11" in
    None
    ];
  value saveFontInfo (face,style) sizes = (instance())#addFont (face,style) sizes;
end;

value registerDynamic (sizes:list int) ttfpath =
  let open Freetype in
    let (face,style,sizesMap,_) =
      List.fold_left (fun (face,style,res, texInfo) size ->
      let info = Freetype.getFont ttfpath size in
      let face = info.face in
      let style = info.style in
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


value getChar isDynamic info chars code = 
  try 
    Some (Hashtbl.find chars code) 
  with [ Not_found -> 
    match isDynamic with
    [True -> Freetype.getChar info code
    |False -> None 
    ]
  ];

value show size =
  (
    let tex = 
      let sizes = Hashtbl.find fonts ("Noto Sans SC","Regular")in
      let bf = MapInt.find size sizes in
      bf.texture in
    Image.create tex;
  );

value dynamicFontComplete () = 
  match Freetype.needCompletion () with
  [True -> 
    ( 
      Freetype.complete (); 
    )
  |False -> ()
  ];

IFPLATFORM(ios android)
  external getSystemFontPath: string -> string = "ml_getSystemFontPath";
ELSE 
  value getSystemFontPath _ = "";
ENDPLATFORM;
