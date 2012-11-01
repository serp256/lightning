type acmtrData = {
  accX : float;
  accY : float;
  accZ : float;
};

type callback = acmtrData -> unit;

IFDEF IOS THEN
external acmtrStart : callback -> float -> unit = "ml_acmtrStart";
external acmtrStop : unit -> unit = "ml_acmtrStop";
ELSE
value acmtrStart (cb:callback) (interval:float) = ();
value acmtrStop () = ();
ENDIF;

