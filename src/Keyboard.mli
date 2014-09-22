value paste: (string -> unit) -> unit;
value copy: string -> unit;
value show: ?visible:bool -> ?size:(int * int) -> ?inittxt:string -> ?onhide:(string -> unit) -> ?onchange:(string -> unit) -> unit -> unit;
value hide: unit -> unit;
