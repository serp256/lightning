open Ojson;
open SNTypes;

(*
OAuth.set_close_button_visible True;
OAuth.set_close_button_insets 60 10 10 10;
*)

type permission = [ Valuable_access | Set_status | Photo_content ];

type permissions = list permission;

value string_of_permission = fun
  [ Valuable_access -> "VALUABLE ACCESS"
  | Set_status      -> "SET STATUS"
  | Photo_content   -> "PHOTO CONTENT"
  ];
  
  
value scope_of_perms perms = 
  String.concat ";" (List.map string_of_permission perms);
  
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
  

module type Param = sig
  value appid:string;
  value permissions:permissions;
  value application_key: string;
  value private_key: string;
end;

value auth_endpoint = "http://www.odnoklassniki.ru/oauth/authorize";
value token_endpoint = "http://api.odnoklassniki.ru/oauth/token.do"; 
value close_button = {OAuth.cb_insets = (60,10,10,10); OAuth.cb_image = None};

module Make(P:Param) = struct

(*
module MyOAuth = OAuth.Make(struct 
  value auth_endpoint = "http://www.odnoklassniki.ru/oauth/authorize"; value token_endpoint = "http://api.odnoklassniki.ru/oauth/token.do"; 
  value close_button = Some {OAuth.cb_insets = (60,10,10,10); OAuth.cb_image = None};
  value grant_type = OAuth.Code;
  value client_id = P.appid;
  value redirect_uri = "http://api.odnoklassniki.ru/success.html";
  value params = 
    let oauth_params = [("client_secret", P.private_key)] in
    match P.permissions with
    [ [] -> oauth_params
    | perms -> [ ("scope", (scope_of_perms perms)) :: oauth_params ]
    ];
end
);
*)


(* 
   Используйте необязательный параметр scope чтобы запросить у пользователя требующиеся вашему приложению привилегии. 
   Если требуется запросить несколько привилегий, они передаются в scope через пробел. 
value init appid appkey pkey perms = (
  _appid.val := appid;
  _private_key.val := pkey;
  _perms.val := Some (scope_of_perms perms);
  _application_key.val := appkey;
);
*)
  


(* вызываем REST метод *)
value call_method' meth access_token params callback = 
  let params = [ ("application_key", P.application_key) :: [("method", meth) :: params ]] in
  let signature = calc_signature params P.private_key access_token in
  let params = [ ("sig", signature) :: params ] in
  let params = [ ("access_token", access_token) :: params ] in
  let url = Printf.sprintf "http://api.odnoklassniki.ru/fb.do?%s" (UrlEncoding.mk_url_encoded_parameters params) in
  let loader = new URLLoader.loader ()  in 
  (

    ignore (
      loader#addEventListener URLLoader.ev_IO_ERROR (
        fun _ _ _ -> callback (Error IOError)
      )
    );
    
    ignore (
      loader#addEventListener URLLoader.ev_COMPLETE (
        fun _ _ _ -> 
          let () = Printf.eprintf "WE GOT DATA: %s\n%!" loader#data in
          let response = 
            try 
              let json_data = Ojson.from_string loader#data in 
              try 
                let () = Printf.eprintf "DATA:\n%!" in
                let error = extract_error_from_json json_data
                in Error error
              with [ Not_found -> let () = Printf.eprintf "DATA IS OK:\n%!" in Data json_data ] 
            with [ exn -> Error (SocialNetworkError ("998", Printexc.to_string exn)) ]
          in callback response
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

  KVStorage.put_string "ok_access_token" token_info.OAuth.access_token;
    
  let expires = string_of_float ((float_of_int 1800) +. Unix.time ()) (* пишут, что acces token експайрится через 30 минут *)
  in KVStorage.put_string "ok_access_token_expires" expires;
    
  match token_info.OAuth.refresh_token with 
  [ Some token -> KVStorage.put_string "ok_refresh_token" token
  | None -> () (* KVStorage.remove storage "ok_refresh_token" *)
  ];
    
  token_info.OAuth.access_token;
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

  let show_auth () =  (* функция показа авторизации. при успехе выполняем REST метод *)
    let redirect_uri = "http://api.odnoklassniki.ru/success.html"
    and params = [("client_secret", P.private_key)] in
    let params = 
      match P.permissions with
      [ [] -> params
      | perms -> [ ("scope", (scope_of_perms perms)) :: params ]
      ] 
    and callback = fun 
      [ OAuth.Token  t ->  
          let access_token = 
            try  
              Some (handle_new_access_token t)
            with [ Not_found -> None ]
          in 
          match access_token with
          [ Some access_token ->  
              let callback = fun
                 [ Data json     ->  call_delegate_success json
                 | Error e       ->  call_delegate_error e
                 ]
              in call_method' meth access_token params callback
          | None -> call_delegate_error (SocialNetworkError ("999", "No UID in token info")) 
          ]
          
      | OAuth.Error e  ->  call_delegate_error (OAuthError e)
      ]
    in 
    OAuth.authorization_grant ~client_id:P.appid ~auth_endpoint ~gtype:(OAuth.Code token_endpoint) ~redirect_uri  ~params ~close_button callback
  in
  let refresh_token rtoken =  (* функция рефреша токена. если не получилось зарефрешить - поднимаем авторизацию *)
    let callback = fun 
      [ OAuth.Token t ->
            let access_token = 
              try 
                Some (handle_new_access_token t)
              with [ Not_found -> None ]
            in match access_token with
            
            [ Some access_token -> 
                let callback = fun
                  [ Data json     ->  call_delegate_success json
                  | Error e       ->  match e with 
                      [ SocialNetworkError ("401", _) -> show_auth () (* TODO: надо посмотреть другие ошибки !!! *)
                      | _ -> call_delegate_error e
                      ]
                  ]
                in call_method' meth access_token params callback
            | None -> show_auth () 
            ]
      | OAuth.Error e -> show_auth ()
      ] 
    in 
    OAuth.refresh_token ~client_id:P.appid ~token_endpoint ~rtoken ~params:[("client_secret", P.private_key)] callback
  in 
  try
    let (access_token,token_expires) = 
      try 
        let at = KVStorage.get_string "ok_access_token"
        and te = float_of_string (KVStorage.get_string "ok_access_token_expires") in 
        (at,te)
      with [ KVStorage.Kv_not_found -> raise Show_auth]
    in
    if ((Unix.time ()) > token_expires) then (* expired. try to refresh *)
      refresh_token (KVStorage.get_string "ok_refresh_token")
    else   
      let callback = fun 
      [ Data json   -> call_delegate_success json
      | Error e     -> match e with
          [ SocialNetworkError ("401", _) -> 
              try 
                refresh_token (KVStorage.get_string "ok_refresh_token") (* тот токен, что у нас уже невалиден, надо зарефрешить *)
              with [ KVStorage.Kv_not_found -> show_auth() ]
          | _ -> call_delegate_error e
          ] 
      ]
      in 
      call_method' meth access_token params callback
  with [ Show_auth -> show_auth () ];


(* FIXME!!!! *)
value get_access_token () = 
  try 
    KVStorage.get_string "ok_access_token"
  with [ KVStorage.Kv_not_found -> raise Not_found ];


value get_refresh_token () = 
  try 
    KVStorage.get_string "ok_refresh_token"
  with [ KVStorage.Kv_not_found -> raise Not_found ];

end;
