exception Selector_not_found;
exception Undefined;

type t =  ref (option (Hashtbl.t int (unit -> unit)));
type prop 'a = ((t -> 'a -> unit) * (t -> option 'a));

value create () = None;

value new_id : unit -> int = let id = ref 0 in fun () -> (incr id; !id);

value newProp () =
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
  (set, get);


value set t (set',_) f = set' t f;
value get t (_,get') = get' t;

value get_exn obj sel = 
  match get obj sel with
  [ Some s -> s
  | None -> raise Undefined
  ];

value (%) = get_exn;

value define obj f =
  let prop = newProp () in
  (
    set obj prop f;
    prop;
  );
