

IFPLATFORM(android ios)

external start: ~appId:string -> ?userId:string -> ?securityToken:string -> unit -> unit = "ml_sponsorPay_start";
external showOffers: unit -> unit = "ml_sponsorPay_showOffers";

ELSE

value start: ~appId:string -> ?userId:string -> ?securityToken:string -> unit -> unit = fun  ~appId ?userId ?securityToken () -> ();
value showOffers () = ();
ENDPLATFORM;
