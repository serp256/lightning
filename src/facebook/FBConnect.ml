IFDEF IOS THEN

external ios_facebook_init : string -> unit = "ml_facebook_init";
  
value init appid = ios_facebook_init appid;




(*** SESSION ***)
module Session = struct

  type status = [ NotAuthorized | Authorizing of Queue.t (bool -> unit) | Authorized ];

  value auth_status = ref NotAuthorized;

  external ios_facebook_authorize : list string -> unit = "ml_facebook_authorize";

  value permissions = ref [];

  external ios_facebook_check_auth_token : unit -> bool = "ml_facebook_check_auth_token";

  value facebook_logged_in () = 
  (
    match !auth_status with
    [ Authorizing callbacks -> (* call pending callbacks *)
      (
        while not (Queue.is_empty callbacks) do
          let c = Queue.pop callbacks in
          c True
        done;
      )
    | _ -> failwith "Invalid auth status"
    ];
  
    auth_status.val := Authorized;
  );



  value facebook_session_invalidated () = 
  (  
    match !auth_status with
    [ Authorizing callbacks ->
      (
        while not (Queue.is_empty callbacks) do
          let c = Queue.pop callbacks in
          c False
        done;
      )
    | _ -> ()
    ];
  
    auth_status.val := NotAuthorized;
  );


  value facebook_logged_out  = facebook_session_invalidated;
  value facebook_login_cancelled  = facebook_session_invalidated;


  value authorize perms = 
    match ios_facebook_check_auth_token () with
    [ True  -> facebook_logged_in ()
    | False -> ios_facebook_authorize perms
    ];
  

  value with_auth_check callback = 
    match !auth_status with
    [ Authorized -> callback True
    | Authorizing callbacks -> Queue.add callback callbacks
    | NotAuthorized -> 
        let callbacks = Queue.create () in
        (
          Queue.push callback callbacks;
          auth_status.val := Authorizing callbacks;
          authorize !permissions
        )
    ];



  Callback.register "facebook_logged_in" facebook_logged_in;
  Callback.register "facebook_login_cancelled" facebook_login_cancelled;
  Callback.register "facebook_logged_out" facebook_logged_out;
  Callback.register "facebook_session_invalidated" facebook_session_invalidated;
  
end;


(*** GRAPH API ***)
module GraphAPI = struct

type delegate = 
{
  fb_request_did_fail   : option (string -> unit);    
  fb_request_did_load   : option (Ojson.t -> unit)
};

value delegates = Hashtbl.create 1;

external ios_facebook_request_with_graph_api_and_params : string -> list (string*string) -> int -> unit = "ml_facebook_request";

(* graph api request *)

value _request graph_path params ?(delegate = None) () = 
  let requestID = Random.int 10000 in
  (
    match delegate with
    [ Some d -> Hashtbl.add delegates requestID d
    | None -> ()
    ];
    
    ios_facebook_request_with_graph_api_and_params graph_path params requestID
  );

value request graph_path params ?(delegate = None) () = 
  let f = (fun _ -> _request graph_path params ~delegate:delegate ())
  in Session.with_auth_check f;


(* *)
value facebook_request_did_fail requestID error_str = 
  try 
    (
      let delegate = Hashtbl.find delegates requestID in
      match delegate.fb_request_did_fail with
      [ Some f -> f error_str
      | _ -> ()
      ];
      
      Hashtbl.remove delegates requestID;
    )
  with [ Not_found -> () ];




(* *)
value facebook_request_did_load requestID json_str = 
  let json_data = Ojson.from_string json_str in
  match json_data with
  [ `Assoc data ->
    try 
      ignore(List.assoc "error" data) (* если есть такой ключ, то будет вызван facebook_request_did_fail *)
    with 
    [ Not_found ->
        try 
          (
            let delegate = Hashtbl.find delegates requestID in
            match delegate.fb_request_did_load with
            [ Some f -> f json_data
            | _ -> ()
            ];
      
            Hashtbl.remove delegates requestID;
          )
        with [ Not_found -> () ]
    ]
  | _ -> facebook_request_did_fail requestID "The operation couldn’t be completed. (facebookErrDomain error 10000.)" 
  ];
  

Callback.register "facebook_request_did_fail" facebook_request_did_fail;
Callback.register "facebook_request_did_load" facebook_request_did_load;
  
end;



(*** DIALOGS ***)

module Dialog = struct

type delegate = 
{
  fb_dialog_did_complete              : option (unit -> unit);
  fb_dialog_did_cancel                : option (unit -> unit);
  fb_dialog_did_fail                  : option (string -> unit)
};

type users_filter = [ All | AppUsers | NonAppUsers ];

value string_of_users_filter filter = 
  match filter with
  [ All -> "all"
  | AppUsers -> "app_users"
  | NonAppUsers -> "app_non_users"
  ];

value delegates = Hashtbl.create 1;

external ios_facebook_open_apprequest_dialog : string -> string -> string -> string -> int -> unit = "ml_facebook_open_apprequest_dialog";

(* apprequest dialog *)
value _apprequest ?(message="") ?(recipients=[]) ?(filter=All) ?(title="") ?(delegate=None) () = 
  let dialogID = Random.int 10000 in
  (
    match delegate with
    [ Some d -> Hashtbl.add delegates dialogID d
    | None -> ()
    ];
    
    let recipientsStr = 
    match recipients with 
    [ []    -> ""
    | _     -> ExtString.String.join "," recipients
    ] 
    in ios_facebook_open_apprequest_dialog message recipientsStr (string_of_users_filter filter) title dialogID
  );
  

value apprequest ?(message="") ?(recipients=[]) ?(filter=All) ?(title="") ?(delegate=None) () = 
  let f = (fun _ -> _apprequest ~message ~recipients ~filter ~delegate ())
  in Session.with_auth_check f;



(* success *)
value facebook_dialog_did_complete dialogID = 
  try
    let delegate = Hashtbl.find delegates dialogID in
    (
      Hashtbl.remove delegates dialogID;
      match delegate.fb_dialog_did_complete with
      [ Some f -> f ()
      | None -> ()
      ]
    )
  with [ Not_found -> () ];


(* *)
value facebook_dialog_did_cancel dialogID = 
  try
    let delegate = Hashtbl.find delegates dialogID in
    (
      Hashtbl.remove delegates dialogID;
      match delegate.fb_dialog_did_cancel with
      [ Some f -> f ()
      | None -> ()
      ]
    )
  with [ Not_found -> () ];
  


(* *)
value facebook_dialog_did_fail_with_error dialogID error =   
  try
    let delegate = Hashtbl.find delegates dialogID in
    (
      Hashtbl.remove delegates dialogID;
      match delegate.fb_dialog_did_fail with
      [ Some f -> f error
      | None -> ()
      ]
    )
  with [ Not_found -> () ];


Callback.register "facebook_dialog_did_complete" facebook_dialog_did_complete;
Callback.register "facebook_dialog_did_cancel" facebook_dialog_did_cancel;
Callback.register "facebook_dialog_did_fail_with_error" facebook_dialog_did_fail_with_error;
Random.self_init ();
end;
  

ELSE 
    
value init appid = ();

module Session = struct
  value permissions = ref [];
end;


(*** GRAPH API ***)
module GraphAPI = struct

  type delegate = 
  {
    fb_request_did_fail   : option (string -> unit);    
    fb_request_did_load   : option (Ojson.t -> unit)
  };

  value request graph_path params ?(delegate = None) () = (); 
end;



(*** DIALOGS ***)
module Dialog = struct
  type delegate = 
  {
    fb_dialog_did_complete              : option (unit -> unit);
    fb_dialog_did_cancel                : option (unit -> unit);
    fb_dialog_did_fail                  : option (string -> unit)
  };

  type users_filter = [ All | AppUsers | NonAppUsers ];

  value apprequest ?(message="") ?(recipients=[]) ?(filter=All) ?(title="") ?(delegate=None) () = ();
end;


ENDIF;