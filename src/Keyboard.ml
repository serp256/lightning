IFDEF PC THEN
value paste () = "not SDL";
value copy _ = ();
value show _ _ _ = ();
value hide () = ();
ELSE
external paste: unit -> string = "ml_paste";
external copy: string -> unit = "ml_copy";
external show: ?visible:bool -> ?size:(int * int) -> ?inittxt:string -> ?onhide:(string -> unit) -> ?onchange:(string -> unit) -> unit -> unit = "ml_keyboard_byte" "ml_keyboard";
external hide: unit -> unit = "ml_hidekeyboard";
ENDIF;