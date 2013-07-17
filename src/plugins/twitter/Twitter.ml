IFPLATFORM(ios pc)
value init ?comsumerKey ?consumerSecret () = ();
ELSE
external init: ?consumerKey:string -> ?consumerSecret:string -> unit -> unit = "ml_init";
ENDPLATFORM;

IFPLATFORM(ios android)
external tweet: ?success:(unit -> unit) -> ?fail:(string -> unit) -> ~text:string -> unit -> unit = "ml_tweet";
ELSE
value tweet ?success ?fail ~text:string () = ();
ENDPLATFORM;