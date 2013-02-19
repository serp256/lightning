exception Kv_not_found;

IFPLATFORM(pc)
value get_storage_path () = ".";
ENDPLATFORM;

IFPLATFORM(android) 
external get_storage_path: unit -> string = "ml_getInternalStoragePath";
ENDPLATFORM;
IFPLATFORM(pc) 
value get_storage_path () = "";
ENDPLATFORM;

IFPLATFORM(ios) 
external commit : unit -> unit = "ml_kv_storage_commit";

external get_string_opt : string -> option string = "ml_kv_storage_get_string";
external get_bool_opt : string -> option bool = "ml_kv_storage_get_bool";
external get_int_opt : string -> option int = "ml_kv_storage_get_int";

external put_string : string -> string -> unit = "ml_kv_storage_put_string";
external put_bool :  string -> bool -> unit = "ml_kv_storage_put_bool";
external put_int  :  string -> int -> unit = "ml_kv_storage_put_int";
external remove   :  string -> unit = "ml_kv_storage_remove";
external exists   :  string -> bool = "ml_kv_storage_exists"; 




value get_string  k = match get_string_opt k with [ Some s -> s | None -> raise Kv_not_found ];
value get_bool    k = match get_bool_opt k with [ Some b -> b   | None -> raise Kv_not_found ];
value get_int     k = match get_int_opt k with [ Some i -> i    | None -> raise Kv_not_found ];

ELSE


type t = Hashtbl.t string string;

value storage_file = 
  ifplatform(android)
    (get_storage_path ()) ^ "kvstorage"
  else "kvstorage";


value storage_file_tmp = (get_storage_path ()) ^ ".kvstorage.tmp";


value storage = ref None;
value commit () =
  match !storage with
  [ None -> ()
  | Some s -> 
		 let ch = open_out_bin storage_file_tmp in
     (
       Marshal.to_channel ch s [];
       close_out ch;
       Sys.rename storage_file_tmp storage_file;
     )
  ];

value get_storage () = 
  match !storage with
  [ Some s -> s
  | None ->
    if Sys.file_exists storage_file 
    then
      let (s:Hashtbl.t string string) = 
        try
          Marshal.from_channel (open_in_bin storage_file)
        with [ End_of_file -> Hashtbl.create 0 ]
      in
      (
        storage.val := Some s;
        s
      )
    else 
      let s = Hashtbl.create 0 in
      (
        storage.val := Some s;
        commit ();
        s;
      )
  ];

value get_string k = try Hashtbl.find (get_storage()) k with [ Not_found -> raise Kv_not_found ];
value get_bool k = try bool_of_string (Hashtbl.find (get_storage()) k) with [ Not_found -> raise Kv_not_found ];
value get_int k = try int_of_string (Hashtbl.find (get_storage()) k) with [ Not_found -> raise Kv_not_found ];
(*value get_float k = try float_of_string (Hashtbl.find (get_storage ()) k) with [ Not_found -> raise Kv_not_found ];*)
      
value put_string k v = Hashtbl.replace (get_storage()) k v;
value put_bool k v = Hashtbl.replace (get_storage()) k (string_of_bool v); 
value put_int k v = Hashtbl.replace (get_storage()) k (string_of_int v);
value put_float k v = Hashtbl.replace (get_storage()) k (string_of_float v);
value remove k = Hashtbl.remove (get_storage()) k;
value exists k = Hashtbl.mem (get_storage()) k;

value get_string_opt (k:string) = try Some (get_string k) with [ Kv_not_found -> None ];
value get_bool_opt k = try Some (get_bool k) with [ Kv_not_found -> None ];
value get_int_opt k = try Some (get_int k) with [ Kv_not_found -> None ];
(*value get_float_opt k = try Some (get_float k) with [ Kv_not_found -> None ];*)

ENDPLATFORM;

