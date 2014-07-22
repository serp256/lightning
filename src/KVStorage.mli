(* type t; *)

exception Kv_not_found;

(* value create : unit -> t; *)

value get_string_opt : string -> option string;

value get_bool_opt : string -> option bool;

value get_int_opt : string -> option int;

(*value get_float_opt : string -> option float;*)

value get_string : string -> string;

value get_bool : string -> bool;

value get_int : string -> int;

(*value get_float : string -> float;*)

value put_string : string -> string -> unit;

value put_bool : string -> bool -> unit;

value put_int : string -> int -> unit;

(*value put_float : string -> float -> unit;*)

value remove : string -> unit;

value exists : string -> bool;

value commit : unit -> unit;