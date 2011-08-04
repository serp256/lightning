%{
	open Data
%}

%token <string> GLCONSTANT
%token <string> GLFUNCTION
%token <string> GLTYPE
%token <int32> NUMBER
%token <string> GLNAME
%token GLCONST
%token EOF
%token OPEN CLOSE COMMA
%start decls
%type <unit> decls
%%

decls:
	| constant decls {  qconstants := !qconstants @ [$1] }
	| func decls { qfunctions := !qfunctions @ [$1] }
	| EOF { }
	
constant:
	| GLCONSTANT NUMBER { mkconst1 $1 $2 }
	| GLCONSTANT GLCONSTANT { mkconst2 $1 $2 }	

func:
	| GLTYPE GLFUNCTION OPEN params CLOSE { mkfunc $1 $2 $4 }
	
params:
	| param { [$1] }
	| param COMMA params { [$1] @ $3 }

param:	
	| GLCONST GLTYPE GLNAME { mktype3 $2 }
	| GLTYPE GLNAME { mktype2 $1 }
	| GLTYPE  { mktype1 $1}
