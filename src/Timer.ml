

class type virtual c ['event_type, 'event_data] =
  object('self)
    inherit EventDispatcher.simple ['event_type,'event_data, c 'event_type 'event_data ];
    method running: bool;
    method delay: float;
    method repeatCount: int;
    method currentCount: int;
    method start: unit -> unit;
    method stop: unit -> unit;
    method reset: unit -> unit; 
  end;

