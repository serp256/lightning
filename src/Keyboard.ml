IFDEF PC THEN
module Filter =
  struct
    type t = string;
    value create f = f;
  end;

value paste f = f "not supported on pc";
value copy _ = ();
value show ?filter ?visible ?size ?inittxt ?onhide ?onchange () = ();
value hide () = ();
ELSE
external paste: (string -> unit) -> unit = "ml_paste";
external copy: string -> unit = "ml_copy";

module Filter =
  struct
    type t = string;

    value create src =
      let rec create i res =
        if i < UTF8.length src
        then create (i + 1) (res ^ (Printf.sprintf "\\u%04x" (UChar.code (UTF8.get src i))))
        else res
      in
        create 0 "";
  end;


IFDEF ANDROID THEN
external show: ?filter:Filter.t -> ?visible:bool -> ?size:(int * int) -> ?inittxt:string -> ?onhide:(string -> unit) -> ?onchange:(string -> unit) -> unit -> unit = "ml_keyboard_byte" "ml_keyboard";
external hide: unit -> unit = "ml_hidekeyboard";
ELSE
external keyboard : option Filter.t -> bool -> (int * int) -> string -> ?onhide:(string -> unit) -> ?onchange:(string -> unit) -> unit = "ml_keyboard_byte"  "ml_keyboard";
value show ?filter ?(visible=True) ?(size=(400,50)) ?(inittxt="") ?onhide ?onchange () = keyboard filter visible size inittxt ?onhide ?onchange;
external hide : unit -> unit = "ml_hidekeyboard";
ENDIF;

ENDIF;
