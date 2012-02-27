

type h_t 'a 'b = 
  {
    size: mutable int;
    data: mutable array (h_bucketlist 'a 'b)
  }
and h_bucketlist 'a 'b =
  [ Empty 
  | Cons of 'a and 'b and  (h_bucketlist 'a 'b)
  ];


include ExtLib.Hashtbl;


external h_conv : t 'a 'b -> h_t 'a 'b = "%identity";
external h_make : h_t 'a 'b -> t 'a 'b = "%identity";

value is_empty h = (h_conv h).size = 0;
value empty () = h_make {size=0;data=[| Empty |]};

value remove_exn h key =
  let hc = h_conv h in
  let rec remove_bucket = fun
    [ Empty -> raise Not_found
    | Cons(k, i, next) ->
        if compare k key = 0
        then begin hc.size := pred hc.size; next end
        else Cons(k, i, remove_bucket next) 
    ]
  in
  let i = (hash key) mod (Array.length hc.data) in
  hc.data.(i) := remove_bucket hc.data.(i);

value pop h key = 
  let hc = h_conv h in
  let pos = (hash key) mod (Array.length hc.data) in
  let l = Array.unsafe_get hc.data pos in
  match l with
  [ Empty -> raise Not_found
  | Cons (k,v,next) ->
      if k = key 
      then 
      (
        hc.size := pred hc.size;
        Array.unsafe_set hc.data pos next;
        v
      )
      else 
        let rec loop = fun
         [ Empty -> raise Not_found
         | Cons (k,v,next) ->
            if k = key 
            then 
            (
              hc.size := pred hc.size;
              (v,next)
            )
            else 
              let (res,next) = loop next in
              (res,Cons(k,v,next))
         ]
        in
        let (res,next) = loop next in
        (
          Array.unsafe_set hc.data pos (Cons(k,v,next));
          res 
        )
  ];


value pop_any h = 
  let hc = h_conv h in
  let rec find pos = 
    if pos < Array.length hc.data
    then
      match Array.unsafe_get hc.data pos with
      [ Empty -> find (succ pos)
      | Cons (k,v,next) ->
        (
          Array.unsafe_set hc.data pos next;
          Some (k,v)
        )
      ]
    else None
  in
  find 0;


value pop_all h key = 
  let hc = h_conv h in
  let rec find_in_bucket = fun
    [ Empty -> ([],Empty)
    | Cons(k, d, rest) ->
        let (f,r) = find_in_bucket rest in
        if k = key
        then 
        (
          hc.size := pred hc.size;
          ( [ d :: f ] , r )
        )
        else ( f , Cons k d r)
    ]
  in
  let pos = (hash key) mod (Array.length hc.data) in
  let (f,b) = find_in_bucket (Array.unsafe_get hc.data pos) in
  (
    Array.unsafe_set hc.data pos b;
    f
  );


value add_list h key lst = (* FIXME: вставляет в обратном порядке *)
  let hc = h_conv h in
  let pos = (hash key) mod (Array.length hc.data) in
  let b = 
    List.fold_left begin fun b d -> 
      (
        hc.size := succ hc.size;
        Cons (key,d,b)
      )
    end (Array.unsafe_get hc.data pos) lst 
  in
  Array.unsafe_set hc.data pos b;



