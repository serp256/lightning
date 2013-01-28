type connect = unit;

IFDEF PC THEN

value init ~appId () = ();

value connect ~successCallback ~failCallback () = ();
value disconnect connect = ();
value loggedIn () = None;

value accessToken connect = "";
value apprequest ~title ~message ?recipient ?data ?successCallback ?failCallback connect = ();
value graphrequest ~path ?params ?successCallback ?failCallback connect = ();

ELSE

type status = [ NotConnected | Connecting | Connected ];

external _init: string -> unit = "ml_fbInit";

external _connect: unit -> unit = "ml_fbConnect";
external _loggedIn: unit -> option connect = "ml_fbLoggedIn";
external _disconnect: connect -> unit = "ml_fbDisconnect";

external _accessToken: connect -> string = "ml_fbAccessToken";
external _apprequest: connect -> string -> string -> option string -> option string -> option (list string -> unit) -> option (string -> unit) -> unit = "ml_fbApprequest_byte" "ml_fbApprequest";
external _graphrequest: connect -> string -> option (list (string * string)) -> option (Ojson.json -> unit) -> option (string -> unit) -> unit = "ml_fbGraphrequest";

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
	| _ -> failwith "something wrong with facebook connect success callback"
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
	| _ -> failwith "something wrong with facebook connect fail callback"
	];
);

value sessionClosed () = status.val := NotConnected;

Callback.register "fb_success" success;
Callback.register "fb_fail" fail;
Callback.register "fb_sessionClosed" sessionClosed;

value init ~appId () = _init appId;

value connect  ~successCallback ~failCallback () =
	match !status with
	[ Connected -> successCallback ()
	| Connecting -> ()
        (*failwith "facebook connecting alredy in progress"*)
	| NotConnected ->
		(
			_successCallback.val := Some successCallback;
			_failCallback.val := Some failCallback;

			status.val := Connecting;
			_connect ();
		)		
	];

value loggedIn () = _loggedIn ();

value accessToken connect = _accessToken connect;

value apprequest ~title ~message ?recipient ?data ?successCallback ?failCallback connect = _apprequest connect title message recipient data successCallback failCallback;

value graphrequestSuccess json callback = callback (Ojson.from_string json);

Callback.register "fb_graphrequestSuccess" graphrequestSuccess;

value graphrequest ~path ?params ?successCallback ?failCallback connect = _graphrequest connect path params successCallback failCallback;

ENDIF;
