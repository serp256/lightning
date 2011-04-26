

class type c [ 'event_type, 'event_data] =
  object
    inherit EventDispatcher.c ['event_type,'event_data, c _ _];
    method private bubbleEvent: _;
    method private upcast: c _ _;
    method start: unit -> unit;
    method stop: unit -> unit;
    method reset: unit -> unit; 
  end;

