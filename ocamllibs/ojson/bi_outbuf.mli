(* $Id: bi_outbuf.mli 57 2010-11-14 08:49:29Z mjambon $ *)

(** Output buffer *)

type t = {
  mutable o_s : string;
    (** Buffer string *)

  mutable o_max_len : int;
    (** Same as [String.length s] *)

  mutable o_len : int;
    (** Length of the data present in the buffer = current position
        in the buffer *)

  mutable o_offs : int;
    (** Length of data written and flushed out of the buffer.
        The total number of bytes written to the buffer
        is therefore [o_offs + o_len]. *)

  o_init_len : int;
    (** Initial length of the buffer *)

  o_make_room : t -> int -> unit;
  (**
    [make_room buf n] must provide space for at least the requested 
    number of bytes [n], typically by reallocating a larger buffer 
    string or by flushing the data to a channel.
    This function is only called when there is not enough space for [n]
    bytes.
  *)
}

val really_extend : t -> int -> unit
  (**
    Default make_room function: reallocate a larger buffer string.
  *)
 
val flush_to_channel : out_channel -> t -> int -> unit
  (**
    Alternate make_room function: write to an out_channel.
  *)

val create : ?make_room:(t -> int -> unit) -> int -> t
  (**
     Create a buffer.  The default [make_room] function is [really_extend].
     @param shrlen initial size of the table used to store shared values.
  *)

val contents : t -> string
  (**
    Returns the data currently in the buffer.
  *)

val create_channel_writer : ?len:int -> out_channel -> t
val flush_channel_writer : t -> unit
  (**
    Pair of convenience functions for creating a buffer that
    flushes data to an out_channel when it is full.
  *)

val extend : t -> int -> unit
  (**
    Guarantee that the buffer string has enough room for n additional bytes.
  *)

val alloc : t -> int -> int
  (**
    [alloc buf n] makes room for [n] bytes and returns the position 
    of the first byte in the buffer string [buf.s].
    It behaves as if [n] arbitrary bytes were added and it is
    the user's responsibility to set them to some meaningful values
    by accessing [buf.s] directly.
  *)

val add_string : t -> string -> unit
  (** Add a string to the buffer. *)

val add_substring : t -> string -> int -> int -> unit
  (** [add_substring dst src srcpos len] copies [len] bytes from
     string [src] to buffer [dst] starting from position [srcpos]. *)

val add_char : t -> char -> unit
  (** Add a byte to the buffer. *)

val add_char2 : t -> char -> char -> unit
  (** Add two bytes to the buffer. *)

val add_char4 : t -> char -> char -> char -> char -> unit
  (** Add four bytes to the buffer. *)

val unsafe_add_char : t -> char -> unit
  (** Add a byte to the buffer without checking that there is enough
     room for it. *)

val clear : t -> unit
  (** Remove any data present in the buffer and in the table holding
      shared objects. *)

val reset : t -> unit
  (** Remove any data present in the buffer and reset it to its original
      size.
      Remove any data present in the table holding shared objects
      and reset it to its original size. *)

