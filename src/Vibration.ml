IFPLATFORM(android)

external c_vibro : int -> unit = "ml_vibration";

value vibrate time = (
	debug "ml vibro call";
	c_vibro time;
);

ELSE

value vibrate (_ : int) = ();

ENDPLATFORM;
