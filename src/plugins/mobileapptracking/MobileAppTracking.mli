
IFPLATFORM(ios android)
external init: ~advertiser_id:string -> ~conversion_key:string -> ?site_id:string -> unit -> unit = "ml_MATinit";
external setUserId: string -> unit = "ml_MATsetUserId";
external install: unit -> unit = "ml_MATinstall";
external update: unit -> unit = "ml_MATupdate";
external trackAction: string -> unit = "ml_MATtrackAction";
external trackPurchase: ~key:string -> ~amount:float -> ~currency:string -> unit = "ml_MATtrackPurchase";
ELSE
value init: ~advertiser_id:string -> ~conversion_key:string -> ?site_id:string -> unit -> unit;
value setUserId: string -> unit;
value install: unit -> unit;
value update: unit -> unit; 
value trackAction: string -> unit;
value trackPurchase: ~key:string -> ~amount:float -> ~currency:string -> unit;
ENDPLATFORM;
