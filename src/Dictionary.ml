exception Selector_not_found;

type t =  Hashtbl.t int (unit -> unit);
type prop 'a = ((t -> 'a -> unit) * (t -> option 'a));

value create () = Hashtbl.create 13;

value new_id : unit -> int = let id = ref 0 in fun () -> (incr id; !id);

value newProp () =
  let id = new_id () in
  let v = ref None in
  let set t x = Hashtbl.replace t id (fun () -> v.val := Some x) in
  let get t = 
    try
      (Hashtbl.find t id) ();
      match !v with
      [ Some x as s -> (v.val := None; s)
      | None -> None
      ]
    with [ Not_found -> None ]
  in
  (set, get);


value setProp t (set',_) f = set' t f;
value getProp t (_,get') = get' t;

value call obj sel = 
  match getProp obj sel with
  [ Some s -> s
  | None -> raise Selector_not_found
  ];

value (%) = call;

value define obj f =
  let prop = newProp () in
  (
    setProp obj prop f;
    prop;
  );


