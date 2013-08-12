IFPLATFORM(ios pc)
value init ?consumerKey ?consumerSecret () = ();
value tweetPic ?success ?fail ~fname ~text () = ();
ELSE
external init: ?consumerKey:string -> ?consumerSecret:string -> unit -> unit = "ml_init";
ENDPLATFORM;

IFPLATFORM(ios android)
external tweet: ?success:(unit -> unit) -> ?fail:(string -> unit) -> ~text:string -> unit -> unit = "ml_tweet";
external tweetPic: ?success:(unit -> unit) -> ?fail:(string -> unit) -> ~fname:string -> ~text:string -> unit -> unit = "ml_tweet_pic";
ELSE
value tweet ?success ?fail ~text:string () = ();
ENDPLATFORM;