value init : string -> unit;

module Session : 
  sig
    value permissions : ref (list string);
    value get_auth_token : unit -> string;
    value authorize : list string -> unit;
    value with_auth_check : (bool -> unit) -> unit;
  end;


module GraphAPI :
  sig
    type delegate = 
    {
      fb_request_did_fail   : option (string -> unit);    
      fb_request_did_load   : option (Ojson.t -> unit)
    };

    value request : string -> list (string*string) -> ?delegate:option delegate -> unit -> unit;
  end;


module Dialog :
  sig
    type delegate = 
    {
      fb_dialog_did_complete              : option (unit -> unit);
      fb_dialog_did_cancel                : option (unit -> unit);
      fb_dialog_did_fail                  : option (string -> unit)
    };

    type users_filter = [ All | AppUsers | NonAppUsers ];

    value apprequest : ?message:string -> ?recipients:list string -> ?filter:users_filter -> ?title:string -> ?delegate:option delegate -> unit -> unit;
  end;
  
