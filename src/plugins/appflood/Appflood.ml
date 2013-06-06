IFPLATFORM(android ios)
external startSession: ~appKey:string -> ~secKey:string -> unit -> unit = "ml_appfloodStartSession";
ELSE
value startSession ~appKey:string ~secKey:string () = ();
ENDPLATFORM;