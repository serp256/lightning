
(* type eventType = [= `TIMER | `TIMER_COMPLETE ]; *)

value ev_TIMER = Ev.gen_id "TIMER";
value ev_TIMER_COMPLETE = Ev.gen_id "TIMER_COMPLETE";

class type virtual c = 
  object('self)
    inherit EventDispatcher.simple [ c ];
    method name: string;
    method running: bool;
    method delay: float;
    method setDelay: float -> unit;
    method repeatCount: int;
    method setRepeatCount : int -> unit;
    method currentCount: int;
    method start: unit -> unit;
    method stop: unit -> unit;
    method reset: unit -> unit; 
    method restart: ~reset:bool -> unit;
  end;


value create ?(repeatCount=0) delay name = (*{{{*)
  let o = 
    object(self)
      inherit EventDispatcher.simple [ c];
      value mutable running = None;
      method running = running <> None;
      value mutable currentCount = 0;
      value mutable _delay = delay;
      value mutable _repeatCount = repeatCount;
      method name = name;
      method delay = _delay;
      method setDelay d = _delay := d;
      method repeatCount = _repeatCount;
      method setRepeatCount newCount = _repeatCount := newCount;
      method currentCount = currentCount;
      method fire () = 
      (
        debug "fire timer %s" self#name;
        currentCount := currentCount + 1;
        match running with
        [ Some _ -> 
          if _repeatCount <= 0 || currentCount < _repeatCount
          then
          (
            running := Some (Timers.start _delay self#fire);
            let event = Ev.create ev_TIMER () in
            self#dispatchEvent event; 
          )
          else 
          (
            running := None;
            let event = Ev.create ev_TIMER () in
            self#dispatchEvent event; 
            let event = Ev.create ev_TIMER_COMPLETE () in
            self#dispatchEvent event
          )
        | None -> assert False
        ];
        debug "timer fired";
      );

      method private start' () = 
        running := Some (Timers.start _delay self#fire);

      method start () = 
        match running with
        [ None -> self#start'()
        | Some _ ->
            (
              failwith (Printf.sprintf "Timer %S alredy started" self#name);
            )
        ];

      method private stop' id = 
        match running with
        [ None -> ()
        | Some id -> 
            (
              Timers.stop id;
              running := None;
            )
        ];

      method stop () = 
        match running with
        [ Some id -> 
          (
            Timers.stop id;
            running := None;
          )
        | None -> failwith (Printf.sprintf "Timer %S alredy stopped" self#name)
        ];

      method private asEventTarget = (self :> c);

      method reset () = 
      (
        currentCount := 0;
        self#stop'();
      );

      method restart ~reset = 
      (
        match reset with
        [ True -> currentCount := 0
        | False -> ()
        ];
        self#stop'();
        self#start'();
      );

    end
  in
  (o :> c);
