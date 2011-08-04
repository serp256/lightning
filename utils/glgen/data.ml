open Printf
open Int32


type vartype = VOID | VARIABLE | POINTER | DOUBLEPOINTER

type glconst = NumericalValue of int | Reference of string

type glconstant = 
	{
		cname : string;
		cval: glconst
	}

type glparameter =
	{
		pname: string;
		pconst: bool;
		pptr: vartype
	}

type glfunction =
	{
		fname : string;
		freturn: glparameter;
		fparams: glparameter list
	}	

let classify_ptr s =
	let l = (String.length s) in
	if l > 2 then
		if (s.[l-1] = '*') then
			if (s.[l-2] = '*') then
				DOUBLEPOINTER
			else
				POINTER
		else
			if (s = "GLvoid" || s = "void") then
				VOID
			else
				VARIABLE	
	else
		VARIABLE


let mkconst1 name number =
	{ cname = name; cval = NumericalValue (to_int number)}	

let mkconst2 name reference =
	{ cname = name; cval = Reference reference}	

let mktype1 name =
	{ pname = name; pconst = true; pptr = classify_ptr name } 

let mktype2 name =
	{ pname = name; pconst = false; pptr = classify_ptr name } 

let mktype3 name =
	{ pname = name; pconst = true; pptr = classify_ptr name } 

let mkfunc r f p =
	{
	  fname = f;
	  freturn = mktype1 r;
	  fparams = p
	}	

let pvartype = function
	| VOID -> "void"
	| VARIABLE -> "variable"
	| POINTER -> "pointer"
	| DOUBLEPOINTER -> "doublepointer"

let pconst p =
	let v =
	match p.cval with
	| NumericalValue r -> sprintf "%d" r
	| Reference r -> sprintf "%s" r
	in
	printf "%s %s\n" p.cname v

let pparam p =
	printf "%s (%s) " p.pname (pvartype p.pptr)

let pfunc p =
	pparam p.freturn;	
	printf "%s " p.fname ;
	List.iter pparam p.fparams;
	printf "\n"


let qconstants = ref []

let qfunctions = ref []

(* Transform a C type into the requisite ML FFI type *)
let val_translate t s =
	let p = sprintf in
	match t with
		| "GLboolean"  	-> p "Val_bool(%s)" s
		| "void"     	-> p "Val_unit(%s)" s
		| "GLvoid"     	-> p "Val_unit(%s)" s
		| "GLuint"     	-> p "Val_int(%s)" s
		| "GLint"      	-> p "Val_int(%s)" s
		| "GLintptr"   	-> p "Val_int(%s)" s
		| "GLenum"     	-> p "Val_int(%s)" s
		| "GLsizei"    	-> p "Val_int(%s)" s
		| "GLsizeiptr" 	-> p "Val_int(%s)" s
		| "GLfloat"    	-> p "Val_double(%s)" s
		| "GLdouble"   	-> p "Val_double(%s)" s
		| "GLchar"     	-> p "Val_int(%s)" s
		| "GLclampf"   	-> p "Val_double(%s)" s
		| "GLclampd"   	-> p "Val_double(%s)" s
		| "GLshort"    	-> p "Val_int(%s)" s
		| "GLubyte"   	-> p "Val_int(%s)" s
		| "GLbitfield"	-> p "Val_int(%s)" s
		| "GLushort"   	-> p "Val_int(%s)" s
		| "GLbyte"     	-> p "Val_int(%s)" s
		| "void*"		-> p "(value)(%s)" s
		| "GLvoid*"		-> p "(value)(%s)" s
		| "GLstring"	-> p "caml_copy_string(%s)" s
		| _            	-> "unknown"

(* Extract the C value from an ML FFI value *)
let translate_val t =
	match t with
	| "GLboolean"  	-> "Bool_val"
	| "void"    	-> ""
	| "GLvoid"    	-> ""
	| "GLuint"     	-> "Int_val"
	| "GLint"      	-> "Int_val"
	| "GLintptr"   	-> "Int_val"
	| "GLenum"     	-> "Int_val"
	| "GLsizei"   	-> "Int_val"
	| "GLsizeiptr" 	-> "Int_val"
	| "GLfloat"    	-> "Double_val"
	| "GLdouble"   	-> "Double_val"
	| "GLchar"     	-> "Int_val"
	| "GLclampf"   	-> "Double_val"
	| "GLclampd"   	-> "Double_val"
	| "GLshort"    	-> "Int_val"
	| "GLubyte"    	-> "Int_val"
	| "GLbitfield" 	-> "Int_val"
	| "GLushort"   	-> "Int_val"
	| "GLbyte"     	-> "Int_val"
	| "GLstring"   	-> "String_val"
	| _            	-> "unknown"

(* Translate an ML array to a C pointer *)
let translate_ptr t s =
	let p = sprintf in
	match t with
(*
	| "void*" 		-> p "(void *)((Tag_val(%s) == String_tag)? (String_val(%s)) : (Data_bigarray_val(%s)))" s s s
*)
	| "GLvoid*" 	-> p "(GLvoid *)(Is_long(%s) ? (void*)Long_val(%s) : ((Tag_val(%s) == String_tag)? (String_val(%s)) : (Data_bigarray_val(%s))))" s s s s s
	| "GLboolean*" 	-> p "Data_bigarray_val(%s)" s
	| "GLuint*"    	-> p "Data_bigarray_val(%s)" s
	| "GLint*"     	-> p "Data_bigarray_val(%s)" s
	| "GLintptr*"  	-> p "Data_bigarray_val(%s)" s
	| "GLenum*"    	-> p "Data_bigarray_val(%s)" s
	| "GLsizei*"   	-> p "Data_bigarray_val(%s)" s
	| "GLsizeiptr*"	-> p "Data_bigarray_val(%s)" s
	| "GLfloat*"   	-> p "Data_bigarray_val(%s)" s
	| "GLdouble*"  	-> 
		p "(Tag_val(%s) == Double_array_tag)? (double *)%s: Data_bigarray_val(%s)" s s s
	| "GLchar*"    	-> p "String_val(%s)" s
	| "GLclampf*"  	-> p "Data_bigarray_val(%s)" s
	| "GLclampd*"  	-> 
		p "(Tag_val(%s) == Double_array_tag)? (double *)%s: Data_bigarray_val(%s)" s s s
	| "GLshort*"   	-> p "Data_bigarray_val(%s)" s
	| "GLubyte*"   	-> p "Data_bigarray_val(%s)" s
	| "GLbitfield*"	-> p "Data_bigarray_val(%s)" s
	| "GLushort*"  	-> p "Data_bigarray_val(%s)" s
	| "GLbyte*"    	-> p "Data_bigarray_val(%s)" s
	| "GLstring*"  	-> p "(GLstring *)(%s)" s 
	| _ -> "unknown"

(* Translate an ML array to C double pointer *)
let translate_dblptr t s =
	let p = sprintf in
	match t with
	| "void**" 		-> p "Data_bigarray_val(%s)" s
	| "GLvoid**" 	-> p "Data_bigarray_val(%s)" s
	| "GLboolean**"	-> p "Data_bigarray_val(%s)" s
	| "GLchar**" 	-> p "(GLchar** )(%s)" s
	| _ -> "unknown"


(* Translate between native C and native ML types *)
let translate_ml t =
	match t with
		| "GLboolean"  	-> "bool"
		| "void"    	-> "unit"
		| "GLvoid"    	-> "unit"
		| "GLuint"     	-> "int"
		| "GLint"      	-> "int"
		| "GLintptr"   	-> "int"
		| "GLenum"     	-> "int"
		| "GLsizei"   	-> "int"
		| "GLsizeiptr" 	-> "int"
		| "GLfloat"    	-> "float"
		| "GLdouble"   	-> "float"
		| "GLchar"     	-> "int"
		| "GLclampf"   	-> "float"
		| "GLclampd"   	-> "float"
		| "GLshort"    	-> "int"
		| "GLubyte"    	-> "int"
		| "GLbitfield" 	-> "int"
		| "GLushort"   	-> "int"
		| "GLbyte"     	-> "int"
		| "GLstring"	-> "string"
		| "GLbyte*"    	-> "byte_array"
		| "GLubyte*"    -> "ubyte_array"
		| "void*"    	-> "'a"
		| "GLvoid*"    	-> "'a"
		| "GLvoid**"   	-> "'a"
		| "GLuint*"    	-> "word_array"
		| "GLint*"    	-> "word_array"
		| "GLfloat*"   	-> "float_array"
		| "GLdouble*"  	-> "float array"
		| "GLchar*"    	-> "string"
		| "GLchar**"   	-> "string array"
		| "GLclampf*"  	-> "float_array"
		| "GLclampd*"  	-> "double_array"
		| "GLshort*"   	-> "short_array"
		| "GLushort*"  	-> "ushort_array"
		| "GLboolean*"  -> "word_array"
		| "GLboolean**" -> "word_matrix"
		| "GLsizei*"   	-> "word_array"
		| "GLenum*"    	-> "word_array"
		| _            	-> "unknown"

