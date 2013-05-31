IFPLATFORM(android)
external init: ~appId:string -> unit -> unit = "ml_flurryInit";
external startSession: unit -> unit = "ml_flurryStartSession";
external endSession: unit -> unit = "ml_flurryEndSession";
ELSE
value init ~appId:string () = ();
value startSession () = ();
value endSession () = ();
ENDPLATFORM;