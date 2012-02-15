type vk_error = [ IOError | VKError of (int*string*list (string*Ojson.t)) | VKAuthCancelled];

type delegate = 
{
  vk_method_call_error : option (vk_error -> unit);
  vk_method_call_success: option (Ojson.t -> unit)
};

value vk_init : string -> string -> unit;

value vk_call_method : ?delegate: option delegate -> string -> list (string*string) -> unit; 

value vk_get_auth_token : unit -> string;

