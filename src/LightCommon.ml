open ExtString;

(* external (|>) : 'a -> ('a -> 'b) -> 'b = "%apply%" (*= b a*); *)
(* external (<|): ('a -> 'b) -> 'a -> 'b = "%revapply%" (*= f v*); *)


value (|>) v f = f v;
value (<|) f v = f v;

value color_white = 0xFFFFFF;
value color_black = 0x000000;


value round v =
  let mult  = if v < 0. then ~-.1. else 1. in
  let v_abs = abs_float v in
  let v' = ceil v_abs in
  match v' -. v_abs > 0.5 with
  [ True -> mult *. (v' -. 1.)
  | _ -> mult *. v'
  ];

type textureID;
type framebufferID = int;

type halign = [= `HAlignLeft | `HAlignCenter | `HAlignRight ];
type valign = [= `VAlignTop | `VAlignCenter | `VAlignBottom ];

value pi  =  3.14159265359;
value half_pi = pi /. 2.;
value two_pi =  6.28318530718;

value clamp_rotation nr =
  let nr =
    if nr < ~-.pi
    then loop nr where rec loop nr = let nr = nr +. two_pi in if nr < ~-.pi then loop nr else nr
    else nr
  in
  if nr > pi
  then loop nr where rec loop nr = let nr = nr -. two_pi in if nr > pi then loop nr else nr
  else nr
;

type remoteNotification = [= `RNBadge | `RNSound | `RNAlert ];

exception File_not_exists of string;
exception Extra_resources of string;

Callback.register_exception "extra_resources" (Extra_resources "");

type qColor =
  {
    qcTopLeft: int32;
    qcTopRight: int32;
    qcBottomLeft: int32;
    qcBottomRight: int32;
  };

IFPLATFORM(pc)
value getLocale () = "en";
ELSE
external getLocale: unit -> string = "ml_getLocale";
ENDPLATFORM;

IFPLATFORM(ios android)
external getVersion: unit -> string = "ml_getVersion";
ELSE
value getVersion () = "PC version";
ENDPLATFORM;


(*
value qColor ?topRight ?bottomLeft ?bottomRight ~topLeft =
  {
    qcTopLeft = topLeft;
    qcTopRight = match topRight with [ None -> topLeft | Some c -> c];
    qcBottomLeft = match bottomLeft with [ None -> topLeft | Some c -> c];
    qcBottomRight = match bottomRight with [ None -> topLeft | Some c -> c];
  };
*)

value qColor ~topLeft ~topRight ~bottomLeft ~bottomRight =
  {qcTopLeft=topLeft;qcTopRight=topRight;qcBottomLeft=bottomLeft;qcBottomRight=bottomRight};

type color = [= `NoColor | `Color of int | `QColors of qColor ];

value powOfTwo p =
  let r = ref 1 in
  (
    for i = 0 to p -1 do
      r.val := !r * 2;
    done;
    !r;
  );


value nextPowerOfTwo x =
  let x = x - 1 in
  let x = x lor (x lsr 1) in
  let x = x lor (x lsr 2) in
  let x = x lor (x lsr 4) in
  let x = x lor (x lsr 8) in
  let x = x lor (x lsr 16) in
  x + 1;


DEFINE COLOR_PART_ALPHA(color) = (color lsr 24) land 0xff;
DEFINE COLOR_PART_RED(color) = (color lsr 16) land 0xff;
DEFINE COLOR_PART_GREEN(color) = (color lsr  8) land 0xff;
DEFINE COLOR_PART_BLUE(color) =  color land 0xff;


value _resources_suffix = ref None;
value resources_suffix () = !_resources_suffix;

value set_resources_suffix suffix = _resources_suffix.val := Some suffix;

value split_filename filename =
  try
    let i = String.rindex filename '.' in
    (String.sub filename 0 i,String.sub filename i ((String.length filename) - i))
  with [ Not_found -> (filename,"") ];

value path_with_suffix path =
  match !_resources_suffix with
  [ Some p ->
    let (fname,ext) = split_filename path in
    fname ^ p ^ ext
  | None -> path
  ];

value floats_of_color color =
  let red = COLOR_PART_RED(color)
  and green = COLOR_PART_GREEN(color)
  and blue = COLOR_PART_BLUE(color)
  in
  (((float red) /. 255.),((float green) /. 255.),((float blue) /. 255.));

Callback.register_exception "File_not_exists" (File_not_exists "");

(* IFPLATFORM(ios)

external bundle_path_for_resource: string -> option string -> option string = "ml_bundle_path_for_resource";

(*
value resource_path ?(with_suffix=True) path =
  let suffix = match with_suffix with [ True -> !_resources_suffix | False -> None ] in
  match bundle_path_for_resource path suffix with
  [ None    -> raise (File_not_exists path)
  | Some p  -> p
  ];
*)

value open_resource ?(with_suffix=True) path =
  let suffix = match with_suffix with [ True -> !_resources_suffix | False -> None ] in
  match bundle_path_for_resource path suffix with
  [ None -> raise (File_not_exists path)
  | Some p -> open_in p
  ];


value read_json ?with_suffix path =
  let ch = open_resource ?with_suffix path in
  Ojson.from_channel ch;

value read_resource ?with_suffix path = Std.input_all (open_resource ?with_suffix path);

ELSPLATFORM(android)  *)
IFPLATFORM(android ios)

external bundle_fd_of_resource: string -> option (Unix.file_descr * int64) = "caml_getResource";
external regExtraResources: ~fname:string -> unit -> unit = "ml_reg_extra_resources";

value request_remote_notifications rntypes success error = ();

value _get_resource with_suffix path =
  match with_suffix with
  [ True ->
    let spath = path_with_suffix path in
    match bundle_fd_of_resource spath with
    [ Some (fd,len) as res -> res
    | None -> bundle_fd_of_resource path
    ]
  | False -> bundle_fd_of_resource path
  ];

value get_resource with_suffix path =
  let () = debug "get_resource call %s" path in
  match _get_resource with_suffix path with
  [ None -> raise (File_not_exists path)
(*     let locale = getLocale () in
      let () = debug "cannot find in common resources, try %s" ("locale/" ^ locale ^ "/" ^ path) in
      match _get_resource with_suffix ("locale/" ^ locale ^ "/" ^ path) with
      [ None ->
        let () = debug "cannot find in locale resources" in
        if locale <> "en" then
          let () = debug "try en locale" in
          match _get_resource with_suffix ("locale/en/" ^ path) with
          [ None -> raise (File_not_exists path)
          | res -> res
          ]
        else
          let () = debug "xyu" in
          raise (File_not_exists path)
      | res -> res
      ] *)
  | res -> res
  ];


value open_resource_unsafe ?(with_suffix=True) path =
  let () = debug "open_resource call %s" path in
  match get_resource with_suffix path with
  [ None -> raise (File_not_exists path)
  | Some (fd,length) -> Unix.in_channel_of_descr fd
  ];


value open_resource ?(with_suffix=True) path =
  let () = debug "open_resource call %s" path in
  match get_resource with_suffix path with
  [ None -> raise (File_not_exists path)
  | Some (fd,length) ->
      let length = Int64.to_int length in
      let pos = ref 0 in
      let ic = Unix.in_channel_of_descr fd in
      IO.create_in
        ~read:(fun () -> if !pos < length then (incr pos; input_char ic) else raise IO.No_more_input)
        ~input:(fun buf p l -> if (!pos + l < length) then (pos.val := !pos + l; input ic buf p l) else raise IO.No_more_input)
        ~close:(fun () -> close_in ic)
  ];

value read_resource ?(with_suffix=True) path =
  match get_resource with_suffix path with
  [ None -> raise (File_not_exists path)
  | Some (fd, length) ->
      let () = debug:res "%s -> %Ld" path length in
      let length = Int64.to_int length in
      let buff = String.create length in
      (
        Unix.read fd buff 0 length |> ignore;
        Unix.close fd;
        buff
      )
  ];

value read_json ?(with_suffix=True) path =
  match get_resource with_suffix path with
  [ None -> raise (File_not_exists path)
  | Some (fd, length) ->
    let read = ref Int64.zero
    and ic = Unix.in_channel_of_descr fd in
    let retval =
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
    in (
      close_in ic;
      retval;
    )
  ];


ELSPLATFORM(pc)

value resources_path = "Resources";
value resource_path ?(with_suffix=True) fname =
  let () = debug "resource_path call, %B" with_suffix in
  match with_suffix with
  [ True ->
    let spath = Filename.concat resources_path (path_with_suffix fname) in
    let () = debug "spath: %s" spath in
    match Sys.file_exists spath with
    [ True -> spath
    | False ->
        let path = Filename.concat resources_path fname in
        match Sys.file_exists path with
        [ True -> path
        | False -> raise (File_not_exists fname)
        ]
    ]
  | False ->
    let path = Filename.concat "Resources" fname in
    match Sys.file_exists path with
    [ True -> path
    | False -> raise (File_not_exists fname)
    ]
  ];

value open_resource_unsafe ?with_suffix fname = open_in (resource_path ?with_suffix fname);
value open_resource ?with_suffix fname =
  let ch = open_resource_unsafe ?with_suffix fname in
    IO.input_channel ch;

value read_resource ?with_suffix path =
  let inp = open_resource_unsafe ?with_suffix path in
  let retval = Std.input_all inp in
    (
      close_in inp;
      retval;
    );

value read_json ?with_suffix path =
  let ch = open_resource_unsafe ?with_suffix path in
  Ojson.from_channel ch;

value regExtraResources ~fname () = ();

ENDPLATFORM;


type deviceType = [ Phone | Pad ];
value internalDeviceType = ref Pad;

IFPLATFORM(ios android)
external getDeviceType: unit -> deviceType = "ml_getDeviceType";
ELSE
value getDeviceType () = !internalDeviceType;
ENDPLATFORM;


type ios_device = [ IPhoneOld | IPhone3GS | IPhone4 | IPhone5 | IPhone6 | IPhone6plus | IPhoneNew | IPad1 | IPad2 | IPad3 | IPadNew | IUnknown ];
type androidScreen = [ UnknownScreen | Small | Normal | Large | Xlarge ];
type androidDensity = [ UnknownDensity | Ldpi | Mdpi | Hdpi | Xhdpi | Tvdpi | Xxhdpi ];

type device = [ Android of (androidScreen * androidDensity) | IOS of ios_device ];
value internal_device = ref (IOS IPad2);

IFPLATFORM(android)
external androidScreen: unit -> (androidScreen * androidDensity) = "ml_androidScreen";
value getDevice () = Android (androidScreen ());
ELSPLATFORM(ios)
external ios_platfrom: unit -> string = "ml_platform";
value getDevice () =
  let d : ios_device =
    let ip = ios_platfrom () in
    if String.starts_with ip "iPhone"
    then
      if String.starts_with ip "iPhone1" then IPhoneOld
      else if String.starts_with ip "iPhone2" then IPhone3GS
      else if String.starts_with ip "iPhone3" then IPhone4
      else if String.starts_with ip "iPhone4" then IPhone4
      else if String.starts_with ip "iPhone5" then IPhone5
      else if String.starts_with ip "iPhone6" then IPhone5
      else if String.starts_with ip "iPhone7,2" then IPhone6
      else if String.starts_with ip "iPhone7,1" then IPhone6plus
      else IPhoneNew
    else begin
      if String.starts_with ip "iPod"
      then
        if String.starts_with ip "iPod1" || String.starts_with ip "iPod2" then IPhoneOld
        else if String.starts_with ip "iPod3" then IPhone3GS
        else if String.starts_with ip "iPod4" then IPhone4
        else if String.starts_with ip "iPod5" then IPhone5
        else IPhoneNew
      else
        if String.starts_with ip "iPad"
        then
          if String.starts_with ip "iPad1" then IPad1
          else if String.starts_with ip "iPad2" then IPad2
          else if String.starts_with ip "iPad3" then IPad3
          else if String.starts_with ip "iPad4" then IPad3
          else IPadNew
        else IUnknown
    end
  in
  IOS d;
ELSPLATFORM(pc)
value getDevice () = let () = debug "internal_device call" in !internal_device;
ENDPLATFORM;

IFPLATFORM(pc)
value deviceType = getDeviceType;
ELSE
value _deviceType = Lazy.lazy_from_fun getDeviceType;
value deviceType () = Lazy.force _deviceType;
ENDPLATFORM;

value deviceTypeToStr devType =
  match devType with
  [ Pad -> "Pad"
  | Phone -> "Phone"
  ];

IFPLATFORM(pc)
value device = getDevice;
ELSE
value _device = Lazy.lazy_from_fun getDevice;
value device () : device = Lazy.force _device;
ENDPLATFORM;

value androidScreenToString screen =
  match screen with
  [ UnknownScreen -> "unknown"
  | Small -> "small"
  | Normal -> "normal"
  | Large -> "large"
  | Xlarge -> "xlarge"
  ];

value androidDensityToString density =
  match density with
  [ UnknownDensity -> "unknown"
  | Ldpi -> "ldpi"
  | Mdpi -> "mdpi"
  | Hdpi -> "hdpi"
  | Xhdpi -> "xhdpi"
  | Tvdpi -> "tvdpi"
  | Xxhdpi -> "xxhdpi"
  ];

value deviceToStr dev =
  match dev with
  [ Android (scrn, dnsty) ->
    let devStr = Printf.sprintf "android(%s,%s)" (androidScreenToString scrn) (androidDensityToString dnsty) in
      String.lowercase devStr
  | IOS dev ->
    let devStr =
      match dev with
      [ IPhoneOld -> "IPhoneOld"
      | IPhone3GS -> "IPhone3GS"
      | IPhone4 -> "IPhone4"
      | IPhone5 -> "IPhone5"
      | IPhone6 -> "IPhone6"
      | IPhone6plus -> "IPhone6plus"
      | IPhoneNew -> "IPhoneNew"
      | IPad1 -> "IPad1"
      | IPad2 -> "IPad2"
      | IPad3 -> "IPad3"
      | IPadNew -> "IPadNew"
      | IUnknown -> "IUnknown"
      ]
    in
      let devStr = Printf.sprintf "ios(%s)" devStr in
        String.lowercase devStr
  ];


value strToDevice s =
  match String.lowercase s with
  [ "iphoneold" -> IOS IPhoneOld
  | "iphone3gs" -> IOS IPhone3GS
  | "iphone4" -> IOS IPhone4
  | "iphone5" -> IOS IPhone5
  | "iphone6" -> IOS IPhone6
  | "iphone6plus" -> IOS IPhone6plus
  | "iphonenew" -> IOS IPhoneNew
  | "ipad1" -> IOS IPad1
  | "ipad2" -> IOS IPad2
  | "ipad3" -> IOS IPad3
  | "ipadnew" -> IOS IPadNew
  | s ->
    let (screen, density) =
      try ExtString.String.split s "-"
      with
        [ _ ->
          try ExtString.String.split s "_"
          with [ _ -> failwith "unknown device string" ]
        ]
    in
    let screen =
      match screen with
      [ "small" -> Small
      | "normal" -> Normal
      | "large" -> Large
      | "xlarge" -> Xlarge
      | _ -> failwith "unknown android screen string"
      ]
    in
    let density =
      match density with
      [ "ldpi" -> Ldpi
      | "mdpi" -> Mdpi
      | "hdpi" -> Hdpi
      | "xhdpi" -> Xhdpi
      | "tvdpi" -> Tvdpi
      | "xxhdpi" -> Xxhdpi
      | _ -> failwith "unknown android density string"
      ]
    in
      Android (screen, density)
  ];

value deviceToSize = fun
  [ IOS ios ->
    match ios with
    [ IPhoneOld -> (320, 480)
    | IPhone3GS -> (320, 480)
    | IPhone4 -> (640, 960)
    | IPhone5 -> (640, 1136)
    | IPhone6 -> (750, 1334)
    | IPhone6plus -> (1080, 1920)
    | IPad1 -> (768, 1024)
    | IPad2 -> (768, 1024)
    | IPad3 -> (1536, 2048)
    | IPadNew -> (1536, 2048)
    | _ -> assert False
    ]
  | Android android ->
    match android with
    [ (Large, Ldpi) -> (480, 800)
    | (Large, Mdpi) -> (600, 1024)
    | (Large, Tvdpi) -> (800, 1280)
    | (Large, Xhdpi) -> (1200, 1920)
    | (Xlarge, Hdpi) -> (1200, 1920)
    | (Xlarge, Xhdpi) -> (1600, 2560)
    | (Normal, Mdpi) -> (320, 480)
    | (Normal, Hdpi) -> (480, 800)
    | (Normal, Xhdpi) -> (720, 1280)
    | (Normal, Xxhdpi) -> (1080, 1920)
    | _ -> assert False
    ]
  ];

type compression = [ Pvr | Dxt | Atc | Etc | Etc2 ];
IFPLATFORM(pc)
value compression () = Etc;
ELSE
  IFPLATFORM(ios)
    value compression () = Pvr;
  ELSE
    external compression: unit -> compression = "ml_compression";
  ENDPLATFORM;
ENDPLATFORM;

value compressionToStr = fun
  [ Pvr -> "Pvr"
  | Dxt -> "Dxt"
  | Atc -> "Atc"
  | Etc -> "Etc"
  | Etc2 -> "Etc2"
  ];

IFPLATFORM(pc)
value storagePath () = "Storage";
ELSE
external storagePath: unit -> string = "ml_getStoragePath";
value _storagePath = Lazy.lazy_from_fun storagePath;
value storagePath () = Lazy.force _storagePath;
ENDPLATFORM;



exception Xml_error of string and string;

module MakeXmlParser(P:sig value path: string; value with_suffix: bool; end) = struct

  value input = open_resource_unsafe ~with_suffix:P.with_suffix P.path;

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
    let () = debug "Parse element %s" tag_name in
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

(* IFDEF ANDROID THEN
external pathExistsInExpansions: string -> bool = "ml_pathExistsInExpansions";
ELSE
value pathExistsInExpansions (path:string) = False;
ENDIF; *)

value exitApp () = ignore(exit 0);

value positiveOrZero a = float (if a > 0 then a else 0);
value negativeOrZero a = float (if a < 0 then a else 0);
value invertNegativeOrZero a = float (if a < 0 then ~-a else 0);

value glowMatrix mhgs x y = Matrix.create ~translate:{ Point.x = mhgs +. (negativeOrZero x); y = mhgs +. (negativeOrZero y)} ();
value glowFirstDrawMatrix originaMtx x y = Matrix.translate originaMtx (positiveOrZero x, positiveOrZero y);
value glowLastDrawMatrix originaMtx x y = Matrix.translate originaMtx (invertNegativeOrZero x, invertNegativeOrZero y);

IFPLATFORM(pc)
value strToLower str = str;
value strToUpper str = str;
ELSE
external strToLower: string -> string = "ml_str_to_lower";
external strToUpper: string -> string = "ml_str_to_upper";
ENDPLATFORM;

value strCapitalize str =
  let fstCharPos = UTF8.nth str 1 in
  let fst = String.sub str 0 fstCharPos in
  let rest = String.sub str fstCharPos (String.length str - fstCharPos) in
    (strToUpper fst) ^ rest;

IFPLATFORM(ios)
external systemVersion: unit -> string = "ml_systemVersion";
ELSE
  IFPLATFORM(android)
  value systemVersion () = Hardware.platform ();
  ELSE
  value systemVersion () = "MAC_OS_X";
  ENDPLATFORM;
ENDPLATFORM;

IFPLATFORM(ios)
external model: unit -> string = "ml_model";
ELSE
  IFPLATFORM(android)
  value model () = Hardware.hwmodel();
  ELSE
  value model () = "iMAC";
  ENDPLATFORM;
ENDPLATFORM;
