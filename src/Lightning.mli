
(*value deviceIdentifier: unit -> option string;*)

value init: (float -> float -> #Stage.c) -> unit;
value openURL : string -> unit;
value sendEmail : string -> ~subject:string -> ?body:string -> unit -> unit;
external memUsage: unit -> int = "ml_memUsage";
external setMaxGC: int64 -> unit = "ml_setMaxGC";
type malinfo = 
  {
    malloc_total: int;
    malloc_used: int;
    malloc_free: int;
  };

IFDEF PC THEN
value malinfo: unit -> malinfo;
ELSE
external malinfo: unit -> malinfo = "ml_malinfo";
ENDIF;
value getReferrer: unit -> option (string*string);
value clearReferrer: unit -> unit;

type remoteNotification = [= `RNBadge | `RNSound | `RNAlert ];
value request_remote_notifications: list remoteNotification ->  (string -> unit) -> (string -> unit) -> unit;

value getLocale: unit -> string;
value getVersion: unit -> string;

value addExceptionInfo: string -> unit;
value setSupportEmail: string -> unit;
(*value getMACID: unit -> string;*)
value getUDID: unit -> string;

value downloadExpansions: ?errorCallback:(string -> unit) -> ?progressCallback:(~total:int -> ~progress:int -> ~timeRemain:int -> unit -> unit) -> ~completeCallback:(unit -> unit) -> unit -> unit;
(* value extractAssetsIfRequired: (bool -> unit) -> unit;
value extractAssetsAndExpansionsIfRequired: (bool -> unit) -> unit; *)

(* external test_c_fun: (unit -> unit) -> unit = "ml_test_c_fun"; *)

value showUrl: string -> unit; (* display WebView with specified url *)
