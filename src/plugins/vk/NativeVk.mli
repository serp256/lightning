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

type t;
type fail = string -> unit;

value authorize: ~appid:string -> ~permissions:list string -> ?fail:fail -> ~success:(t -> unit) -> ?force:bool -> unit -> unit;
value friends: ?fail:fail -> ~success:(list User.t -> unit) -> t -> unit;
value users: ?fail:fail -> ~success:(list User.t -> unit)-> ~ids:list string -> t -> unit;
(*
value apprequest:?fail:fail -> ~success:(string-> unit) -> ?request_type: string -> ~text: string -> ~user_id:string -> unit;
*)
value token: t -> string;
value uid: t -> string;
value logout: unit -> unit;
