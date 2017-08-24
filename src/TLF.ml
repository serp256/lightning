
module D = DisplayObject;
open ExtList;
open ExtHashtbl;

value default_font_family = ref "Arial";
value default_font_size = ref 14;
value (|>) a f = f a;

type img_valign = [= `aboveBaseLine | `underBaseLine | `centerBaseLine | `default ];
type img_attribute = 
  [= `width of float
  | `height of float
  | `paddingLeft of float
  | `paddingRight of float
  | `paddingTop of float
  | `valign of img_valign
  ];

type img_attributes = list img_attribute;

type span_attribute = 
  [= `fontFamily of string
  | `fontSize of int
  | `fontWeight of string
  | `color of int
  | `alpha of float
  | `backgroundColor of int (* как это замутить то я забыла *)
  | `backgroundAlpha of float 
  ];

type span_attributes = list span_attribute;

type simple_element = [= `img of (img_attributes * D.c) | `span of (span_attributes * simple_elements) | `br | `substring of (string * int * int) | `text of string ]
and simple_elements = list simple_element;

type p_halign = [= `left | `right | `center ];
type p_valign = [= `top | `bottom | `center ];
type p_attribute = 
  [= span_attribute
  | `halign of p_halign
  | `valign of p_valign
  | `spaceBefore of float
  | `spaceAfter of float
  | `textIndent of float
  ];

type p_attributes = list p_attribute;

type div_attribute = 
  [= p_attribute
  | `paddingTop of float
  | `paddingLeft of float
  ];


type div_attributes = list div_attribute;


type main = 
  [= `div of (div_attributes * (list main))
  | `p of (p_attributes * simple_elements)
  ];


DEFINE AEXPAND(name,tag) = 
  match name with
  [ Some v -> [ tag v :: attrs ]
  | None -> attrs
  ];


value img ?width ?height ?paddingLeft ?paddingTop ?paddingRight ?valign img : simple_element = 
  let attrs = [] in
  let attrs = AEXPAND (width,`width) in
  let attrs = AEXPAND (height,`height) in
  let attrs = AEXPAND (paddingLeft,`paddingLeft) in
  let attrs = AEXPAND (paddingTop,`paddingTop) in
  let attrs = AEXPAND (paddingRight,`paddingRight) in
  let attrs = AEXPAND (valign,`valign) in
  `img (attrs,img#asDisplayObject);


DEFINE FONT_WEIGHT =
  match fontWeight with
  [ Some "normal" -> [ `fontWeight "regular" :: attrs ]
  | Some w -> [ `fontWeight w :: attrs ]
  | None -> attrs
  ];

value span ?fontWeight ?fontFamily ?fontSize ?color ?alpha elements : simple_element = 
  let attrs = [] in
  let attrs = FONT_WEIGHT in
  let attrs = AEXPAND(fontFamily,`fontFamily) in
  let attrs = AEXPAND(fontSize,`fontSize) in
  let attrs = AEXPAND(color,`color) in
  let attrs = AEXPAND(alpha,`alpha) in
  `span (attrs,elements);


value p ?fontWeight ?fontFamily ?fontSize ?color ?alpha ?halign ?valign ?spaceBefore ?spaceAfter ?textIndent elements : main = 
  let attrs = [] in
  let attrs = FONT_WEIGHT in
  let attrs = AEXPAND(fontFamily,`fontFamily) in
  let attrs = AEXPAND(fontSize,`fontSize) in
  let attrs = AEXPAND(color,`color) in
  let attrs = AEXPAND(alpha,`alpha) in
  let attrs = AEXPAND(halign,`halign) in
  let attrs = AEXPAND(valign,`valign) in
  let attrs = AEXPAND(spaceBefore,`spaceBefore) in
  let attrs = AEXPAND(spaceAfter,`spaceAfter) in
  let attrs = AEXPAND(textIndent,`textIndent) in
  `p (attrs,elements);


value getAttr(*: ('a -> option 'b) -> 'b -> list 'a -> 'b *)= fun f default attrs -> try (ExtList.List.find_map f attrs) with [ Not_found -> default ];
value getAttrOpt(*: ('a -> option 'b) -> list 'a -> option 'b*) = fun f attrs -> try Some (ExtList.List.find_map f attrs) with [ Not_found -> None ];


exception Parse_error of (string*string);

value parse_error inp fmt = 
  let (line,column) = Xmlm.pos inp in
  Printf.kprintf (fun s -> raise (Parse_error (Printf.sprintf "%d:%d" line column) s)) fmt;


value parse_float inp p = 
  try
    float_of_string p
  with [ Failure "float_of_string" -> parse_error inp "bad float: %s" p ];
  
  
value parse_int inp p = 
  try
    try 
      let (_, c) = ExtString.String.split p "#" in
      int_of_string ("0x" ^ c)
    with
      [ _ -> int_of_string p ] 
  with [ Failure "int_of_string" -> parse_error inp "bad int: %s" p ];



value parse_span_attribute inp:  Xmlm.attribute -> span_attribute =
(
  ();
  fun
    [ ((_,("font-family" | "fontFamily")),ff) -> `fontFamily ff
    | ((_,("font-size" | "fontSize")),sz) -> `fontSize (parse_int inp sz)
    | ((_,("font-weight" | "fontWeight")),sz) -> `fontWeight (match sz with [ "normal" -> "regular" | x -> x ])
    | ((_,"color"),c) -> `color (parse_int inp c)
    | ((_,"alpha"),alpha) -> `alpha (parse_float inp alpha)
    | ((_,an),_) -> parse_error inp "unknown attribute %s" an
    ];
);

value parse_simple_elements inp imgLoader = 
  let el_end () =  
    match Xmlm.input inp with
    [ `El_end -> ()
    |  _ -> parse_error inp "want end tag"
    ]
  in
  parse [] where
    rec parse res = 
      match Xmlm.input inp with
      [ `El_start (("",tag),attributes) ->
        match tag with
        [ "img" -> 
          let img = ref None in
          let attribs = 
            ExtList.List.filter_map begin fun ((_,name),vlue) ->
              match name with
              [ "src" -> 
                ( 
                  let i = imgLoader vlue in img.val := Some i;
                  None
                )
              | "width" | "w" -> Some (`width (parse_float inp vlue))
              | "height" | "h" -> Some (`height (parse_float inp vlue))
              | "padding-left" -> Some (`paddingLeft (parse_float inp vlue))
              | "padding-top" -> Some (`paddingTop (parse_float inp vlue))
              | "padding-right" -> Some (`paddingRight (parse_float inp vlue))
              | "valign" -> 
                  let v = 
                    match vlue with
                    [ "above-baseline" -> `aboveBaseLine
                    | "under-baseline" -> `underBaseLine
                    | "center-baseline" -> `centerBaseLine
                    | "default" -> `default
                    | _ -> parse_error inp "incorrect img halign value %s" vlue
                    ]
                  in
                  Some (`valign v)
              | _ -> parse_error inp "unknown attribute img:%s" name
              ]
            end attributes
          in
          match !img with
          [ None -> parse_error inp "img src"
          | Some img -> 
              let () = el_end () in
              parse [ `img (attribs,img) :: res ]
          ]
        | "span" ->
            let attribs = List.map (parse_span_attribute inp) attributes in
            let elements = parse [] in
            parse [ `span (attribs,elements) :: res ]
        | "br" -> let () = el_end () in parse [ `br :: res ]
        | _ -> parse_error inp "unknown simple tag: %s" tag
        ]
      | `Data text -> parse [ `text text :: res ]
      | `El_end -> List.rev res
      | _ -> parse_error inp "DTD?"
      ];



value parse_simples ?(imgLoader:option (string -> DisplayObject.c)) text : simple_elements = 
  let imgLoader = match imgLoader with [ Some f -> f | None -> fun s -> ((Image.load s) :> DisplayObject.c) ] in
  let inp = Xmlm.make_input (`String (0,"<simples>"^text^"</simples>")) in
  match Xmlm.input inp with
  [ `Dtd _ -> 
    match Xmlm.input inp with
    [ `El_start (("","simples"),[]) -> parse_simple_elements inp imgLoader
    | _ -> assert False
    ]
  | _ -> parse_error inp "Dtd"
  ];




value parse ?(imgLoader:option (string -> DisplayObject.c)) xml : main = 
  let imgLoader = match imgLoader with [ Some f -> f | None -> fun s -> ((Image.load s) :> DisplayObject.c) ] in
  let inp = Xmlm.make_input (`String (0,xml)) in
  match Xmlm.input inp with
  [ `Dtd _ ->
    let parse_p_attribute : Xmlm.attribute -> p_attribute = fun
      [ ((_,"halign"),v) -> `halign (match v with [ "left" -> `left | "right" -> `right | "center" -> `center | _ -> parse_error inp "incorrect attribute halign value %s" v])
      | ((_,"valign"),v) -> `valign (match v with [ "top" -> `top | "bottom" -> `bottom | "center" -> `center | _ -> parse_error inp "incorrect attribute valign value %s" v])
      | ((_,"text-indent"),v) -> `textIndent (parse_float inp v)
      | ((_,"space-before"),spb) -> `spaceBefore (parse_float inp spb) 
      | ((_,"space-after"),spa) -> `spaceAfter (parse_float inp spa)
      | x -> ((parse_span_attribute inp x) :> p_attribute)
      ]
    in
    let rec parse_top_level () : option main = 
      match Xmlm.input inp with
      [ `El_start (("","p"),attributes) -> (* need to parse p attributes *)
        let p_attribs = List.map parse_p_attribute attributes in
        let elements = parse_simple_elements inp imgLoader in
        Some (`p (p_attribs,elements))
      | `El_start (("","div"),attributes) -> (* need to parse div attributes *)
          let attribs = 
            List.map begin fun
              [ ((_,"padding-top"),v) -> `paddingTop (parse_float inp v)
              | ((_,"padding-left"),v) -> `paddingLeft (parse_float inp v)
              (* TODO: something about positions *)
              | x -> ((parse_p_attribute x) :> div_attribute)
              ]
            end attributes
          in
          let rec parse_content res = 
            match parse_top_level () with
            [ Some el -> parse_content [ el :: res ]
            | None -> res
            ]
          in
          let elements = parse_content [] in
          Some (`div (attribs,List.rev elements))
      | `El_end -> None
      | _ -> parse_error inp "top level"
      ]
    in
    match parse_top_level () with
    [ Some res -> res
    | None -> assert False 
    ]
  | _ -> parse_error inp "Dtd"
  ];

value (=|=) k v = (("",k),v);
value (=.=) k v = k =|= string_of_float v;
value (=*=) k v = k =|= string_of_int v;

value to_string t = 
  let span_attribute = fun
    [ `fontFamily s -> "font-family" =|= s
    | `fontSize i -> "font-size" =*= i
    | `fontWeight s -> "font-weight" =|= s
    | `color i -> "color" =|= (Printf.sprintf "%X" i)
    | `alpha f -> "alpha" =.= f
    | `backgroundColor i -> "background-color" =|= (Printf.sprintf "%X" i)
    | `backgroundAlpha f -> "background-alpha" =.= f
    ]
  in
  let string_of_p_halign = fun [ `left -> "left" | `right -> "right" | `center -> "center" ]
  and string_of_p_valign = fun [ `top -> "top" | `bottom -> "bottom" | `center -> "center" ]
  in
  let p_attribute = fun
    [ #span_attribute as sa -> span_attribute sa
    | `halign p_halign -> "halign" =|= (string_of_p_halign p_halign)
    | `valign p_valign -> "valign" =|= (string_of_p_valign p_valign)
    | `spaceBefore f -> "space-before" =.= f
    | `spaceAfter  f -> "space-after" =.= f
    | `textIndent f -> "text-indent" =.= f
    ]
  in
  let main_attributes attrs = 
    List.map begin fun 
      [ #p_attribute as sa -> p_attribute sa
      | `paddingTop f -> "padding-top" =.= f
      | `paddingLeft f -> "padding-left" =.= f
      ]
    end attrs
  and img_attributes attrs = 
    List.map begin fun
      [ `width f -> "width" =.= f
      | `height f -> "height" =.= f
      | `paddingLeft f -> "padding-left" =.= f
      | `paddingRight f -> "padding-right" =.= f
      | `paddingTop f -> "pading-top" =.= f
      | `valign valign -> "valign" =|= "unknown poeven'"
      ]
    end attrs
  in
  let buf = Buffer.create 64 in
  let xmlout = Xmlm.make_output (`Buffer buf) in
  let () = Xmlm.output xmlout (`Dtd None) in
  let rec convert_simple = fun
    [ `img attributes img -> 
      (
        let el = `El_start (("","img"),img_attributes attributes) in
        Xmlm.output xmlout el;
        Xmlm.output xmlout (`Data img#name);
        Xmlm.output xmlout `El_end;
      )
    | `br -> (Xmlm.output xmlout (`El_start (("","br"),[])); Xmlm.output xmlout `El_end) 
    | `text text | `substring text _ _ -> Xmlm.output xmlout (`Data text)
    | `span attributes children ->
      (
        let el = `El_start (("","span"),List.map span_attribute attributes) in
        Xmlm.output xmlout el;
        List.iter convert_simple children;
        Xmlm.output xmlout `El_end;
      )
    ]
  in
  let rec convert_main = fun
    [ `div attributes children -> 
      let el = `El_start (("","div"),main_attributes attributes) in
      (
        Xmlm.output xmlout el;
        List.iter convert_main children;
        Xmlm.output xmlout `El_end;
      )
    | `p attributes children ->
      (
        let el = `El_start (("","p"),List.map p_attribute attributes) in
        Xmlm.output xmlout el;
        List.iter convert_simple children;
        Xmlm.output xmlout `El_end;
      )
    ]
  in
  (
    convert_main t;
    Buffer.contents buf;
  );

value subtractSize (sx,sy) (sx',sy') = 
  (
    match sx with [ None -> None | Some sx -> Some (sx -. sx') ],
    match sy with [ None -> None | Some sy -> Some (sy -. sy') ]
  );


value getFontFamily =
  let f: !'p. ([> `fontFamily of string] as 'p) -> option string = fun [ `fontFamily fn -> Some fn | _ -> None ] in
  getAttrOpt f;

value getFontStyle = getAttrOpt (fun [ `fontWeight fw -> Some fw | _ -> None ]);

value getFontSize = getAttrOpt (fun [ `fontSize fn -> Some fn | _ -> None ]);



value getTextIndent attributes = getAttr (fun [ `textIndent v -> Some v | _ -> None]) 0. attributes;

value getFont attributes =
  let fontFamily =
    match getFontFamily attributes with
    [ Some fn -> fn
    | None -> !default_font_family
    ]
  and style = getFontStyle attributes 
  and size = 
    match getFontSize attributes with
    [ Some size -> size 
    | _ -> !default_font_size
    ]
  in
  BitmapFont.get ~applyScale:True ~size ?style fontFamily;



type line_element = [ Img of D.c | Char of (int * BitmapFont.bc * AtlasNode.t) | WhiteSpace of float ];
type line = 
  {
    lchars: mutable DynArray.t line_element;
    lx: mutable float; 
    ly: mutable float;
    lineHeight: mutable float;
    ascender: mutable float;
    descender: mutable float;
    currentX: mutable float;
    closed: mutable bool;
  };

class tlfSprite () =
  object(self)
    inherit Sprite.c as super;

    method! setFilters f =
      let (stroke, rest) = List.partition (fun f -> match f with [ `Stroke _ -> True | _ -> False]) f in
        (
          if stroke = []
          then ()
          else Enum.iter (fun c -> c#setFilters stroke) self#children;

          super#setFilters rest;
          filters := f;
        );
  end;


value createLine ?(indent=0.) font lines =  
  let line = 
    {
      lchars = DynArray.create (); 
      lineHeight = font.BitmapFont.lineHeight; 
      ascender = font.BitmapFont.ascender; 
      descender = font.BitmapFont.descender; 
      currentX = indent;
      lx = 0.; 
      ly = 0.; 
      closed = False
    } in
  (
    Stack.push line lines;
    line;
  );



value imagesAndCharsFilter c = 
  match c with 
  [ Char _ | Img _ -> True 
  | _ -> False 
  ];


value lineWidth line = 
  if DynArray.empty line.lchars
  then 0.
  else
    
    let lchars = DynArray.copy line.lchars in 
    let () = DynArray.filter imagesAndCharsFilter lchars in
    let (lx,lw) = 
      match DynArray.last lchars with
      [ Img i -> (i#x,i#width)
      | Char (_, _, c) -> (AtlasNode.x c, AtlasNode.width c)
      | _ -> failwith "Can't be here"
      ]
    and fx = 
      match DynArray.get lchars 0 with
      [ Img i -> i#x
      | Char (_, _, c) -> AtlasNode.x c
      | _ -> failwith "Can't be here"      
      ]
    in
    lx +. lw -. fx;



value lineMinY line = 
  if DynArray.empty line.lchars
  then 0.
  else

    let lchars = DynArray.copy line.lchars in 
    let () = DynArray.filter imagesAndCharsFilter lchars in    
    let minY = ref line.lineHeight in
    (
      for i = 0 to DynArray.length lchars - 1 do
        let y = 
          match DynArray.get lchars i with
          [ Img i -> i#y
          | Char (_, _, c) -> AtlasNode.y c
          | _ -> failwith "Can't be here"
          ]
        in
        if !minY > y then minY.val := y else ()
      done;
      !minY;
    );


value adjustToLine ?ascender ?descender ?height line = 
(
  let res = 
    match ascender with
    [ Some asc ->
      let () = debug "ascender %f: line asc %f" asc line.ascender in
      match compare line.ascender asc with
      [ 0 -> 0.
      | -1 -> (* надо увеличить отступ сверху *)
        (
          let lchars = DynArray.copy line.lchars in 
          let () = DynArray.filter imagesAndCharsFilter lchars in    
          let diff = asc -. line.ascender in
          (
            DynArray.iteri begin fun i -> fun
              [ Img img -> img#setY (img#y +. diff)
              | Char (code, bmc, c) -> DynArray.set lchars i (Char (code, bmc, (AtlasNode.setY ((AtlasNode.y c) +. diff) c)))
              | _ -> failwith "I'd better do this shit usign polymorphic variants"
              ]
            end lchars;
          );
          line.ascender := asc;
          0.
        )
      | _ -> 
          let diff = line.ascender -. asc in
          diff
      ]
    | None -> line.ascender
    ]
  in
  (
    match descender with
    [ Some desc when line.descender < desc -> line.descender := desc
    | _ -> ()
    ];
    match height with
    [ Some h when h > line.lineHeight -> line.lineHeight := h
    | None ->
      let nheight = line.ascender +. line.descender in
      if nheight > line.lineHeight 
      then line.lineHeight := nheight
      else ()
    | _ -> ()
    ];
    res;
  );
);

value addToLine width element line = 
(
    DynArray.add line.lchars element;
    line.currentX := width +. line.currentX;
    
    
    (*
    match compare line.baseLine baseLine with
    [ 0 -> DynArray.add line.lchars element
    | -1 (* был меньше *) ->
      let diff = baseLine -. line.baseLine in
      (
        DynArray.iteri begin fun i -> fun
          [ Img img -> img#setY (img#y +. diff)
          | Char (code, bmc,c) -> DynArray.set line.lchars i (Char (code, bmc, (AtlasNode.setY ((AtlasNode.y c) +. diff) c)))
          ]
        end line.lchars;
        line.baseLine := baseLine;
        DynArray.add line.lchars element;
      )
    | _ (* был больше *) -> 
        match element with
        [ Img img as i ->
          (
            img#setY (img#y +. (line.baseLine -. baseLine));
            DynArray.add line.lchars i;
          )
        | Char (code, bmc, c) -> DynArray.add line.lchars (Char (code, bmc, (AtlasNode.setY ((AtlasNode.y c) +. (line.baseLine -. baseLine)) c)))
        ]
    ];
    line.currentX := width +. line.currentX;
    *)
); (* здесь же надо позырить что предыдущий базелайн такой-же и перехуячить там все нахуй *)





value lineRollback ascender descender line = 
(
  if line.ascender <> ascender 
  then () (* need move all chars *)
  else ();
  line.descender := descender;
  line.lineHeight := ascender +. descender;
);


(* Сперва переставляем символы в нужном порядке, а затем пересчитываем координаты *)
value convert_line_to_farsi line = 

  let initialX = 
    try 
      let ix = ref 0. in 
      let _ = DynArray.index_of (fun item -> match item with [ Char (_, _, c) -> (ix.val := (AtlasNode.x c); True ) | _ -> False ]) line.lchars 
      in  ix.val
    with [ Not_found -> 0.]
  in
  
  
  let rec process_line res tmp items = 
    match items with
    [ [] -> List.rev (List.append res (List.rev tmp))
    
    | [ item :: tail ] ->   
          
        let (res', tmp') = 
          match item with 
          [ Char (code, _, _)  -> 

              if (Farsi.isFarsi (UChar.uchar_of_int code)) then
                (List.append (List.append res (List.rev tmp)) [item]  ,[])
              else 
                (res, (List.append tmp [item]))

          | WhiteSpace _ -> (res, (List.append tmp [item]))

          | _   ->  (res, tmp)
          ]    
        in process_line res' tmp' tail    
    ]
  in 
  
  let reordered = process_line [] [] (DynArray.to_list line.lchars) in


  (* *)
  let rec update_positions x items res = 

    match items with 
    [ [] -> res

    | [item :: tail ] -> 
        match item with 
        [ Char (code, bminfo, anode) -> 
            
            let anode' = AtlasNode.setX (bminfo.xOffset +. x) anode in 
            let char'  = Char (code, bminfo, anode')             
            in update_positions (x +. bminfo.xAdvance) tail [ char' :: res ]
        
        | WhiteSpace space -> update_positions (x +. space ) tail res

        | _ -> update_positions x tail res
        ]        
    ]
  in   
  
  let updated = update_positions initialX reordered [] in
   (
    line.lchars := DynArray.of_list updated;
    line
  );
  



  


DEFINE CHAR_SPACE = 32;
DEFINE CHAR_THIN_SPACE = 0x2009;
DEFINE CHAR_NEWLINE = 10;


  (*}}}*)


(* width, height вытащить наверно в html тоже *)
value create ?width ?height ?border ?dest ?farsi (html:main) = 
  
  let () = debug 
    let opt = fun [ Some f -> string_of_float f | None -> "NONE" ] in
    Debug.d "create %s:%s" (opt width) (opt height) 
  in



  let make_lines width attributes lines (elements:list simple_element) =

    let line_whitespace = ref None in
    let createLine ?indent font lines =  
      (
        line_whitespace.val := None;
        createLine ?indent font lines;
      )
    in
    
    
    (* START: draw text  *)
    let rec draw_text attributes text sidx eidx elements next = 

      let () = debug "draw text: %s [%d:%d]" text sidx eidx in
      let color = getAttr (fun [ `color n -> Some n | _ -> None]) 0 attributes in
      let alpha = getAttr (fun [ `alpha a -> Some a | _ -> None]) 1. attributes in
      let fontFamily =
          match getFontFamily attributes with
          [ Some fn -> fn
          | None -> !default_font_family
          ]
      and fontStyle = 
          match getFontStyle attributes with
          [ Some s-> s
          | _ -> "regular"
          ]
      and fontSize = 
          match getFontSize attributes with
          [ Some size -> size 
          | _ -> !default_font_size
          ]
      in
      let font = getFont attributes in

      let () = debug "font scale: %f" font.BitmapFont.scale in

      let text_whitespace = ref None in
      let yoffset = ref 0. in


      let rec add_line currentLine index = 
        let () = debug "add line" in
        let () = currentLine.closed := True in
        let nextLine = createLine font lines in
        (
          yoffset.val := 0.;
          text_whitespace.val := None;
          add_char nextLine index
        )



      (* Add char WHERE??? *)
      and add_char line index = 
        if index <= eidx 
        then
          let code = match farsi with 
            [ Some t when t -> Farsi.remap_char_at_index text index
            | _ -> UTF8.look text index
            ]
          in 
          let code = UChar.uint_code code in 
          
          let open BitmapFont in
          if code = CHAR_NEWLINE 
          then
            add_line line (UTF8.next text index)
          else if code = CHAR_SPACE 
          then
           (
             
             (* line.currentX := line.currentX +. font.space; *)
             addToLine font.space (WhiteSpace font.space) line;

             
             text_whitespace.val := Some (index,DynArray.length line.lchars);
             add_char line (UTF8.next text index)
           )
           else if code = CHAR_THIN_SPACE 
           then
           (
             
             (* line.currentX := line.currentX +. font.space/.2.; *)

             addToLine (font.space /. 2.) (WhiteSpace (font.space /. 2.)) line;
             
             text_whitespace.val := Some (index,DynArray.length line.lchars);
             add_char line (UTF8.next text index)
           )
           else

            let bchar =
                try 
                  Some (Hashtbl.find font.chars code, font.ascender, font.descender, font.lineHeight)
                with [ Not_found -> 
                  match font.isDynamic with
                  [ True -> BitmapFont.getBitmapChar (fontFamily, fontStyle, fontSize) code
                  | False -> None
                  ]
                ] 
            in
            
            match bchar with
            (* first match of bchar *)
            [ Some (bchar, asc, desc, lheight) ->
                
                let (bchar, asc, desc, lheight) = 
                  if font.scale <> 1. 
                  then ({(bchar) with xOffset = bchar.xOffset *. font.scale; yOffset = bchar.yOffset *. font.scale; xAdvance = bchar.xAdvance *. font.scale}, asc *. font.scale, desc *. font.scale, lheight *. font.scale)
                  else (bchar, asc ,desc, lheight)
                in
                
                let () = debug "put char with code: %d, current_x: %f, xAdvance: %f, width: %f" code line.currentX bchar.BitmapFont.xAdvance (Option.default 0. width) in
                match width with
                [ Some width when line.currentX +. bchar.BitmapFont.xAdvance > width && bchar.BitmapFont.xAdvance <= width ->
                    
                    let () = debug "can't add this char" in
                    match !text_whitespace with
                    [ None -> 
                         match !line_whitespace with
                         [ None -> 
                            let () = debug "has no whitespaces on this line" in
                            add_line line index 
                         | Some len ascender descender elements ->
                            (
                              debug "line has whitespace";
                              DynArray.delete_range line.lchars len ((DynArray.length line.lchars) - len);
                              lineRollback ascender descender line;
                              line.closed := True;
                              loop elements
                            )
                         ]
                    | Some (idx, numAddedChars) ->
                      (
                         debug "text has whitespace %d:%d" idx numAddedChars;
                         let cnt_chars_in_line = DynArray.length line.lchars in
                         DynArray.delete_range line.lchars numAddedChars (cnt_chars_in_line - numAddedChars);
                         add_line line (UTF8.next text idx)
                      )
                    ]
                
                | _ ->
                   (
                      yoffset.val := line.ascender -. asc;
                      line.descender := max line.descender desc;
                      line.lineHeight := max line.lineHeight lheight;
                      let b = AtlasNode.update ~scale:font.scale ~pos:{Point.x = line.currentX +. bchar.xOffset; y = !yoffset +. bchar.yOffset} ~color:(`Color color) ~alpha:alpha bchar.atlasNode in
                      addToLine bchar.xAdvance (Char (code, bchar, b)) line;
                      add_char line (UTF8.next text index)
                   )
                ] (* match width *)
            
             (* second match of bchar *)   
             | None -> 
               (
                 Debug.w "char %d not found\n%!" code;
                 (* line.currentX := line.currentX +. font.space; *)
                 addToLine font.space (WhiteSpace font.space) line;
                 add_char line (UTF8.next text index)
               )
             ]
        else 
        (
          match !text_whitespace with
          [ Some (widx,ws) -> 
            let () = debug "set line_whitespace: %d, %d" ws widx in
            line_whitespace.val := Some ( 
              ws , line.ascender, line.descender, 
              if widx < eidx (* Скипнуть пробел в конце???? *)
              then 
                let nidx = UTF8.next text widx in
                let lidx = UTF8.next text eidx in
                let sbst = String.sub text nidx (lidx - nidx) in
                [ (attributes, [ (`text sbst) :: elements ]) :: next ]
              else [ (attributes,elements) :: next ]
            )
          | None -> ()
          ];
          loop [ (attributes,elements) :: next ]
        )
      in
      
      let line = 
        if Stack.is_empty lines 
        then createLine ~indent:(getTextIndent attributes) font lines
        else if (Stack.top lines).closed 
        then 
          createLine font lines
        else 
          let line = Stack.top lines in
          (
            yoffset.val := adjustToLine ~ascender:font.BitmapFont.ascender ~descender:font.BitmapFont.descender ~height:font.BitmapFont.lineHeight line;
            line
          )
      in
      add_char line sidx

    and loop = fun
      [ [] -> () 
      | [ (_,[]) :: next ] -> loop next 
      | [ (attributes, [ `img attrs image :: elements ]) :: next ] ->
        let () = debug "attrs empty %B" (attrs = []) in
        let () = debug "process img: lines: %d" (Stack.length lines) in
        let (iwidth, iheight) =
          let (w, h) =
            match (getAttrOpt (fun [ `width w -> Some w | _ -> None ]) attrs, getAttrOpt (fun [ `height h -> Some h | _ -> None ]) attrs) with
            [ (Some w, Some h) -> (w, h)
            | (Some w, None) -> (w, image#height *. w /. image#width)
            | (None, Some h) -> (image#width *. h /. image#height, h)
            | _ -> (image#width, image#height)
            ]
          in
          (
            image#setWidth w;
            image#setHeight h;
            (w, h);
          )
  (*       let iwidth = match getAttrOpt (fun [ `width w -> Some w | _ -> None ])  attrs with [ Some w -> (image#setWidth w; w) | None -> image#width] (*{{{*)
        and iheight = match getAttrOpt (fun [ `height h -> Some h | _ -> None ])  attrs with [ Some h -> (image#setHeight h; h) | None -> image#height] *)
        and paddingLeft = getAttr (fun [ `paddingLeft pl -> Some pl | _ -> None]) 0. attrs in
        let () = debug "paddingLeft: %f" paddingLeft in

        let font = getFont attributes in
        let line = 
          if Stack.is_empty lines 
          then createLine ~indent:(getTextIndent attributes) font lines
          else
            let line = Stack.top lines in
            if line.closed 
            then createLine font lines
            else 
              match width with
              [ None -> line
              | Some width ->
                if line.currentX +. iwidth +. paddingLeft > width 
                then 
                (
                  line.closed := True;
                  createLine font lines;
                )
                else line
              ]
        in
        (
          image#setX (line.currentX +. paddingLeft);
          let paddingRight = getAttr (fun [ `paddingRight pl -> Some pl | _ -> None]) 0. attrs in
          let eWidth = paddingLeft +. iwidth +. paddingRight in
          let paddingTop = getAttr (fun [ `paddingTop pt -> Some pt | _ -> None]) 0. attrs in
          match getAttr (fun [ `valign v -> Some v | _ -> None]) `default attrs with
          [ `default ->
            (
              let textHeight = line.ascender +. line.descender in
              let dh = (iheight -. textHeight) /. 2. in
              let y = adjustToLine ~ascender:(line.ascender +. dh) ~descender:(line.descender +. dh) line in
              image#setY (y +. paddingTop);
              addToLine eWidth (Img image) line;
            )
          | `aboveBaseLine -> 
            (
              let y = adjustToLine ~ascender:iheight line in
              image#setY (y +. paddingTop);
              addToLine eWidth (Img image) line;
            )
          | `underBaseLine -> 
            (
              let y = adjustToLine ~descender:iheight line in
              image#setY (y +. paddingTop);
              addToLine eWidth (Img image) line
            )
          | `centerBaseLine -> 
            let () = debug "place image by text center" in
            let h2 = iheight /. 2. in
            let y = adjustToLine ~ascender:h2 ~descender:h2 line in
            (
              image#setY (y +. paddingTop);
              addToLine eWidth (Img image) line
            )
          ];
          loop [ (attributes,elements) :: next ]
        )(*}}}*)
      | [ (attributes,[ `span attribs celements :: elements ]) :: next ] ->
        (
          let () = debug "process span" in
          let sattributes = (attribs :> div_attributes) @ attributes in
          loop [ (sattributes,celements) ; (attributes,elements) :: next ]
        )
      | [ (attributes, [ `text text :: elements ]) :: next ] -> (* рендер text {{{*)
          let () = debug "process text: [%s] lines: %d" text (Stack.length lines) in
          let strLength = String.length text in
          match strLength with
          [ 0 -> loop [ (attributes, elements) :: next ]
          | _ -> draw_text attributes text 0 (UTF8.last text) elements next
          ]
      | [ (attributes, [ `substring str idx len :: elements ]) :: next ] -> 
          let sidx = UTF8.nth str idx
          and eidx = UTF8.nth str (idx + len - 1) in
          draw_text attributes str sidx eidx elements next
      | [ (attributes, [`br :: elements]) :: next ] -> 
        (
          if Stack.is_empty lines || (Stack.top lines).closed 
          then 
            let line = createLine (getFont attributes) lines in
            line.closed := True
          else 
            let line = Stack.top lines in
            line.closed := True;
          loop [ (attributes,elements) :: next ]
        )
      ]
    in
    loop [(attributes,elements)] 
  in (* END ID make_lines *)
  
  
  
  let rec process ((width,height) as size) attributes = fun
    [ `div attrs elements -> (* не доделано нихуя вообще нахуй *)
        let div = RefList.empty () in
        let attribs = attrs @ attributes in
        let paddingTop = getAttr (fun [ `paddingTop x -> Some x | _ -> None ]) 0. attrs 
        and paddingLeft = getAttr (fun [ `paddingLeft x -> Some x | _ -> None ]) 0. attrs 
        in
        let csize = subtractSize size (paddingTop,paddingLeft) in
        (* дети могут быть либо параграфы, либо опять дивы * параграф цельный сцука а див нихуя нахуй * *)
        let (_,mwidth,height) = 
          List.fold_left begin fun (((rwidth,rheight) as csize),mwidth,y) element ->
              let ((cwidth,cheight),lines) = process csize attribs element in 
              (
                List.iter begin fun line -> 
                  (
                    line.lx := line.lx +. paddingLeft; 
                    line.ly := line.ly +. y;
                    RefList.push div line
                  )
                end lines;
                ((rwidth,match rheight with [ None -> None | Some h -> Some (h -. cheight) ]), max cwidth mwidth, y +. cheight);
              )
          end (csize,0.,paddingTop) elements
        in
        ((paddingLeft +. mwidth,height),RefList.to_list div)
    | `p attrs elements ->  (* p - содержит линии *)
        let () = debug "process p" in
        let attribs = (attrs :> div_attributes) @ attributes in
        let spaceBefore = getAttr (fun [ `spaceBefore s -> Some s | _ -> None]) 0. attrs in
        let spaceAfter = getAttr (fun [ `spaceAfter s -> Some s | _ -> None]) 0. attrs in
        let yOffset = ref spaceBefore in
        let qlines = RefList.empty () in
        (
          let max_width = 
            let lines = Stack.create () in
            let () = make_lines width attribs lines elements in
            match width with
            [ Some w -> 
              (
                let f line = 
                  let width = lineWidth line in 
                  RefList.push qlines (line,width)
                in
                Stack.iter f lines;
                w
              )
            | None -> 
              let max_width = ref 0. in
              (
                let f line =
                  let width = lineWidth line in
                  (
                    if width > !max_width then max_width.val := width else ();
                    RefList.push qlines (line,width)
                  )
                in
                Stack.iter f lines;
                !max_width;
              )
            ]
          in
          
          let halign = getAttr (fun [ `halign p -> Some p | _ -> None ]) `left attribs in
          let halign = match farsi with
          [ Some f when f -> match halign with [`left -> `right | `right -> `left | _ -> halign ]
          | _   ->  halign
          ] 
          in
          
          
          let () = debug "align p: by %s - %f" (match halign with [ `left -> "left" | `right -> "right" | `center -> "center" ]) max_width in
          
          let lines = 
            if RefList.is_empty qlines
            then []
            else 
              let lines = 
                List.fold_left begin fun res (line,width) ->
                  (
                    match halign with
                    [ `center | `right as ha ->
                      let widthDiff = max_width -. width in
                      line.lx :=
                        (match ha with
                        [ `center -> widthDiff /. 2.
                        | `right -> widthDiff
                        ])
                    | _ -> ()
                    ];
                    match res with
                    [ [ pline :: _ ] -> yOffset.val := !yOffset +. pline.lineHeight
                    | _ -> ()
                    ];
                    line.ly := line.ly +. !yOffset;
                    debug "line.x = %f, y = %f" line.lx line.ly;
                    [ line :: res ]
                  )
                end [] (RefList.to_list qlines)
              in
              (
                let lline = List.hd lines in
                yOffset.val := !yOffset +. lline.ascender +. lline.descender;
                lines
              )
          in
          ((max_width,(!yOffset +. spaceAfter)),lines)
      )
    ]
  in

  let no_zero = fun [ Some x when  x <= 0. -> (Debug.w "w or h not correct"; None) | x ->  x ] in

  let ((width,height),lines) = process (no_zero width,no_zero height) [] html in

  let _container = ref (match dest with [ Some s -> Some (s :> Sprite.c) | None -> None  ]) in

  let container () = match !_container with [ Some c -> c | None -> let c = new tlfSprite () in (_container.val := Some c; c) ] in
  
  
  (* FARSI *)
  let lines = match farsi with
  [ Some b when b -> List.map convert_line_to_farsi lines 
  | _ -> lines
  ]
  
  in
  
  let atlases : Hashtbl.t Texture.c Atlas.tlf = Hashtbl.create 1 in
  (
    List.iter begin fun line ->
      for i = 0 to (DynArray.length line.lchars) - 1 do
        match DynArray.get line.lchars i with
        [ Img i -> 
          (
            let pos = {Point.x = i#x +. line.lx; y = i#y +. line.ly } in
            let () = debug "add image to line [%f:%f]" pos.Point.x pos.Point.y in
            i#setPosPoint pos;
            (container())#addChild i
          )
        | Char (_, _, c) ->
          let atex = AtlasNode.texture c in
          let atlas = 
            try
               Hashtbl.find atlases atex
            with [ Not_found -> 
              let (atl : Atlas.tlf) = Atlas.tlf atex in
              (
                Hashtbl.add atlases atex atl;
                atl
              )
            ]
          in
          let pos = Point.addPoint (AtlasNode.pos c) {Point.x = line.lx; y = line.ly} in
          let () = debug "add char to [%f:%f]" pos.Point.x pos.Point.y in
          atlas#addChild (AtlasNode.setPosPoint pos c)
        
        | _ -> ()
        
        ]
      done
      
    end lines;
    
    let res = 
      match !_container with
      [ None ->
        if Hashtbl.length atlases = 1
        then 
          let () = debug "result is atlas" in
          (OPTGET (Enum.get (Hashtbl.values atlases)))#asDisplayObject
        else 
          let c = new tlfSprite () in
          (
            debug "result sprite with atlases";
            Hashtbl.iter (fun _ atlas -> c#addChild atlas) atlases;
            c#asDisplayObject
          )
      | Some c -> 
          (
            debug "result container";
            Hashtbl.iter (fun _ atlas -> c#addChild atlas) atlases;
            c#asDisplayObject
          )
      ]
    in   
    ((width,height), res)
    
  ); (* let atlases and create *)