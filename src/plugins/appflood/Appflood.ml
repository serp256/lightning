IFPLATFORM(android)
external init: ~appKey:string -> ~secKey:string -> unit -> unit = "ml_appfloodInit";
external startSession: unit -> unit = "ml_appfloodStartSession";
ELSE
value init ~appKey:string ~secKey:string () = ();
value startSession () = ();
ENDPLATFORM;