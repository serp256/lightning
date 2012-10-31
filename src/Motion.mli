type acmtrData = {
  accX : float;
  accY : float;
  accZ : float;
};

type callback = acmtrData -> unit;

value acmtrStart : callback -> float -> unit;
value acmtrStop : unit -> unit;
value paste : unit -> string;
value copy : string -> unit;
value show : ?visible:bool -> ?size:(int * int) -> ?inittxt:string -> ?onhide:(string -> unit) -> ?onchange:(string -> unit) -> unit -> unit;
value hideKeyboard : unit -> unit;
