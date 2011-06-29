(***********************************************************************)
(*                                                                     *)
(*                           HWeak                                     *)
(*                                                                     *)
(*                        Remi Vanicat                                 *)
(*                                                                     *)
(*  Copyright 2002 Rémi Vanicat                                        *)
(*  All rights reserved.  This file is distributed under the terms of  *)
(*  the GNU Library General Public License, with the special exception *)
(*  on linking described in the LICENCE file of the Objective Caml     *)
(*  distribution                                                       *)
(*                                                                     *)
(*  Most of this file is an adptation of the implentation of Weak      *)
(*  Hastable by Damien Doligez that can be found into Objective Caml   *)
(*  which is Copyright 1997 Institut National de Recherche en          *)
(*  Informatique et en Automatique and is distributed under the same   *)
(*  licence                                                            *)
(*                                                                     *)
(***********************************************************************)
module type S =
  sig
    type key;
    (** The type of the elements stored in the table. *)
    type t 'a;
    (** The type of weak hash tables from type [key] to type ['a]. 
        if etheir the key or the data of a binding is freed by the GC,
        the binding is silently droped *)
    value create : int -> t 'a;
    (** [create n] creates a new empty weak hash table, of initial
        size [n].  The table will grow as needed. *)
    value clear : t 'a -> unit;
    (** Remove all elements from the table. *)
    value add : t 'a -> key -> 'a -> unit;
    (** [add tbl key x] adds a binding of [k] to [x] in table [t]. Previous
        binding for [x] are not removed, and which binding will be find 
        by next [find] (or [merge]) is unspecified *)
    value replace : t 'a -> key -> 'a -> unit;
    (** [replace tbl key x] replace the current binding of [key] in table
        [t] by a binding from [key] to [x]. If there was no such binding
        a new one is still created. This new binding will be
        the one find by next find (and merge) *)
    value remove : t 'a -> key -> unit;
    (** [remove tbl x] removes the current binding of [x] in [tbl].
        if there is another binding of [x] in [tbl] then it became the
        current one.
        It does nothing if x is not bound in [tbl] *)
    value merge : t 'a -> key -> 'a -> 'a;
    (** [merge tbl key x] returns the current binding of [k] in [t] if any,
        or else adds a bindding of [k] to [x] in the table and return [x]. *)
    value find : t 'a -> key -> 'a;
    (** [find tbl key] returns the current binding of [k] in [t] if any,
        otherwise raise Not_found *)
    value find_all : t 'a -> key -> list 'a;
    (** [find tbl key] returns the current binding of [k] in [t] if any,
        otherwise raise Not_found *)
    value mem : t 'a -> key -> bool;
    (** [mem tbl x] checks if [x] is bound in [tbl]. *)
    value iter : (key -> 'a -> unit) -> t 'a -> unit;
    (** [iter f tbl] applies [f] to all bindings in table [tbl].
        [f] receives the key as first argument, and the associated value
        as second argument. The order in which the bindings are passed to
        [f] is unspecified. Each binding is presented exactly once
        to [f]. *)
    value fold : (key -> 'a -> 'b -> 'b) -> t 'a -> 'b -> 'b;
    (** [fold f tbl init] computes
        [(f kN dN ... (f k1 d1 init)...)],
        where [k1 ... kN] are the keys of all bindings in [tbl],
        and [d1 ... dN] are the associated values.
        The order in which the bindings are passed to
        [f] is unspecified. Each binding is presented exactly once
        to [f]. *)
    value count : t 'a -> int;
    value stats : t 'a -> (int * int * int * int * int * int);
  end;
(** some statistic function *)
module Make (H : Hashtbl.HashedType) : S with type key = H.t;

