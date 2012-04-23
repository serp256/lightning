open SNTypes;

type permission = [ Valuable_access | Set_status | Photo_content ];

type permissions = list permission;

module type Param = sig
  value appid:string;
  value permissions:permissions;
  value application_key: string;
  value private_key: string;
end;

module Make(P:Param) : sig
(*   value init : string -> string -> string -> permissions -> unit; *)
    
  value call_method : ?delegate:delegate -> string -> list (string*string) -> unit;

  value get_access_token : unit -> string;

  value get_refresh_token : unit -> string;
end;

