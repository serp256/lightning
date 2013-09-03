
type remoteNotification = [= `RNBadge | `RNSound | `RNAlert ];


value referrer = ref None;
value set_referrer tp key = referrer.val := Some (tp,key);
Callback.register "set_referrer" set_referrer;
value getReferrer () = !referrer;
value clearReferrer () = referrer.val := None;

IFDEF IOS THEN
value showUrl _ = failwith "ios version now doesnt support this function";

external showNativeWaiter: Point.t -> unit = "ml_showActivityIndicator";
external hideNativeWaiter: unit -> unit = "ml_hideActivityIndicator";

external openURL: string -> unit = "ml_openURL";
value sendEmail recepient ~subject ?(body="") () = 
  let params = UrlEncoding.mk_url_encoded_parameters [ ("subject",subject); ("body", body)] in
  openURL (Printf.sprintf "mailto:%s?%s" recepient params);
external show_alert: ~title:string -> ~message:string -> unit = "ml_show_alert";
external ml_request_remote_notifications : int -> (string -> unit) -> (string -> unit) -> unit = "ml_request_remote_notifications";
value request_remote_notifications rntypes success error = 
  let typesBitmask = 
    List.fold_left begin fun mask -> fun 
      [ `RNBadge -> mask lor 1
      | `RNSound -> mask lor 2
      | `RNAlert -> mask lor 4
      ]
    end 0 rntypes
  in 
  ml_request_remote_notifications typesBitmask success error;

ELSE
value request_remote_notifications rntypes success error = ();
value showNativeWaiter _pos = ();
value hideNativeWaiter () = ();

IFDEF ANDROID THEN
external openURL: string -> unit = "ml_openURL";
value sendEmail recepient ~subject ?(body="") () = 
  let params = UrlEncoding.mk_url_encoded_parameters [ ("subject",subject); ("body", body)] in
  openURL (Printf.sprintf "mailto:%s?%s" recepient params);
  (*
external _deviceIdentifier: unit -> string = "ml_device_id";
value deviceIdentifier () = Some (_deviceIdentifier ());
*)
external showUrl: string -> unit = "ml_showUrl";
ELSE
value showUrl _ = ();
value openURL _ = ();
value sendEmail recepient ~subject ?(body="") () = (); 
(*
value deviceIdentifier () = None;
*)
ENDIF;

ENDIF;

type stage_constructor = float -> float -> Stage.c;

(* value _stage: ref (option (float -> float -> stage eventTypeDisplayObject eventEmptyData)) = ref None; *)

IFDEF PC THEN
value init s =
  let s = (s :> stage_constructor) in
  Pc_run.run s;

ELSE

value _stage : ref (option stage_constructor) = ref None;

value init s = 
  let s = (s :> stage_constructor) in
    _stage.val := Some s;  

value stage_create width height = 
  match _stage.val with
  [ None -> failwith "Stage not initialized"
  | Some stage -> stage width height 
  ];

IFDEF ANDROID THEN (* for link mlwrapper_android *)
external jni_onload: unit -> unit = "JNI_OnLoad";
ENDIF;

value () = 
(
  Printexc.record_backtrace True;
  Callback.register "stage_create" stage_create;
);
ENDIF;


value getLocale = LightCommon.getLocale;
value getVersion = LightCommon.getVersion;

external memUsage: unit -> int = "ml_memUsage";
type malinfo = 
  {
    malloc_total: int;
    malloc_used: int;
    malloc_free: int;
  };

IFDEF PC THEN
value malinfo () = {malloc_total=0;malloc_used=0;malloc_free=0};
ELSE
external malinfo: unit -> malinfo = "ml_malinfo";
ENDIF;

external setMaxGC: int64 -> unit = "ml_setMaxGC";

IFDEF IOS THEN
external addExceptionInfo: string -> unit = "ml_addExceptionInfo";
external setSupportEmail: string -> unit = "ml_setSupportEmail";
ELSE

IFDEF ANDROID THEN 
external addExceptionInfo: string -> unit = "ml_addExceptionInfo";
external setSupportEmail: string -> unit = "ml_setSupportEmail";
ELSE
value addExceptionInfo (_:string) = ();
value setSupportEmail (_:string) = ();
ENDIF;
ENDIF;

IFDEF ANDROID THEN
external downloadExpansions: unit -> unit = "ml_downloadExpansions";

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

value downloadExpansions ?errorCallback ?progressCallback ~completeCallback () =
  if not !expansionsInProgress
  then (
    expansionsInProgress.val := True;

    Callback.register "expansionsError" expansionsError;
    Callback.register "expansionsProgress" expansionsProgress;
    Callback.register "expansionsComplete" expansionsComplete;

    _errorCallback.val := errorCallback;
    _progressCallback.val := progressCallback;
    _completeCallback.val := Some completeCallback;

    downloadExpansions ();
  )
  else (); 
ELSE
value downloadExpansions ?errorCallback ?progressCallback ~completeCallback () = 
(
	completeCallback ();
);
ENDIF;

(* IFDEF ANDROID THEN

(* external miniunz : string -> string -> option string -> unit = "ml_miniunz"; *)
(* external getApkPath : unit -> string = "ml_apkPath"; *)
(* external _assetsPath : unit -> string = "ml_assetsPath";*)
(* external setAssetsDir : string -> unit = "ml_setAssetsDir"; *)
(* external _getVersion : unit -> string = "ml_getVersion"; *)
(* external rm : string -> string -> (unit -> unit) -> unit = "ml_rm"; *)
(* external downloadExpansions : unit -> unit = "ml_downloadExpansions"; *)
(* external getExpansionPath : bool -> string = "ml_getExpansionPath"; *)
(* external getExpansionVer : bool -> int = "ml_getExpansionVer"; *)
(* external _extractExpansions : (bool -> unit) -> unit = "ml_extractExpansions"; *)
(* external expansionExtracted : unit -> bool = "ml_expansionExtracted"; *)

(* value unzipCbs = Hashtbl.create 0; *)

(* value unzip ?prefix zipPath dstPath cb =
(
  Hashtbl.add unzipCbs (zipPath, dstPath) cb;
  miniunz zipPath dstPath prefix;
);

value unzipComplete zipPath dstPath success =
  let key = (zipPath, dstPath) in
    ExtHashtbl.Hashtbl.((
      List.iter (fun cb -> cb success) (find_all unzipCbs key);
      remove_all unzipCbs key;
    ));

Callback.register "unzipComplete" unzipComplete;     *)

(* value _apkPath = Lazy.lazy_from_fun _apkPath; *)
(* value apkPath () = Lazy.force _apkPath; *)
(* value _apkVer = Lazy.lazy_from_fun _getVersion; *)
(* value apkVer () = Lazy.force _apkVer; *)
(* value _assetsPath = Lazy.lazy_from_fun _assetPath; *)
(* value assetsPath () = Lazy.force _assetsPath; *)
(* value assetsPath () = (LightCommon.storagePath ()) ^ "/assets/"; *)
(* value assetsVerFilename () = (assetsPath()) ^ "a" ^ (apkVer ()); *)

value assetsExtracted () = Sys.file_exists (assetsVerFilename ());

(* value extractAssets cb =
  let cb success =
    (
      if success then
      (
        setAssetsDir ((assetsPath ()));
        close_out (open_out (assetsVerFilename ()));
      )
      else ();
      cb success;
    )
  in
  unzip ~prefix:"assets" (getApkPath ()) (LightCommon.storagePath() ^ "/") cb; *)

(* value extractExpansions cb =
(
  Callback.register "expnsDownloadComplete" (fun () -> _extractExpansions cb);
  downloadExpansions ();
    fun () -> unzip (getExpansionPath True) (externalStoragePath ^ "assets/") (
      fun success ->
      (
        if success then close_out (open_out expansionVerFilename) else ();
        cb success;
      )
    )
); *)

value extractAssetsIfRequired cb =
  if assetsExtracted () then
  (
    setAssetsDir (assetsPath ());
    cb True;
  )
  else
(*     rm (ExtString.String.slice ~last:~-1 (LightCommon.storagePath())) "assets" (fun () -> extractAssets cb); *)
    rm (LightCommon.storagePath()) "assets" (fun () -> extractAssets cb);

value extractAssetsAndExpansionsIfRequired cb =  
  let extractAssetsRes = ref None
  and extractExpansionRes = ref None in
    let callCb () =
      match (!extractAssetsRes, !extractExpansionRes) with
      [ (Some ear, Some eer) ->  cb (ear && eer)
      | _ -> ()
      ]
    in
    (
      extractAssetsIfRequired (fun success -> ( extractAssetsRes.val := Some success; callCb (); ));
      extractExpansions (fun success -> ( extractExpansionRes.val := Some success; callCb (); ));
    );

ELSE
value extractAssetsIfRequired (cb:(bool -> unit)) =  cb True;
value extractAssetsAndExpansionsIfRequired (cb:(bool -> unit)) = cb True;
ENDIF; *)

(*external getMACID: unit -> string = "ml_getMACID";*)
external getUDID: unit -> string = "ml_getUDID";

IFPLATFORM(ios android)
external showNativeWait: ?message:string -> unit -> unit = "ml_show_nativeWait";
external hideNativeWait: unit -> unit = "ml_hide_nativeWait";
ELSE
value showNativeWait ?message () = ();
value hideNativeWait () = ();
ENDPLATFORM;
