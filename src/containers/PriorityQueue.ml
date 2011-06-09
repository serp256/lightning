(* base/lib/priorityQueue.ml

   Copyright (C) 2008 Holger Arnold 

   This file may be redistributed and modified under the terms of the 
   GNU LGPL version 2.1.  See the LICENSE file for details.  
*)
module type OrderedType = sig
  type t;
  value order: t -> t -> bool;
end;

module type S =
  sig
    type elt;
    type t;
    value make : unit -> t;
    value length : t -> int;
    value is_empty : t -> bool;
    value add : t -> elt -> unit;
    value mem : t -> elt -> bool;
    value first : t -> elt;
    value remove_first : t -> unit;
    value remove : t -> elt -> unit;
    value remove_if: (elt -> bool) -> t -> unit;
    value clear : t -> unit;
    value reorder_up : t -> elt -> unit;
    value reorder_down : t -> elt -> unit;
    value is_heap: t -> bool;
    value fold: ('a -> elt -> 'a) -> 'a -> t -> 'a;
  end;

module Make(P:OrderedType): S  with type elt = P.t = struct

type elt = P.t;

type queue =
  { 
    heap : DynArray.t P.t; 
    indices : Hashtbl.t P.t int 
  };

type t = queue;

value make () =
  {
    heap = DynArray.make 0; 
    indices = Hashtbl.create 32;
  };

value length h = DynArray.length h.heap;
value is_empty h = (length h) = 0;
value get h = DynArray.unsafe_get h.heap;
value set h i x = (DynArray.unsafe_set h.heap i x; Hashtbl.replace h.indices x i);
value mem h x = Hashtbl.mem h.indices x;

value parent i = (i - 1) / 2;

value left i = (2 * i) + 1;
value right i = (2 * i) + 2;

value has_left h i = (left i) < (length h);
value has_right h i = (right i) < (length h);

value is_heap h =
  let ord = P.order in
  let rec is_heap i =
    ((not (has_left h i)) ||
       ((ord (get h i) (get h (left i))) && (is_heap (left i))))
      &&
      ((not (has_right h i)) ||
         ((ord (get h i) (get h (right i))) && (is_heap (right i))))
  in is_heap 0;

value down_heap h i =
  let x = get h i in
  let ord = P.order in
  let rec down_heap j =
    if has_left h j
    then
      let l = left j in
      let r = right j in
      let k =
        if (has_right h j) && (not (ord (get h l) (get h r))) then r else l in
      let y = get h k
      in if ord x y then set h j x else (set h j y; down_heap k)
    else if j <> i then set h j x else ()
  in down_heap i;

value up_heap h i =
  let x = get h i in
  let ord = P.order in
  let rec up_heap j =
    let k = parent j in
    let y = get h k
    in if (j = 0) || (ord y x) then set h j x else (set h j y; up_heap k)
  in up_heap i;

value make_heap h =
  for i = ((length h) / 2) - 1 downto 0 do down_heap h i done;

value first h =
  if is_empty h then failwith "PriorityQueue.first: empty queue" else get h 0;

value add h x =
  let i = length h in 
  (
    DynArray.add h.heap x; 
    Hashtbl.add h.indices x i; 
    up_heap h i
  );

value fold f a t = (* FIXME *)
  DynArray.fold_left f a t.heap;

value remove_index h i =
  let x = get h i
  and y = get h ((length h) - 1) in
  (
    set h i y;
    DynArray.delete_last h.heap;
    Hashtbl.remove h.indices x;
    down_heap h i
  );

value remove_first h =
  if is_empty h
  then failwith "PriorityQueue.first: empty queue"
  else remove_index h 0;

value remove h x =
  try remove_index h (Hashtbl.find h.indices x) with [ Not_found -> () ];


value remove_if f h = 
  try
    let x = DynArray.index_of f h.heap in
    remove_index h x;
  with [ Not_found -> ()];

value clear h = (DynArray.clear h.heap; Hashtbl.clear h.indices);

value reorder_up h x =
  try up_heap h (Hashtbl.find h.indices x) with [ Not_found -> () ];

value reorder_down h x =
  try down_heap h (Hashtbl.find h.indices x) with [ Not_found -> () ];

end;
(*
module type HashedType =
  sig type t; value equal : t -> t -> bool; value hash : t -> int; end;

module type S =
  sig
    type elt;
    type order = elt -> elt -> bool;
    type t;
    value make : order -> t;
    value length : t -> int;
    value is_empty : t -> bool;
    value add : t -> elt -> unit;
    value mem : t -> elt -> bool;
    value first : t -> elt;
    value remove_first : t -> unit;
    value remove : t -> elt -> unit;
    value clear : t -> unit;
    value reorder_up : t -> elt -> unit;
    value reorder_down : t -> elt -> unit;
  end;
module Make (H : HashedType) =
  struct
    type elt = H.t;
    type order = elt -> elt -> bool;
    module Tbl = Hashtbl.Make H;
    type queue =
      { heap : DynArray.t elt; indices : Tbl.t int; order : order
      };
    type t = queue;
    value make order =
      {
        heap = DynArray.make 0;
        indices = Tbl.create 32;
        order = order;
      };
    value length h = DynArray.length h.heap;
    value is_empty h = (length h) = 0;
    value get h = DynArray.unsafe_get h.heap;
    value set h i x =
      (DynArray.unsafe_set h.heap i x; Tbl.replace h.indices x i);
    value mem h x = Tbl.mem h.indices x;
    value parent i = (i - 1) / 2;
    value left i = (2 * i) + 1;
    value right i = (2 * i) + 2;
    value has_left h i = (left i) < (length h);
    value has_right h i = (right i) < (length h);
    value is_heap h =
      let ord = h.order in
      let rec is_heap i =
        ((not (has_left h i)) ||
           ((ord (get h i) (get h (left i))) && (is_heap (left i))))
          &&
          ((not (has_right h i)) ||
             ((ord (get h i) (get h (right i))) && (is_heap (right i))))
      in is_heap 0;

    value down_heap h i =
      let x = get h i in
      let ord = h.order in
      let rec down_heap j =
        if has_left h j
        then
          let l = left j in
          let r = right j in
          let k =
            if (has_right h j) && (not (ord (get h l) (get h r)))
            then r
            else l in
          let y = get h k
          in if ord x y then set h j x else (set h j y; down_heap k)
        else if j <> i then set h j x else ()
      in down_heap i;

    value up_heap h i =
      let x = get h i in
      let ord = h.order in
      let rec up_heap j =
        let k = parent j in
        let y = get h k
        in if (j = 0) || (ord y x) then set h j x else (set h j y; up_heap k)
      in up_heap i;

    value make_heap h =
      for i = ((length h) / 2) - 1 downto 0 do down_heap h i done;

    value first h =
      if is_empty h
      then failwith "PriorityQueue.first: empty queue"
      else get h 0;

    value add h x =
      let i = length h
      in (DynArray.add h.heap x; Tbl.add h.indices x i; up_heap h i);

    value remove_index h i =
      let x = get h i
      and y = get h ((length h) - 1) in
      (
        set h i y;
        DynArray.delete_last h.heap;
        Tbl.remove h.indices x;
        down_heap h i
      );

    value remove_first h =
      if is_empty h
      then failwith "PriorityQueue.first: empty queue"
      else remove_index h 0;

    value remove h x =
      try remove_index h (Tbl.find h.indices x) with [ Not_found -> () ];

    value clear h = (DynArray.clear h.heap; Tbl.clear h.indices);

    value reorder_up h x =
      try up_heap h (Tbl.find h.indices x) with [ Not_found -> () ];

    value reorder_down h x =
      try down_heap h (Tbl.find h.indices x) with [ Not_found -> () ];

  end;
*)

