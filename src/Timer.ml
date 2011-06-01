
type eventType = [= `TIMER | `TIMER_COMPLETE ];

class type virtual c = 
  object('self)
    inherit EventDispatcher.simple [eventType,Event.dataEmpty, c ];
    method running: bool;
    method delay: float;
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
      inherit EventDispatcher.simple [eventType, Event.dataEmpty, c];
      value mutable running = False;
      method running = running;
      value mutable currentCount = 0;
      method delay = delay;
      method repeatCount = repeatCount;
      method currentCount = currentCount;
      method fire () = 
      (
        let event = Event.create `TIMER () in
        self#dispatchEvent event; 
        currentCount := currentCount + 1;
        match running with
        [ True -> 
          if repeatCount <= 0 || currentCount < repeatCount
          then
            Timers.add delay self
          else 
            (
              running := False;
(*                     Hashtbl.remove timers id; *)
              let event = Event.create `TIMER_COMPLETE () in
              self#dispatchEvent event
            )
        | False -> ()
        ]
      );

      method private start' () = 
      (
          Timers.add delay self;
          running := True
      );

      method start () = 
        match running with
        [ False -> self#start'()
        | True -> failwith "Timer alredy started"
        ];

      method private stop' () = 
       (
         Timers.remove self;
         running := False;
       );

      method stop () = 
        match running with
        [ True -> self#stop'()
        | False -> failwith "Timer alredy stopped"
        ];

      method private asEventTarget = (self :> c);

      method reset () = 
      (
        currentCount := 0;
        match running with
        [ False -> ()
        | True -> self#stop'() 
        ];
      );

      method restart ~reset = 
      (
        match running with
        [ True -> 
          (
            match reset with
            [ True -> currentCount := 0
            | False -> ()
            ];
            self#stop'()
          )
        | False -> ()
        ];
        self#start'();
      );

    end
  in
  (o :> c);

