value (|>) a b = b a;
value color_white = 0xFFFFFF;
value color_black = 0x000000;


type textureID = int;
type framebufferID;

type halign = [= `HAlignLeft | `HAlignCenter | `HAlignRight ];
type valign = [= `VAlignTop | `VAlignCenter | `VAlignBottom ];

value pi  =  3.14159265359;
value half_pi = pi /. 2.;
value two_pi =  6.28318530718;

exception File_not_exists of string;

value rec nextPowerOfTwo number =
  let rec loop result = 
    if result < number 
    then loop (result * 2)
    else result
  in 
  loop 1;

DEFINE COLOR_PART_ALPHA(color) = (color lsr 24) land 0xff;
DEFINE COLOR_PART_RED(color) = (color lsr 16) land 0xff;
DEFINE COLOR_PART_GREEN(color) = (color lsr  8) land 0xff;
DEFINE COLOR_PART_BLUE(color) =  color land 0xff;

value floats_of_color color = 
  let red = COLOR_PART_RED(color)
  and green = COLOR_PART_GREEN(color)
  and blue = COLOR_PART_BLUE(color)
  in
  (((float red) /. 255.),((float green) /. 255.),((float blue) /. 255.));

IFDEF IOS THEN

Callback.register_exception "File_not_exists" (File_not_exists "");
external bundle_path_for_resource: string -> float -> option string = "ml_bundle_path_for_resource";
external device_scale_factor: unit -> float = "ml_device_scale_factor";

value resource_path path = 
  match bundle_path_for_resource path 2.0 with
  [ None    -> raise (File_not_exists path)
  | Some p  -> p
  ];

value open_resource path scale =
  match bundle_path_for_resource path scale with
  [ None -> raise (File_not_exists path)
  | Some p -> open_in p
  ];


value read_json path = 
  let ch = LightCommon.open_resource path 1. in                                                                                                                
  Ojson.from_channel ch;

value read_resource path scale = Std.input_all (open_resource path scale);

ELSE IFDEF ANDROID THEN

external bundle_fd_of_resource: string -> option (Unix.file_descr * int64) = "caml_getResource";
value device_scale_factor () = 1.0;

value resource_path path = 
  match bundle_fd_of_resource path with 
  [ None -> raise (File_not_exists path)  
  | Some p -> path
  ];  


value open_resource path _ = 
  match bundle_fd_of_resource path with
  [ None -> raise (File_not_exists path)
  | Some (fd,length) -> Unix.in_channel_of_descr fd
  ];


value read_resource path _ = 
  match bundle_fd_of_resource path with
  [ None -> raise (File_not_exists path)
  | Some (fd, length) -> 
      let length = Int64.to_int length in 
      let buff = String.create length
      and ic = Unix.in_channel_of_descr fd in
      (
        really_input ic buff 0 length;
        buff
      )
  ];
  
value read_json path = 
  match bundle_fd_of_resource path with 
  [ None -> raise (File_not_exists path)
  | Some (fd, length) ->  
    let read = ref Int64.zero
    and ic = Unix.in_channel_of_descr fd in
    Ojson.from_function begin fun buff len -> 
      match Int64.compare !read length with
      [ x when x >= 0 -> 0
      | _ ->
        let n = input ic buff 0 len in 
        let () = read.val := Int64.add (Int64.of_int n) !read in
        match Int64.compare !read length with
        [ x when x >= 0 -> Int64.to_int (Int64.sub length (Int64.sub !read (Int64.of_int n)))
        | _ -> n
        ]  
      ]
    end
  ];
  

ELSE IFDEF SDL THEN

value device_scale_factor () = 1.0;
value resource_path fname = 
  let path = Filename.concat "Resources" fname in
  match Sys.file_exists path with
  [ True -> path
  | False -> raise (File_not_exists fname)
  ];

value open_resource fname scale = open_in (resource_path fname);

value read_resource path scale = Std.input_all (open_resource path scale);

value read_json path = 
  let ch = LightCommon.open_resource path 1. in                                                                                                                
  Ojson.from_channel ch;

ENDIF;
ENDIF;
ENDIF;

(*
value resource_path path _ = 
  match Filename.is_relative path with (* убрать нах эту логику нах. *)
  [ True -> match bundle_path_for_resource path with [ Some p -> p | None -> raise (File_not_exists path) ]
  | False -> 
    match Sys.file_exists path with
    [ True -> path
    | False -> raise (File_not_exists path)
    ]
  ];
*)

exception Xml_error of string and string;

module MakeXmlParser(P:sig value path: string; end) = struct

  value input = open_resource P.path 1.;

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

  value ints x = 
    try int_of_string x with [ Failure _ -> error "int_of_string: %s" x ];

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
