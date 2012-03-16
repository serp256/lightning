type vk_error = [ IOError | VKError of (int*string*list (string*Ojson.t)) | VKAuthCancelled ];
type delegate = 
{
  vk_method_call_error : option (vk_error -> unit);
  vk_method_call_success: option (Ojson.t -> unit)
};



IFDEF IOS THEN

type status = [ NotAuthorized | Authorizing of Queue.t (bool -> unit) | Authorized ];

value storage = KVStorage.create ();

value auth_status = ref NotAuthorized;

value captcha_queue = Queue.create ();

value _appid = ref "0";

value _permissions = ref "";

external ml_vk_init : string -> unit = "ml_vk_init";

value vk_init appid perms = 
  (
    _appid.val := appid;
    _permissions.val := perms;
    ml_vk_init appid;
  );


external ml_vk_authorize : string -> unit = "ml_vk_authorize";

external ml_vk_display_captcha : string -> string -> unit = "ml_vk_display_captcha";

value vk_display_captcha = ml_vk_display_captcha;


(* проверяем наличие валидного токена *)
value vk_check_auth_token () = 
  try 
    let _ = KVStorage.get_string storage "vk_auth_token"
    and expires = float_of_string (KVStorage.get_string storage "vk_auth_token_expires") in
    Unix.time () < expires  
  with [ _ -> False ];


(* возвращаем auth token. рейзим Not_found если нет токена или он заекспайрился *)
value vk_get_auth_token () = 
  match vk_check_auth_token () with 
  [ False -> raise Not_found 
  | True  -> KVStorage.get_string storage "vk_auth_token"
  ];


(* возвращаем user_id. рейзим Not_found если нет токена или он заекспайрился *)
value vk_get_user_id () = 
  match vk_check_auth_token () with 
  [ False -> raise Not_found 
  | True  -> KVStorage.get_string storage "vk_user_id"
  ];



(* локальный логаут *)
value vk_clear_auth_data () = 
  (
    KVStorage.remove storage "vk_auth_token";
    KVStorage.remove storage "vk_auth_token_expires";
    KVStorage.remove storage "vk_user_id";
    KVStorage.commit storage;
  );


(* ошибка авторизаци - пользователь отменил авторизацию *) 
value vk_login_failed error = 
  match !auth_status with
  [ Authorizing callbacks ->
    (
      auth_status.val := NotAuthorized;
      while not (Queue.is_empty callbacks) do
        let c = Queue.pop callbacks in
        c False                                                                                                                                                                   
      done;                                                                                                                                                                       
    )
  | _ -> () (* failwith "vk_login_failed must be in authorizing state" : если долбить по кнопке Отмена, failed вызовется несколько раз *)
  ];


(* пользователь авторизовался *)
value on_vk_logged_in () = 
  match !auth_status with
  [ Authorizing callbacks ->
    (
      auth_status.val := Authorized;
      while not (Queue.is_empty callbacks) do
        let c = Queue.pop callbacks in
        c True                                                                                                                                                                   
      done;                                                                                                                                                                       
    )
  | _ -> () (* failwith "on_vk_logged_in must be in authorizing state" *)
  ];


(* успешно залогинился *)
value vk_logged_in user_id token expires = 

  let fexpires = float_of_string expires in
  let expiration = string_of_float (fexpires +. Unix.time ()) in
  (  
     KVStorage.put_string storage "vk_user_id" user_id;
     KVStorage.put_string storage "vk_auth_token" token;
     KVStorage.put_string storage "vk_auth_token_expires" expiration;
     KVStorage.commit storage;
     Printf.eprintf "Login succes\n%!";
     on_vk_logged_in ();
  );
  

(*  поднимаем диалог авторизации - вообще нафиг не нужно *)
value vk_authorize perms = 
  match vk_check_auth_token () with
  [ True    -> on_vk_logged_in ()
  | False   -> 
      match !_appid with
      [ "0" -> failwith "VK API not initialized. Call VK.vk_init first"
      | _   -> ml_vk_authorize perms
      ]
  ];


(* *)
value process_captcha_queue () = 
  try 
    let (sid, url, _) = Queue.peek captcha_queue
    in 
    vk_display_captcha sid url    
  with [ Queue.Empty -> () ];
  

(* *)
value vk_captcha_entered captcha_sid captcha_value = 
  try 
    let (_, _, cb) = Queue.take captcha_queue in
    let () = cb captcha_value in
    match Queue.is_empty captcha_queue with
    [ False -> process_captcha_queue ()
    | True -> ()
    ] 
  with [ _  -> () ];
    

Callback.register "vk_logged_in" vk_logged_in;
Callback.register "vk_login_failed" vk_login_failed;
Callback.register "vk_captcha_entered" vk_captcha_entered;


(* *)
value mk_url_encoded_parameters params = 
  let encode str = 
    ExtLib.String.replace_chars begin fun c -> 
      match c with 
      [ ' ' | '<' | '>' | '#' | '%' | '{' | '}' | '|' | '\\' | '^' | '~' | '[' | ']' | '`' | ':' | ';' | '/' | '?' | '@' | '=' | '&' | '$' -> Printf.sprintf "%%%X" (Char.code c)
      | _ -> String.make 1 c
      ]
    end str
  in ExtLib.String.join "&" (List.map begin fun (k,v) -> k ^ "=" ^ (encode v) end params);
  
  

exception VK_Auth_Required;  

exception VK_Captcha_Required of (string*string);

value _call_delegate_error delegate e = 
  match delegate with [ Some d -> match d.vk_method_call_error with [ Some f -> f e | _ -> () ] | _ -> () ];


(* вызываем любой метод API. *)
value vk_call_method_no_auth ?(delegate = None)  meth params token = 
  let params = [ ("access_token", token) :: params ] in
  let url = Printf.sprintf "https://api.vkontakte.ru/method/%s?%s" meth (mk_url_encoded_parameters params)
  and loader = new URLLoader.loader () in
  (
    ignore (loader#addEventListener URLLoader.ev_IO_ERROR (fun _ _ _ -> _call_delegate_error delegate IOError));
            
    ignore (
    loader#addEventListener URLLoader.ev_COMPLETE 
      (fun _ _ _ -> 
        match delegate with 
        [ Some d -> 
          let json_data = Ojson.from_string loader#data in
          let () = Printf.eprintf "%s" loader#data in 
          match json_data with
          [ `Assoc data ->   
            try 
              let error = 
                match (List.assoc "error" data) with
                [ `Assoc e -> 
                  try 
                    match ((List.assoc "error_code" e), (List.assoc "error_msg" e)) with
                    [ (`Intlit code, `String msg) -> ((int_of_string code), msg, e)
                    | (_,_) -> failwith "Incorrent type for error code and message"
                    ]
                  with [ Not_found -> (1, "Unknown error", []) ]
                | _ -> failwith "Incorrent type for error"
                ] 
              in match d.vk_method_call_error with [ Some f -> f (VKError error) | _ -> () ]
            with 
              [ Not_found -> match d.vk_method_call_success with [ Some f -> f json_data | _ -> () ] ] 
          
          (* not an object *)
          | _ -> _call_delegate_error delegate (VKError (1, "Not a json object", [])) 
          ]
        | _ -> ()
        ]
      ));
      
    let request = 
    { 
      URLLoader.httpMethod = `GET;
      headers = [];
      data = None;
      url = url
    } in loader#load request;
  );

  
(* *)
value rec vk_call_method ?(delegate = None) meth params = 

  (* 
     Если была ошибка аутентификации - пользователь не стал вводить логин-пароль, то уведомляем об этом делегата ошибкой.
     В противном случае снова пробуем вызвать метод API  
  *)
  let handle_auth_required () = 
    let auth_callback result = 
      match result with
      [ True    -> vk_call_method ~delegate:delegate meth params
      | False   -> _call_delegate_error delegate VKAuthCancelled
      ]
    in match !auth_status with
    [ NotAuthorized | Authorized  -> 
      let callbacks = Queue.create () in
      (
        Queue.push auth_callback callbacks;
        auth_status.val := Authorizing callbacks;
        ml_vk_authorize !_permissions;
      )
    | Authorizing callbacks -> Queue.push auth_callback callbacks
    ]

  (* 
     показываем капчу. 
  *)  
  and handle_captcha_required captcha_sid captcha_url = 
    let captcha_callback = 
      fun word -> 
        let params = [("captcha_sid", captcha_sid) :: [ ("captcha_key", word) :: params ]]
        in vk_call_method ~delegate:delegate meth params
    in 
    (
      Queue.add (captcha_sid, captcha_url, captcha_callback) captcha_queue;
      match Queue.length captcha_queue with
      [ 1  -> process_captcha_queue ()
      | _  -> ()
      ];
    )

  in 
  try 
      let token = vk_get_auth_token () in

      (* error handler *)
      let dlgt_error   = 
        fun error ->           
          try 
            match error with
            [ VKError (ecode, emsg, error_params) -> 
              match ecode with 
              [ 5  -> raise VK_Auth_Required
              | 14 -> 
                 match ((List.assoc "captcha_sid" error_params), (List.assoc "captcha_img" error_params)) with
                 [((`String captcha_sid), (`String captcha_url)) -> raise (VK_Captcha_Required (captcha_sid, captcha_url))
                 | _ -> failwith "Invalid params for captcha"
                 ]
              | _  -> _call_delegate_error delegate error
              ]
            | _ -> _call_delegate_error delegate error
            ]
      
          with 
          [ VK_Auth_Required    -> (vk_clear_auth_data (); handle_auth_required ())
          | VK_Captcha_Required (sid, url) -> handle_captcha_required sid  url
          ]
        (* / End of error handler *)
        
      and dlgt_success = match delegate with [ Some d -> d.vk_method_call_success | _ -> None ] in
      let dlgt = Some { vk_method_call_success = dlgt_success; vk_method_call_error = Some dlgt_error } in 
      vk_call_method_no_auth ~delegate:dlgt meth params token
  with [ Not_found -> handle_auth_required () ];


ELSE


value vk_init _ _  = ();
value vk_call_method ?delegate _ _  = ();
value vk_get_auth_token () =  "";
value vk_get_user_id () = raise Not_found;

ENDIF;
