open Ojson;
open SNTypes;

type permission = [ Valuable_access | Set_status | Photo_content ];

type permissions = list permission;

value storage = KVStorage.create ();

value _appid = ref "";

value _perms = ref None;

value _private_key = ref "";

value _application_key = ref "";

value _oauth = OAuth.create "http://www.odnoklassniki.ru/oauth/authorize" "http://api.odnoklassniki.ru/oauth/token.do";

(* *)
value string_of_permission = fun
  [ Valuable_access -> "VALUABLE ACCESS"
  | Set_status      -> "SET STATUS"
  | Photo_content   -> "PHOTO CONTENT"
  ];
  
  
(* В Моем мире привелегии передаются через пробел *)
value scope_of_perms perms = 
  String.concat ";" (List.map string_of_permission perms);
  

(* 
   Используйте необязательный параметр scope чтобы запросить у пользователя требующиеся вашему приложению привилегии. 
   Если требуется запросить несколько привилегий, они передаются в scope через пробел. 
*)
value init appid appkey pkey perms = (
  _appid.val := appid;
  _private_key.val := pkey;
  _perms.val := Some (scope_of_perms perms);
  _application_key.val := appkey;
);
  

(* высчитываем сигнатуру параметров *)
value calc_signature params pkey access_token = 
  let sorted = List.sort (fun (k1,_) (k2,_) -> compare k1 k2) params in
  let joined = List.fold_left (fun acc (k,v) -> acc ^ k ^ "=" ^ v) "" sorted in
  let () = Printf.eprintf "Signing %s\n%!" joined in
  let md5_1 = Digest.to_hex (Digest.string (access_token ^ pkey)) in
  Digest.to_hex (Digest.string (joined ^ md5_1));

  


(* достаем ошибку *)
value extract_error_from_json json = 
  match json with 
  [ `Assoc dict ->
      let code = match List.assoc "error_code" dict with
      [ `Int i -> string_of_int i
      | `Intlit s | `String s -> s
      | _ -> raise Not_found
      ]
      and msg  = match List.assoc "error_msg" dict with
      [ `String s -> s
      | _ -> raise Not_found
      ] 
      in SocialNetworkError (code, msg)
  | _ -> raise Not_found
  ];
  


(* вызываем REST метод *)
value call_method' meth access_token params callback = 
  let params = [ ("application_key", !_application_key) :: [("method", meth) :: params ]] in
  let signature = calc_signature params !_private_key access_token in
  let params = [ ("sig", signature) :: params ] in
  let params = [ ("access_token", access_token) :: params ] in
  let url = Printf.sprintf "http://api.odnoklassniki.ru/fb.do?%s" (UrlEncoding.mk_url_encoded_parameters params) in
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
          try 
            let json_data = Ojson.from_string loader#data in 
            try 
              let error = extract_error_from_json json_data
              in callback (Error error)
            with [ Not_found -> callback (Data json_data) ] 
          with [ _ -> callback (Error (SocialNetworkError ("998", "HOHA error"))) ]
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
value handle_new_access_token token_info = (

  KVStorage.put_string storage "ok_access_token" token_info.OAuth.access_token;
    
  let expires = string_of_float ((float_of_int 1800) +. Unix.time ()) (* пишут, что acces token експайрится через 30 минут *)
  in KVStorage.put_string storage "ok_access_token_expires" expires;
    
  match token_info.OAuth.refresh_token with 
  [ Some token -> KVStorage.put_string storage "ok_refresh_token" token
  | None -> KVStorage.remove storage "ok_refresh_token"
  ];
    
  token_info.OAuth.access_token;
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
    let redirect_uri = "http://api.odnoklassniki.ru/success.html"
    and oauth_params = [("client_secret", !_private_key)] in
    let oauth_params = match !_perms with
      [ Some "" | None -> oauth_params
      | Some s -> [ ("scope", s) :: oauth_params ]
      ] 
    and oauth_callback = fun 
      [ OAuth.Token  t ->  
          try 
            let access_token = handle_new_access_token t in
            let callback = fun
              [ Data json     ->  call_delegate_success json
              | Error e       ->  call_delegate_error e
              ]
            in call_method' meth access_token params callback
          with [ Not_found -> call_delegate_error (SocialNetworkError ("999", "No UID in token info")) ]
      | OAuth.Error e  ->  call_delegate_error (OAuthError e)
      ]
    in OAuth.authorization_grant _oauth OAuth.Code !_appid redirect_uri oauth_params oauth_callback
  in


  (* функция рефреша токена. если не получилось зарефрешить - поднимаем авторизацию *)
  let refresh_token rtoken = 
    let oauth_refresh_callback = fun 
    [ OAuth.Token t ->
        try 
          let access_token = handle_new_access_token t in 
          let callback = fun
            [ Data json     ->  call_delegate_success json
            | Error e       ->  match e with 
                [ SocialNetworkError ("401", _) -> show_auth () (* TODO: надо посмотреть другие ошибки !!! *)
                | _ -> call_delegate_error e
                ]
            ]
          in call_method' meth access_token params callback
        with [ Not_found -> show_auth () ]
    | OAuth.Error e -> show_auth ()
    ] 
    in OAuth.refresh_token _oauth rtoken !_appid [("client_secret", !_private_key)] oauth_refresh_callback

  in try 
    let access_token = KVStorage.get_string storage "ok_access_token"
    and token_expires = float_of_string (KVStorage.get_string storage "ok_access_token_expires") in 
    if ((Unix.time ()) > token_expires) then (* expired. try to refresh *)
      refresh_token (KVStorage.get_string storage "ok_refresh_token")
    else   
      let callback = fun 
      [ Data json   -> call_delegate_success json
      | Error e     -> match e with
          [ SocialNetworkError ("401", _) -> 
              try 
                refresh_token (KVStorage.get_string storage "ok_refresh_token") (* тот токен, что у нас уже невалиден, надо зарефрешить *)
              with [ KVStorage.Kv_not_found -> show_auth() ]
          | _ -> call_delegate_error e
          ] 
      ]
      in call_method' meth access_token params callback
  with [ KVStorage.Kv_not_found -> show_auth() ];  
  
