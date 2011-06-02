exception Selector_not_found;
exception Undefined;

type t =  ref (option (Hashtbl.t int (unit -> unit)));
(* type prop 'a = ((t -> 'a -> unit) * (t -> option 'a)); *)
type prop 'a = (int * (ref (option 'a)));

value create () = ref None;
value clear t = 
  match !t with
  [ None -> ()
  | Some t -> Hashtbl.clear t
  ];


value new_id : unit -> int = let id = ref 0 in fun () -> (incr id; !id);

(* alternative implementation *)
value create_selector () = (new_id(),ref None);
value set t (id,v) x = 
  let h = 
    match !t with
    [ None -> 
      let h = Hashtbl.create 3 in
      (
        t.val := Some h;
        h
      )
    | Some h -> h 
    ]
  in
  Hashtbl.replace h id (fun () -> v.val := Some x);

value get t (id,v) =
  match !t with
  [ None -> raise Selector_not_found
  | Some t -> 
      try
        (Hashtbl.find t id) ();
        match !v with
        [ Some x as s -> (v.val := None; s)
        | None -> None
        ]
      with [ Not_found -> None ]
  ];

value unset t (id,v) = 
  match !t with
  [ None -> ()
  | Some h -> Hashtbl.remove h id
  ];
  
(*
value create_selector () =
  let id = new_id () in
  let v = ref None in
  let set t x = 
    let h = 
      match !t with
      [ None -> 
        let h = Hashtbl.create 3 in
        (
          t.val := Some h;
          h
        )
      | Some h -> h 
      ]
    in
    Hashtbl.replace h id (fun () -> v.val := Some x) 
  in
  let get t = 
    match !t with
    [ None -> raise Selector_not_found
    | Some t -> 
        try
          (Hashtbl.find t id) ();
          match !v with
          [ Some x as s -> (v.val := None; s)
          | None -> None
          ]
        with [ Not_found -> None ]
    ]
  in
  (id, set, get);


value set t (set',_) f = set' t f;
value unset t (set',_) f =
  match !t with
  [ None -> ()
  | Some h -> Hashtbl.remove h 
  ];

value get t (_,get') = get' t;
*)

value get_exn obj sel = 
  match get obj sel with
  [ Some s -> s
  | None -> raise Undefined
  ];

value (%) = get_exn;

value define obj f =
  let sel = create_selector () in
  (
    set obj sel f;
    sel;
  );
