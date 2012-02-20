exception Kv_not_found;

IFDEF SDL THEN
type t = Hashtbl.t string string;

value storage = ref None;
value commit s =
 let ch = open_out_bin "kvstorage" in
 (
  Marshal.to_channel ch s [];
  close_out ch
);

value create () = 
  match !storage with
  [ Some s -> s
  | None ->
    let s =
      if Sys.file_exists "kvstorage" then
        Marshal.from_channel (open_in_bin "kvstorage")
      else 
        let s = Hashtbl.create 0 in
        (
          commit s;
          s;
        )
    in
    (
      storage.val := Some s;
      s;
    )
  ];

value get_string s k = try Hashtbl.find s k with [ Not_found -> raise Kv_not_found ];
value get_bool s k = try bool_of_string (Hashtbl.find s k) with [ Not_found -> raise Kv_not_found ];
value get_int s k = try int_of_string (Hashtbl.find s k) with [ Not_found -> raise Kv_not_found ];
      
value put_string s k v = Hashtbl.add s k v;
value put_bool s k v = Hashtbl.add s k (string_of_bool v); 
value put_int s k v = Hashtbl.add s k (string_of_int v);
value remove s k = Hashtbl.remove s k;
value exists s k = Hashtbl.mem s k;

value get_string_opt s (k:string) = try Some (get_string s k) with [ Kv_not_found -> None ];
value get_bool_opt s k = try Some (get_bool s k) with [ Kv_not_found -> None ];
value get_int_opt s k = try Some (get_int s k) with [ Kv_not_found -> None ];
 
ELSE
type t;

external ml_create : unit -> t = "ml_kv_storage_create";
external ml_commit : t -> unit = "ml_kv_storage_commit";

external ml_get_string : t -> string -> option string = "ml_kv_storage_get_string";
external ml_get_bool : t -> string -> option bool = "ml_kv_storage_get_bool";
external ml_get_int : t -> string -> option int = "ml_kv_storage_get_int";

external ml_put_string : t -> string -> string -> unit = "ml_kv_storage_put_string";
external ml_put_bool :   t -> string -> bool -> unit = "ml_kv_storage_put_bool";
external ml_put_int  :   t -> string -> int -> unit = "ml_kv_storage_put_int";
external ml_remove   :   t -> string -> unit = "ml_kv_storage_remove";
external ml_exists   :   t -> string -> bool = "ml_kv_storage_exists"; 



value create = ml_create;
value commit = ml_commit;

value get_string_opt = ml_get_string;
value get_bool_opt  = ml_get_bool;
value get_int_opt   = ml_get_int;

value get_string  t k = match get_string_opt t k with [ Some s -> s | None -> raise Kv_not_found ];
value get_bool    t k = match get_bool_opt t k with [ Some b -> b   | None -> raise Kv_not_found ];
value get_int     t k = match get_int_opt t k with [ Some i -> i    | None -> raise Kv_not_found ];

value put_string = ml_put_string;
value put_bool = ml_put_bool;
value put_int = ml_put_int;
value remove  = ml_remove;
value exists  = ml_exists;

ENDIF;

