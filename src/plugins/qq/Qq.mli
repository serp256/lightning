module User:
	sig
		type t;
		type gender = [= `male | `female | `none ];

		value id: t -> string;
		value name: t -> string;
    value gender: t -> gender;
		value photo: t -> string;
		value online: t -> bool;
		value lastSeen: t -> float;
		value toString: t -> string;
	end;

type fail = string -> unit;

value init: ~appid:string -> ~uid:string -> ~token: string -> ~expires: string -> unit -> unit;
value authorize: ?fail:fail -> ~success:(unit -> unit) -> ?force:bool -> unit -> unit;
value token: unit -> string;
value uid: unit -> string;
value logout: unit -> unit;

value friends: ?fail:fail -> ~success:(list User.t -> unit) -> unit -> unit;
value users: ?fail:fail -> ~success:(list User.t -> unit)-> ~ids:list string -> unit -> unit;

value apprequest:?fail:fail -> ~success:(string-> unit) -> ?request_type: string -> ~text: string -> ~user_id:string -> unit -> unit;

