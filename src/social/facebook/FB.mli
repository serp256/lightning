type connect;

value init: ~appId:string -> unit -> unit;

value connect: ~successCallback:(connect -> unit) -> ~failCallback:(string -> unit) -> unit -> unit;
value loggedIn: unit -> option connect;

value accessToken: connect -> string;
value apprequest: ~title:string -> ~message:string -> ?recipient:string -> ?successCallback:(list string -> unit) -> ?failCallback:(string -> unit) -> connect -> unit; (* list string in success callback -- user ids, which received request *)
value graphrequest: ~path:string -> ?params:(list (string * string)) -> ?successCallback:(Ojson.t -> unit) -> ?failCallback:(string -> unit) -> connect -> unit;