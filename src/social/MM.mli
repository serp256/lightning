open SNTypes;

type permission = [ Photos | Guestbook | Stream | Messages | Events ];

type permissions = list permission;

value init : string -> string -> permissions -> unit;
  
value call_method : ?delegate:option delegate -> string -> list (string*string) -> unit;

value get_access_token : unit -> string;

value get_user_id : unit -> string;

value get_refresh_token : unit -> string;