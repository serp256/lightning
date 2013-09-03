IFPLATFORM(android ios)
external installed: unit -> bool = "ml_instagram_installed";
external post: ~fname:string -> ~text:string -> unit -> bool = "ml_instagram_post";
ELSE
value instaled () = False;
value post ~fname ~text () = False;
ENDPLATFORM;
