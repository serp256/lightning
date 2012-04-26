
value deviceIdentifier: unit -> option string;

value init: (float -> float -> #Stage.c) -> unit;
value openURL : string -> unit;
value sendEmail : string -> ~subject:string -> ?body:string -> unit -> unit;
external memUsage: unit -> int = "ml_memUsage";
external setMaxGC: int64 -> unit = "ml_setMaxGC";

type remoteNotification = [= `RNBadge | `RNSound | `RNAlert ];
value request_remote_notifications: list remoteNotification ->  (string -> unit) -> (string -> unit) -> unit;
