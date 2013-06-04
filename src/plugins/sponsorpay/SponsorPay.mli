

IFPLATFORM(android)

external start: ~appId:string -> ?userId:string -> ?securityToken:string -> unit -> unit = "ml_sponsorPay_start";
external showOffers: unit -> unit = "ml_sponsorPay_showOffers";

ELSE

value start: ~appId:string -> ?userId:string -> ?securityToken:string -> unit -> unit; 
value showOffers: unit -> unit;
ENDPLATFORM;
