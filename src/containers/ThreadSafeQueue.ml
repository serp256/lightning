(******************************************************************************
 *                             Core                                           *
 *                                                                            *
 * Copyright (C) 2008- Jane Street Holding, LLC                               *
 *    Contact: opensource@janestreet.com                                      *
 *    WWW: http://www.janestreet.com/ocaml                                    *
 *                                                                            *
 *                                                                            *
 * This library is free software; you can redistribute it and/or              *
 * modify it under the terms of the GNU Lesser General Public                 *
 * License as published by the Free Software Foundation; either               *
 * version 2 of the License, or (at your option) any later version.           *
 *                                                                            *
 * This library is distributed in the hope that it will be useful,            *
 * but WITHOUT ANY WARRANTY; without even the implied warranty of             *
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU          *
 * Lesser General Public License for more details.                            *
 *                                                                            *
 * You should have received a copy of the GNU Lesser General Public           *
 * License along with this library; if not, write to the Free Software        *
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA  *
 *                                                                            *
 ******************************************************************************)

(* This module exploits the fact that OCaml does not perform context-switches
   under certain conditions.  It can therefore avoid using mutexes.

   Given the semantics of the current OCaml runtime (and for the foreseeable
   future), code sections documented as atomic below will never contain a
   context-switch.  The deciding criterion is whether they contain allocations
   or calls to external/builtin functions.  If there is none, a context-switch
   cannot happen.  Assignments without allocations, field access,
   pattern-matching, etc., do not trigger context-switches.

   Code reviewers should therefore make sure that the sections documented
   as atomic below do not violate the above assumptions.  It is prudent to
   disassemble the .o file (using objdump -dr) and examine it.
*)

type queue_end 'a = ref (option (z 'a))
and z 'a = {
  v : 'a;
  next : queue_end 'a;
};

type t 'a = {
  front : mutable queue_end 'a;
  back : mutable queue_end 'a;
};

value create () =
  let queue_end = ref None in
  { front = queue_end; back = queue_end };

value enqueue t a =
  let next = ref None in
  let el = Some { v = a; next = next } in
  (
    (* BEGIN ATOMIC SECTION *)
    t.back.val := el;
    t.back := next;
    (* END ATOMIC SECTION *)
  )
;

value dequeue t =
  (* BEGIN ATOMIC SECTION *)
  match !(t.front) with
  [ None -> None
  | Some el ->
    (
      t.front := el.next;
      (* END ATOMIC SECTION *)
      Some el.v
    )
  ]
;

value create' () =
  let t = create () in
  ((fun () -> dequeue t), fun a -> enqueue t a);
