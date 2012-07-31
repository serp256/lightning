
external ios_facebook_init : string -> unit = "ml_fb_init";
external fb_auth : list string -> unit = "ml_fb_authorize";

value auth perms = fb_auth perms;

value init appid = 
  (
    ios_facebook_init appid;
  );

