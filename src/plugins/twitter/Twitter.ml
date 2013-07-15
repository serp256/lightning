IFPLATFORM(ios)
external tweet: ?success:(unit -> unit) -> ?fail:(string -> unit) -> ~text:string -> unit -> unit = "ml_tweet";
ELSE
value tweet ?success ?fail ~text:string () = ();
ENDPLATFORM;