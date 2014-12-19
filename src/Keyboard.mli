module Filter:
  sig
    type t;

    value create: string -> t;
  end;

value paste: (string -> unit) -> unit;
value copy: string -> unit;
(* visible and size arguments are ignored on android *)
value show: ?filter:Filter.t -> ?visible:bool -> ?size:(int * int) -> ?inittxt:string -> ?onhide:(string -> unit) -> ?onchange:(string -> unit) -> unit -> unit;
value hide: unit -> unit;
