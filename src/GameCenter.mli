value init: ?callback:(bool -> unit) ->	?amazon:bool -> unit -> unit;
value is_connected: unit -> bool;
value playerID: unit -> option string;
IFPLATFORM(ios pc)
value reportAchievement: string -> float -> unit;
ENDPLATFORM;
value reportLeaderboard: string -> int64 -> unit;
value unlockAchievement: string -> unit;
value showLeaderboard: unit -> unit;
value showAchievements: unit -> unit;
value reportAchievement: string -> float -> unit;


type player = 
  {
    id: string;
    name: string;
    icon: option Texture.c;
  };

value getFriends: (list string -> unit) -> unit; (* NOT works on ANDROID *)
(* (string*(string*option Texture.c) *)
value loadUserInfo: list string -> (list player -> unit) -> unit;

value currentPlayer: unit -> option player;

value signOut: unit -> unit; (* NOT works for IOS *)


