

exception Record_not_found;

value load: string ->
  <
    save: unit -> unit;
    get: string -> string;
    get_opt: string -> option string;
    set: string -> string -> unit;
    remove:  string -> unit;
    iter: (string -> string -> unit) -> unit;
  >;
