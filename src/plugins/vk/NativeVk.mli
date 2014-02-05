module Friend:
	sig
		type t;
		type gender = [= `male | `female | `none ];

		value id: t -> string;
		value name: t -> string;
		value gender: t -> gender;
		value toString: t -> string;
	end;

type t;
type fail = string -> unit;

value authorize: ~appid:string -> ~permissions:list string -> ?fail:fail -> ~success:(t -> unit) -> unit -> unit;
value friends: ?fail:fail -> ~success:(list Friend.t -> unit) -> t -> unit;