
module Make(Image:Image.S)(Sprite:Sprite.S with module D = Image.D) = struct

module DisplayObject = Image.D;
(* module Shape = Shape.Make DisplayObject; *)

value default_font_family = ref "Helvetica";

type img_valign = [= `baseLine | `center | `lineCenter ];
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
  | `color of int
  | `alpha of float
  | `backgroundColor of int (* как это замутить то я забыла *)
  | `backgroundAlpha of float 
  ];

type span_attributes = list span_attribute;

type simple_element = [= `img of (img_attributes * Image.c) | `span of (span_attributes * simple_elements) | `br | `text of string ]
and simple_elements = list simple_element;

type p_halign = [= `left | `right | `center ];
type p_valign = [= `top | `bottom | `center ];
type p_attribute = 
  [= span_attribute
  | `halign of p_halign
  | `valign of p_valign
  | `spaceBefore of float
  | `spaceAfter of float
  ];

type p_attributes = list p_attribute;

type div_attribute = 
  [= span_attribute 
  | p_attribute
  | `paddingTop of float
  | `paddingLeft of float
  ];


type div_attributes = list div_attribute;


(* type attribute = [= div_attribute | p_attribute | span_attribute ]; *)

type main = 
  [= `div of (div_attributes * (list main))
  | `p of (p_attributes * simple_elements)
  ];

DEFINE AEXPAND(name,tag) = 
  match name with
  [ Some v -> [ tag v :: attrs ]
  | None -> attrs
  ];


value img ?width ?height ?paddingLeft ?paddingTop ?paddingRight ?paddingLeft ?valign img : simple_element = 
  let attrs = [] in
  let attrs = AEXPAND (width,`width) in
  let attrs = AEXPAND (height,`height) in
  let attrs = AEXPAND (paddingLeft,`paddingLeft) in
  let attrs = AEXPAND (paddingTop,`paddingTop) in
  let attrs = AEXPAND (paddingRight,`paddingRight) in
  let attrs = AEXPAND (valign,`valign) in
  `img (attrs,img);


value span ?fontFamily ?fontSize ?color ?alpha elements : simple_element = 
  let attrs = [] in
  let attrs = AEXPAND(fontFamily,`fontFamily) in
  let attrs = AEXPAND(fontSize,`fontSize) in
  let attrs = AEXPAND(color,`color) in
  let attrs = AEXPAND(alpha,`alpha) in
  `span (attrs,elements);


value p ?fontFamily ?fontSize ?color ?alpha ?halign ?valign ?spaceBefore ?spaceAfter elements : main = 
  let attrs = [] in
  let attrs = AEXPAND(fontFamily,`fontFamily) in
  let attrs = AEXPAND(fontSize,`fontSize) in
  let attrs = AEXPAND(color,`color) in
  let attrs = AEXPAND(alpha,`alpha) in
  let attrs = AEXPAND(halign,`halign) in
  let attrs = AEXPAND(valign,`valign) in
  let attrs = AEXPAND(spaceBefore,`spaceBefore) in
  let attrs = AEXPAND(spaceAfter,`spaceAfter) in
  `p (attrs,elements);


value getAttr(*: ('a -> option 'b) -> 'b -> list 'a -> 'b *)= fun f default attrs -> try (ExtList.List.find_map f attrs) with [ Not_found -> default ];
value getAttrOpt(*: ('a -> option 'b) -> list 'a -> option 'b*) = fun f attrs -> try Some (ExtList.List.find_map f attrs) with [ Not_found -> None ];

value subtractSize (sx,sy) (sx',sy') = 
  (
    match sx with [ None -> None | Some sx -> Some (sx -. sx') ],
    match sy with [ None -> None | Some sy -> Some (sy -. sy') ]
  );


value getFontFamily =
  let f: !'p. ([> `fontFamily of string] as 'p) -> option string = fun [ `fontFamily fn -> Some fn | _ -> None ] in
  getAttrOpt f;
value getFontSize = getAttrOpt (fun [ `fontSize fn -> Some fn | _ -> None ]);

(*
value getFontOpt attributes = 
   match getFontFamily attributes with
   [ Some fn ->
     match getFontSize attributes with
     [ Some size -> Some (BitmapFont.get ~applyScale:True ~size fn)
     | None -> None
     ]
   | None -> None
   ];
*)

value getFont attributes =
  let fontFamily =
   match getFontFamily attributes with
   [ Some fn -> fn
   | None -> !default_font_family
   ]
  in
  let size = getFontSize attributes in 
  BitmapFont.get ~applyScale:True ?size fontFamily;




type line = 
  {
    container: Sprite.c;
    lineHeight: mutable float;
    baseLine: mutable float;
    currentX: mutable float;
    closed: mutable bool;
  };

value createLine font lines =  
  let () = debug "create new line" in
(*   let line = {container = Sprite.create (); lineHeight = match font with [ Some fnt -> fnt.BitmapFont.lineHeight | None -> 0. ]; baseLine = 0.; currentX = 0.; closed = False} in *)
  let line = {container = Sprite.create (); lineHeight = font.BitmapFont.lineHeight; baseLine = font.BitmapFont.baseLine; currentX = 0.; closed = False} in
  (
    Stack.push line lines;
    line;
  );

value addToLine width baseLine element line = 
  (
    match compare line.baseLine baseLine with
    [ 0 -> ()
    | -1 (* был меньше *) ->
        let diff = baseLine -. line.baseLine in
        (
          (* здесь нужно теперь все элементы подвинуть вниз *)
          Enum.iter (fun el -> el#setY (el#y +. diff)) line.container#children;
          line.baseLine := baseLine;
        )
    | _ (* был больше *) -> 
        (* текущий мальца сдвинуть *)
        element#setY (element#y +. (line.baseLine -. baseLine))
    ];
    line.container#addChild element;
    line.currentX := width +. line.currentX;
  ); (* здесь же надо позырить что предыдущий базелайн такой-же и перехуячить там все нахуй *)

DEFINE CHAR_SPACE = 32;
DEFINE CHAR_NEWLINE = 10;

exception Parse_error of (string*string);
(* exception Unknown_attribute (string*string); *)



value parse ?(imgLoader=Image.load) xml : main = 
  let inp = Xmlm.make_input (`String (0,xml)) in
  let parse_error fmt = 
    let (line,column) = Xmlm.pos inp in
    Printf.kprintf (fun s -> raise (Parse_error (Printf.sprintf "%d:%d" line column) s)) fmt
  in
  match Xmlm.input inp with
  [ `Dtd _ ->
    let el_end () =  
      match Xmlm.input inp with
      [ `El_end -> ()
      |  _ -> parse_error "want end tag"
      ]
    in
    let parse_float p = 
      try
        float_of_string p
      with [ Failure "float_of_string" -> parse_error "bad float: %s" p ]
    and parse_int p = 
      try
        int_of_string p
      with [ Failure "float_of_string" -> parse_error "bad int: %s" p ]
    in
    let parse_span_attribute: Xmlm.attribute -> span_attribute =
      fun
        [ ((_,"font-family"),ff) -> `fontFamily ff
        | ((_,"font-size"),sz) -> `fontSize (parse_int sz)
        | ((_,"color"),c) -> `color (parse_int c)
        | ((_,"alpha"),alpha) -> `alpha (parse_float alpha)
        | ((_,an),_) -> parse_error "unknown attribute %s" an
        ]
    in
    let parse_p_attribute : Xmlm.attribute -> p_attribute = fun
      [ ((_,"halign"),v) -> `halign (match v with [ "left" -> `left | "right" -> `right | "center" -> `center | _ -> parse_error "incorrect attribute halign value %s" v])
      (*   | `valign of [= `top | `bottom | `center ] *)
      | ((_,"space-before"),spb) -> `spaceBefore (parse_float spb) 
      | ((_,"space-after"),spa) -> `spaceAfter (parse_float spa)
      | x -> ((parse_span_attribute x) :> p_attribute)
      ]
    in
    let rec parse_simple_elements res : simple_elements = 
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
              | "width" -> Some (`width (parse_float vlue))
              | "height" -> Some (`width (parse_float vlue))
              | "padding-left" -> Some (`paddingLeft (parse_float vlue))
              | "padding-top" -> Some (`paddingTop (parse_float vlue))
              | "padding-right" -> Some (`paddingRight (parse_float vlue))
              | "valign" -> 
                  let v = 
                    match vlue with
                    [ "baseline" -> `baseLine
                    | "center" -> `center
                    | "line-center" -> `lineCenter
                    | _ -> parse_error "incorrect img halign value %s" vlue
                    ]
                  in
                  Some (`valign v)
              | _ -> parse_error "unknown attribute img:%s" tag
              ]
            end attributes
          in
          match !img with
          [ None -> parse_error "img src"
          | Some img -> 
              let () = el_end () in
              parse_simple_elements [ `img (attribs,img) :: res ]
          ]
        | "span" ->
            let attribs = List.map parse_span_attribute attributes in
            let elements = parse_simple_elements [] in
            parse_simple_elements [ `span (attribs,elements) :: res ]
        | "br" -> let () = el_end () in parse_simple_elements [ `br :: res ]
        | _ -> parse_error "unknown simple tag: %s" tag
        ]
      | `Data text -> parse_simple_elements [ `text text :: res ]
      | `El_end -> List.rev res
      | _ -> parse_error "DTD?"
      ]
    in
    let rec parse_top_level () : option main = 
      match Xmlm.input inp with
      [ `El_start (("","p"),attributes) -> (* need to parse p attributes *)
        let p_attribs = List.map parse_p_attribute attributes in
        let elements = parse_simple_elements [] in
        Some (`p (p_attribs,elements))
      | `El_start (("","div"),attributes) -> (* need to parse div attributes *)
          let attribs = 
            List.map begin fun
              [ ((_,"padding-top"),v) -> `paddingTop (parse_float v)
              | ((_,"padding-left"),v) -> `paddingLeft (parse_float v)
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
          Some (`div (attribs,elements))
      | `El_end -> None
      | _ -> parse_error "top level"
      ]
    in
    match parse_top_level () with
    [ Some res -> res
    | None -> assert False 
    ]
  | _ -> parse_error "Dtd"
  ];

(* width, height вытащить наверно в html тоже *)
value create ?width ?height ?border ?dest (html:main) = 
  let rec make_lines width attributes lines : simple_element -> unit = fun 
    [ `img attrs image -> 
      let () = debug "process img: lines: %d" (Stack.length lines) in
      let iwidth = match getAttrOpt (fun [ `width w -> Some w | _ -> None ])  attrs with [ Some w -> (image#setWidth w; w) | None -> image#width] (*{{{*)
      and iheight = match getAttrOpt (fun [ `height h -> Some h | _ -> None ])  attrs with [ Some h -> (image#setHeight h; h) | None -> image#height]
      and paddingLeft = match getAttrOpt (fun [ `paddingLeft pl -> Some pl | _ -> None]) attrs with [ Some pl -> pl | None -> 0. ] in
      let font = getFont attributes in
      let line = 
        if Stack.is_empty lines 
        then createLine font lines
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
        let paddingRight = match getAttrOpt (fun [ `paddingRight pl -> Some pl | _ -> None]) attrs with [ Some pl -> pl | None -> 0. ] in
        let eWidth = paddingLeft +. iwidth +. paddingRight in
        let paddingTop = getAttr (fun [ `paddingTop pt -> Some pt | _ -> None]) 0. attrs in
        match getAttr (fun [ `valign v -> Some v | _ -> None]) `center attrs with
        [ `baseLine -> (* тру работает пиздец как круто *)
          (
            let newLineHeight = iheight +. (line.lineHeight -. line.baseLine) in 
            if newLineHeight > line.lineHeight
            then line.lineHeight := newLineHeight
            else ();
            image#setY paddingTop;
            addToLine eWidth iheight image line;
          )
        | `lineCenter -> (* хуево пашет *)
            let () = debug "place image by lineCenter: %f,%f" iheight line.lineHeight in
            let baseLine = 
              if line.lineHeight < iheight
              then (* нужно будет всю хуйню сдвинуть чтобы поместилось тут все *)
                let diff = (iheight -. line.lineHeight) /. 2. in
                (
                  line.lineHeight := iheight;
                  line.baseLine +. diff;
                )
              else 
                line.baseLine
            in
            (
              let yOffset = (line.lineHeight -. iheight) /. 2. in
              let () = debug "img center yOffset: %f" yOffset in
              image#setY (paddingTop +. yOffset);
              addToLine eWidth baseLine image line;
            )
        | `center -> (* центер by text *)
            let () = debug "place image by text center" in
            (* хуево сцука двигаем *)
            let baseLine = 
              if line.lineHeight < iheight
              then 
                let diff = (iheight -. line.lineHeight) /. 2. in
                line.baseLine +. diff
              else 
                line.baseLine
            in
            (
              let fdiff = (font.BitmapFont.lineHeight -. iheight) /. 2. in
              (* теперь понять как это дифф применить *)
              let ldiff = baseLine -. font.BitmapFont.baseLine in
              let yOffset = ldiff +. fdiff in
              (
                image#setY (paddingTop +. yOffset);
                let imgHeight = yOffset +. iheight in
                if imgHeight > line.lineHeight 
                then
                  line.lineHeight := imgHeight +. 1.
                else ();
              );
              let () = debug "y: %f, baseLine: %f, line.baseLine: %f" image#y baseLine line.baseLine in
              addToLine eWidth baseLine image line;
            )
        ]
      )(*}}}*)
    | `span attribs elements ->
        let () = debug "process span" in
        let attributes = (attribs :> div_attributes) @ attributes in
        List.iter (make_lines width attributes lines) elements
    | `text text -> (* рендер text {{{*)
        let () = debug "process text: lines: %d" (Stack.length lines) in
        let strLength = String.length text in
        match strLength with
        [ 0 -> ()
        | _ ->
          let color = getAttr (fun [ `color n -> Some n | _ -> None]) 0 attributes in
          let alpha = getAttr (fun [ `alpha a -> Some a | _ -> None]) 1. attributes in
          let font = getFont attributes in
          let () = debug "font scale: %f" font.BitmapFont.scale in
          (*
          let containerWidth =
            match width with
            [ Some width -> Some (width *. font.BitmapFont.scale)
            | None -> None
            ]
          in
          *)
          let lastWhiteSpace = ref None in
          let rec add_line currentLine index = 
            let () = debug "add line" in
            let () = currentLine.closed := True in
            let nextLine = createLine font lines in
            (
              lastWhiteSpace.val := None;
              add_char nextLine index
            )
          and add_char line index = 
            if index < strLength 
            then
              let code = UChar.code (UTF8.look text index) in
              let open BitmapFont in
              let bchar = try Hashtbl.find font.chars code with [ Not_found -> let () = Printf.eprintf "char %d not found\n%!" code in Hashtbl.find font.chars CHAR_SPACE ] in
              let bchar = if font.scale <> 1. then {(bchar) with xOffset = bchar.xOffset *. font.scale; yOffset = bchar.yOffset *. font.scale; xAdvance = bchar.xAdvance *. font.scale} else bchar in
              let () = debug "put char with code: %d, current_x: %f, xAdvance: %f, width: %f" code line.currentX bchar.BitmapFont.xAdvance (Option.default 0. width) in
              if code = CHAR_NEWLINE 
              then
                add_line line (UTF8.next text index)
              else 
                match width with
                [ Some width when line.currentX +. bchar.BitmapFont.xAdvance > width ->
                  let idx = 
                    match !lastWhiteSpace with
                    [ Some idx -> 
                      let removeIndex = idx in
                      let numCharsToRemove = line.container#numChildren - removeIndex in
                      (
                        for i = 0 to numCharsToRemove - 1 do
                          ignore(line.container#removeChildAtIndex removeIndex)
                        done;
                        UTF8.move text index ~-numCharsToRemove
                      )
                    | None -> index
                    ]
                  in
                  add_line line idx
                | _ ->
                  let bitmapChar = Image.create bchar.BitmapFont.charTexture in
                  (
                    bitmapChar#setScale font.BitmapFont.scale;
                    bitmapChar#setPos (line.currentX +. bchar.BitmapFont.xOffset) (bchar.BitmapFont.yOffset);
                    bitmapChar#setColor color;
                    bitmapChar#setAlpha alpha;
                    addToLine bchar.BitmapFont.xAdvance font.BitmapFont.baseLine bitmapChar line;
                    if code = CHAR_SPACE then lastWhiteSpace.val := Some line.container#numChildren else ();
                    add_char line (UTF8.next text index)
                  )
                ]
            else ()
          in
          let line = 
            if Stack.is_empty lines || (Stack.top lines).closed 
            then createLine font lines
            else 
              let line = Stack.top lines in
              (
                if line.lineHeight < font.BitmapFont.lineHeight
                then line.lineHeight := font.BitmapFont.lineHeight
                else ();
                line
              )
          in
          add_char line 0(*}}}*)
        ]
    | `br -> 
        if Stack.is_empty lines || (Stack.top lines).closed 
        then 
          let line = createLine (getFont attributes) lines in
          line.closed := True
        else 
          let line = Stack.top lines in
          line.closed := True
    ]
  in
  let rec process ((width,height) as size) attributes = fun
    [ `div attrs elements -> (* не доделано нихуя вообще нахуй *)
        let div = Sprite.create () in
        (*
        let dy = ref 0 in
        let mainCont = 
          match (getAttr attrs (fun [ `paddingTop x -> Some x | _ -> None ]), getAttr attrs (fun [ `paddingLeft x -> Some x | _ -> None ])) with
          [ ((Some _ as top),( _ as left)) | ((_ as top),(Some _ as left)) -> 
            (
              match top with
              [ Some paddingTop -> (dy.val := paddingTop; div#setY paddingTop)
              | None -> ()
              ];
              match left with
              [ Some paddingLeft -> div#setX paddingLeft
              | None -> ()
              ];
              let cont = Sprite.create () in
              (
                cont#adChild div;
                cont;
              )
            )
          | _ -> div
          ]
        in
        *)
        let attribs = attrs @ attributes in
        let paddingTop = getAttr (fun [ `paddingTop x -> Some x | _ -> None ]) 0. attrs 
        and paddingLeft = getAttr (fun [ `paddingLeft x -> Some x | _ -> None ]) 0. attrs 
        in
        let nsize = subtractSize size (paddingTop,paddingLeft) in
        (* дети могут быть либо параграфы, либо опять дивы 
         * параграф цельный сцука а див нихуя нахуй
         * *)
        let (x,y) = 
          List.fold_left begin fun (x,y) element ->
              let (pos,obj) = process nsize attribs element in
              match pos with
              [ `P height ->
                (
                  obj#setPos x y;
                  div#addChild obj;
                  (x,y +. height)
                )
              ]
          end (paddingLeft,paddingTop) elements
        in
        (`P y,div)
    | `p attrs elements ->  (* p - содержит линии *)
        let () = debug "process p" in
        let container = Sprite.create () in 
        let attribs = (attrs :> div_attributes) @ attributes in
        let spaceBefore = getAttr (fun [ `spaceBefore s -> Some s | _ -> None]) 0. attrs in
        let spaceAfter = getAttr (fun [ `spaceAfter s -> Some s | _ -> None]) 0. attrs in
        let yOffset = ref spaceBefore in
        (
          let lines = Stack.create () in
          (
            let f = make_lines width attribs lines in
            List.iter f elements;
            let qlines = Stack.create () in
            let max_width = 
              match width with
              [ Some w -> 
                (
                  let f line = 
                    let linec = line.container in
                    let width = try (linec#getChildAt 0)#x +. linec#width with [ DisplayObject.Invalid_index -> 0. ] in
                    Stack.push (line,width) qlines
                  in
                  Stack.iter f lines;
                  w
                )
              | None -> 
                let max_width = ref 0. in
                (
                  let f line =
                    let linec = line.container in
                    let width = try (linec#getChildAt 0)#x +. linec#width with [ DisplayObject.Invalid_index -> 0. ] in
                    (
                      if width > !max_width then max_width.val := width else ();
                      Stack.push (line,width) qlines
                    )
                  in
                  Stack.iter f lines;
                  !max_width;
                )
              ]
            in
            (
              let halign = match getAttrOpt (fun [ `halign p -> Some p | _ -> None ]) attribs with [ None -> `left | Some align -> align ] in
              Stack.iter begin fun (line,width) ->
                (
                  match halign with
                  [ `center | `right as ha ->
                    let widthDiff = max_width -. width in
                    line.container#setX
                      (match ha with
                      [ `center -> widthDiff /. 2.
                      | `right -> widthDiff
                      ])
                  | _ -> ()
                  ];
                  debug "set line y to %f" !yOffset;
                  line.container#setY !yOffset;
                  container#addChild line.container;
                  yOffset.val := !yOffset +. line.lineHeight;
                )
              end qlines;
            )
          );
          (`P (!yOffset +. spaceAfter),container)
        )
    ]
  in
  let result = match dest with [ Some s -> (s :> Sprite.c) | None -> Sprite.create () ] in
  let (pos,container) = process (width,height) [] html in
  (
    (*
    match border with
    [ Some bcolor ->
      let shape = Shape.create () in
      let g = shape#graphics in
      (
        Graphics.lineStyle g 1. bcolor 1.;
        let width = match width with [ Some w -> w | None -> container#width ]
        and height = match height with [ Some h -> h | None -> container#height ]
        in (
          Graphics.beginFill g bcolor 1.;
          Graphics.drawRect g 0. 0. width height;
          result#addChild shape;
        );
      )
    | None -> ()
    ];
    *)
    (* FIXME: skip pos *)
    result#addChild container;
    result
  );


end;
