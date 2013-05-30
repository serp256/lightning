

IFPLATFORM(android)

external start: ~appId:string -> ?userId:string -> ?securityToken:string -> unit -> unit = "ml_sponsorPayStart";
external showOffers: unit -> unit = "ml_sponsorPay_showOffers";

ELSE

value start: ~appId:string -> ?userId:string -> ?securityToken:string -> unit -> unit = fun  ~appId ?userId ?securityToken () -> ();
value showOffers () = ();
ENDPLATFORM;
