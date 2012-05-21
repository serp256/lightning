type accData = {
  accX : float;
  accY : float;
  accZ : float;
};

type callback = accData -> unit;

IFDEF IOS THEN
external accStart : callback -> float -> unit = "ml_accStart";
external accStop : unit -> unit = "ml_accStop";
ELSE
value accStart (cb:callback) (interval:float) = ();
value accStop () = ();
ENDIF;