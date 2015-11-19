

(* Init
 * Android: only devkey param needed
 * IOS: both appid and devkey should be provided
 *)
value init: ?appid:string -> string -> unit;
value setUserId: string -> unit;
value setCurrencyCode: string -> unit;
value sendTracking: unit -> unit;

value trackPurchase: ~sku: string -> ~currency:string -> ~revenue:float -> unit -> unit;
value trackLevel: int -> unit;
value trackTapjoyEvent: unit -> unit;
value getUID : unit -> string;
