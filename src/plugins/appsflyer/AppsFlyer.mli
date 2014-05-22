

(* Init
 * Android: "Dev_id"
 * IOS: "App_ID;Dev_Key"
 *)
value init: ~appid:string -> ~devkey:string -> unit;
value setUserId: string -> unit;
value setCurrencyCode: string -> unit;
value sendTracking: unit -> unit;
value sendTrackingWithEvent: string -> string -> unit;
value getUID : unit -> string;
