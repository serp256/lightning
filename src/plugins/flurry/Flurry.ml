IFPLATFORM(android ios)
external startSession: ~appId:string -> unit -> unit = "ml_flurryStartSession";
ELSE
value startSession ~appId:string () = ();
ENDPLATFORM;