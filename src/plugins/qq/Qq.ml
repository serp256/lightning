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

		value create id name gender photo online lastSeen = { id; name; gender = match gender with [ 1 -> `female | 2 -> `male | _ -> `none ]; photo; online; lastSeen };
		value id t = t.id;
		value name t = t.name;
		value gender t = t.gender;
		value photo t = t.photo;
		value online t = t.online;
		value lastSeen t = t.lastSeen;
		value toString t = Printf.sprintf "%s (id %s, gender %s, photo %s, online %B, lastSeen %f)" t.name t.id (match t.gender with [ `male -> "male" | `female -> "female" | `none -> "not specified"]) t.photo t.online t.lastSeen;
	end;

type t = unit;
type fail = string -> unit;

IFDEF PC THEN
value init ~appid ?uid ?token ?expires () = ();
value authorize ?fail ~success ?force () = ();
value token _ = "";
value uid _ = "";
value logout _ = ();
value share ~title ~summary ~url ~imageUrl () = ();
ELSE
Callback.register "qq_create_user" User.create;

external init: ~appid:string -> ~uid:option string -> ~token: option string -> ~expires: option string -> unit -> unit = "ml_qq_init";
value init ~appid ?uid ?token ?expires () = init ~appid ~uid ~token ~expires ();
external authorize: ?fail:fail -> ~success:(unit -> unit) -> ~force:bool -> unit -> unit = "ml_qq_authorize";
value authorize ?fail ~success ?(force = False) = authorize ?fail ~success ~force;

external share: ~title:string -> ~summary: string -> ~url: string ->  ~imageUrl: string -> unit -> unit = "ml_qq_share";

external token: unit -> string = "ml_qq_token";
external uid: unit -> string = "ml_qq_uid";
external logout: unit -> unit= "ml_qq_logout";

ENDIF;
