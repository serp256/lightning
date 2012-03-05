

IFDEF IOS THEN


type state = [ NotInitialized | Initializing of Queue.t (bool -> unit) | Initialized | InitFailed ];

value state = ref NotInitialized;

external ios_init: unit -> bool = "ml_game_center_init";

value game_center_initialized success = 
  let callbacks = 
    match !state with
    [ Initializing callbacks -> callbacks
    | _ -> (Debug.w "Game center alredy initialized"; Queue.create ())
    ]
  in
  (
    state.val := 
      match success with
      [ True -> Initialized
      | False -> InitFailed
      ];
    while not (Queue.is_empty callbacks) do
      let c = Queue.pop callbacks in
      c success
    done;
  );


Callback.register "game_center_initialized" game_center_initialized;

value init ?callback () = 
  match !state with 
  [ NotInitialized -> 
    match ios_init () with
    [ True ->
      (
        let callbacks  = Queue.create () in
        (
          state.val := Initializing callbacks;
          match callback with
          [ None -> ()
          | Some f -> Queue.push f callbacks
          ];
        )
      )
    | False -> ()
    ]
  | Initializing callbacks -> 
      match callback with
      [ None -> ()
      | Some f -> Queue.push f callbacks
      ]
  | Initialized ->
      match callback with
      [ Some f -> f True
      | None ->  ()
      ]
  | InitFailed ->
      match callback with
      [ Some f -> f False
      | None -> ()
      ]
  ];


external playerID: unit -> string = "ml_playerID";

value report_leaderboard_failed category score = Debug.e "report leaderboard failed";
Callback.register "report_leaderboard_failed" report_leaderboard_failed;

external report_leaderboard: string -> int64 -> unit = "ml_report_leaderboard";
value reportLeaderboard category score = 
  match !state with
  [ NotInitialized -> failwith("GameCenter not initialized")
  | Initializing callbacks -> 
      let c = fun 
        [ True -> report_leaderboard category score
        | False -> report_leaderboard_failed category score
        ]
      in
      Queue.push c callbacks
  | Initialized -> report_leaderboard category score
  | InitFailed -> report_leaderboard_failed category score
  ];



external show_leaderboard: unit -> unit = "ml_show_leaderboard";
value showLeaderboard () = 
  match !state with
  [ NotInitialized -> failwith "GameCenter not initialized"
  | Initializing callbacks -> 
      let c = fun
        [ True -> show_leaderboard ()
        | False -> ()
        ]
      in
      Queue.push c callbacks
  | Initialized -> show_leaderboard ()
  | InitFailed -> ()
  ];



external report_achivement: string -> float -> unit = "ml_report_achivement";

value report_achivement_failed identifier percentComplete = Debug.e "report achivement failed";
Callback.register "report_achivement_failed" report_achivement_failed;

value reportAchivement identifier percentComplete = 
  let () = debug "report achivement" in
  match !state with
  [ NotInitialized -> failwith "GameCenter not initialized"
  | Initializing callbacks ->
      let c = fun
        [ True -> report_achivement identifier percentComplete
        | False -> report_achivement_failed identifier percentComplete
        ]
      in
      Queue.push c callbacks
  | Initialized -> report_achivement identifier percentComplete
  | InitFailed -> report_achivement_failed identifier percentComplete
  ];


external show_achivements: unit -> unit = "ml_show_achivements";


value showAchivements () =
  match !state with
  [ NotInitialized -> failwith "GameCenter not initialized"
  | Initializing callbacks ->
      let c = fun
        [ True -> show_achivements ()
        | False -> ()
        ]
      in
      Queue.push c callbacks
  | Initialized -> show_achivements ()
  | InitFailed -> ()
  ];

external get_friends_identifiers : (list string -> unit) -> unit = "ml_get_friends_identifiers";

value getFriends cb = 
  match !state with
  [ NotInitialized -> failwith "GameCenter not initialized" 
  | Initializing callbacks -> 
      let c = fun 
        [ True  -> get_friends_identifiers cb
        | False -> cb []
        ]
      in Queue.push c callbacks
  | Initialized -> get_friends_identifiers cb
  | InitFailed -> cb []
  ];



external load_users_info : list string -> (list (string*(string*option Texture.textureInfo)) -> unit) -> unit = "ml_load_users_info";

value loadUserInfo identifiers cb = 
  let lcb infos = 
    cb (List.map 
      begin fun (playerId, (alias, photoTInfo)) ->
        match photoTInfo with
        [ None -> (playerId, (alias, None))
        | Some tinfo -> (playerId, (alias, (Some (Texture.make tinfo))))
        ]
      end infos)
  in 
  match !state with
  [ NotInitialized -> failwith "GameCenter not initialized" 
  | Initializing callbacks -> 
      let c = fun 
        [ True  -> load_users_info identifiers lcb
        | False -> lcb []
        ]
      in Queue.push c callbacks
  | Initialized -> load_users_info identifiers lcb
  | InitFailed -> lcb []
  ];


ELSE

value init ?callback () = 
  match callback with
  [ Some c -> c False
  | None -> ()
  ];

value playerID () = "";

value reportLeaderboard (category:string) (scores:int64) = ();
value showLeaderboard () = ();
value reportAchivement (identifier:string) (percentComplete:float) = ();
value showAchivements () = ();
value getFriends cb = cb [];
value loadUserInfo identifiers cb = cb [];

ENDIF;
