open SNTypes;

type permission = [ Photos | Guestbook | Stream | Messages | Events ];

type permissions = list permission;

value init : string -> string -> list (string*string) -> unit;
  
value call_method : ?delegate:option delegate -> string -> list (string*string) -> unit;



