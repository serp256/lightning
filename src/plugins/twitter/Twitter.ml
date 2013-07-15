IFPLATFORM(ios)
external tweet: unit -> unit = "ml_tweet";
ELSE
value tweet () = ();
ENDPLATFORM;