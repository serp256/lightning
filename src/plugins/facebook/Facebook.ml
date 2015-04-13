type connect = unit;
type httpMethod = [= `get | `post ];

IFDEF PC THEN

value init ~appId () = ();

value connect ?permissions ~successCallback ~failCallback () = ();
value disconnect = ();
value loggedIn () = None;

value accessToken () = "";
(*
value apprequest ~title ~message ?recipient ?data ?successCallback ?failCallback () = ();
*)
value graphrequest ~path ?params ?successCallback ?failCallback ?httpMethod () = ();

(* value sharePicUsingNativeApp ~fname:string ~text:string () = False; *)
(*
value sharePic ?success ?fail ~fname ~text connect = ();

value share ?text ?link ?picUrl ?success ?fail () = match fail with [ Some fail -> fail "this method not supported on pc and ios" | _ -> () ];
*)
ELSE

(*
external sharePic: ?success:(unit -> unit) -> ?fail:(string -> unit) -> ~fname:string -> ~text:string -> connect -> unit = "ml_fb_share_pic";
*)

(*
IFDEF ANDROID THEN
external share: ?text:string -> ?link:string -> ?picUrl:string -> ?success:(unit -> unit) -> ?fail:(string -> unit) -> unit -> unit = "ml_fb_share_byte" "ml_fb_share";
ELSE
value share ?text ?link ?picUrl ?success ?fail () = match fail with [ Some fail -> fail "this method not supported on pc and ios" | _ -> () ];
ENDIF;
*)



external _init: string -> unit = "ml_fbInit";

external _connect: option (list string) -> unit -> unit = "ml_fbConnect";
external loggedIn: unit -> bool  = "ml_fbLoggedIn";
external disconnect: unit -> unit = "ml_fbDisconnect";

external accessToken: unit-> string = "ml_fbAccessToken";
(*
external _apprequest: string -> string -> option string -> option string -> option (list string -> unit) -> option (string -> unit) -> unit = "ml_fbApprequest_byte" "ml_fbApprequest";
*)
external _graphrequest: string -> option (list (string * string)) -> option (string -> unit) -> option (string -> unit) -> httpMethod -> unit = "ml_fbGraphrequest";

value _successCallback = ref None;
value _failCallback = ref None;

value success () =
(
	match !_successCallback with
	[ Some successCallback ->
		(
			successCallback ();
			_successCallback.val := None;
		)
	| _ -> (* failwith "something wrong with facebook connect success callback" *)()
	];
);

value fail description =
(
	match !_failCallback with
	[ Some failCallback ->
		(
			failCallback description;
			_failCallback.val := None;
		)
	| _ -> (* failwith "something wrong with facebook connect fail callback" *)()
	];
);


Callback.register "fb_success" success;
Callback.register "fb_fail" fail;

value init ~appId () = _init appId;

value connect ?permissions ~successCallback ~failCallback () =
		(
			_successCallback.val := Some successCallback;
			_failCallback.val := Some failCallback;

			_connect permissions ();
    );		
(*value apprequest ~title ~message ?recipient ?data ?successCallback ?failCallback () = _apprequest title message recipient data successCallback failCallback;
 * *)
value graphrequestSuccess json callback = callback json;
value graphrequest ~path ?params ?successCallback ?failCallback ?(httpMethod = `get) () = _graphrequest path params successCallback failCallback httpMethod;

ENDIF;
