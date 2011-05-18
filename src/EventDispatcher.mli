
exception Listener_not_found;


type lst 'eventType 'eventData 'target 'currentTarget = 
  {
    counter: mutable int;
    lstnrs: mutable list (int * (Event.t 'eventType 'eventData 'target 'currentTarget -> int -> unit));
  };

class base [ 'eventType,'eventData,'target,'currentTarget ]: 
  object
    type 'listener = Event.t 'eventType 'eventData 'target 'currentTarget -> int -> unit;
    value mutable listeners: list ('eventType * (lst 'eventType 'eventData 'target 'currentTarget));
    method addEventListener: 'eventType -> 'listener -> int;
    method removeEventListener: 'eventType -> int -> unit;
    method hasEventListeners: 'eventType -> bool;
  end;


class virtual simple [ 'eventType , 'eventData , 'target ]:
  object
    inherit base ['eventType,'eventData,'target,'target];
    method virtual private asEventTarget: 'target;
    method dispatchEvent: Event.t 'eventType 'eventData 'target 'target -> unit;
  end;
