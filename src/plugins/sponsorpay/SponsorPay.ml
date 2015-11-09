
IFPLATFORM(android ios)

external _start: ~appId:string -> ?userId:string -> ?securityToken:string -> ~test: bool -> unit -> unit = "ml_sponsorPay_start";
value start ~appId ?userId ?securityToken ?(test = False) () = _start ~appId ?userId ?securityToken ~test ();
external showOffers: unit -> unit = "ml_sponsorPay_showOffers";
external requestVideo: ~callback:(bool -> unit) -> unit -> unit = "ml_request_video";
external showVideo: ~callback:(bool -> unit) -> unit -> unit = "ml_show_video";

ELSE

value start ~appId ?userId ?securityToken ?test () = ();
value showOffers () = ();
value requestVideo ~callback () = ();
value showVideo ~callback () = ();

ENDPLATFORM;

