type t;

IFDEF SDL THEN

value ml_create _ = failwith "Not implemented";
value ml_commit _ = failwith "Not implemented";
value ml_get_string _ _ = failwith "Not implemented";
value ml_get_bool _ _ = failwith "Not implemented";
value ml_get_int _ _ = failwith "Not implemented";

value ml_put_string _ _ _ = failwith "Not implemented";
value ml_put_bool _ _ _ = failwith "Not implemented"; 
value ml_put_int  _ _ _ = failwith "Not implemented";
value ml_remove   _ _   = failwith "Not implemented";
value ml_exists   _ _   = failwith "Not implemented";
 
ELSE

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

ENDIF;

value create = ml_create;
value commit = ml_commit;

value get_string_opt = ml_get_string;
value get_bool_opt  = ml_get_bool;
value get_int_opt   = ml_get_int;

value get_string  t k = match get_string_opt t k with [ Some s -> s | None -> raise Not_found ];
value get_bool    t k = match get_bool_opt t k with [ Some b -> b   | None -> raise Not_found ];
value get_int     t k = match get_int_opt t k with [ Some i -> i    | None -> raise Not_found ];

value put_string = ml_put_string;
value put_bool = ml_put_bool;
value put_int = ml_put_int;
value remove  = ml_remove;
value exists  = ml_exists;


