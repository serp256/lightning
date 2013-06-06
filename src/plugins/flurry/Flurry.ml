IFPLATFORM(android)
external startSession: ~appId:string -> unit -> unit = "ml_flurryStartSession";
external endSession: unit -> unit = "ml_flurryEndSession";
ELSE
value startSession ~appId:string () = ();
value endSession () = ();
ENDPLATFORM;