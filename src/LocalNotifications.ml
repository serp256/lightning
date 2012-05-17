IFDEF IOS THEN
external schedule : ?alertAction:string -> ?badgeNum:int -> string -> float -> string -> bool = "ml_lnSchedule";
external cancel : string -> unit = "ml_lnCancel";
external exists : string -> bool = "ml_lnExists";
ELSE
value schedule ?alertAction:(alertAction:option string) ?badgeNum:(badgeNum:option int) (nid:string) (fireDate:float) (alertBody:string) = False;
value cancel (kind:string) = ();
value exists (kind:string) = False;
ENDIF;