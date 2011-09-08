
type img_attribute = 
  [ `width of float
  | `height of float
  | `paddingLeft of float
  | `paddingRight of float
  | `paddingTop of float
  | `paddingBottom of float
  ];

type span_attribute = 
  [= `fontFamily of string
  | `fontSize of string
  | `color of int
  | `textAlpha of float
  | `backgroundColor of int
  | `backgroundAlpha of float
  ];

type p_attribute = 
  [= span_attribute
  | `horizontalAlign of [= `left | `right | `center ]
  | `verticalAlign of [= `top | `bottom | `center ]
  | `paragraphSpaceBefore of float
  | `paragraphSpaceAfter of float
  ];

type div_attribute = 
  [= span_attribute 
  | p_attribute
  | `paddingTop of float
  | `paddingLeft of float
  ];

type simple_elements = 
  [ `img of ((list img_attributes) * Image.c)
  | `span of ((list span_attributes) * simple_elements)
  | `br
  | `text of string
  ];

type p = ((list p_attributes) * (list simple_elements));

type main = 
  [= `div of ((list div_attributes) * (list main))
  | `p of p
  ];

value getAttr attrs f default = try (List.find_map f) with [ Not_found -> default ];
value getAttrOpt attrs f = try Some (List.find_map f) with [ Not_found -> None ];

value subtractSize (sx,sy) (sx',xy') = 
  (
    match sx with [ None -> None | Some sx -> sx - sx' ],
    match sy with [ None -> None | Some sy -> sy - sy' ]
  );


value getFontFamily attrs = gtAttr attrs (fun [ `fontFamily fn -> Some fn | _ -> None ]);
value getFontSize attrs = gtAttr attrs (fun [ `fontSize fn -> Some fn | _ -> None ]);
value getFontOpt attributes = 
   match getFontFamily attributes with
   [ Some fn ->
     match getFontSize attributes with
     [ Some size -> BitmapFont.get ~size fn
     | None -> None
     ]
   | None -> None
   ];

value getFont attributes =
  let fontFamily =
   match getFontFamily attributes with
   [ Some fn -> fn
   | None -> default_font_family
   ];
  in
  let size = getFontSize attributes in 
  BitmapFont.get ?size fontFamily;


type line = 
  {
    container: Sprite.c;
    lineHeight: option float;
    currentX: mutable float;
    closed: mutable bool;
  };


value createLine font =  {container = Sprite.create (); lineHeight = match font with [ Some fnt -> fnt.BitmapFont.lineHeight | None -> 0. ]; currentX = 0.; closed = False};
value lineAdd offset element line = 
  let x = offset +. line.currentX in
  (
    element#setX x;
    line.container#addChild element;
    line.currentX := x;
  );

(*
*)

value create ?width ?height html = 
  let rec make_lines width attributes lines = fun (* функция возвращает список линий *)
    [ `img attrs image -> (*{{{*)
      let iWidth = match getAttr attrs (fun [ `width w -> Some w | _ -> None ]) with [ Some w -> (image#setWidth w; w) | None -> image#width]
      and iHeight = match getAttr attrs (fun [ `height h -> Some h | _ -> None ]) with [ Some h -> (image#setHeight h; h) | None -> mage#height]
      and paddingLeft = match getAttr attrs (fun [ `paddingLeft pl -> Some pl | _ -> None]) with [ Some pl -> pl | None -> 0. ] in
      DEFINE new_line = 
        (
          let line = createLine font in
          Stack.push line lines;
          line
        )
      in
      let font = getFontOpt attributes in
      let line = 
        if Stack.is_empty lines 
        then new_line
        else
          let line = Stack.top lines in
          if line.closed 
          then new_line
          else 
            match width with
            [ None -> line
            | Some width ->
              if line.currentX +. iwidth +. paddingLeft > width 
              then 
              (
                line.closed := True;
                new_line
              )
              else line
            ]
      in
      let baseLine = 
        match font with
        [ Some fnt -> fnt.BitmapFont.baseLine
        | None -> iHeight
        ]
      in
      let paddingTop = getAttr attrs (fun [ `paddingTop pt -> Some pt | _ -> None]) 0. in
      (
        if baseLine > image#height
        then 
        (
          line.lineHeight := iHeight;
          line#setY padingTop;
        )
        else line#setY (iHeight -. baseLine +. paddingTop);
        lineAdd paddingLeft image line;
      ) (*}}}*)
    | `span attribs elements ->
        let attributes = attribs @ attributes in
        List.iter (fun make_lines width attributes lines) elements
    | `text text -> (* рендер text {{{*)
        let strLength = String.length text in
        match strLength with
        [ 0 -> ()
        | _ ->
          let containerWidth =
            match width with
            [ Some width -> width /. font.BitmapFont.scale
            | None -> ()
            ]
          in
          let lastWhiteSpace = ref None in
          let rec add_line currentLine index = 
            (
              currentLine.closed := closed;
              Stack.push currentLine lines;
              match index with
              [ Some index -> 
                let () = currentLine.closed := True in
                let nextLine = createLine font in
                (
                  lastWhiteSpace.val := None;
                  add_char nextLine index
                )
              | None -> ()
              ]
            )
          and  add_char line index = 
            if index < strLength 
            then
              let code = UChar.code (UTF8.look text index) in
              let bchar = try Hashtbl.find t.chars code with [ Not_found -> let () = Printf.eprintf "char %d not found\n%!" code in Hashtbl.find t.chars CHAR_SPACE ] in
              if code = CHAR_NEWLINE 
              then
                add_line currentLine (Some (UTF8.next text index))
              else 
                match containerWidth with
                [ Some containerWidth when line.currentX +. bchar.xAdvance > containerWidth ->
                  let idx = 
                    match !lastWhiteSpace with
                    [ Some idx -> 
                      let removeIndex = idx in
                      let numCharsToRemove = currentLine#numChildren - removeIndex in
                      (
                        for i = 0 to numCharsToRemove - 1 do
                          ignore(currentLine#removeChildAtIndex removeIndex)
                        done;
                        UTF8.move text index ~-numCharsToRemove
                      )
                    | None -> index
                    ]
                  in
                  add_line currentLine (Some idx)
                | _ ->
                  let bitmapChar = Image.create bchar.charTexture in
                  (
                    bitmapChar#setScale font.BitmapFont.scale;
                    bitmapChar#setX (currentX +. );
                    bitmapChar#setY bchar.yOffset;
                    bitmapChar#setColor color;
                    lineAdd bchar.xOffset bitmapChar currentLine
                    if code = CHAR_SPACE then lastWhiteSpace.val := Some currentLine#numChildren else ();
                    add_char currentLine (UTF8.next text index)
                  )
                ]
            else add_line currentLine None
          in
          let line = 
            if Stack.is_empty lines || (Stack.top lines).closed 
            then createLine font
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
    | `br -> ()
    ]
  in
  let rec process ((width,height) as size) attributes = fun
    [ `div attrs els ->
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
        let paddigTop = getAttr attrs (fun [ `paddingTop x -> Some x | _ -> None ]) 0.
        and paddingLeft = getAttr attrs (fun [ `paddingLeft x -> Some x | _ -> None ]) 0. 
        in
        let (width,height) = subtractSize size (paddingTop,paddingLeft) in
        (* дети могут быть либо параграфы, либо опять дивы 
         * параграф цельный сцука а див нихуя нахуй
         * *)
        let (x,y) = 
          List.fold_left begin fun (x,y) element ->
              let (pos,obj) = process size attribs in
              match pos with
              [ `P height ->
                (
                  obj#setPos (x,y);
                  mainCont#addChild obj
                  (x,y +. height)
                )
              ]
          end (paddingTop,paddingLeft) elements
        in
        (`P y,div)
    | `p attrs elements ->  (* p - содержит линии *)
        let container = Sprite.create () in 
        let attribs = attrs @ attributes in
        (
          let lines = Stack.create () in
          (
            make_lines width attribs lines;
            let qlines = Queue.create () in
            (
              let max_width = ref 0. in
              Stack.iter begin fun line -> 
                (
                  let width = (line#getChildAt 0)#x +. line#width in
                  if width > !max_width then max_width.val := width else ()
                  Queue.push (line,width) qlines
                )
              end lines;
              let halign = match getAttr attribs (fun [ `horizontalAlign p -> Some p | _ -> None ]) with [ None -> `left | Some align -> align ] in
              let yOffset = ref 0. in
              Queue.iter begin fun (line,width) ->
                (
                  match halign with
                  [ `center | `right ->
                    let widthDiff = !max_width - width in
                    line#setX
                      match halign with
                      [ `center -> widthDiff /. 2
                      | `right -> widthDiff
                      ]
                  | _ -> ()
                  ];
                  line#setY !yOffset;
                  container#addChild line.container;
                  yOffset.val := !yOffset +. line.lineHeight;
                )
              end qlines;
            )
          );
          (`P !yOffset,container)
        )
    ]
  in
  let result = Sprite.create () in
  let (pos,container) = process (width,height) [] html in
  result;
