type network = [= `applifier of string ];

value start: ~appId:string -> ?userId:string -> ?securityToken:string -> ?networks:list network -> unit -> unit; 
value requestVideo: ~callback:(bool -> unit) -> unit -> unit;
value showVideo: ~callback:(unit -> unit) -> unit -> unit;