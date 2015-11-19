

IFPLATFORM(ios android)
external init: ?appid:string -> string -> unit = "ml_af_set_key";
external setUserId: string -> unit = "ml_af_set_user_id";
external setCurrencyCode: string -> unit = "ml_af_set_currency_code";
external sendTracking: unit -> unit = "ml_af_send_tracking";
(*
external sendTrackingWithEvent: string -> string -> unit = "ml_af_send_tracking_with_event";
*)
external getUID: unit -> string = "ml_af_get_uid";
external trackPurchase: ~sku: string -> ~currency:string -> ~revenue:float -> unit -> unit = "ml_af_track_purchase";
external trackLevel: int -> unit = "ml_af_track_level";
external trackTapjoyEvent: unit -> unit = "ml_af_track_tapjoy_event";
(**)
ELSE
value init: ?appid:string -> string -> unit = fun ?appid devkey -> ();
value setUserId: string -> unit = fun _ -> ();
value setCurrencyCode: string -> unit = fun _ -> ();
value sendTracking: unit -> unit = fun () -> ();
value getUID: unit -> string = fun () -> "";
value trackPurchase: ~sku: string -> ~currency:string -> ~revenue:float -> unit -> unit = fun _ _ _ _ -> ();
value trackLevel: int -> unit = fun _ -> ();
value trackTapjoyEvent: unit -> unit = fun _ -> ();
ENDPLATFORM;
