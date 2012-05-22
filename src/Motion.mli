type acmtrData = {
  accX : float;
  accY : float;
  accZ : float;
};

type callback = acmtrData -> unit;

value acmtrStart : callback -> float -> unit;
value acmtrStop : unit -> unit;