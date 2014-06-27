
type timer = unit -> unit;
module TimersQueue = PriorityQueue.Make (struct type t = (float*int*timer); value order (t1,_,_) (t2,_,_) = t1 <= t2; end);
value time = ref None;
value timer_id = ref 0;
value getTime () = 
  match !time with
  [ None -> failwith "Time not initialized"
  | Some time -> time
  ];

value queue = TimersQueue.make ();
value start delay (f:(unit -> unit)) =
  match !time with
  [ Some time -> 
    let id = !timer_id in
    (
      debug:timer "planing timer to time %f %f %f" time delay (time +. delay);
      TimersQueue.add queue ((time +. delay),id,f);
      incr timer_id;
      id
    )
  | None -> failwith "Timers not initialized"
  ];

value stop id = TimersQueue.remove_if (fun (_,id',_) -> id = id') queue;

value init t = time.val := Some t;

value process dt = 
  match !time with
  [ Some t ->
    let () = debug:timer "process %f %f" t dt in
    let t = t +. dt in
    (
      debug:timer "new t = %f" t;
      time.val := Some t;
      if not (TimersQueue.is_empty queue)
      then
        let rec run_timers () = 
          match TimersQueue.first queue with
          [ (t',_,timer) when t' <= t ->
            let () = debug:timer "t' %f, t %f" t' t in
            (
              TimersQueue.remove_first queue; 
              timer ();
              match TimersQueue.is_empty queue with
              [ True -> ()
              | False -> run_timers ()
              ]
            )
          | _ -> ()
          ]
        in
        run_timers ()
      else ();
    )
  | None -> failwith "Timers not initialized"
  ];

value clear () = TimersQueue.clear queue;
Callback.register "clear_timers" clear;
