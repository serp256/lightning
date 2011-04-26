
(** Priority queues. 

    The [PriorityQueue] module provides a polymorphic and a functorial
    interface to an imperative priority queue data structure.  A queue is
    implemented by embeddeding a heap in a resizable array.

    The polymorphic interface requires that the elements in a priority queue
    are distinct w.r.t. [(=)].  The functorial interface requires that the
    elements in a priority queue are distinct w.r.t. the [equal] function in
    their [HashedType] module.  Otherwise the functions based on element
    values ([mem], [remove], [reorder_up], and [reorder_down]) may not work
    correctly. *)

module type OrderedType = sig
  type t;
  value order: t -> t -> bool;
(** The type of priority orders on ['a].  A priority order [ord] is a
    non-strict total order where [ord a b = true] means that the priority of
    [b] is not higher than the priority of [a].  When the priority of an
    element changes, the queue must be notified using the [reorder_up] or
    [reorder_down] function. *)
end;

module type S =
  sig
    type elt;
    (** The element type. *)
    type t;
    (** The type of priority queues with element type [elt]. *)
    value make : unit -> t;
    (** [make ord] creates a new priority queue with order [ord]. *)
    value length : t -> int;
    (** Returns the number of elements in a queue. *)
    value is_empty : t -> bool;
    (** Tests whether a queue is empty. *)
    value add : t -> elt -> unit;
    (** Adds an elements to the queue. *)
    value mem : t -> elt -> bool;
    (** Tests whether a queue contains a given element. *)
    value first : t -> elt;
    (** [first q] returns an element with maximal priority contained in the
      queue [q].

      @raise Failure if [q] is empty. *)

    value remove_first : t -> unit;
    (** [remove_first q] removes the element returned by [first q] from the
      queue [q].

      @raise Failure if [q] is empty. *)
    value remove : t -> elt -> unit;
    (** [remove q x] removes the element [x] from the queue [q].  If [q] does
      not contain the element [x], the function does nothing. *)
    value remove_if: (elt -> bool) -> t -> unit;
    value clear : t -> unit;
    (** Removes all elements from a queue. *)
    value reorder_up : t -> elt -> unit;
    (** [reorder_up q x] notifies the queue [q] that the priority of the element
      [x] has increased.  If [q] does not contain [x], the function does
      nothing. *)
    value reorder_down : t -> elt -> unit;
    (** [reorder_down q x] notifies the queue [q] that the priority of the
    element [x] has decreased.  If [q] does not contain [x], the function does
    nothing. *)
    value is_heap : t -> bool;
    value fold: ('a -> elt -> 'a) -> 'a -> t -> 'a;
  end;
module Make (P : OrderedType) : S with type elt = P.t;


