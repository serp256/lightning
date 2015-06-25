type httpMethod = [= `get | `post ];

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

value init: ~appId:string -> unit -> unit;

value authorize : ?permissions:(list string) -> ~success:(unit -> unit) -> ~fail:(string -> unit) -> ?force:bool -> unit -> unit;
value loggedIn: unit -> bool;

value accessToken: unit -> string;
value uid: unit -> string;

(*callbacks not implemented yet*)
value apprequest: ~title:string -> ~message:string -> ?recipient:string -> ?data:string -> ?successCallback:(list string -> unit) -> ?failCallback:(string -> unit) -> unit -> unit; (* list string in success callback -- user ids, which received request *)

value graphrequest: ~path:string -> ?params:(list (string * string)) -> ?success:(string -> unit) -> ?fail:(string -> unit) -> ?httpMethod:httpMethod -> unit -> unit;
value logout: unit -> unit;

value share: ?text:string -> ?link:string -> ?picUrl:string -> ?success:(unit -> unit) -> ?fail:(string -> unit) -> unit -> unit; 
value friends: ?invitable:bool -> ?fail:(string -> unit) -> ~success:(list User.t -> unit) -> unit -> unit;
value users: ?fail:(string -> unit) -> ~success:(list User.t -> unit)-> ~ids:list string -> unit -> unit;
(*
value sharePic: ?success:(unit -> unit) -> ?fail:(string -> unit) -> ~fname:string -> ~text:string -> connect -> unit;
value share: ?text:string -> ?link:string -> ?picUrl:string -> ?success:(unit -> unit) -> ?fail:(string -> unit) -> unit -> unit; (* This functions uses share dialog, integrated into Facebook app (Facebook app must be installed). No need to call "connect", "init" function call with app id is enough. *)

*)

(*value sharePicUsingNativeApp: ~fname:string -> ~text:string -> unit -> bool; (* this method works only on android, share on ios using next method; text parameter skipped now due to facebook policy *)*)
