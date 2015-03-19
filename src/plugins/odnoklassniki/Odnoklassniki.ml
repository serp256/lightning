
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
  value init ~appId ~appSecret ~appKey = ();
  value authorize ?fail ~success () = ();
  value friends ?fail ~success () = ();
  value users ?fail ~success ~ids () = ();
  value token _ = "";
  value uid _ = "";
ELSE
  Callback.register "create_user" User.create;

  external init: ~appId:string -> ~appSecret:string -> ~appKey:string -> unit = "ok_init"; 
  external authorize: ?fail:fail -> ~success:(unit -> unit) -> unit -> unit = "ok_authorize"; 
  external friends: ?fail:fail -> ~success:(list User.t-> unit) -> unit -> unit = "ok_friends"; 
  external users: option fail -> (list User.t -> unit) -> string -> unit = "ok_users";
  value users ?fail ~success ~ids t =
      let ids = String.concat "," ids in
          users fail success ids;
  external token: unit -> string = "ok_token";
  external uid: unit -> string = "ok_uid";
ENDIF;
