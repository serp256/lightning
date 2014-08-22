module Friend =
	struct
		type gender = [= `male | `female | `none ];

		type t =
			{
				id: string;
				name: string;
				gender: gender;
			};

		value create id name gender = { id; name; gender = match gender with [ 1 -> `female | 2 -> `male | _ -> `none ] };
		value id t = t.id;
		value name t = t.name;
		value gender t = t.gender;
		value toString t = Printf.sprintf "%s (id %s, gender %s)" t.name t.id (match t.gender with [ `male -> "male" | `female -> "female" | `none -> "not specified"]);
	end;

type t = unit;
type fail = string -> unit;

IFDEF PC THEN
value authorize ~appid ~permissions ?fail ~success () = ();
value friends ?fail ~success t = ();
value token _ = "";
value uid _ = "";
ELSE

Callback.register "create_friend" Friend.create;

external authorize: ~appid:string -> ~permissions:list string -> ?fail:fail -> ~success:(t -> unit) -> unit -> unit = "ml_vk_authorize";
external friends: ?fail:fail -> ~success:(list Friend.t -> unit) -> t -> unit = "ml_vk_friends";
external token: t -> string = "ml_vk_token";
external uid: t -> string = "ml_vk_uid";
ENDIF;
