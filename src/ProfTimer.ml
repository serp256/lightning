(* Simple start/stop timer
 * Copyright (C) 2004 WingNET Internet Services
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version,
 * with the special exception on linking described in file LICENSE.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the Free
 * Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 *)

(*
 * ----------------------------------------------------------------------------
 *   timer.ml - Simple start/stop timer
 *     Author - Jesse D. Guardiani
 *    Created - 2004/08/16
 *   Modified - 2004/08/16
 * ----------------------------------------------------------------------------
 *
 *  ChangeLog
 *  ---------
 *
 *  2004/08/16 - JDG
 *  ----------------
 *  - Created
 * ----------------------------------------------------------------------------
 * Copyright (C) 2004 WingNET Internet Services
 * Contact: <jesse@wingnet.net>
 * ----------------------------------------------------------------------------
 *)


(** Simple start/stop timer
 *)

(* exception Not_started; *)
exception Not_stopped;
exception Alredy_stopped;

(* type resolution = Seconds|Minutes|Hours|Days;; *)
type t = {start: mutable float; stop: mutable option float};

value create () = {start = 0. ; stop = Some 0. };

(**
   [start ()] Start and return [timer].
*)

value clear t = 
(
  t.start := 0.;
  t.stop := Some 0.;
);

value start () =
  {
    start=(Unix.gettimeofday ());
    stop=None
  };


value start_again ({start = s; stop = sp } as t) = 
  match sp with
  [ Some p -> 
    (
      t.start := (Unix.gettimeofday()) -. (p -. s);
      t.stop := None;
    )
  | None -> raise Not_stopped
  ];

(**
   [stop timer] Stop [timer].
*)
value stop ({start=_; stop = sp} as t)  =
  match sp with
  [ None -> t.stop := Some (Unix.gettimeofday())
  | _ -> raise Alredy_stopped
  ];

value stop_if ({start=_;stop=sp} as t) =
  match sp with
  [ None -> t.stop := Some (Unix.gettimeofday())
  | _ -> ()
  ];

(**
   [length timer] Calculate and return length timer was active.

   @param res Determines returned time resolution; defaults to [Seconds].
*)
value length (* ?(res=Seconds)*) timer =
    match timer with
    [ {start=_; stop=None  } -> raise Not_stopped
    | {start=s; stop=Some p} -> p -. s
    ];
    (*
                    let sec = p -. s in
                    match res with
                      Seconds -> sec
                    | Minutes -> sec /. 60.0
                    | Hours   -> sec /. 3600.0
                    | Days    -> sec /. 216000.0
    *)


value elapsed timer = 
  match timer with
  [ {start=s;stop=None} -> (Unix.gettimeofday()) -. s
  | _ -> raise Alredy_stopped
  ];
