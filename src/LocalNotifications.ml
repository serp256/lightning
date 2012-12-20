IFDEF PC THEN
value schedule ~notifId:string ~fireDate:float ~mes:string () = False;
value cancel ~notifId:string () = ();
ELSE

external _schedule: string -> float -> string -> bool = "ml_lnSchedule";
external _cancel: string -> unit = "ml_lnCancel";

value schedule ~notifId ~fireDate ~mes () = _schedule notifId fireDate mes;
value cancel ~notifId () = _cancel notifId;
ENDIF;