IFPLATFORM(ios android)
external init: ~advertiser_id:string -> ~conversion_key:string -> ?site_id:string -> unit -> unit = "ml_MATinit";
external setUserId: string -> unit = "ml_MATsetUserId";
external install: unit -> unit = "ml_MATinstall";
external update: unit -> unit = "ml_MATupdate";
external trackAction: string -> unit = "ml_MATtrackAction";
external trackPurchase: ~key:string -> ~amount:float -> ~currency:string -> unit = "ml_MATtrackPurchase";
ELSE
value init ~advertiser_id ~conversion_key ?site_id () = ();
value setUserId _ = ();
value install () = ();
value update () = ();
value trackAction _ = ();
value trackPurchase ~key ~amount ~currency = ();

ENDPLATFORM;
