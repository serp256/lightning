
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
ELSE
value openURL _ = ();
value sendEmail recepient ~subject ?(body="") () = (); 
ENDIF;

value deviceIdentifier () = None;
ENDIF;

type stage_constructor = float -> float -> Stage.c;

(* value _stage: ref (option (float -> float -> stage eventTypeDisplayObject eventEmptyData)) = ref None; *)

IFDEF SDL THEN
value init s = 
  let s = (s :> stage_constructor) in
  Sdl_run.run s;
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


IFDEF SDL THEN
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

external malinfo: unit -> malinfo = "ml_malinfo";

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
external extractAssets : unit -> unit = "ml_extractAssets";
ELSE
value extractAssets () = ();
ENDIF;

external getMACID: unit -> string = "ml_getMACID";
