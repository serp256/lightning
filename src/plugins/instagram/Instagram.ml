IFPLATFORM(android ios)
external post: ~fname:string -> ~text:string -> unit -> bool = "ml_instagram_post";
ELSE
value post ~fname ~text () = False;
ENDPLATFORM;