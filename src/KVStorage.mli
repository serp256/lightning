type t;

value create : unit -> t;

value get_string_opt : t -> string -> option string;

value get_bool_opt : t -> string -> option bool;

value get_int_opt : t -> string -> option int;

value get_string : t -> string -> string;

value get_bool : t -> string -> bool;

value get_int : t -> string -> int;

value put_string : t -> string -> string -> unit;

value put_bool : t -> string -> bool -> unit;

value put_int : t -> string -> int -> unit;

value remove : t -> string -> unit;

value exists : t -> string -> bool;

value commit : t -> unit;


