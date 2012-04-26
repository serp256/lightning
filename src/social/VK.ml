open SNTypes;

type permission = 
  [ Notify | Friends | Photos | Audio | Video | Docs | Notes | Pages 
  | Wall | Groups | Messages | Notifications | Stats | Ads | Offline 
  ];

type permissions = list permission;

value auth_endpoint = "http://oauth.vk.com/authorize";
(* value _oauth = OAuth.create "http://oauth.vk.com/authorize" ""; *)



(* *)
value string_of_permission = fun
  [ Notify      -> "notify"
  | Friends     -> "friends"
  | Photos      -> "photos"
  | Audio       -> "audio"
  | Video       -> "video"
  | Docs        -> "docs"
  | Notes       -> "notes"
  | Pages       -> "pages"
  | Wall        -> "wall"
  | Groups      -> "groups"
  | Messages    -> "messages"
  | Notifications  -> "notifications"
  | Stats       -> "stats"
  | Ads         -> "ads"
  | Offline     -> "offline"
  ];
  
  
(* В Моем мире привелегии передаются через пробел *)
value scope_of_perms perms = 
  String.concat "," (List.map string_of_permission perms);
  
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
  
module type Param = sig
  value appid: string;
  value permissions:permissions;
end;


module Make(P:Param) = struct

(* Используйте необязательный параметр scope чтобы запросить у пользователя требующиеся вашему приложению привилегии. 
value init appid perms = (
  _appid.val := appid;
  _perms.val := Some (scope_of_perms perms);
);
*)


(* проверяем все ли данные есть и сохраняем токен *)
value handle_new_access_token token_info = 
  let uid = List.assoc "user_id" token_info.OAuth.other_params in (

    KVStorage.put_string "vk_access_token" token_info.OAuth.access_token;
    KVStorage.put_string "vk_user_id" uid;
    
    match token_info.OAuth.expires_in with 
    [ Some seconds -> 
        let expires = string_of_float ((float_of_int seconds) +. Unix.time ())
        in KVStorage.put_string "vk_access_token_expires" expires
    | None -> KVStorage.remove "vk_access_token_expires"
    ];
    
    (token_info.OAuth.access_token, uid);
  );


(* вызываем REST метод *)
value call_method' meth access_token params callback = 
  let params = [("access_token", access_token) :: params ] in
  let url = Printf.sprintf "https://api.vk.com/method/%s?%s" meth (UrlEncoding.mk_url_encoded_parameters params) in
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
  

exception Show_auth;

(* Вызываем REST method. Если нужно, проводим авторизацию *)
value call_method ?delegate meth params = 
  
  let (call_delegate_success, call_delegate_error) =  
    match delegate with 
    [ None -> (fun _ -> (), fun _ -> ())
    | Some d -> (d.on_success, d.on_error)
    ]
  in         

  (* функция показа авторизации. при успехе выполняем REST метод *)
  let show_auth () = 
    let redirect_uri = "http://api.vk.com/blank.html"
    and params = [("display", "touch")]
    and callback = fun 
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
                ]
              in call_method' meth access_token params callback
          | None ->  call_delegate_error (SocialNetworkError ("999", "No UID in token info")) 
          ]
      | OAuth.Error e  ->  call_delegate_error (OAuthError e)
      ]
    in OAuth.authorization_grant ~client_id:P.appid ~auth_endpoint ~gtype:OAuth.Implicit ~redirect_uri ~params callback

  in try 
    let (access_token,token_expires) = 
      try
        let at = KVStorage.get_string "vk_access_token"
        and te = float_of_string (KVStorage.get_string "vk_access_token_expires") 
        in
        (at,te)
      with [ KVStorage.Kv_not_found -> raise Show_auth ]
    in 
    if ((Unix.time ()) > token_expires) then (* expired. show auth *)
      show_auth ()
    else   
      let callback = fun 
        [ Data json   -> call_delegate_success json
        | Error e     -> match e with
            [ SocialNetworkError ("5", _) -> show_auth()
            | _ -> call_delegate_error e
            ] 
        ]
      in 
      call_method' meth access_token params callback
  with [ Show_auth -> show_auth() ];  



value get_access_token () = 
  try 
    KVStorage.get_string "vk_access_token"
  with [ KVStorage.Kv_not_found -> raise Not_found ];


value get_user_id () = 
  try 
    KVStorage.get_string "vk_user_id"
  with [ KVStorage.Kv_not_found -> raise Not_found ];  


end;
