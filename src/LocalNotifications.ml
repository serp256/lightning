IFPLATFORM(pc) 
value schedule ~notifId:string ~fireDate:float ~mes:string () = False;
value cancel ~notifId:string () = ();
value cancelAll () = ();
ELSE

external _schedule: string -> float -> string -> bool = "ml_lnSchedule";
external _cancel: string -> unit = "ml_lnCancel";

value schedule ~notifId ~fireDate ~mes () = _schedule notifId fireDate mes;
value cancel ~notifId () = _cancel notifId;
external cancelAll: unit -> unit = "ml_lnCancelAll";
ENDPLATFORM;

IFPLATFORM(android)
external clearAll: unit -> unit = "ml_lnClearAll";
ELSE
value clearAll () = ();
ENDPLATFORM;
