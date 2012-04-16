

value init: ?callback:(bool -> unit) -> unit -> unit;
value playerID: unit -> option string;
value reportLeaderboard: string -> int64 -> unit;
value reportAchivement: string -> float -> unit;
value showLeaderboard: unit -> unit;
value showAchivements: unit -> unit;
value getFriends: (list string -> unit) -> unit;
value loadUserInfo: list string -> (list (string*(string*option Texture.c)) -> unit) -> unit;


