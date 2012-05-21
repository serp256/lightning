type accData = {
  accX : float;
  accY : float;
  accZ : float;
};

type callback = accData -> unit;

value accStart : callback -> float -> unit;
value accStop : unit -> unit;