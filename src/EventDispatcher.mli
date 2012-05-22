
exception Listener_not_found of (Ev.id * string * int);

type listener 'target 'currentTarget = Ev.t -> ('target * 'currentTarget ) -> int -> unit;
type lst 'target 'currentTarget = 
  {
    counter: mutable int;
    lstnrs: mutable list (int * (listener 'target 'currentTarget));
  };

class base [ 'target,'currentTarget ]: 
  object
    type 'listener = Ev.t -> ('target * 'currentTarget) -> int -> unit;
    value mutable listeners: list (Ev.id * (lst 'target 'currentTarget));
    method addEventListener: Ev.id -> 'listener -> int;
    method removeEventListener: Ev.id -> int -> unit;
    method hasEventListeners: Ev.id -> bool;
  end;


class virtual simple [ 'target ]:
  object
    inherit base ['target,'target];
    method virtual private asEventTarget: 'target;
    method dispatchEvent: Ev.t -> unit;
  end;
