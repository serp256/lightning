

type auth_grant = [ Code of string | Implicit ];

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
    cb_image: option string;
  };


value authorization_grant: 
  ~client_id:string -> ~auth_endpoint:string -> ~redirect_uri:string -> 
  ~gtype:auth_grant -> ~params:list (string*string) -> ?close_button:close_button ->
  (auth_response -> unit) -> unit;

value refresh_token : 
  ~client_id:string -> ~token_endpoint:string -> ~rtoken:string -> 
  ~params:list (string*string) -> (auth_response -> unit) -> unit;

(*
  value  set_close_button_insets : int -> int -> int -> int -> unit;
  value  set_close_button_visible : bool -> unit;
  value  set_close_button_image_name : string -> unit;
*)
