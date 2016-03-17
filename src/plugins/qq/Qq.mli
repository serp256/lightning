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

value init: ~appid:string -> ?uid:string -> ?token: string -> ?expires: string -> unit -> unit;
value authorize: ?fail:fail -> ~success:(unit -> unit) -> ?force:bool -> unit -> unit;
value token: unit -> string;
value uid: unit -> string;
value logout: unit -> unit;
value share: ~title:string -> ~summary:string -> ~url: string -> ~imageUrl: string -> unit -> unit;


