(* Convert a UTF8 Line to Farsi *)
value convert_line: string -> string;

(* Convert UTF8 Text to Farsi line by line *)
value convert : string -> string;

(* *)
value remap_char_at_index: UTF8.t -> int -> UChar.t;

(* *)
value isFarsi: UChar.t -> bool; 


