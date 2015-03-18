
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
    value toString t = 
      let time = 
        let tm = Unix.localtime t.lastSeen in
        Printf.sprintf
        "%04d.%02d.%02d - %02d:%02d:%02d"
        (tm.Unix.tm_year + 1900) (tm.Unix.tm_mon + 1) (tm.Unix.tm_mday) tm.Unix.tm_hour tm.Unix.tm_min tm.Unix.tm_sec in
      Printf.sprintf "%s (id %s, gender %s, photo %s, online %B, lastSeen %s)" t.name t.id (match t.gender with [ `male -> "male" | `female -> "female" | `none -> "not specified"]) t.photo t.online time;
  end;

type fail = string -> unit;

IFDEF PC THEN
  value init _ _ _ = ();
  value authorize ?fail ~success () = ();
  value friends ?fail ~success () = ();
  value users ?fail ~success ~ids () = ();
ELSE
  Callback.register "create_user" User.create;

  external init: string -> string -> string -> unit = "ok_init"; 
  external authorize: ?fail:fail -> ~success:(unit -> unit) -> unit -> unit = "ok_authorize"; 
  external friends: ?fail:fail -> ~success:(list User.t-> unit) -> unit -> unit = "ok_friends"; 
  external users: option fail -> (list User.t -> unit) -> string -> unit = "ok_users";
  value users ?fail ~success ~ids t =
      let ids = String.concat "," ids in
          users fail success ids;
(*
Callback.register "create_user" User.create;

external authorize: ~appid:string -> ~permissions:list string -> ?fail:fail -> ~success:(t -> unit) -> ~force:bool -> unit -> unit = "ml_vk_authorize_byte" "ml_vk_authorize";
value authorize ~appid ~permissions ?fail ~success ?(force = False) = authorize ~appid ~permissions ?fail ~success ~force;
external friends: ?fail:fail -> ~success:(list User.t -> unit) -> t -> unit = "ml_vk_friends";
external users: option fail -> (list User.t -> unit) -> string -> unit = "ml_vk_users";
value users ?fail ~success ~ids t =
  let ids = String.concat "," ids in
    users fail success ids;
external token: t -> string = "ml_vk_token";
external uid: t -> string = "ml_vk_uid";
*)
ENDIF;
