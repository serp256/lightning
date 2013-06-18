IFPLATFORM(android ios)
external startSession: ~appId:string -> ~appSig:string -> unit -> unit = "ml_chartBoostStartSession";
ELSE
value startSession ~appId:string ~appSig:string () = ();
ENDPLATFORM;