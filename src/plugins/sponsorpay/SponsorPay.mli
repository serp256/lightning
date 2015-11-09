
value start: ~appId:string -> ?userId:string -> ?securityToken:string -> ?test: bool -> unit -> unit; 
value requestVideo: ~callback:(bool -> unit) -> unit -> unit;
value showVideo: ~callback:(bool-> unit) -> unit -> unit;
value showOffers: unit -> unit;
