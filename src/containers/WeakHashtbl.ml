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
(** Weak array operations *)
open Weak;
(** Weak hash tables *)
module type S =
  sig
    type key;
    type t 'a;
    value create : int -> t 'a;
    value clear : t 'a -> unit;
    value add : t 'a -> key -> 'a -> unit;
    value replace : t 'a -> key -> 'a -> unit;
    value remove : t 'a -> key -> unit;
    value merge : t 'a -> key -> 'a -> 'a;
    value find : t 'a -> key -> 'a;
    value find_all : t 'a -> key -> list 'a;
    value mem : t 'a -> key -> bool;
    value iter : (key -> 'a -> unit) -> t 'a -> unit;
    value fold : (key -> 'a -> 'b -> 'b) -> t 'a -> 'b -> 'b;
    value count : t 'a -> int;
    value stats : t 'a -> (int * int * int * int * int * int);
  end;
module Make (H : Hashtbl.HashedType) : S with type key = H.t =
  struct
    type weak_t 'a = t 'a;
    value weak_create = create;
    value emptybucket = weak_create 0;
    type key = H.t;
    type t 'a =
      { emptybucket : weak_t 'a;
        table : mutable array ((weak_t key) * (weak_t 'a));
        totsize : mutable int; (* sum of the bucket sizes *)
        limit : mutable int
      };
    (* max ratio totsize/table length *)
    value get_index t d =
      ((H.hash d) land max_int) mod (Array.length t.table);
    value create sz =
      let sz = if sz < 7 then 7 else sz in
      let sz =
        if sz > Sys.max_array_length then Sys.max_array_length else sz in
      let em = weak_create 0
      in
        {
          emptybucket = em;
          table = Array.create sz (emptybucket, em);
          totsize = 0;
          limit = 3;
        };
    value clear t =
      (for i = 0 to (Array.length t.table) - 1 do
         t.table.(i) := (emptybucket, (t.emptybucket))
       done;
       t.totsize := 0;
       t.limit := 3);
    value fold f t init =
      let rec fold_bucket i (((b1, b2) as cpl)) accu =
        if i >= (length b1)
        then accu
        else
          match ((get b1 i), (get b2 i)) with
          [ (Some v1, Some v2) -> fold_bucket (i + 1) cpl (f v1 v2 accu)
          | _ -> fold_bucket (i + 1) cpl accu ]
      in Array.fold_right (fold_bucket 0) t.table init;
    value iter f t = fold (fun d1 d2 () -> f d1 d2) t ();
    value count t =
      let rec count_bucket i (((b1, b2) as cpl)) accu =
        if i >= (length b1)
        then accu
        else
          count_bucket (i + 1) cpl
            (accu + (if (check b1 i) && (check b2 i) then 1 else 0))
      in Array.fold_right (count_bucket 0) t.table 0;
    value next_sz n = min (((3 * n) / 2) + 3) (Sys.max_array_length - 1);

    value rec resize t =
      let oldlen = Array.length t.table in
      let newlen = next_sz oldlen
      in
        if newlen > oldlen
        then
          let newt = create newlen
          in
            (* prevent resizing of newt *)
            (* assert Array.length newt.table = newlen; *)
            (newt.limit := t.limit + 100;
             fold (fun f t () -> add newt f t) t ();
             t.table := newt.table;
             t.limit := t.limit + 2)
        else ()
    and add_aux t k e index =
      let (bucket1, bucket2) = t.table.(index) in
      let sz = length bucket1 in
      let rec loop i =
        if i >= sz
        then
          let newsz = min (sz + 3) (Sys.max_array_length - 1)
          in
            (if newsz <= sz
             then failwith "Weak.Make : hash bucket cannot grow more"
             else ();
             let newbucket1 = weak_create newsz
             and newbucket2 = weak_create newsz;
             blit bucket1 0 newbucket1 0 sz;
             blit bucket2 0 newbucket2 0 sz;
             set newbucket1 i (Some k);
             set newbucket2 i (Some e);
             t.table.(index) := (newbucket1, newbucket2);
             t.totsize := t.totsize + (newsz - sz);
             if t.totsize > (t.limit * (Array.length t.table))
             then resize t
             else ())
        else
          if (check bucket1 i) && (check bucket2 i)
          then loop (i + 1)
          else (set bucket1 i (Some k); set bucket2 i (Some e))
      in loop 0
    and add t k e = add_aux t k e (get_index t k);

    value find_or t d ifnotfound =
      let index = get_index t d in
      let (bucket1, bucket2) = t.table.(index) in
      let sz = length bucket1 in
      let rec loop i =
        if i >= sz
        then ifnotfound index
        else
          match get_copy bucket1 i with
          [ Some v when H.equal v d ->
              match get bucket2 i with [ Some v -> v | None -> loop (i + 1) ]
          | _ -> loop (i + 1) ]
      in loop 0;
    value merge t k d = find_or t k (fun index -> (add_aux t k d index; d));
    value find t d = find_or t d (fun index -> raise Not_found);
    value find_shadow t d iffound ifnotfound =
      let index = get_index t d in
      let (bucket1, bucket2) = t.table.(index) in
      let sz = length bucket1 in
      let rec loop i =
        if i >= sz
        then ifnotfound
        else
          match get_copy bucket1 i with
          [ Some v when (H.equal v d) && (check bucket2 i) ->
              iffound bucket1 bucket2 i
          | _ -> loop (i + 1) ]
      in loop 0;
    value replace t k d =
      if
        find_shadow t k
          (fun w1 w2 i -> (set w1 i (Some k); set w2 i (Some d); False)) True
      then add t k d
      else ();
    value remove t d =
      find_shadow t d (fun w1 w2 i -> (set w1 i None; set w2 i None)) ();
    value mem t d = find_shadow t d (fun _ _ i -> True) False;
    value find_all t d =
      let index = get_index t d in
      let (bucket1, bucket2) = t.table.(index) in
      let sz = length bucket1 in
      let rec loop i accu =
        if i >= sz
        then accu
        else
          match get_copy bucket1 i with
          [ Some v when H.equal v d ->
              match get bucket2 i with
              [ Some v -> loop (i + 1) [ v :: accu ]
              | None -> loop (i + 1) accu ]
          | _ -> loop (i + 1) accu ]
      in loop 0 [];
    value stats t =
      let len = Array.length t.table in
      let lens = Array.map (fun (b, _) -> length b) t.table
      in
        (Array.sort compare lens;
         let totlen = Array.fold_left ( + ) 0 lens;
         (len, (count t), totlen, (lens.(0)), (lens.(len / 2)),
          (lens.(len - 1))));
  end;
