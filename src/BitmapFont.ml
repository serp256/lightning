
open LightCommon;


type bc = 
  {
    charID:int;
    xOffset:float;
    yOffset:float;
    xAdvance: float;
    charTexture: Texture.c;
  };

type t = 
  {
    texture: Texture.c;
    chars: Hashtbl.t int bc;
    name: string;
    size: float;
    lineHeight: float;
  };

value fonts = Hashtbl.create 0;
value exists name = Hashtbl.mem fonts name;
exception Font_not_found of string;
value get name =
  try
    Hashtbl.find fonts name
  with [ Not_found -> raise (Font_not_found name) ];

DEFINE CHAR_NEWLINE = 10;
DEFINE CHAR_SPACE = 32;
DEFINE CHAR_TAB = 9;

value register path = (*{{{*)
  let path = resource_path path 1. in
  let input = open_in path in
  let xmlinput = Xmlm.make_input ~strip:True (`Channel input) in
  let () = ignore(Xmlm.input xmlinput) in (* ignore dtd *)
  let parse_info () = 
    let res = parse_xml_element xmlinput "info" [ "face"; "size"] in
    (List.assoc "face" res,float_of_string (List.assoc "size" res))
  and parse_common () = 
    let res = parse_xml_element xmlinput "common" [ "lineHeight"] in
    float_of_string ( List.assoc "lineHeight" res)
  and parse_page () = 
    match Xmlm.input xmlinput with
    [ `El_start ((_,"pages"),_) ->
      let res = parse_xml_element xmlinput "page" [ "file"] in
      (
        match Xmlm.input xmlinput with
        [ `El_end -> List.assoc "file" res
        | _ -> failwith "Bitmap fonts with multiple pages are not supported"
        ]
      )
    | _ -> assert False
    ]
  and parse_chars texture = 
    match Xmlm.input xmlinput with
    [ `El_start ((_,"chars"),attributes) ->
      let count = get_xml_attribute "count" attributes in
      let chars = Hashtbl.create (int_of_string count) in
      let rec loop () =
        match Xmlm.peek xmlinput with
        [ `El_end -> (ignore(Xmlm.input xmlinput); chars)
        | _ ->
          (
            let res = parse_xml_element xmlinput "char" ["id";"x";"y";"width";"height";"xoffset";"yoffset";"xadvance"] in
            let charID = int_of_string (List.assoc "id" res) in
            let get_float x = float_of_string (List.assoc x res) in
            let bc = 
              let region = Rectangle.create (get_float "x") (get_float "y") (get_float "width") (get_float "height") in
              let charTexture = Texture.createSubTexture region texture in
              { charID ; xOffset = get_float "xoffset"; yOffset = get_float "yoffset"; xAdvance = get_float "xadvance"; charTexture }
            in
            Hashtbl.add chars charID bc;
            loop ()
          )
        ]
      in
      loop ()
    | _ -> assert False
    ]
  in
  match Xmlm.input xmlinput with
  [ `El_start ((_,"font"),_) -> 
    let (name,size) = parse_info () in
    let lineHeight = parse_common () in
    let imgFile = parse_page () in
    let texture = Texture.createFromFile imgFile in
    let chars = parse_chars texture in
    let bf = { texture; chars; name; size; lineHeight } in
    let () = Printf.printf "register font %s\n%!" name in
    Hashtbl.add fonts name bf
  | _ -> assert False 
  ];(*}}}*)


module Make(D:DisplayObjectT.M) = struct

  module Sprite = Sprite.Make D;
  module Image = Image.Make D;
  module Quad = Quad.Make D;

value createText t ~width ~height ?(size=t.size) ~color ?(border=False) ?hAlign ?vAlign text =
(*   let () = Printf.eprintf "create text: [%s]\n%!" text in *)
  let lineContainer = Sprite.create ()
  and scale = size /. t.size in
  let containerWidth = width /. scale
  and containerHeight = height /. scale 
  in
  (
    lineContainer#setScale scale;
    let lines = Queue.create () in
    (
      let strLength = String.length text in
      match strLength with
      [ 0 -> ()
      | _ ->
          let lastWhiteSpace = ref None in
          let rec add_line currentLine index = 
          (
            Queue.add currentLine lines;
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
  (*                     let () = Printf.printf "lastWhiteSpace: numChildren: %d, removeIndex: %d, numCharsToRemove: %d\n%!" currentLine#numChildren removeIndex numCharsToRemove in *)
                      for i = 0 to numCharsToRemove - 1 do
  (*                       let () = Printf.printf "remove %d\n%!" currentLine#numChildren in *)
                        currentLine#removeChildAtIndex removeIndex 
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
(*                   bitmapChar#setName (Printf.sprintf "letter: %d" index); *)
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
      ];
      match hAlign with
      [ Some ((`HAlignRight | `HAlignCenter) as halign) ->
        Queue.iter begin fun line ->
          (
            let lastChar = line#getLastChild in
            let lineWidth = lastChar#x +. lastChar#width in
            let widthDiff = containerWidth -. lineWidth in
(*             let () = Printf.printf "lastChar#x: %f, lastChar#width: %f, lineWidth: %f, widthDiff: %f\n%!" lastChar#x lastChar#width lineWidth widthDiff in *)
            line#setX begin
              match halign with
              [ `HAlignRight -> widthDiff
              | `HAlignCenter -> widthDiff /. 2.
              ]
            end;
            lineContainer#addChild line
          )
        end lines 
      | _ -> Queue.iter lineContainer#addChild lines
      ];
    );
    let outerContainer = Sprite.create () in (* FIXME: must be compiled sprite *)
    (
      outerContainer#addChild lineContainer;
      match vAlign with
      [ Some ((`VAlignCenter | `VAlignBottom) as valign) ->
        let contentHeight = (float lineContainer#numChildren) *. t.lineHeight *. scale in
        let heightDiff = height -. contentHeight in
        lineContainer#setY begin
          match valign with
          [ `VAlignBottom -> heightDiff 
          | `VAlignCenter -> heightDiff /. 2.
          ]
        end
      | _ -> ()
      ];
      if border
      then
        let topBorder = Quad.create width 1.
        and bottomBorder = Quad.create width 1.
        and leftBorder = Quad.create 1. (height -. 2.)
        and rightBorder = Quad.create 1. (height -. 2.)
        in
        (
          topBorder#setColor color;
          bottomBorder#setColor color;
          leftBorder#setColor color;
          rightBorder#setColor color;
          bottomBorder#setY (height -. 1.);
          leftBorder#setY 1.;
          rightBorder#setY 1.;
          rightBorder#setX (width -. 1.);
          outerContainer#addChild topBorder;
          outerContainer#addChild bottomBorder;
          outerContainer#addChild leftBorder;
          outerContainer#addChild rightBorder;
        )   
      else ();
      outerContainer;
    )
  );

end;
