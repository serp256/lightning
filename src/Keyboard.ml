IFDEF PC THEN
value paste () = "not SDL";
value copy _ = ();
value show ?visible ?size ?inittxt ?onhide ?onchange () = ();
value hide () = ();
ELSE
external paste: unit -> string = "ml_paste";
external copy: string -> unit = "ml_copy";

IFDEF ANDROID THEN
external show: ?visible:bool -> ?size:(int * int) -> ?inittxt:string -> ?onhide:(string -> unit) -> ?onchange:(string -> unit) -> unit -> unit = "ml_keyboard_byte" "ml_keyboard";
external hide: unit -> unit = "ml_hidekeyboard";
ELSE
external keyboard : bool -> (int * int) -> string -> ?onhide:(string -> unit) -> ?onchange:(string -> unit) -> unit = "ml_keyboard";
value show ?(visible=True) ?(size=(400,50)) ?(inittxt="") ?onhide ?onchange () = keyboard visible size inittxt ?onhide ?onchange;
external hide : unit -> unit = "ml_hidekeyboard";
ENDIF;

ENDIF;
