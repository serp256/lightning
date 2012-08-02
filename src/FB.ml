
external ios_facebook_init : string -> unit = "ml_fb_init";
external fb_auth : int -> list string -> unit = "ml_fb_authorize";
external fb_graph_api : ?callback:(string -> unit) -> ?ecallback:(string -> unit) -> string -> int -> list (string*string) -> unit = "ml_fb_graph_api"; (* success callback, error callback, path, length params, params, *)

value graphAPI  ?callback ?ecallback path params = 
  fb_graph_api path (List.length params) params ?callback ?ecallback;

value auth perms = fb_auth (List.length perms) perms;

value init appid = 
  (
    ios_facebook_init appid;
  );

