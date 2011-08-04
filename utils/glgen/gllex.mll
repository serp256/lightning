{
	open Printf
	open Glparse
	let line = ref 1
}

let glconst =  'c''o''n''s''t'
let word = ['a'-'z''A'-'Z'] ['a'-'z''A'-'Z''0'-'9''_']*
let hex = '0''x' ['a'-'f''A'-'F''0'-'9']+
let decimal = ['0'-'9']+
let number = hex | decimal
let ws = ['\t'' ']
let glfunc = 'g''l' word+ 
let glconstant = 'G''L''_'['a'-'z''A'-'Z''0'-'9''_']*
let gltype = 'G''L' word+ ['*']* | 'v''o''i''d' ['*']* 
let glpname = ['a'-'z']+ ['a'-'z''A'-'Z']* ['a'-'z''A'-'Z''0'-'9']*


rule token = parse
	| '\n' { incr line; token lexbuf }
	| ws+  {  token lexbuf }
	| '-''-'[^'\n']* {  token lexbuf } 
	| glconst  {   GLCONST }
	| glconstant  as glc 	{  GLCONSTANT (glc) }
	| glfunc as glf { GLFUNCTION glf }
	| gltype as glt { GLTYPE glt }
	| glpname  as name {  GLNAME name }
	| '('  { OPEN }
	| ')' { CLOSE }
	| ',' { COMMA }
	| number as n 	{ NUMBER (Int32.of_string n) }
	| eof { EOF }
	| _ { failwith((Lexing.lexeme lexbuf) ^ 
        ": Error at line " ^ string_of_int !line)}
{

}
