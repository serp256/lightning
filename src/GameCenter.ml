
type player = 
  {
    id: string;
    name: string;
    icon: option Texture.c;
  };

(************************************
 * INITIALIZATION
 **************************************)

IFPLATFORM(ios android)


type state = [ NotInitialized | Initializing of Queue.t (bool -> unit) | Initialized ];

value state = ref NotInitialized;

value is_connected () = 
  match !state with
  [ Initialized -> True
  | _ -> False 
  ];

value initializer_handler = ref None;

external gamecenter_init: unit -> bool = "ml_gamecenter_init";

value game_center_initialized success = 
  let () = debug "GameCenter initialized" in
  match !state with
  [ Initializing callbacks -> 
    (
      state.val := 
        match success with
        [ True -> Initialized
        | False -> NotInitialized
        ];
      match !initializer_handler with
      [ Some f -> f success
(*           initializer_handler.val := None; *)
      | _ -> ()
      ];
      while not (Queue.is_empty callbacks) do
        let c = Queue.pop callbacks in
        c success
      done
    )
  | _ -> Debug.w "Game center state incosistent"
  ];


Callback.register "game_center_initialized" game_center_initialized;

value init ?callback () = 
  match !state with 
  [ NotInitialized -> 
    match gamecenter_init () with
    [ True ->
      (
        initializer_handler.val := callback;
        let callbacks  = Queue.create () in
        state.val := Initializing callbacks;
      )
    | False -> ()
    ]
  | Initializing callbacks -> 
      match callback with
      [ Some c -> Queue.add c callbacks
      | None -> ()
      ]
  | Initialized ->
      match callback with
      [ Some f -> f True
      | None ->  ()
      ]
  ];


external _playerID: unit -> option string = "ml_gamecenter_playerID";


value playerID () = 
  match !state with
  [ Initialized -> _playerID ()
  | _ -> None
  ];

ELSE

value init ?callback () = 
  match callback with
  [ Some c -> c False
  | None -> ()
  ];

value playerID () = None;
value is_connected () = False;

ENDPLATFORM;


(************************************
 * LEADERBOARDS AND ACHIEVEMNTS REPORT
 **************************************)


IFPLATFORM(ios)

external report_achievement: string -> float -> unit = "ml_gamecenter_report_achievement";
value report_achievement_failed identifier percentComplete = Debug.e "report achievement failed"; (* FIXME: try to save this in local data *)
Callback.register "report_achievement_failed" report_achievement_failed;
value reportAchievement identifier percentComplete = 
  let () = debug "report achievement" in
  match !state with
  [ NotInitialized -> report_achievement_failed identifier percentComplete
  | Initializing callbacks ->
      let c = fun
        [ True -> report_achievement identifier percentComplete
        | False -> report_achievement_failed identifier percentComplete
        ]
      in
      Queue.push c callbacks
  | Initialized -> report_achievement identifier percentComplete
  ];

value unlockAchievement identifier = reportAchievement identifier 100.;

value report_leaderboard_failed category score = Debug.e "report leaderboard failed";
Callback.register "report_leaderboard_failed" report_leaderboard_failed;

external report_leaderboard: string -> int64 -> unit = "ml_gamecenter_report_leaderboard";
value reportLeaderboard category score = 
  match !state with
  [ NotInitialized -> report_leaderboard_failed category score
  | Initializing callbacks -> 
      let c = fun 
        [ True -> report_leaderboard category score
        | False -> report_leaderboard_failed category score
        ]
      in
      Queue.push c callbacks
  | Initialized -> report_leaderboard category score
  ];






ELSPLATFORM(android)

external unlock_achievement: string -> unit = "ml_gamecenter_unlock_achievement";

value unlock_achievement_failed identifier = Debug.e "unlock achievement '%s' failed" identifier;

value unlockAchievement identifier =
  match !state with
  [ NotInitialized -> unlock_achievement_failed identifier 
  | Initializing callbacks ->
      let c = fun
        [ True -> unlock_achievement identifier 
        | False -> unlock_achievement_failed identifier 
        ]
      in
      Queue.push c callbacks
  | Initialized -> unlock_achievement identifier 
  ];



ELSE

value reportLeaderboard (category:string) (scores:int64) = ();
value reportAchievement (identifier:string) (percentComplete:float) = ();
value unlockAchievement (identifier:string) = ();


ENDPLATFORM;


(************************************
 * SHOW LEADERBOARD and ACHIEVEMENTS
 **************************************)


IFPLATFORM(ios android)

external show_achievements: unit -> unit = "ml_gamecenter_show_achievements";

value showAchievements () =
  match !state with
  [ NotInitialized -> ()
  | Initializing callbacks ->
      let c = fun
        [ True -> show_achievements ()
        | False -> ()
        ]
      in
      Queue.push c callbacks
  | Initialized -> show_achievements ()
  ];

external show_leaderboard: unit -> unit = "ml_gamecenter_show_leaderboard";
value showLeaderboard () = 
  match !state with
  [ NotInitialized -> ()
  | Initializing callbacks -> 
      let c = fun
        [ True -> show_leaderboard ()
        | False -> ()
        ]
      in
      Queue.push c callbacks
  | Initialized -> show_leaderboard ()
  ];


ELSE

value showLeaderboard () = ();
value showAchievements () = ();

ENDPLATFORM;


(***************************
 *  GET_FRIENDS LOAD_USERS
 ************************** 
 *)

IFPLATFORM(ios)
external get_friends_identifiers : (list string -> unit) -> unit = "ml_gamecenter_get_friends_identifiers";
value getFriends cb = 
  match !state with
  [ NotInitialized -> cb []
  | Initializing callbacks -> 
      let c = fun 
        [ True  -> get_friends_identifiers cb
        | False -> cb []
        ]
      in Queue.push c callbacks
  | Initialized -> get_friends_identifiers cb
  ];

external load_users_info : list string -> (list (string*string*option Texture.textureInfo) -> unit) -> unit = "ml_gamecenter_load_users_info";

value loadUserInfo identifiers cb = 
  let lcb infos = 
    cb (List.map 
      begin fun (playerId, alias, photoTInfo) ->
        match photoTInfo with
        [ None -> {id=playerId;name=alias;icon= None}
        | Some tinfo -> {id=playerId; name=alias; icon = Some (Texture.make tinfo)}
        ]
      end infos)
  in 
  match !state with
  [ NotInitialized -> lcb []
  | Initializing callbacks -> 
      let c = fun 
        [ True  -> load_users_info identifiers lcb
        | False -> lcb []
        ]
      in Queue.push c callbacks
  | Initialized -> load_users_info identifiers lcb
  ];

ELSE
value getFriends cb = cb [];
value loadUserInfo identifiers cb = cb [];
ENDPLATFORM;


(**********************************
 *    CURRENT PLAYER
 *************************************)

IFPLATFORM(ios android)

external current_player: unit -> option player = "ml_gamecenter_current_player";


value currentPlayer () = 
  match !state with
  [ Initialized -> current_player ()
  | _ -> None
  ];

ELSE
value currentPlayer () = None;
ENDPLATFORM;




(**********************************
 *    SIGN OUT
 *************************************)

IFPLATFORM(android)

external sign_out: unit -> unit = "ml_gamecenter_signout";
value game_center_disconnected () = (* ????? *)
  let () = debug "GameCenter disconnected" in
  match !state with
  [ NotInitialized -> ()
  | Initializing queue -> ()
  | Initialized -> state.val := NotInitialized
  ];

Callback.register "game_center_disconnected" game_center_disconnected;

value signOut () = 
  match !state with
  [ Initialized -> 
    (
      sign_out ();
      state.val := NotInitialized;
    )
  | _ -> ()
  ];

ELSE
value signOut () = ();
ENDPLATFORM;
