exception Kv_not_found;

IFDEF SDL THEN
type t = Hashtbl.t string string;

value storage = ref None;
value commit () =
  match !storage with
  [ None -> ()
  | Some s -> 
     let ch = open_out_bin "kvstorage" in
     (
       Marshal.to_channel ch s [];
       close_out ch
     )
  ];

value get_storage () = 
  match !storage with
  [ Some s -> s
  | None ->
      if Sys.file_exists "kvstorage" 
      then
        let s = Marshal.from_channel (open_in_bin "kvstorage") in
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
value get_float k = try float_of_string (Hashtbl.find (get_storage ()) k) with [ Not_found -> raise Kv_not_found ];
      
value put_string k v = Hashtbl.add (get_storage()) k v;
value put_bool k v = Hashtbl.add (get_storage()) k (string_of_bool v); 
value put_int k v = Hashtbl.add (get_storage()) k (string_of_int v);
value put_float k v = Hashtbl.add (get_storage()) k (string_of_float v);
value remove k = Hashtbl.remove (get_storage()) k;
value exists k = Hashtbl.mem (get_storage()) k;

value get_string_opt (k:string) = try Some (get_string k) with [ Kv_not_found -> None ];
value get_bool_opt k = try Some (get_bool k) with [ Kv_not_found -> None ];
value get_int_opt k = try Some (get_int k) with [ Kv_not_found -> None ];
value get_float_opt k = try Some (get_float k) with [ Kv_not_found -> None ];
 
ELSE

(* external ml_create : unit -> t = "ml_kv_storage_create"; *)
external commit : unit -> unit = "ml_kv_storage_commit";

external get_string_opt : string -> option string = "ml_kv_storage_get_string";
external get_bool_opt : string -> option bool = "ml_kv_storage_get_bool";
external get_int_opt : string -> option int = "ml_kv_storage_get_int";
external get_float_opt : string -> option float = "ml_kv_storage_get_float";

external put_string : string -> string -> unit = "ml_kv_storage_put_string";
external put_bool :  string -> bool -> unit = "ml_kv_storage_put_bool";
external put_int  :  string -> int -> unit = "ml_kv_storage_put_int";
external put_float : string -> float -> unit = "ml_kv_storage_put_float";
external remove   :  string -> unit = "ml_kv_storage_remove";
external exists   :  string -> bool = "ml_kv_storage_exists"; 



(*
value create = ml_create;
value commit = ml_commit;
*)

(*
value get_string_opt = ml_get_string;
value get_bool_opt  = ml_get_bool;
value get_int_opt   = ml_get_int;
*)

value get_string  k = match get_string_opt k with [ Some s -> s | None -> raise Kv_not_found ];
value get_bool    k = match get_bool_opt k with [ Some b -> b   | None -> raise Kv_not_found ];
value get_int     k = match get_int_opt k with [ Some i -> i    | None -> raise Kv_not_found ];
value get_float k = match get_float_opt k with [ Some f -> f | None -> raise Kv_not_found ];

(*
value put_string = ml_put_string;
value put_bool = ml_put_bool;
value put_int = ml_put_int;
value remove  = ml_remove;
value exists  = ml_exists;
*)

ENDIF;

