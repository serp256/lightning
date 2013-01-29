
type json =
    [ `Null
    | `Bool of bool
    | `Int of int
    | `Intlit of string
    | `Float of float
(*     | `Floatlit of string *)
    | `String of string
    | `Assoc of (string * json) list
    | `List of json list
    ]


module Browse : sig 
  val null: json -> unit
  val string: json -> string
  val bool: json -> bool
  val int: json -> int
  val float: json -> float
  val array: json -> json list
  val list: (json -> 'a) -> json -> 'a list 
  val assoc: json -> (string * json) list 
  val assoc_field: (json -> 'a) -> string -> json -> 'a
  val assoc_field_opt: (json -> 'a) -> string -> json -> 'a option
  val assoc_table: json -> (string,json) Hashtbl.t
  val assoc_field_table: (json -> 'a) -> string -> (string,json) Hashtbl.t  -> 'a

end

module Build : sig
  val null: json
  val bool: bool -> json
  val int : int -> json
  val intlit : string -> json
  val string : string -> json
  val float : float -> json
  val assoc : (string * json) list -> json
  val list : ('a -> json) -> 'a list -> json
  val array : json list -> json
  val opt: ('a -> json) -> 'a option -> json
end

val from_string :
  ?buf:Bi_outbuf.t ->
  ?fname:string ->
  ?lnum:int ->
  string -> json
  (** Read a JSON value from a string.
      @param buf use this buffer at will during parsing instead of creating
      a new one.
      @param fname data file name to be used in error messages. It does
      not have to be a real file.
      @param lnum number of the first line of input. Default is 1.
  *)

val from_channel :
  ?buf:Bi_outbuf.t ->
  ?fname:string ->
  ?lnum:int ->
  in_channel -> json
  (** Read a JSON value from a channel.
      See [from_string] for the meaning of the optional arguments. *)

val from_file :
  ?buf:Bi_outbuf.t ->
  ?fname:string ->
  ?lnum:int ->
  string -> json
  (** Read a JSON value from a file.
      See [from_string] for the meaning of the optional arguments. *)

val from_function :
  ?buf:Bi_outbuf.t ->
  ?fname:string ->
  ?lnum:int ->
  (string -> int -> int) ->json


val to_string :
  ?buf:Bi_outbuf.t ->
  ?len:int ->
  ?std:bool ->
  json -> string
  (** Write a compact JSON value to a string.
      @param buf allows to reuse an existing buffer created with 
      [Bi_outbuf.create]. The buffer is cleared of all contents
      before starting and right before returning.
      @param len initial length of the output buffer.
      @param std use only standard JSON syntax,
      i.e. convert tuples and variants into standard JSON (if applicable),
      refuse to print NaN and infinities,
      require the root node to be either an object or an array.
      Default is [false].
  *)

val to_channel :
  ?buf:Bi_outbuf.t ->
  ?len:int ->
  ?std:bool ->
  out_channel -> json -> unit
  (** Write a compact JSON value to a channel.
      @param buf allows to reuse an existing buffer created with 
      [Bi_outbuf.create_channel_writer] on the same channel.
      [buf] is flushed right
      before [to_channel] returns but the [out_channel] is
      not flushed automatically.

      See [to_string] for the role of the other optional arguments. *)

val to_file :
  ?len:int ->
  ?std:bool ->
  string -> json -> unit
  (** Write a compact JSON value to a file.
      See [to_string] for the role of the optional arguments. *)

  

