open SNTypes;

type permission = [ Photos | Guestbook | Stream | Messages | Events ];

type permissions = list permission;

(* value init : string -> string -> permissions -> unit; *)
module type Param = sig
  value appid: string;
  value private_key: string;
  value permissions: permissions;
end;



module Make(P:Param) : sig
    
  value call_method : ?delegate:delegate -> string -> list (string*string) -> unit;

  value get_access_token : unit -> string;

  value get_user_id : unit -> string;

  value get_refresh_token : unit -> string;

end;
