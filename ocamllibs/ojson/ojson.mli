
type t =
    [ `Null
    | `Bool of bool
    | `Int of int
    | `Intlit of string
    | `Float of float
(*     | `Floatlit of string *)
    | `String of string
    | `Assoc of (string * t) list
    | `List of t list
    ]

val from_string :
  ?buf:Buffer.t ->
  ?fname:string ->
  ?lnum:int ->
  string -> t
  (** Read a JSON value from a string.
      @param buf use this buffer at will during parsing instead of creating
      a new one.
      @param fname data file name to be used in error messages. It does
      not have to be a real file.
      @param lnum number of the first line of input. Default is 1.
  *)

val from_channel :
  ?buf:Buffer.t ->
  ?fname:string ->
  ?lnum:int ->
  in_channel -> t
  (** Read a JSON value from a channel.
      See [from_string] for the meaning of the optional arguments. *)

val from_file :
  ?buf:Buffer.t ->
  ?fname:string ->
  ?lnum:int ->
  string -> t
  (** Read a JSON value from a file.
      See [from_string] for the meaning of the optional arguments. *)

