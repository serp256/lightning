
module Transitions : sig
  type t = 
    [= `linear 
    | `easeIn | `easeOut | `easeInOut | `easeOutIn 
    | `easeInBack | `easeOutBack | `easeInOutBack | `easeOutInBack 
    | `easeInElastic | `easeOutElastic | `easeInOutElastic | `easeOutInElastic
    | `easeInBounce | `easeOutBounce | `easeInOutBounce | `easeOutInBounce
    ];

  value linear: float -> float;
  value easeIn: float -> float;
end;

type loop = [= `LoopNone | `LoopRepeat | `LoopReverse ];
type prop = ((unit -> float) * (float -> unit));

class c: [?transition:Transitions.t] -> [?loop:loop] -> [float] ->
  object
    method animate: prop -> float -> unit;
    method process: float -> bool;
  end;
