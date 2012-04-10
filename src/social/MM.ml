open Ojson;
open SNTypes;

type permission = [ Photos | Guestbook | Stream | Messages | Events ];

type permissions = list permission;

value storage = KVStorage.create ();

value _appid = ref "";

value _perms = ref None;

value _private_key = ref "";

value _oauth = OAuth.create "https://connect.mail.ru/oauth/authorize" "https://appsmail.ru/oauth/token";

(* *)
value string_of_permission = fun
  [ Photos      -> "photos"
  | Guestbook   -> "guestbook"
  | Stream      -> "stream"
  | Messages    -> "messages"
  | Events      -> "events"
  ];
  
  
(* В Моем мире привелегии передаются через пробел *)
value scope_of_perms perms = 
  String.concat " " (List.map string_of_permission perms);
  

(* 
   Используйте необязательный параметр scope чтобы запросить у пользователя требующиеся вашему приложению привилегии. 
   Если требуется запросить несколько привилегий, они передаются в scope через пробел. 
*)
value init appid pkey perms = (
  _appid.val := appid;
  _private_key.val := pkey;
  _perms.val := Some (scope_of_perms perms);
);
  

(* высчитываем сигнатуру параметров *)
value calc_signature uid params pkey = 
  let sorted = List.sort (fun (k1,_) (k2,_) -> compare k1 k2) params in
  let joined = List.fold_left (fun acc (k,v) -> acc ^ k ^ "=" ^ v) "" sorted in
  let () = Printf.eprintf "Sighning %s\n%!" joined in
  Digest.to_hex (Digest.string (uid ^ joined ^ pkey));

  


(* достаем ошибку *)
value extract_error_from_json json = 
  match json with 
  [ `Assoc dict ->
      let error = List.assoc "error" dict in
      match error with 
      [ `Assoc eparams ->
         try 
            let code = match List.assoc "error_code" eparams with
            [ `Int i -> string_of_int i
            | `Intlit s | `String s -> s
            | _ -> raise Not_found
            ]
            and msg  = match List.assoc "error_msg" eparams with
            [ `String s -> s
            | _ -> raise Not_found
            ] 
            in SocialNetworkError (code, msg)
         with [ Not_found -> SocialNetworkError ("999", "Error code or error message not found") ]      
      | _ -> raise Not_found
      ]
  | _ -> raise Not_found 
  ];
  


(* вызываем REST метод *)
value call_method' meth session_key uid params callback = 
  let params = [ ("app_id", !_appid ) :: [ ("method", meth) :: [ ("session_key", session_key) :: params ]]] in
  let signature = calc_signature uid params !_private_key in
  let params = [ ("sig", signature) :: params ] in
  let url = Printf.sprintf "http://www.appsmail.ru/platform/api?%s" (UrlEncoding.mk_url_encoded_parameters params) in
  let loader = new URLLoader.loader ()  in (
    
    ignore (
      loader#addEventListener URLLoader.ev_IO_ERROR (
        fun _ _ _ -> callback (Error IOError)
      )
    );
    
    ignore (
      loader#addEventListener URLLoader.ev_COMPLETE (
        fun _ _ _ -> 
          let () = Printf.eprintf "WE GOT DATA: %s\n%!" loader#data in
          let cb = 
            try 
              let json_data = Ojson.from_string loader#data in 
              try 
                let error = extract_error_from_json json_data
                in fun () -> callback (Error error)
              with [ Not_found -> fun () -> callback (Data json_data) ] 
            with [ _ -> fun () -> callback (Error (SocialNetworkError ("998", "HOHA error"))) ]
          in cb ()
      )
    );
    
    let request = 
    { 
      URLLoader.httpMethod = `GET;
      headers = [];
      data = None;
      url = url
    } in loader#load request; 
  );
  


  
(* проверяем все ли данные есть и сохраняем токен *)
value handle_new_access_token token_info = 
  let uid = List.assoc "x_mailru_vid" token_info.OAuth.other_params in (

    KVStorage.put_string storage "mm_access_token" token_info.OAuth.access_token;
    KVStorage.put_string storage "mm_user_id" uid;
    
    match token_info.OAuth.expires_in with 
    [ Some seconds -> 
        let expires = string_of_float ((float_of_int seconds) +. Unix.time ())
        in KVStorage.put_string storage "mm_access_token_expires" expires
    | None -> KVStorage.remove storage "mm_access_token_expires"
    ];
    
    
    match token_info.OAuth.refresh_token with 
    [ Some token -> KVStorage.put_string storage "mm_refresh_token" token
    | None -> (* KVStorage.remove storage "mm_refresh_token" *) ()
    ];
    
    (token_info.OAuth.access_token, uid);
  );
  
  



(* Вызываем REST method. Если нужно, проводим авторизацию *)
value call_method ?(delegate=None) meth params = 
  
  let (call_delegate_success, call_delegate_error) =  
    match delegate with 
    [ None -> (fun _ -> (), fun _ -> ())
    | Some d -> (d.on_success, d.on_error)
    ]
  in         

  (* функция показа авторизации. при успехе выполняем REST метод *)
  let show_auth () = 
    let redirect_uri = "https://connect.mail.ru/oauth/success.html"
    and oauth_params = [("display", "mobile")]
    and oauth_callback = fun 
      [ OAuth.Token  t ->  
          let access_token_info =  
            try 
              Some (handle_new_access_token t)
            with [ Not_found -> None ]
          in match access_token_info with 
          [ Some (access_token, uid) -> 
              let callback = fun
              [ Data json     ->  call_delegate_success json
              | Error e       ->  call_delegate_error e
              ] in call_method' meth access_token uid params callback
          | _ -> call_delegate_error (SocialNetworkError ("999", "No UID in token info")) 
          ] 
      | OAuth.Error e  ->  call_delegate_error (OAuthError e)
      ]
    in OAuth.authorization_grant _oauth OAuth.Implicit !_appid redirect_uri oauth_params oauth_callback
  in


  (* функция рефреша токена. если не получилось зарефрешить - поднимаем авторизацию *)
  let refresh_token rtoken = 
    let oauth_refresh_callback = fun 
    [ OAuth.Token t ->
        let access_token_info = 
          try 
            Some (handle_new_access_token t)
          with [ Not_found -> None ]
        in match access_token_info with
        [ Some (access_token, uid) -> 
            let callback = fun
              [ Data json     ->  call_delegate_success json
              | Error e       ->  match e with 
                  [ SocialNetworkError ("102", _) -> show_auth ()
                  | _ -> call_delegate_error e
                  ]
              ]
            in call_method' meth access_token uid params callback
        | None -> show_auth ()
        ]
        
    | OAuth.Error e -> show_auth ()
    ] 
    in OAuth.refresh_token _oauth rtoken !_appid [("client_secret", !_private_key)] oauth_refresh_callback
  in try 
    let access_token = KVStorage.get_string storage "mm_access_token"
    and uid = KVStorage.get_string storage "mm_user_id"
    and token_expires = float_of_string (KVStorage.get_string storage "mm_access_token_expires") in 
    if ((Unix.time ()) > token_expires) then (* expired. try to refresh *)
      refresh_token (KVStorage.get_string storage "mm_refresh_token")
    else   
      let callback = fun 
      [ Data json   -> call_delegate_success json
      | Error e     -> match e with
          [ SocialNetworkError ("102", _) -> 
              try 
                refresh_token (KVStorage.get_string storage "mm_refresh_token") (* тот токен, что у нас уже невалиден, надо зарефрешить *)
              with [ KVStorage.Kv_not_found -> show_auth() ]
          | _ -> call_delegate_error e
          ] 
      ]
      in call_method' meth access_token uid params callback
  with [ KVStorage.Kv_not_found -> show_auth() ];  
  

value get_access_token () = 
  try 
    KVStorage.get_string storage "mm_access_token"
  with [ KVStorage.Kv_not_found -> raise Not_found ];


value get_refresh_token () = 
  try 
    KVStorage.get_string storage "mm_refresh_token"
  with [ KVStorage.Kv_not_found -> raise Not_found ];

value get_user_id () = 
  try 
    KVStorage.get_string storage "mm_user_id"
  with [ KVStorage.Kv_not_found -> raise Not_found ];  


