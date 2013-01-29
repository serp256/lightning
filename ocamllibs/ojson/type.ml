(* $Id: type.ml 25 2010-05-17 07:27:39Z mjambon $ *)

(** {3 Type of the JSON tree} *)

type json =
    [
    | `Null
    | `Bool of bool
    | `Int of int
    | `Intlit of string
    | `Float of float
(*     | `Floatlit of string *)
    | `String of string
    | `Assoc of (string * json) list
    | `List of json list
    ]

exception OJson_error of string 

module Build = struct

let null = `Null
let bool x = `Bool x
let int x = `Int x
let intlit x = `Intlit x
let string x = `String x
let float x = `Float x
let assoc x = `Assoc x
let list f x = `List (List.map f x)
let array l = `List l 

let opt f v = 
  match v with 
    Some x -> f x
  | None -> `Null


end

module Browse = struct
  
let json_error s = raise (OJson_error s)

let type_mismatch s  = json_error (Printf.sprintf "type mismatch %s " s)

let null = function
    `Null -> ()
  | x -> type_mismatch "null"

let string = function 
    `String s -> s
  | x -> type_mismatch "string"

let bool = function
    `Bool x -> x
  | x -> type_mismatch "bool"

let int = function
    `Int i -> i
  | x -> type_mismatch "int"

let float = function 
    `Float f -> f
  | x -> type_mismatch "float"

let array = function
    `List l -> l
  | x -> type_mismatch "list"

let list f x = List.map f (array x)

let assoc = function 
    `Assoc x -> x
  | x -> type_mismatch "assoc"

let assoc_field convert field = function
    `Assoc x -> 
      let v = List.assoc field x in
      convert v
  | x -> type_mismatch "assoc"

let assoc_field_opt convert field json = 
  try 
    Some (assoc_field convert field json)
  with Not_found -> None

let assoc_table = function
    `Assoc x ->
      let h = Hashtbl.create 0 in
      List.iter (fun (k,v) -> Hashtbl.add h k v) x;
      h
  | x -> type_mismatch "assoc"

let assoc_field_table convert field table = 
  convert (Hashtbl.find table field)

end

(**
All possible cases defined in Yojson:
- `Null: JSON null
- `Bool of bool: JSON boolean
- `Int of int: JSON number without decimal point or exponent.
- `Intlit of string: JSON number without decimal point or exponent,
	    preserved as a string.
- `Float of float: JSON number, Infinity, -Infinity or NaN.
- `Floatlit of string: JSON number, Infinity, -Infinity or NaN,
	    preserved as a string.
- `String of string: JSON string. Bytes in the range 128-255 are preserved
	    as-is without encoding validation for both reading
	    and writing.
- `Stringlit of string: JSON string literal including the double quotes.
- `Assoc of (string * json) list: JSON object.
- `List of json list: JSON array.
- `Tuple of json list: Tuple (non-standard extension of JSON).
	    Syntax: [("abc", 123)].
- `Variant of (string * json option): Variant (non-standard extension of JSON).
	    Syntax: [<"Foo">] or [<"Bar":123>].
*)
(*
  Note to adventurers: ocamldoc does not support inline comments
  on each polymorphic variant, and cppo doesn't allow to concatenate
  comments, so it would be complicated to document only the
  cases that are preserved by cppo in the type definition.
*)
