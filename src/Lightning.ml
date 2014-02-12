
type remoteNotification = [= `RNBadge | `RNSound | `RNAlert ];


value referrer = ref None;
value set_referrer tp key = referrer.val := Some (tp,key);
Callback.register "set_referrer" set_referrer;
value getReferrer () = !referrer;
value clearReferrer () = referrer.val := None;

IFPLATFORM(android)
external showUrl: string -> unit = "ml_showUrl";
ELSE
value showUrl _ = failwith "showUrl not supported";
ENDPLATFORM;


IFPLATFORM(ios)
external showNativeWaiter: Point.t -> unit = "ml_showActivityIndicator";
external hideNativeWaiter: unit -> unit = "ml_hideActivityIndicator";
ELSE
value showNativeWaiter _pos = ();
value hideNativeWaiter () = ();
ENDPLATFORM;

(* external show_alert: ~title:string -> ~message:string -> unit = "ml_show_alert"; *)

IFPLATFORM(ios android)
external openURL: string -> unit = "ml_openURL";
value sendEmail recepient ~subject ?(body="") () = 
  let params = UrlEncoding.mk_url_encoded_parameters [ ("subject",subject); ("body", body)] in
  openURL (Printf.sprintf "mailto:%s?%s" recepient params);

ELSE
value showUrl _ = ();
value openURL _ = ();
value sendEmail recepient ~subject ?(body="") () = (); 
ENDPLATFORM;


type stage_constructor = float -> float -> Stage.c;

(* value _stage: ref (option (float -> float -> stage eventTypeDisplayObject eventEmptyData)) = ref None; *)

IFPLATFORM(pc)

value init s =
  let s = (s :> stage_constructor) in
  Pc_run.run s;

ELSPLATFORM(ios android)

value _stage : ref (option stage_constructor) = ref None;

value init s = 
  let s = (s :> stage_constructor) in
    _stage.val := Some s;  

value stage_create width height = 
  match _stage.val with
  [ None -> failwith "Stage not initialized"
  | Some stage -> stage width height 
  ];


value () = 
(
  Printexc.record_backtrace True;
  Callback.register "stage_create" stage_create;
);
ENDPLATFORM;

IFPLATFORM(android) (* for link mlwrapper_android *)
external jni_onload: unit -> unit = "JNI_OnLoad";
external native_activity_dummy: unit -> unit = "android_main";
ENDPLATFORM;

value getLocale = LightCommon.getLocale;
value getVersion = LightCommon.getVersion;

external memUsage: unit -> int = "ml_memUsage";
type malinfo = 
  {
    malloc_total: int;
    malloc_used: int;
    malloc_free: int;
  };

IFPLATFORM(ios android)
external malinfo: unit -> malinfo = "ml_malinfo";
ELSE
value malinfo () = {malloc_total=0;malloc_used=0;malloc_free=0};
ENDPLATFORM;

external setMaxGC: int64 -> unit = "ml_setMaxGC";

IFPLATFORM(ios android)
external addExceptionInfo: string -> unit = "ml_addExceptionInfo";
external setSupportEmail: string -> unit = "ml_setSupportEmail";
ELSE
value addExceptionInfo (_:string) = ();
value setSupportEmail (_:string) = ();
ENDPLATFORM;

IFPLATFORM(android) 
external downloadExpansions: string -> unit = "ml_downloadExpansions";

value expansionsInProgress = ref False;
value _errorCallback = ref None;
value _progressCallback = ref None;
value _completeCallback = ref None;

value expansionsError reason = (
  match !_errorCallback with
  [ Some errorCallback -> errorCallback reason
  | _ -> ()
  ];

  expansionsInProgress.val := False;
);

value expansionsProgress total progress timeRemain =
  match !_progressCallback with
  [ Some progressCallback -> progressCallback ~total ~progress ~timeRemain ()
  | _ -> ()
  ];

value expansionsComplete () = (
  match !_completeCallback with
  [ Some completeCallback -> completeCallback ()
  | _ -> failwith "expansions complete callback cannot be None"
  ];

  expansionsInProgress.val := False;
);

value downloadExpansions ?errorCallback ?progressCallback ~pubkey ~completeCallback () =
  if not !expansionsInProgress
  then (
    expansionsInProgress.val := True;

    Callback.register "expansionsError" expansionsError;
    Callback.register "expansionsProgress" expansionsProgress;
    Callback.register "expansionsComplete" expansionsComplete;

    _errorCallback.val := errorCallback;
    _progressCallback.val := progressCallback;
    _completeCallback.val := Some completeCallback;

    downloadExpansions pubkey;
  )
  else (); 
ELSE
value downloadExpansions ?errorCallback ?progressCallback ~pubkey ~completeCallback () = 
(
	completeCallback ();
);
ENDPLATFORM;


IFPLATFORM (ios android)
external getUDID: unit -> string = "ml_getUDID";
value _udid = Lazy.lazy_from_fun getUDID;
value getUDID () = Lazy.force _udid;
external getOldUDID: unit -> string = "ml_getOldUDID";
ELSE
value getUDID () = "PC_UDID";
value getOldUDID () = "PC_UDID";
ENDPLATFORM;

IFPLATFORM(ios android)
external showNativeWait: ?message:string -> unit -> unit = "ml_show_nativeWait";
external hideNativeWait: unit -> unit = "ml_hide_nativeWait";
ELSE
value showNativeWait ?message () = ();
value hideNativeWait () = ();
ENDPLATFORM;
