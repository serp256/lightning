
type remoteNotification = [= `RNBadge | `RNSound | `RNAlert ];

IFDEF IOS THEN
external showNativeWaiter: Point.t -> unit = "ml_showActivityIndicator";
external hideNativeWaiter: unit -> unit = "ml_hideActivityIndicator";
external _deviceIdentifier: unit -> string = "ml_deviceIdentifier";
value deviceIdentifier () = Some (_deviceIdentifier ());
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
external _deviceIdentifier: unit -> string = "ml_device_id";
value deviceIdentifier () = Some (_deviceIdentifier ());
ELSE
value openURL _ = ();
value sendEmail recepient ~subject ?(body="") () = (); 
value deviceIdentifier () = None;
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


IFDEF PC THEN
value getLocale () = "en";
ELSE
external getLocale: unit -> string = "ml_getLocale";
ENDIF;

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
ENDIF;

value addExceptionInfo (_:string) = ();
value setSupportEmail (_:string) = ();
ENDIF;

IFDEF ANDROID THEN

external miniunz : string -> string -> option string -> unit = "ml_miniunz";
external _apkPath : unit -> string = "ml_apkPath";
external _externalStoragePath : unit -> string = "ml_externalStoragePath";
external setAssetsDir : string -> unit = "ml_setAssetsDir";
external _getVersion : unit -> string = "ml_getVersion";
external rm : string -> string -> (unit -> unit) -> unit = "ml_rm";
external downloadExpansions : unit -> unit = "ml_downloadExpansions";
external getExpansionPath : bool -> string = "ml_getExpansionPath";
external getExpansionVer : bool -> int = "ml_getExpansionVer";

value unzipCbs = Hashtbl.create 0;

value unzip ?prefix zipPath dstPath cb =
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

Callback.register "unzipComplete" unzipComplete;    

value apkPath = _apkPath ();
value apkVer = _getVersion ();
value externalStoragePath = _externalStoragePath ();
value assetsVerFilename = externalStoragePath ^ "assets/a" ^ apkVer;
value expansionVerFilename = externalStoragePath ^ "assets/e" ^ (string_of_int (getExpansionVer True));

value assetsExtracted () =
  Sys.file_exists assetsVerFilename;

value expansionExtracted () =
  Sys.file_exists expansionVerFilename;

value extractAssets cb =
  let assetsPath = externalStoragePath ^ "assets" in
    let cb success =
      (
        if success then
        (
          setAssetsDir (assetsPath ^ "/");
          close_out (open_out assetsVerFilename);
        )
        else ();

        cb success;
      )
    in
      unzip ~prefix:"assets" apkPath externalStoragePath cb;

value extractExpansions cb =
(
  Callback.register "expnsDownloadComplete" (
    fun () -> unzip (getExpansionPath True) (externalStoragePath ^ "assets/") (
      fun success ->
      (
        if success then close_out (open_out expansionVerFilename) else ();
        cb success;
      )
    )
  );
  downloadExpansions ();
);

value extractAssetsAndExpansionsIfRequired cb =
  if (assetsExtracted ()) && (expansionExtracted ()) then
  (
    setAssetsDir (externalStoragePath ^ "assets/");
    cb True;
  )    
  else
    let extractAssetsRes = ref None
    and extractExpansionRes = ref None in
      let callCb () =
        match (!extractAssetsRes, !extractExpansionRes) with
        [ (Some ear, Some eer) ->  cb (ear && eer)
        | _ -> ()
        ]
      in
        let rmCb () =
        (
          extractAssets (fun success -> ( extractAssetsRes.val := Some success; callCb (); ));
          extractExpansions (fun success -> ( extractExpansionRes.val := Some success; callCb (); ));
        )
        in
          rm (ExtString.String.slice ~last:~-1 externalStoragePath) "assets" rmCb;

ELSE
value extractAssets (cb:(bool -> unit)) = ();
value assetsExtracted () = False;
ENDIF;

external getMACID: unit -> string = "ml_getMACID";
