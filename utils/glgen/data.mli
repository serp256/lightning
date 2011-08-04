type vartype = VOID | VARIABLE | POINTER | DOUBLEPOINTER
type glconst = NumericalValue of int | Reference of string
type glconstant = { cname : string; cval : glconst; }
type glparameter = { pname : string; pconst : bool; pptr : vartype; }
type glfunction = {
  fname : string;
  freturn : glparameter;
  fparams : glparameter list;
}
val classify_ptr : string -> vartype
val mkconst1 : string -> int32 -> glconstant
val mkconst2 : string -> string -> glconstant
val mktype1 : string -> glparameter
val mktype2 : string -> glparameter
val mktype3 : string -> glparameter
val mkfunc : string -> string -> glparameter list -> glfunction
val pvartype : vartype -> string
val pconst : glconstant -> unit
val pparam : glparameter -> unit
val pfunc : glfunction -> unit
val qconstants : glconstant list ref
val qfunctions : glfunction list ref
val val_translate : string -> string -> string
val translate_val : string -> string
val translate_ptr : string -> string -> string
val translate_dblptr : string -> string -> string
val translate_ml : string -> string
