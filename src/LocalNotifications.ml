IFDEF PC THEN
value schedule ~notifId:string ~fireDate:float ~mes:string () = False;
value cancel ~notifId:string () = ();
ELSE
external schedule : ~notifId:string -> ~fireDate:float -> ~mes:string -> unit -> bool = "ml_lnSchedule";
external cancel : ~notifId:string -> unit -> unit = "ml_lnCancel";
ENDIF;
