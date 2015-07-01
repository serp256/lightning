type network = [= `applifier of string | `applovin of string ];
IFPLATFORM(pc)
value start ~appId ?userId ?securityToken ?logging ?networks () = ();
ELSE 
IFPLATFORM(android)
external _start: ~appId:string -> ?userId:string -> ?securityToken:string -> ~logging: bool -> unit -> unit = "ml_sponsorPay_start";
value start ~appId ?userId ?securityToken ?(logging = False) ?networks () = _start ~appId ?userId ?securityToken ~logging ();
ELSE
external _start: ~appId:string -> ?userId:string -> ?securityToken:string -> ?networks: list network -> unit -> unit = "ml_sponsorPay_start";
value start ~appId ?userId ?securityToken ?(logging = False) ?networks () = _start ~appId ?userId ?securityToken ?networks ();
ENDPLATFORM;
ENDPLATFORM;

IFPLATFORM(android ios)

external showOffers: unit -> unit = "ml_sponsorPay_showOffers";
external requestVideo: ~callback:(bool -> unit) -> unit -> unit = "ml_request_video";

ELSE

value showOffers () = ();
value requestVideo ~callback () = ();

ENDPLATFORM;

IFPLATFORM(ios)

external showVideo: ~callback:(unit -> unit) -> unit -> unit = "ml_show_video";

ELSE

value showVideo ~callback () = ();

ENDPLATFORM;
