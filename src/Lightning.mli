
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

IFPLATFORM(ios android)
external malinfo: unit -> malinfo = "ml_malinfo";
ELSE
value malinfo: unit -> malinfo;
ENDPLATFORM;

value getReferrer: unit -> option (string*string);
value clearReferrer: unit -> unit;

value getLocale: unit -> string;
value getVersion: unit -> string;

value addExceptionInfo: string -> unit;
value setSupportEmail: string -> unit;
(*value getMACID: unit -> string;*)
value getUDID: unit -> string;
value getOldUDID: unit -> string;

value downloadExpansions: ?errorCallback:(string -> unit) -> ?progressCallback:(~total:int -> ~progress:int -> ~timeRemain:int -> unit -> unit) -> ~pubkey:string -> ~completeCallback:(unit -> unit) -> unit -> unit;
(* value extractAssetsIfRequired: (bool -> unit) -> unit;
value extractAssetsAndExpansionsIfRequired: (bool -> unit) -> unit; *)

(* external test_c_fun: (unit -> unit) -> unit = "ml_test_c_fun"; *)

value showUrl: string -> unit;(* ANDROID ONLY *) (* display WebView with specified url *)
value showNativeWait: ?message:string -> unit -> unit;
value hideNativeWait: unit -> unit;

value fireLightningEvent: string -> unit;
value setNativeEventListener: (string -> unit) -> unit;
value clearNativeEventListener: unit -> unit;

