type httpMethod = [= `get | `post ];
module User =
  struct
    type gender = [= `male | `female | `none ];

    type t =
      {
        id: string;
        name: string;
        gender: gender;
        photo: string;
        online: bool;
        lastSeen: float;
      };

    value create id name gender photo online lastSeen= { id; name; gender = match gender with [ 1 -> `female | 2 -> `male | _ -> `none ]; photo; online; lastSeen };
    value id t = t.id;
    value name t = t.name;
    value gender t = t.gender;
    value photo t = t.photo;
    value online t = t.online;
    value lastSeen t = t.lastSeen;
    value toString t = 
      let time = 
        let tm = Unix.localtime t.lastSeen in
        Printf.sprintf
        "%04d.%02d.%02d - %02d:%02d:%02d"
        (tm.Unix.tm_year + 1900) (tm.Unix.tm_mon + 1) (tm.Unix.tm_mday) tm.Unix.tm_hour tm.Unix.tm_min tm.Unix.tm_sec in
      Printf.sprintf "%s (id %s, gender %s, photo %s, online %B, lastSeen %s)" t.name t.id (match t.gender with [ `male -> "male" | `female -> "female" | `none -> "not specified"]) t.photo t.online time;
  end;


IFDEF PC THEN

value init ~appId () = ();

value authorize ?permissions ~success ~fail ?force () = ();
value logout () = ();
value loggedIn () = False;

value accessToken () = "";
value uid () = "";
value apprequest ~title ~message ?recipient ?data ?successCallback ?failCallback () = ();
value graphrequest ~path ?params ?success ?fail?httpMethod () = ();

value share ?text ?link ?picUrl ?success ?fail () = match fail with [ Some fail -> fail "this method not supported on pc and ios" | _ -> () ];
value friends ?invitable ?fail ~success () = ();
value users ?fail ~success ~ids () = ();
ELSE

external share: ?text:string -> ?link:string -> ?picUrl:string -> ?success:(unit -> unit) -> ?fail:(string -> unit) -> unit -> unit = "ml_fb_share_byte" "ml_fb_share";

external _init: string -> unit = "ml_fbInit";
external uid: unit -> string = "ml_fbUid";

external _authorize: option (list string) -> ~force:bool -> unit -> unit = "ml_fbConnect";
external loggedIn: unit -> bool  = "ml_fbLoggedIn";
external logout: unit -> unit = "ml_fbDisconnect";

external accessToken: unit-> string = "ml_fbAccessToken";

external _apprequest: string -> string -> option string -> option string -> option (list string -> unit) -> option (string -> unit) -> unit = "ml_fbApprequest_byte" "ml_fbApprequest";
value apprequest ~title ~message ?recipient ?data ?successCallback ?failCallback () = _apprequest title message recipient data successCallback failCallback;

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
Callback.register "fb_create_user" User.create;

value init ~appId () = _init appId;

value authorize ?permissions ~success ~fail ?(force=False) () =
		(
			_successCallback.val := Some success;
			_failCallback.val := Some fail;

			_authorize permissions ~force ();
    );		
value graphrequestSuccess json callback = callback json;
value graphrequest ~path ?params ?success ?fail ?(httpMethod = `get) () = _graphrequest path params success fail httpMethod;

external _friends: ~invitable:bool -> ?fail:(string -> unit) -> ~success:(list User.t-> unit) -> unit -> unit = "ml_fbFriends"; 
value friends ?(invitable=False) ?fail ~success () = _friends ~invitable ?fail ~success ();
external _users: option (string -> unit) -> (list User.t -> unit) -> string -> unit = "ml_fbUsers";
value users ?fail ~success ~ids t =
    let ids = String.concat "," ids in
        _users fail success ids;
ENDIF;
