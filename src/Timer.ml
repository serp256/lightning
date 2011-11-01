
type eventType = [= `TIMER | `TIMER_COMPLETE ];

class type virtual c = 
  object('self)
    inherit EventDispatcher.simple [eventType,Ev.dataEmpty, c ];
    method name: string;
    method setName: string -> unit;
    method running: bool;
    method delay: float;
    method setDelay: float -> unit;
    method repeatCount: int;
    method currentCount: int;
    method start: unit -> unit;
    method stop: unit -> unit;
    method reset: unit -> unit; 
    method restart: ~reset:bool -> unit;
  end;


value create ?(repeatCount=0) delay = (*{{{*)
  let o = 
    object(self)
      inherit EventDispatcher.simple [eventType, Ev.dataEmpty, c];
      value mutable running = None;
      method running = running <> None;
      value mutable currentCount = 0;
      value mutable _delay = delay;
      value mutable name = "";
      method setName n = name := n;
      method name = if name = "" then Printf.sprintf "timer %d" (Oo.id self) else name;
      method delay = _delay;
      method setDelay d = _delay := d;
      method repeatCount = repeatCount;
      method currentCount = currentCount;
      method fire () = 
      (
        debug "fire timer %s" self#name;
        currentCount := currentCount + 1;
        match running with
        [ Some _ -> 
          if repeatCount <= 0 || currentCount < repeatCount
          then
          (
            running := Some (Timers.start _delay self#fire);
            let event = Ev.create `TIMER () in
            self#dispatchEvent event; 
          )
          else 
          (
            running := None;
            let event = Ev.create `TIMER () in
            self#dispatchEvent event; 
            let event = Ev.create `TIMER_COMPLETE () in
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
        | Some _ -> failwith "Timer alredy started"
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
        | None -> failwith "Timer alredy stopped"
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

