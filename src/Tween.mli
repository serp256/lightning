
module Transitions : sig

  type t = float -> float;

  type kind = 
    [= `linear 
    | `easeIn | `easeOut | `easeInOut | `easeOutIn 
    | `easeInBack | `easeOutBack | `easeInOutBack | `easeOutInBack 
    | `easeInElastic | `easeOutElastic | `easeInOutElastic | `easeOutInElastic
    | `easeInBounce | `easeOutBounce | `easeInOutBounce | `easeOutInBounce
    | `transitionFun of t
    ];

    value linear: t;
    value easeIn: t;
    value easeOut: t;
    value easeInOut: t;
end;

type loop = [= `LoopNone | `LoopRepeat | `LoopReverse ];
type prop = ((unit -> float) * (float -> unit));

class c: [?transition:Transitions.kind] -> [?loop:loop] -> [float] ->
  object
    method animate: prop -> float -> unit;
    method process: float -> bool;
    method reset: unit -> unit;
    method setOnComplete: (unit -> unit) -> unit;
  end;


value create: ?transition:Transitions.kind -> ?loop:loop -> float -> c;
