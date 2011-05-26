
type timer = <fire: unit -> unit>;
module TimersQueue = PriorityQueue.Make (struct type t = (float*timer); value order (t1,_) (t2,_) = t1 <= t2; end);
value time = ref None;
value queue = TimersQueue.make ();
value add delay timer =
  match !time with
  [ Some time -> TimersQueue.add queue ((time +. delay),(timer :> timer))
  | None -> failwith "Timers not initialized"
  ];

value remove timer = TimersQueue.remove_if (fun (_,o) -> o = (timer :> timer)) queue;

value init t = time.val := Some t;

value run dt = 
  match !time with
  [ Some t ->
    let t = t +. dt in
    (
      time.val := Some t;
      if not (TimersQueue.is_empty queue)
      then
        let rec run_timers () = 
          match TimersQueue.first queue with
          [ (t',timer) when t' <= t ->
            (
              TimersQueue.remove_first queue; 
              timer#fire();
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

