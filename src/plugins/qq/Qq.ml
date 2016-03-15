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
value init ~appid ~uid ~token ~expires () = ();
value authorize ?fail ~success ?force () = ();
value friends ?fail ~success t = ();
value users ?fail ~success ~ids t = ();
value token _ = "";
value uid _ = "";
value logout _ = ();
value apprequest ?fail ~success ?request_type ~text ~user_id () = ();
ELSE
Callback.register "qq_create_user" User.create;

external init: ~appid:string -> ~uid:string -> ~token: string -> ~expires: string -> unit -> unit = "ml_qq_init";
external authorize: ?fail:fail -> ~success:(unit -> unit) -> ~force:bool -> unit -> unit = "ml_qq_authorize";
value authorize ?fail ~success ?(force = False) = authorize ?fail ~success ~force;

external token: unit -> string = "ml_qq_token";
external uid: unit -> string = "ml_qq_uid";
external logout: unit -> unit= "ml_qq_logout";

external friends: ?fail:fail -> ~success:(list User.t -> unit) -> unit -> unit = "ml_qq_friends";
external users: option fail -> (list User.t -> unit) -> string -> unit = "ml_vk_users";
value users ?fail ~success ~ids t =
	let ids = String.concat "," ids in
		users fail success ids;

(*not available for apps not in mobile catalog*)
external _apprequest:?fail:fail -> ~success:(string -> unit) -> ~user_id:string -> unit = "ml_vk_apprequest";
value apprequest ?fail ~success ?request_type ~text ~user_id () = _apprequest ?fail ~success ~user_id;
ENDIF;
