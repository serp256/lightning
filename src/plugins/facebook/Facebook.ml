type connect = unit;

IFDEF PC THEN

value init ~appId () = ();

value connect ?permissions ~successCallback ~failCallback () = ();
value disconnect connect = ();
value loggedIn () = None;

value accessToken connect = "";
value apprequest ~title ~message ?recipient ?data ?successCallback ?failCallback connect = ();
value graphrequest ~path ?params ?successCallback ?failCallback connect = ();
value sharePicUsingNativeApp ~fname:string ~text:string () = False;
value sharePic ?success ?fail ~fname ~text connect = ();

value share ?text ?link ?picUrl ?success ?fail () = match fail with [ Some fail -> fail "this method not supported on pc and ios" | _ -> () ];
ELSE

external sharePic: ?success:(unit -> unit) -> ?fail:(string -> unit) -> ~fname:string -> ~text:string -> connect -> unit = "ml_fb_share_pic";

IFDEF ANDROID THEN
external share: ?text:string -> ?link:string -> ?picUrl:string -> ?success:(unit -> unit) -> ?fail:(string -> unit) -> unit -> unit = "ml_fb_share_byte" "ml_fb_share";
ELSE
value share ?text ?link ?picUrl ?success ?fail () = match fail with [ Some fail -> fail "this method not supported on pc and ios" | _ -> () ];
ENDIF;



type status = [ NotConnected | Connecting | Connected ];

external _init: string -> unit = "ml_fbInit";

external _connect: option (list string) -> unit -> unit = "ml_fbConnect";
external _loggedIn: unit -> option connect = "ml_fbLoggedIn";
external _disconnect: connect -> unit = "ml_fbDisconnect";

external _accessToken: connect -> string = "ml_fbAccessToken";
external _apprequest: string -> string -> option string -> option string -> option (list string -> unit) -> option (string -> unit) -> unit = "ml_fbApprequest_byte" "ml_fbApprequest";
external _graphrequest: string -> option (list (string * string)) -> option (string -> unit) -> option (string -> unit) -> unit = "ml_fbGraphrequest";

value status = ref NotConnected;
value _successCallback = ref None;
value _failCallback = ref None;

value disconnect connect = _disconnect connect;

value success () =
(
	status.val := Connected;

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
	status.val := NotConnected;

	match !_failCallback with
	[ Some failCallback ->
		(
			failCallback description;
			_failCallback.val := None;
		)
	| _ -> (* failwith "something wrong with facebook connect fail callback" *)()
	];
);

value sessionClosed () = status.val := NotConnected;

Callback.register "fb_success" success;
Callback.register "fb_fail" fail;
Callback.register "fb_sessionClosed" sessionClosed;

value init ~appId () = _init appId;

value connect ?permissions ~successCallback ~failCallback () =
	match !status with
	[ Connected -> successCallback ()
	| Connecting -> ()
        (*failwith "facebook connecting alredy in progress"*)
	| NotConnected ->
		(
			_successCallback.val := Some successCallback;
			_failCallback.val := Some failCallback;

			status.val := Connecting;
			_connect permissions ();
		)		
	];

value loggedIn () = _loggedIn ();

value accessToken connect = _accessToken connect;

value apprequest ~title ~message ?recipient ?data ?successCallback ?failCallback connect = _apprequest title message recipient data successCallback failCallback;

value graphrequestSuccess json callback = callback json;

value graphrequest ~path ?params ?successCallback ?failCallback connect = _graphrequest path params successCallback failCallback;

ENDIF;
