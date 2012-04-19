

type auth_grant = [ Code | Implicit ];

(* инфа о токене *)
type token_info = 
{
  access_token  : string;
  expires_in    : option int;
  token_type    : option string;
  refresh_token : option string;
  other_params  : list (string*string);  
};


type error_response = 
{
  error : string;
  description: string;
};


type auth_response = [ Error of error_response | Token of token_info ];

(* value create : string -> string -> t; *)

type close_button = 
  {
    cb_insets: (int*int*int*int);
    cb_visible: bool;
    cb_image: option string;
  };

module Make (P:sig value auth_endpoint: string; value token_endpoint: string; value close_button: option close_button; end): sig

  value authorization_grant : auth_grant -> string -> string -> list (string*string) -> (auth_response -> unit) -> unit;
  value refresh_token : string -> string -> list (string*string) -> (auth_response -> unit) -> unit;
(*
  value  set_close_button_insets : int -> int -> int -> int -> unit;
  value  set_close_button_visible : bool -> unit;
  value  set_close_button_image_name : string -> unit;
*)

end;
