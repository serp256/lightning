
type t;
value create: unit -> t;
value beginFill: t -> int -> float -> unit;
value endFill: t -> unit;
value lineStyle: t -> float -> int -> float -> unit;
value drawRect: t -> float -> float -> float -> float -> unit;
value drawCircle: t -> float -> float -> float -> unit;
value drawRoundRect: t -> float -> float -> float -> float -> float -> float -> unit;
value render: t -> unit;
value bounds: t -> option Rectangle.t;
