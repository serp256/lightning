
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
  | `fondSize of string
  | `color of int
  | `textAlpha of float
  | `backgroundColor of int
  | `backgroundAlpha of float
  ];

type p_attribute = 
  [= span_attribute
  | `textAlign of [= `left | `right | `center ]
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

type html = 
  [= `div of ((list div_attributes) * list [= `p of p | simple_elements ])
  | `p of p
  | simple_elements
  ];

value getAttr attrs f = try Some (List.find_map f) with [ Not_found -> None ];

value subtractSize (sx,sy) (sx',xy') = 
  (
    match sx with [ None -> None | Some sx -> sx - sx' ],
    match sy with [ None -> None | Some sy -> sy - sy' ]
  );


value getFontFamily attrs = gtAttr attrs (fun [ `fontFamily fn -> Some fn | _ -> None ]);
value getFontSize attrs = gtAttr attrs (fun [ `fontSize fn -> Some fn | _ -> None ]);


value create ?width ?height html = 
  let rec loop lineHeight ((cx,cy) as cpos) ((width,height) as size) attributes container = fun
    [ `div attrs els ->
        let div = Sprite.create () in
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
        let attrs = attrs @ attributes in
        let size = subtractSize size mainCont#pos in
        let (_,(_,endy) = 
          List.fold_left begin fun (lineHeight,endpos) el -> 
            loop lineHeight endpos size attrs div 
          end (0.,(0.,0.)) els 
        in
        (
          let cy = cy +. lineHeight in
          mainCont#setPos (0.,cy);
          (0.,(0.,cy +. endY +. !dy))
        )
    | `p attributes elements -> assert False
    | `img attrs image -> 
        (
          match getAttr attrs (fun [ `width w -> Some w | _ -> None ]) with [ Some w -> image#setWidth w | None -> ()];
          match getAttr attrs (fun [ `height h -> Some h | _ -> None ]) with [ Some h -> image#setHeight h | None -> ()];
          let dy = ref 0 in
          let cx = 
            match width with
            [ Some width when cx + image#width > width -> (dy.val := lineHeight; 0.)
            | _ -> cx
            ]
          in
          let dx = 
            (* apply paddings *)
            match getAttr attrs (fun [ `paddingLeft pl -> Some pl | _ -> None ]) with
            [ Some pl -> pl
            | None -> 0.
            ]
          and baseLine = 
            let font = 
              match getFontFamily attributes with
              [ Some fn ->
                match getFontSize attributes with
                [ Some size -> BitmapFont.get ~size fn
                | None -> None
                ]
              | None -> None
              ]
            in
            match font with
            [ Some fnt -> fnt
            | None -> cy + !dy
            ]
          in
          (* apply paddingTop *)
          in
          in
          (
            image#setPos (x,y);
            container#addChild image

          )
        )
    | `span attribs text -> 
        let attributes = attribs @ attributes in
        let fname = match getFontFamily attributes with [ Some fn -> fn | None -> defaultFontFamily ] in
        let size = getFontSize attributes in
        let font = BitmapFont.get ?size fname in
        let color = match getAttr attributes (fun [ `fontSize sz -> Some sz | _ -> None ]) with [ Some sz -> sz | None -> defaultColor ] in
        (* начинаем хуячить *)
        let open BitmapFont in
        let span = Sprite.create () in
        let scale = match size with [ Some sz -> sz /. font.size | None -> 1. ] in
        (
          span#setScale scale;
          let lastWhiteSpace = ref None in
          let rec add_line currentLine index = 
            (
              span#addChild currentLine;
              match index with
              [ Some index -> 
                let nextLineY = currentLine#y +. t.lineHeight in
                if nextLineY +. t.lineHeight <= containerHeight
                then 
                  let nextLine = Sprite.create () in
                  (
                    nextLine#setY nextLineY;
                    lastWhiteSpace.val := None;
                    add_char nextLine 0. index
                  )
                else ()
              | None -> ()
              ]
            )
          and  add_char currentLine (currentX:float) index = 
    (*         let () = Printf.printf "add char with index: %d\n%!" index in *)
            if index < strLength 
            then
              let code = UChar.code (UTF8.look text index) in
              let bchar = try Hashtbl.find t.chars code with [ Not_found -> let () = Printf.eprintf "char %d not found\n%!" code in Hashtbl.find t.chars CHAR_SPACE ] in
              if code = CHAR_NEWLINE 
              then
                add_line currentLine (Some (UTF8.next text index))
              else 
                if currentX +. bchar.xAdvance > containerWidth 
                then
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
                else
                  let bitmapChar = Image.create bchar.charTexture in
                  (
                    bitmapChar#setX (currentX +. bchar.xOffset);
                    bitmapChar#setY bchar.yOffset;
                    bitmapChar#setColor color;
                    currentLine#addChild bitmapChar;
                    if code = CHAR_SPACE then lastWhiteSpace.val := Some currentLine#numChildren else ();
                    add_char currentLine (currentX +. bchar.xAdvance) (UTF8.next text index)
                  )
            else add_line currentLine None
          in
          add_char (Sprite.create()) 0. 0
        );
    ]
  in
  let result = Sprite.create () in
  (
    ignore(loop (0.,0.) [] result);
    result;
  );


(* задача геморная, но решаемая, главное в начале что-нить нахуячить, а потом видно будет, в начале сложно так как нихуя пока не понятно блядь *)
