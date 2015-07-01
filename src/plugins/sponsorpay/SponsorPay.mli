type network = [= `applifier of string | `applovin of string ];

value start: ~appId:string -> ?userId:string -> ?securityToken:string -> ?logging: bool -> ?networks:list network -> unit -> unit; 
value requestVideo: ~callback:(bool -> unit) -> unit -> unit;
value showVideo: ~callback:(unit -> unit) -> unit -> unit;
value showOffers: unit -> unit;
