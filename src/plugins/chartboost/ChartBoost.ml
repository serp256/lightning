IFPLATFORM(android)
external init: ~appId:string -> ~appSig:string -> unit -> unit = "ml_chartBoostInit";
external startSession: unit -> unit = "ml_chartBoostStartSession";
ELSE
value init ~appId:string ~appSig:string () = ();
value startSession () = ();
ENDPLATFORM;