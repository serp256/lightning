open SNTypes;

type permission = [ Valuable_access | Set_status | Photo_content ];

type permissions = list permission;

value init : string -> string -> string -> permissions -> unit;
  
value call_method : ?delegate:option delegate -> string -> list (string*string) -> unit;

