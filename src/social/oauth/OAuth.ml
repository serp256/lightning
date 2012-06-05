
type close_button = 
  {
    cb_insets: (int*int*int*int);
    cb_image: option string;
  };


open Ojson;

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

type auth_grant = [ Code of string | Implicit ];

type delegate = (auth_response -> unit);




(* 
   Парсит урл-encoded строку и достает данные о токене.
   Если нет данных рейзит Not_found. 
*)
value token_info_of_string str = 
  let id x = x
  and assoc_opt key list f = 
    try 
      let v = List.assoc key list 
      in Some (f v)
    with [ Not_found -> None ]
  in 
  let params = UrlEncoding.dest_url_encoded_parameters str in     
  let access_token = List.assoc "access_token" params
  and expires_in = assoc_opt "expires_in" params int_of_string
  and token_type = assoc_opt "token_type" params id 
  and refresh_token = assoc_opt "refresh_token" params id
  and other_params = List.filter (fun (k,_) -> match k with [ "access_token" | "expires_in" | "token_type" | "refresh_token" -> False | _ -> True ]) params
  in  { access_token; expires_in; token_type; refresh_token; other_params };


value error_info_of_string str = 
  let params = UrlEncoding.dest_url_encoded_parameters str in
  let error  = List.assoc "error" params 
  and description   = try List.assoc "error_description" params with [ _ -> "" ] 
  in { error; description };




(* *)
value extarct_params_string_from_url url = 
  let substr_from_symbol s = 
    let idx = String.index url s in
    String.sub url (idx + 1) ((String.length url) - idx - 1)
  in
  try 
    substr_from_symbol '#'
  with [ Not_found -> 
    try 
      substr_from_symbol '?' 
    with [ Not_found -> "" ]
  ];  
  


(* 
  урл должен содержать фрагментную часть, отделенную '#'. 
  Именно там находятся нужные нам парамерты 
*)
value auth_response_of_url url = 
  let pstr = extarct_params_string_from_url url in 
  try 
    Token (token_info_of_string pstr)
  with [ Not_found ->
    try 
      Error (error_info_of_string pstr)
    with [ Not_found -> Error { error = "invalid_response_data"; description = "Response neither error nor access_token" } ]
  ];
    

(* *)
value params_of_json json =
  match json with
  [ `Assoc dict ->
      List.map begin fun (k,v) ->
        let val = 
          match v with 
          [ `Int i -> string_of_int i
          | `String s | `Intlit s -> s
          | `Bool b -> string_of_bool b
          | `Float f -> string_of_float f
          | _ -> raise Not_found
          ]
        in (k, val)
      end dict
  | _ -> raise Not_found
  ];


(* *)
value token_info_of_json json = 
  
  let ojson_opt_param pname list = 
    match List.mem_assoc pname list with
    [ False -> None
    | True  -> Some (List.assoc pname list)
    ] in 
  let ojson_opt_int_param pname list = 
    match ojson_opt_param pname list with
    [ None -> None
    | Some v -> 
        match v with
        [ `Int i -> Some i
        | `Intlit s | `String s -> Some (int_of_string s)
        | _ -> None
        ]
    ] in
  let ojson_opt_str_param pname list = 
    match ojson_opt_param pname list with 
    [ None -> None
    | Some v -> 
        match v with
        [ `String s | `Intlit s -> Some s
        | _ -> None
        ]
    ]
  in     

  let params = params_of_json json in 
  match json with
  [ `Assoc dict ->
      match ojson_opt_str_param "access_token" dict with
      [ None -> raise Not_found
      | Some access_token -> 
          let expires_in = ojson_opt_int_param "expires_in" dict
          and token_type = ojson_opt_str_param "token_type" dict
          and refresh_token = ojson_opt_str_param "refresh_token" dict
          and other_params = List.filter (fun (k,_) -> match k with [ "access_token" | "expires_in" | "token_type" | "refresh_token" -> False | _ -> True ]) params
          in { access_token; expires_in; token_type; refresh_token; other_params }
      ]
  | _ -> raise Not_found 
  ];
  

(* *)
value error_of_json json = 
  match json with
  [ `Assoc dict -> 
      match List.assoc "error" dict with
      [ `String error -> 
          let description = 
            try 
              match List.assoc "error_description" dict with
              [ `String s -> s
              | _ -> ""
              ]
            with [ Not_found -> "" ]  
          in { error; description }
          
      | _ -> raise Not_found 
      ]
  | _ -> raise Not_found
  ];
  


(* *)
value auth_response_of_json json = 
  try 
    Token (token_info_of_json json)
  with [ Not_found -> 
    try 
      Error (error_of_json json)
    with [ Not_found -> Error { error = "invalid_response_data"; description = "Response neither error nor access_token" } ]
  ];



(*
module type Param = sig
  value auth_endpoint: string; 
  value token_endpoint: string; 
  value close_button: option close_button;
  value grant_type: auth_grant;
  value client_id: string;
  value redirect_uri: string;
  value params: list (string*string);
end;
*)



IFDEF IOS THEN
external ml_authorization_grant : string -> option close_button -> unit = "ml_authorization_grant";

(*
external  set_close_button_insets : int -> int -> int -> int -> unit = "ml_set_close_button_insets";
external  set_close_button_visible : bool -> unit  = "ml_set_close_button_visible";
external  set_close_button_image_name : string -> unit = "ml_set_close_button_image_name";
*)

ELSE

value ml_authorization_grant (str:string) (close_button:option close_button) = debug "HAHAHA";
(*
value set_close_button_insets (top:int) (left:int) (right:int) (botton:int) = ();
value set_close_button_visible (visible: bool) = ();
value set_close_button_image_name (name:string) = ();
*)

ENDIF;

(* ожидаемые авторизации *)
value pendings = Queue.create ();
type state = [ Standby | Authorizing of (string -> unit) ]; 
value state = ref Standby;

value authorization_grant url close_button callback = 
  match !state with
  [ Standby -> 
    (
      state.val := Authorizing callback;
      debug "call ml_auth_grant";
      ml_authorization_grant url close_button;
      debug "called auth grant";
    )
  | Authorizing _ -> Queue.push (url,close_button,callback) pendings
  ];

value oauth_redirected url = 
  match !state with 
  [ Authorizing cb ->
      (
        cb url;
        try 
          let (url,close_button,callback) = Queue.pop pendings in
          (
            state.val := Authorizing callback;
            ml_authorization_grant url close_button;
          )
        with [ Queue.Empty -> state.val := Standby ]
      )
  | Standby -> failwith "Must be Authorizing"
  ];
  
Callback.register "oauth_redirected" oauth_redirected;

(* рефрешим токен *)
value refresh_token ~client_id ~token_endpoint ~rtoken ~params callback = 
  let grant_type = "refresh_token" in
  let params = [ ("client_id", client_id) :: [ ("grant_type", grant_type) :: [ ("refresh_token", rtoken) :: params ]]] in
  let token_url = Printf.sprintf "%s?%s" token_endpoint (UrlEncoding.mk_url_encoded_parameters params) in
  
  let loader = new URLLoader.loader () in (
    
    ignore (loader#addEventListener URLLoader.ev_IO_ERROR (fun _ _ _ -> 
        let error = { error = "io_error"; description = "Network error" }
        in callback (Error error)
      )
    );
    
    ignore (loader#addEventListener URLLoader.ev_COMPLETE (fun _ _ _ ->
        try 
          let json_data = Ojson.from_string loader#data in
          let response  = auth_response_of_json json_data 
          in callback response
        with 
        [ _ -> 
          let error = { error = "io_error"; description = "Not a JSON data in response" }
          in callback (Error error)          
        ];          
      );
    );
    
    let request = 
    { 
      URLLoader.httpMethod = `POST;
      headers = [];
      data = None;
      url = token_url
    } in loader#load request;

  );


(* получаем токен, имея code. Используется в схеме Auth Code Grant *)
value get_token_by_code client_id token_endpoint redirect_uri params code callback = 
  let grant_type = "authorization_code" in
  let params = 
    [ ( "client_id", client_id) ; ("grant_type", grant_type) ; ("code", code) ; ("redirect_uri", redirect_uri) :: params ] in
  let token_url = Printf.sprintf "%s?%s" token_endpoint (UrlEncoding.mk_url_encoded_parameters params) in

  
  let loader = new URLLoader.loader () in (  
    ignore (loader#addEventListener URLLoader.ev_IO_ERROR (fun _ _ _ -> 
        let error = { error = "io_error"; description = "Network error" }
        in callback (Error error)
      )
    );
    
    ignore (loader#addEventListener URLLoader.ev_COMPLETE (fun _ _ _ ->
        try 
          let () = debug "get_token_result: %s" loader#data in
          let json_data = Ojson.from_string loader#data in
          let response  = auth_response_of_json json_data 
          in callback response
        with 
        [ _ -> 
          let error = { error = "io_error"; description = "Not a JSON data in response" }
          in callback (Error error)          
        ];          
      );
    );
    
    let request = 
    { 
      URLLoader.httpMethod = `POST;
      headers = [];
      data = None;
      url = token_url
    } in loader#load request;

  );


(* Запрашиваем авторизацию. *)
value authorization_grant ~client_id ~auth_endpoint ~redirect_uri ~gtype ~params ?close_button callback = 
  let response_type = match gtype with [ Code _ -> "code" | Implicit -> "token" ] in
  let params' = [ ("client_id", client_id) :: [ ("redirect_uri", redirect_uri) :: [ ("response_type", response_type) :: params ]]] in
  let auth_url = Printf.sprintf "%s?%s" auth_endpoint (UrlEncoding.mk_url_encoded_parameters params') in
  (
    let () = debug "Going to: %s" auth_url in
    let handler = 
      match gtype with
      [ Code token_endpoint -> 
        fun url ->
          let () = debug "Got URL: %s" url in
          let pstr = extarct_params_string_from_url url in
          let qs_params = UrlEncoding.dest_url_encoded_parameters pstr in 
          try 
            let error = List.assoc "error" qs_params 
            in callback (Error { error; description = "" })
          with [ Not_found ->
            try 
              let code = List.assoc "code" qs_params
              in get_token_by_code client_id token_endpoint redirect_uri params code callback
            with [ Not_found -> callback (Error { error = "invalid_response_data"; description = "error or code must be there..." }) ]
          ]
      | Implicit -> 
          fun url -> 
            let () = debug "Got URL: %s!" url in
            callback (auth_response_of_url url)
      ]
    in 
    authorization_grant auth_url close_button handler
  );
