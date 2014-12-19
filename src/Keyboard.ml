IFDEF PC THEN
value paste f = f "not supported on pc";
value copy _ = ();
value show ?filter ?visible ?size ?inittxt ?onhide ?onchange () = ();
value hide () = ();
ELSE
external paste: (string -> unit) -> unit = "ml_paste";
external copy: string -> unit = "ml_copy";

IFDEF ANDROID THEN
external show: ?filter:string -> ?visible:bool -> ?size:(int * int) -> ?inittxt:string -> ?onhide:(string -> unit) -> ?onchange:(string -> unit) -> unit -> unit = "ml_keyboard_byte" "ml_keyboard";
external hide: unit -> unit = "ml_hidekeyboard";
ELSE
external keyboard : option string -> bool -> (int * int) -> string -> ?onhide:(string -> unit) -> ?onchange:(string -> unit) -> unit = "ml_keyboard_byte"  "ml_keyboard";
value show ?filter ?(visible=True) ?(size=(400,50)) ?(inittxt="") ?onhide ?onchange () = keyboard filter visible size inittxt ?onhide ?onchange;
external hide : unit -> unit = "ml_hidekeyboard";
ENDIF;

ENDIF;
