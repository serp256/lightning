IFPLATFORM(android)
external init: ~appKey:string -> ~appUid:string -> unit -> unit = "ml_supersonicInit";
external showOffers: unit -> unit = "ml_supersonicShowOffers";
ELSE
value init ~appKey:string ~appUid:string () = ();
value showOffers () = ();
ENDPLATFORM;