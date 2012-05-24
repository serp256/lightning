IFDEF IOS THEN
external schedule : ?alertAction:string -> ?badgeNum:int -> string -> float -> string -> bool = "ml_lnSchedule";
external cancel : string -> unit = "ml_lnCancel";
external exists : string -> bool = "ml_lnExists";
external notifFireDate : string -> option float = "ml_notifFireDate";
ELSE
value schedule ?alertAction:(alertAction:option string) ?badgeNum:(badgeNum:option int) (nid:string) (fireDate:float) (alertBody:string) = False;
value cancel (nid:string) = ();
value exists (nid:string) = False;
value notifFireDate (nid:string) = None;
ENDIF;