
value color_white = 0xFFFFFF;
value color_black = 0x000000;


type halign = [= `HAlignLeft | `HAlignCenter | `HAlignRight ];
type valign = [= `VAlignTop | `VAlignCenter | `VAlignBottom ];

value pi  =  3.14159265359;
value two_pi =  6.28318530718;

IFDEF IOS THEN
external resource_path: string -> float -> string = "ml_resourcePath";
ELSE
value resource_path path scale = 
  match Filename.is_relative path with
  [ True -> Filename.concat "Resources" path
  | False ->  path
  ];
ENDIF;

exception Xml_attribute_not_found of string;
value get_xml_attribute local_name attributes = 
  try
    MList.find_map (fun ((_,ln),v) -> match ln = local_name with [ True -> Some v | False -> None ]) attributes;
  with [ Not_found -> raise (Xml_attribute_not_found local_name) ];

(* допилить пока так сойдет *)
value parse_xml_element xmlinput tag_name attributes =
  match Xmlm.input xmlinput with
  [ `El_start ((_,tname),attrs) when tname = tag_name ->
    let res = 
      List.map begin fun att_name ->
        (att_name,get_xml_attribute att_name attrs) 
      end attributes
    in
    match Xmlm.input xmlinput with
    [ `El_end -> res
    | _ -> assert False 
    ]
  | _ -> assert False
  ];
