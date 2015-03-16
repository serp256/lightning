module User:
  sig
    type gender = [= `male | `female | `none ];
    type t;

    value id: t -> string;
    value name: t -> string;
    value gender: t -> gender;
    value photo: t -> string;
    value online: t -> bool;
    value lastSeen: t -> float;
    value toString: t -> string;
  end;

type fail = string -> unit;

value init: string -> string -> string -> unit;
value authorize: ?fail:fail -> ~success:(unit -> unit) -> unit -> unit;
value friends: ?fail:fail -> ~success:(list User.t -> unit) -> unit -> unit;
value users: ?fail:fail -> ~success:(list User.t -> unit)-> ~ids:list string -> unit -> unit;
(*value authorize: ~appid:string -> ~permissions:list string -> ?fail:fail -> ~success:(t -> unit) -> ?force:bool -> unit -> unit;
value friends: ?fail:fail -> ~success:(list User.t -> unit) -> t -> unit;
value users: ?fail:fail -> ~success:(list User.t -> unit)-> ~ids:list string -> t -> unit;
value token: t -> string;
value uid: t -> string;
*)

