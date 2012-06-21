(* $Id: fl_metatoken.ml 49 2003-12-30 09:48:02Z gerd $
 * ----------------------------------------------------------------------
 *
 *)


type token =
    Name of string
  | LParen 
  | RParen
  | Equal
  | PlusEqual
  | Minus
  | Comma
  | String of string
  | Space
  | Newline
  | Eof
  | Unknown
;;
