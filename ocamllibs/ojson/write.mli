(* $Id$ *)

(** {2 JSON writers} *)

val to_string :
  ?buf:Bi_outbuf.t ->
  ?len:int ->
  ?std:bool ->
  Type.json -> string
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
  out_channel -> Type.json -> unit
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
  string -> Type.json -> unit
  (** Write a compact JSON value to a file.
      See [to_string] for the role of the optional arguments. *)

val to_outbuf :
  ?std:bool ->
  Bi_outbuf.t -> Type.json -> unit
  (** Write a compact JSON value to an existing buffer.
      See [to_string] for the role of the optional argument. *)

val stream_to_string :
  ?buf:Bi_outbuf.t ->
  ?len:int ->
  ?std:bool ->
  Type.json Stream.t -> string
  (** Write a newline-separated sequence of compact one-line JSON values to
      a string.
      See [to_string] for the role of the optional arguments. *)

val stream_to_channel :
  ?buf:Bi_outbuf.t ->
  ?len:int ->
  ?std:bool ->
  out_channel -> Type.json Stream.t -> unit
  (** Write a newline-separated sequence of compact one-line JSON values to
      a channel.
      See [to_channel] for the role of the optional arguments. *)

val stream_to_file :
  ?len:int ->
  ?std:bool ->
  string -> Type.json Stream.t -> unit
  (** Write a newline-separated sequence of compact one-line JSON values to
      a file.
      See [to_string] for the role of the optional arguments. *)

val stream_to_outbuf :
  ?std:bool ->
  Bi_outbuf.t ->
  Type.json Stream.t -> unit
  (** Write a newline-separated sequence of compact one-line JSON values to
      an existing buffer.
      See [to_string] for the role of the optional arguments. *)



(**/**)
(* begin undocumented section *)

val write_null : Bi_outbuf.t -> unit -> unit
val write_bool : Bi_outbuf.t -> bool -> unit
val write_int : Bi_outbuf.t -> int -> unit
val write_float : Bi_outbuf.t -> float -> unit
val write_std_float : Bi_outbuf.t -> float -> unit
val write_float_fast : Bi_outbuf.t -> float -> unit
val write_std_float_fast : Bi_outbuf.t -> float -> unit
val write_string : Bi_outbuf.t -> string -> unit

val write_intlit : Bi_outbuf.t -> string -> unit
val write_floatlit : Bi_outbuf.t -> string -> unit
val write_stringlit : Bi_outbuf.t -> string -> unit

val write_assoc : Bi_outbuf.t -> (string * Type.json) list -> unit
val write_list : Bi_outbuf.t -> Type.json list -> unit
val write_tuple : Bi_outbuf.t -> Type.json list -> unit
val write_std_tuple : Bi_outbuf.t -> Type.json list -> unit
val write_variant : Bi_outbuf.t -> string -> Type.json option -> unit
val write_std_variant : Bi_outbuf.t -> string -> Type.json option -> unit


val write_json : Bi_outbuf.t -> Type.json -> unit
val write_std_json : Bi_outbuf.t -> Type.json -> unit

(* end undocumented section *)
(**/**)
