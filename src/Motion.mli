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
value keyboard : (string -> unit) -> (string -> unit) -> unit;
