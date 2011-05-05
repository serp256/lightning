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
(***********************************************************************)
module EmptyHashed =
  struct type t = < >; value equal = ( = ); value hash = Hashtbl.hash; end;
module EmptyHash = WeakHashtbl.Make EmptyHashed;
class c ['a] size =
  object constraint 'a = < .. >;
    value tbl = EmptyHash.create size;
    method virtual add : 'a -> unit;
    method add = fun x -> EmptyHash.replace tbl (x : < .. > :> < >) x;
    method virtual find : ! 'b. (< .. > as 'b) -> 'a;
    method find = fun x -> EmptyHash.find tbl (x : < .. > :> < >);
    method virtual mem : ! 'b. (< .. > as 'b) -> bool;
    method mem = fun x -> EmptyHash.mem tbl (x : < .. > :> < >);
    method virtual remove : ! 'b. (< .. > as 'b) -> unit;
    method remove = fun x -> EmptyHash.remove tbl (x : < .. > :> < >);
    method clear = fun () -> EmptyHash.clear tbl;
    method count = EmptyHash.count tbl;
  end;

