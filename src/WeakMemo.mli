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
(*  The original Idea come from the GUtil.memo class of the lablgtk    *)
(*  library                                                            *)
(*                                                                     *)
(***********************************************************************)
(** The memo class provides an easy way to remember the real class of
  an object.
  
  This module contain the [Weak_memo.c] class that contain object that 
  can be recover latter from the same object with a different type. An
  object that is into a [Weak_memo.c] object is not prevented from
  recolection by the Gc. *)
(** The memo class.

  [new Weak_memo.c size] create a new memo object with an original size
  of [size]. It will grow as needed. *)
class c ['a] :
  [ int ] ->
    object
      constraint 'a = < .. >;
      method add : 'a -> unit;
      method find : < .. > -> 'a;
      method mem : < .. > -> bool;
      method remove : < .. > -> unit;
      method clear : unit -> unit;
      method count : int;
    end;

