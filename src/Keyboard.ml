IFDEF PC THEN
module Filter =
  struct
    type t = string;
    value create f = f;
  end;

value paste f = f "not supported on pc";
value copy _ = ();
value show ?filter ?max_count_symbols ?visible ?size ?inittxt ?onhide ?onchange () = ();
value hide () = ();
value clean () = ();
ELSE
external paste: (string -> unit) -> unit = "ml_paste";
external copy: string -> unit = "ml_copy";
external clean: unit -> unit = "ml_cleankeyboard";

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
external keyboard : option Filter.t -> int -> option bool -> option (int * int) -> option string -> ?onhide:(string -> unit) -> ?onchange:(string -> unit) -> unit = "ml_keyboard_byte"  "ml_keyboard";
value show ?filter ?(max_count_symbols=0) ?visible ?size ?inittxt ?onhide ?onchange () = keyboard filter max_count_symbols visible size inittxt ?onhide ?onchange;
external hide: unit -> unit = "ml_hidekeyboard";
ELSE
external keyboard : option Filter.t -> int -> bool -> (int * int) -> string -> ?onhide:(string -> unit) -> ?onchange:(string -> unit) -> unit = "ml_keyboard_byte"  "ml_keyboard";
value show ?filter ?(max_count_symbols=0) ?(visible=True) ?(size=(400,50)) ?(inittxt="") ?onhide ?onchange () = keyboard filter max_count_symbols visible size inittxt ?onhide ?onchange;
external hide : unit -> unit = "ml_hidekeyboard";
ENDIF;

ENDIF;
