
IFPLATFORM(android ios)

external _start: ~appId:string -> ?userId:string -> ?securityToken:string -> ~logging: bool -> unit -> unit = "ml_sponsorPay_start";
value start ~appId ?userId ?securityToken ?(logging = False) () = _start ~appId ?userId ?securityToken ~logging ();
external showOffers: unit -> unit = "ml_sponsorPay_showOffers";
external requestVideo: ~callback:(bool -> unit) -> unit -> unit = "ml_request_video";
external showVideo: ~callback:(bool -> unit) -> unit -> unit = "ml_show_video";

ELSE

value start ~appId ?userId ?securityToken ?logging () = ();
value showOffers () = ();
value requestVideo ~callback () = ();
value showVideo ~callback () = ();

ENDPLATFORM;

