

class type virtual c [ 'event_type, 'event_data] =
  object('self)
    inherit EventDispatcher.c ['event_type,'event_data, c 'event_type 'event_data , c 'event_type 'event_data ];
    method private bubbleEvent: _;
    method private upcast: c _ _;
    method start: unit -> unit;
    method stop: unit -> unit;
    method reset: unit -> unit; 
  end;

