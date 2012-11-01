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
external keyboard : bool -> (int * int) -> string -> ?onhide:(string -> unit) -> ?onchange:(string -> unit) -> unit = "ml_keyboard";
value show ?(visible=True) ?(size=(400,50)) ?(inittxt="") ?onhide ?onchange () = keyboard visible size inittxt ?onhide ?onchange;
external hideKeyboard : unit -> unit = "ml_hidekeyboard";
ELSE
value acmtrStart (cb:callback) (interval:float) = ();
value acmtrStop () = ();
value paste () = "not SDL";
value copy _ = ();
value show _ _ _ _ = ();
value hideKeyboard () = ();
ENDIF;

