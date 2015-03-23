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

value init: ~appId:string -> ~appSecret:string -> ~appKey:string -> unit;
value authorize: ?fail:fail -> ~success:(unit -> unit) -> ?force: bool -> unit -> unit;
value friends: ?fail:fail -> ~success:(list User.t -> unit) -> unit -> unit;
value users: ?fail:fail -> ~success:(list User.t -> unit)-> ~ids:list string -> unit -> unit;
value token: unit -> string;
value uid: unit -> string;
value logout: unit -> unit;

