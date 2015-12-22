(* NOT USE THIS METHOD; READ WIKI *)
IFPLATFORM(android ios)
external startSession: ~appId:string -> ~appSig:string -> unit -> unit = "ml_chartBoostStartSession";
ELSE
value startSession ~appId:string ~appSig:string () = ();
ENDPLATFORM;
