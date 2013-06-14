IFPLATFORM(android ios)
external showOffers: ~appKey:string -> ~appUid:string -> unit -> unit = "ml_supersonicShowOffers";
ELSE
value showOffers ~appKey:string ~appUid:string () = ();
ENDPLATFORM;