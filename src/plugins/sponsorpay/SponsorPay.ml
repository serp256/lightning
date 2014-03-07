type network = [= `applifier of string | `applovin of string ];

IFPLATFORM(android ios)

external start: ~appId:string -> ?userId:string -> ?securityToken:string -> ?networks:list network -> unit -> unit = "ml_sponsorPay_start";
external showOffers: unit -> unit = "ml_sponsorPay_showOffers";

external requestVideo: ~callback:(bool -> unit) -> unit -> unit = "ml_request_video";
external showVideo: ~callback:(unit -> unit) -> unit -> unit = "ml_show_video";
ELSE

value start: ~appId:string -> ?userId:string -> ?securityToken:string -> ?networks:list network -> unit -> unit = fun ~appId ?userId ?securityToken ?mediatedNetworks () -> ();
value showOffers () = ();
value requestVideo () = ();
ENDPLATFORM;
