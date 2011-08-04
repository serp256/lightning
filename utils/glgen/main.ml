open Printf
open Data

let dynload = ref false

(*      Reads in a (binary) file and returns the contents in a string *)
let read_file f =
	let ic = open_in_bin f in
	let len = in_channel_length ic in
	let s = String.create len in
	let _ = really_input ic s 0 len in
	s

(* Write string s to file f *)
let write_file s f =
	let oc = open_out f in
	output_string oc s;
	close_out oc

(* Flatten list of strings with separator *)
let rec flatten l sep =
	match l with
		| [] -> ""
		| [x] -> x
		| h :: t -> h ^ (sep) ^ (flatten t sep)

(* -------------------------------- C function stubs ---------------------------------*)

(* Create stub parameter declarations *)
let make_arg_list start nparams prefix =
	flatten 
		(Array.to_list 
			(Array.init nparams 
				(fun i -> sprintf "%s%d" prefix (i + start)))) ", "

(* Create CAMLparam declarations *)	
let make_caml_params f =
	let nparams = List.length f.fparams in
	let n = nparams / 5 and k = nparams mod 5 in
	if n = 0 then
		(sprintf "\tCAMLparam%d(" k) ^
		(make_arg_list 0 k "v") ^
		(");\n")
	else
		let s i = 
			if (i = 0) then 
				"\tCAMLparam5(" 
			else 
				"\tCAMLxparam5(" 
		in
		(flatten 
			(Array.to_list 
				(Array.init n 
					(fun i -> (s i) ^ (make_arg_list (i*5) 5 "v") ^ ")"))) ";\n") ^
		if k = 0 then ";\n" else
		(sprintf ";\n\tCAMLxparam%d(" k) ^
		(make_arg_list (nparams - k) k "v") ^
		(");\n")

(* Create CAMLlocal declaration for return variable *)
let make_caml_local f =
	if (f.freturn.pptr = VOID) then
		""
	else
		"\tCAMLlocal1(result);\n"
		
(* Make C stub return type *)	
let make_stub_return f =
	if (f.freturn.pptr = VOID) then
		"\tCAMLreturn(Val_unit);\n"
	else
		(sprintf "\tresult = %s;\n" (val_translate f.freturn.pname "ret")) ^
		(sprintf "\tCAMLreturn(result);\n") 

(* Make C stub code typedef declarations for a given function *)
let make_typedef_decl f =
	let arglist = flatten (List.map (fun i -> i.pname) f.fparams) ", " in
	(sprintf "DECLARE_FUNCTION(%s,(%s),%s);\n" f.fname arglist f.freturn.pname) 

(* Make C stub function call *)
let make_func_call f =
	let l = (List.length f.fparams) in
	let args = 
		if (l = 1) && (let h = List.hd f.fparams in (h.pptr = VOID)) then
			""
		else	 
			make_arg_list 0 l "lv" 
	in
	let return = 
	if (f.freturn.pptr = VOID) then "" else	"ret = "
	in
  match !dynload with
  | true -> (sprintf "\tLOAD_FUNCTION(%s);\n"  f.fname) ^ (sprintf "\t%s( *stub_%s)(%s);\n"  return f.fname args)	
  | false -> sprintf "\t%s%s(%s);\n" return f.fname args

(* Load ML value into C type *)
let ml_var_to_c i p =
	match p.pptr with
	| VOID 		-> ""
	| VARIABLE 	->  sprintf "\t%s lv%d = %s(v%d);\n" p.pname i (translate_val p.pname) i 
	| POINTER 	->  sprintf "\t%s lv%d = %s;\n" p.pname i (translate_ptr p.pname (sprintf "v%d" i))
	| DOUBLEPOINTER -> sprintf "\t%s lv%d = %s;\n" p.pname i (translate_dblptr p.pname (sprintf "v%d" i))

(* Convert all parameters from ML to C *)
let make_param_decl f = 
	let vars =
	flatten (Array.to_list (Array.mapi 
		(fun i s -> ml_var_to_c i s) (Array.of_list f.fparams))) ""
	and ret = if (f.freturn.pptr = VOID) then "" else (sprintf 	"\t%s ret;\n" f.freturn.pname)
	in
	vars ^ ret

(* Make byte stub functions *)
let make_byte_decl f =
	let n = (List.length f.fparams) in
	if n < 6 then
		""
	else
		let	params = 	
		flatten 
			(Array.to_list 
				(Array.init n 
					(fun i -> sprintf "argv[%d]" i))) ", " 
		in
    match f.freturn.pptr with
    | VOID -> 
      (sprintf "\nvoid glstub_%s_byte(value * argv, int n)\n{\n" f.fname) ^
      (sprintf "\tglstub_%s(%s);\n}\n" f.fname params)
    | _ -> 
      (sprintf "\nvalue glstub_%s_byte(value * argv, int n)\n{\n" f.fname) ^
      (sprintf "\treturn glstub_%s(%s);\n}\n" f.fname params)


(* Make C stub function declaration for a given function *)
let make_func_decl f = 
	let arglist = make_arg_list 0 (List.length f.fparams) "value v" in
  let res = 
    (match f.freturn.pptr with
    | VOID -> 
        (sprintf "void glstub_%s(%s)\n" f.fname arglist) ^
        "{\n" ^
        (make_param_decl f) ^
        (make_func_call f) ^
        "}\n" ^
        (make_byte_decl f)
    | _ -> 
      (sprintf "value glstub_%s(%s)\n" f.fname arglist) ^
      "{\n" ^
      (make_caml_params f) ^
      (make_caml_local f) ^ 
      (make_param_decl f) ^
      (make_func_call f) ^
      (make_stub_return f) ^
      "}\n"  ^
      (make_byte_decl f)
    )
  in
  match !dynload with
  | true -> (make_typedef_decl f) ^ res
  | false -> res



(* Create C stub file *)
let create_c_stub_file () =
	let header = read_file "data/header.c" in
	let src =
	List.fold_left (fun i f -> i ^ (sprintf "%s\n" (make_func_decl f))) header !qfunctions
	in
	write_file src "output/gl_stub.c"


(* -------------------------------- ML code ---------------------------------*)

(* Create GL constant declarations *)
let make_gl_constant_decls () =
	let glf = function
		| NumericalValue d -> sprintf "0x%08X" d
		| Reference s -> s
	in	
	List.fold_left 
		(fun i f -> 
			i ^ (String.lowercase (sprintf "let %s = %s\n" f.cname (glf f.cval)))) "" !qconstants

(* Is an argument a bigarray argument? *)
let is_bigarray p =
	let s = (translate_ml p.pname) in
	if String.contains s '_' then 
		let i = String.index s '_' in
		if s.[i+1] = 'a' then
			true
		else
			false	 
	else 
		false

(* Related: Does a function contain bigarray arguments? *)
let has_pointer_args f =
	List.fold_left (fun i p -> i || (is_bigarray p)) false f.fparams
	

(* Create normal GL function declarations *)
let make_normal_ml_func_decl f = 
	let parms = flatten (List.map (fun i -> translate_ml i.pname) f.fparams) " -> "
	and return = translate_ml f.freturn.pname
	and byte = if (List.length f.fparams) < 6 then 
		(sprintf "glstub_%s" f.fname)
	else
		(sprintf "glstub_%s_byte" f.fname)
	in
  let res = sprintf "external %s: %s -> %s = \"%s\" \"glstub_%s\"\n" f.fname parms return byte f.fname in
  match f.freturn.pptr with
  | VOID -> res ^ " \"noalloc\""
  | _ -> res


(* Create extended GL function declarations (argument preprocessing) *)
let make_ext_ml_func_decl f = 
	let new_arg i p =
		let arg = sprintf "p%d" i in	
		let mlarg = (translate_ml p.pname) in
		if (is_bigarray p) then
			if (p.pname = "GLboolean*") then
				"let n" ^ arg ^ " = " ^ "to_" ^ mlarg ^ " (bool_to_int_array " ^ arg ^ ") in\n"
			else
				"let n" ^ arg ^ " = " ^ "to_" ^ mlarg ^ " " ^ arg ^ " in\n"
		else
			""
	in		
	let ret_arg i p =
		let arg = sprintf "p%d" i in	
		let mlarg = (translate_ml p.pname) in
		if ((is_bigarray p) && (p.pconst = false)) then
			if (p.pname = "GLboolean*") then
				("let b" ^ arg ^ " =  Array.create (Bigarray.Array1.dim n" ^ arg ^ ") 0 in\n" ^
				 "let _ = copy_" ^ mlarg ^ " n" ^ arg ^ " b" ^ arg ^ " in\n" ^
				 "let _ = copy_to_bool_array b" ^ arg ^ " " ^ arg ^ " in\n")
			else	
				("let _ = copy_" ^ mlarg ^ " n" ^ arg ^ " " ^ arg ^ " in\n")
		else
			""
	in		
	let call_params i p =
		let arg = sprintf "p%d" i in	
		if (is_bigarray p) then
			"n" ^ arg
		else
			arg
	in	
	let fparams = Array.of_list f.fparams in
	let flatten a b = flatten (Array.to_list a) b in	
	let arglist = flatten (Array.mapi (fun i p -> sprintf "p%d" i) fparams) " " in
	let parms = flatten (Array.mapi (fun i p -> new_arg i p) fparams) "" in
	let retparms = flatten (Array.mapi (fun i p -> ret_arg i p) fparams) "" in
	let callparams = flatten (Array.mapi (fun i p -> call_params i p) fparams) " " 
	in
	"\n" ^ (make_normal_ml_func_decl f) ^ 
	(sprintf "let %s %s =\n" f.fname arglist) ^
	parms ^ 
	(sprintf "let r = %s %s in\n" f.fname callparams) ^
	retparms ^ "r\n\n"
	
	
	

	
(* Create GL function declarations *)
let make_ml_func_decls () =
	let mk f =
		if has_pointer_args f then 
			make_ext_ml_func_decl f 
		else
			make_normal_ml_func_decl f
	in		
	List.fold_left (fun i f -> i ^ (mk f)) "" !qfunctions



(* Create ML stub file *)
let create_ml_stub_file () =
	let header = read_file "data/header.ml" in
	let	decls = make_gl_constant_decls () in
	let funcs = make_ml_func_decls () in
	let src = header ^ decls ^ funcs in
	write_file src "output/glcaml.ml"


(* ------------------------------- statistics ----------------------------------*)

let count_funcs qlist =
	printf "Total # of functions: %d\n\n" (List.length qlist)


let contains a b =
	if ((String.length b) > (String.length a)) then
		false
	else	
		if (String.sub a 0 (String.length b)) = b then
			true
		else
			false

let filter_byte_short_float qlist = 
	List.filter 
	(
	fun f ->
		List.fold_left 
		(
		fun i p ->
			if  (contains p.pname "GLbyte")   ||
				(contains p.pname "GLubyte")  ||
				(contains p.pname "GLshort")  ||
				(contains p.pname "GLushort") ||
				(contains p.pname "GLfloat")  ||
				(contains p.pname "GLclampf")
			then
				false
			else
				true
		) 		
		true
		f.fparams
	) 
	qlist 

let count_byte_short_float qlist =
	let l = 
	List.filter 
	(
	fun f ->
		List.fold_left 
		(
		fun i p ->
			if  (contains p.pname "GLbyte")   ||
				(contains p.pname "GLubyte")  ||
				(contains p.pname "GLshort")  ||
				(contains p.pname "GLushort") ||
				(contains p.pname "GLfloat")  ||
				(contains p.pname "GLclampf")
			then
				true
			else
				false
		) 		
		false
		f.fparams
	) 
	qlist in
	printf "# of functions with (byte, short, float arguments) = %d\n\n" (List.length l)
	
let count_pointer_args qlist =
	let l = 	
	List.filter 
	(
	fun f ->
		List.fold_left 
		(
		fun i p ->
			if  ((p.pptr = POINTER) || (p.pptr = DOUBLEPOINTER))
			then
				true
			else
				false
		) 		
		false
		f.fparams
	) 
	qlist in
	printf "# of functions with pointer arguments = %d\n\n" (List.length l)

let count_const_pointer_args qlist =
	let l = 	
	List.filter 
	(
	fun f ->
		List.fold_left 
		(
		fun i p ->
			if  ((p.pptr = POINTER) || (p.pptr = DOUBLEPOINTER))
			then
				if p.pconst = true then
					(printf "CONST %s\n" f.fname; true)
				else(
					printf "%s\n" f.fname;
					false)	
			else
				false
		) 		
		false
		f.fparams
	) 
	qlist in
	printf "# of functions with const pointer arguments = %d\n\n" (List.length l)

let count_return_pointer_args qlist =
	let l = 	
	List.filter 
	(fun f -> 
		if (f.freturn.pptr = POINTER) || (f.freturn.pptr = DOUBLEPOINTER) then
			(printf "%s\n" f.fname; true)
		else	
			false
	) qlist in
	printf "# of functions that return pointers = %d\n\n" (List.length l)


let get_statistics () =
	print_string "\nStatistics\n---------------\n\n";
	count_funcs !qfunctions;
	count_byte_short_float !qfunctions;
	let l = filter_byte_short_float !qfunctions in
	print_string "Filtering out bytes, shorts and floats ...\n\n" ;
	count_funcs l;
	count_pointer_args l;
	count_const_pointer_args l;
	count_return_pointer_args l


(* ------------------------------- main ----------------------------------*)


(* Parse file f and split in constants and functions *)
let parse f =
  let lexbuf = Lexing.from_channel (open_in f) in
  Glparse.decls Gllex.token lexbuf

let main fname = 
  parse fname;
  qconstants := List.rev !qconstants;
  qfunctions := List.sort (fun a b -> String.compare a.fname b.fname) !qfunctions;
  create_ml_stub_file ();
  create_c_stub_file ()

let () = Arg.parse [ ("-dynload",Arg.Set dynload,"") ] main ""
