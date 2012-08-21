type acmtrData = {
  accX : float;
  accY : float;
  accZ : float;
};

type callback = acmtrData -> unit;

IFDEF IOS THEN
external acmtrStart : callback -> float -> unit = "ml_acmtrStart";
external acmtrStop : unit -> unit = "ml_acmtrStop";
external paste : unit -> string = "ml_paste";
external copy : string -> unit = "ml_copy";
ELSE
value acmtrStart (cb:callback) (interval:float) = ();
value acmtrStop () = ();
value paste () = "not SDL";
value copy _ = ();
ENDIF;

