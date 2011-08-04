type token =
  | GLCONSTANT of (string)
  | GLFUNCTION of (string)
  | GLTYPE of (string)
  | NUMBER of (int32)
  | GLNAME of (string)
  | GLCONST
  | EOF
  | OPEN
  | CLOSE
  | COMMA

val decls :
  (Lexing.lexbuf  -> token) -> Lexing.lexbuf -> unit
