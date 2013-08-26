

IFPLATFORM(ios android)
external init: string -> unit = "ml_af_set_key";
external setUserId: string -> unit = "ml_af_set_user_id";
external setCurrencyCode: string -> unit = "ml_af_set_currency_code";
external sendTracking: unit -> unit = "ml_af_send_tracking";
external sendTrackingWithEvent: string -> string -> unit = "ml_af_send_tracking_with_event";
external getUID: unit -> string = "ml_af_get_uid";
ELSE
value init: string -> unit = fun _ -> ();
value setUserId: string -> unit = fun _ -> ();
value setCurrencyCode: string -> unit = fun _ -> ();
value sendTracking: unit -> unit = fun () -> ();
value sendTrackingWithEvent: string -> string -> unit = fun _ _ -> ();
value getUID: unit -> string = fun () -> "";
ENDPLATFORM;
