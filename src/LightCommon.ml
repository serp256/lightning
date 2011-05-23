
value color_white = 0xFFFFFF;
value color_black = 0x000000;


type halign = [= `HAlignLeft | `HAlignCenter | `HAlignRight ];
type valign = [= `VAlignTop | `VAlignCenter | `VAlignBottom ];

value pi  =  3.14159265359;
value two_pi =  6.28318530718;

exception File_not_exists of string;
IFDEF IOS THEN
Callback.register_exception "File_not_exists" (File_not_exists "");
(* external resource_path: string -> float -> string = "ml_resourcePath"; *)
external bundle_path_for_resource: string -> string = "ml_bundle_path_for_resource";

ELSE
value bundle_path_for_resource fname = Filename.concat "Resources" path;
(*
value resource_path path scale = 
  match Filename.is_relative path with
  [ True -> Filename.concat "Resources" path
  | False ->  path
  ];
*)
ENDIF;

value resource_path ?dir path = 
  let fullPath = 
    match Filename.is_relative path with
    [ True -> (* тут еще со скейлом надо заморочица нах *) bundle_path_for_resource path
    | False ->  path
    ];
  in
  match Sys.file_exists fullPath with
  [ True -> fullPath
  | False -> raise (File_not_exists path)
  ];

exception Xml_error of string and string;

module MakeXmlParser(P:sig value path: string; end) = struct


  value input = 
    let xml = resource_path P.path 1. in
    open_in xml;

  value xmlinput = Xmlm.make_input ~strip:True (`Channel input);

  value error fmt = 
    let (line,column) = Xmlm.pos xmlinput in
    (
      close_in input;
      Printf.kprintf (fun s -> raise (Xml_error (Printf.sprintf "%s:%d:%d" P.path line column) s)) fmt;
    );


  value accept tag = if Xmlm.input xmlinput = tag then () else error "not accepted";
  value next () = Xmlm.input xmlinput;

  value close () = close_in input;

  value floats x = 
    try float_of_string x with [ Failure _ -> error "float_of_string: %s" x ];

  value get_attribute name attributes = 
    try
      let (_,v) = List.find (fun ((_,ln),v) -> ln = name) attributes in
      Some v
    with [ Not_found -> None ];

  value get_attributes tag_name names attributes : list string = 
    List.map begin fun name ->
      try
        let (_,v) = List.find (fun ((_,ln),v) -> ln = name) attributes in v
      with [ Not_found -> error "attribute %s not found in element %s" name tag_name ]
    end names;

(*   value get_attr name (tag_name,assoc) = try List.assoc name assoc with [ Not_found -> error "can't find attribute %s" name ]; *)

  value parse_element tag_name attr_names =
    match Xmlm.input xmlinput with
    [ `El_start ((_,tname),attributes) when tname = tag_name ->
      let res = get_attributes tname attr_names attributes in
      match Xmlm.input xmlinput with
      [ `El_end -> Some (res,attributes)
      | _ -> error "Unspecified element in %s" tag_name
      ]
    | `El_end -> None
    | _ -> error "Not an element %s" tag_name
    ];

end;
