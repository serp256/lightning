type connect;

value init: ~appId:string -> unit -> unit;

value connect: ?permissions:(list string) -> ~successCallback:(connect -> unit) -> ~failCallback:(string -> unit) -> unit -> unit;
value loggedIn: unit -> option connect;

value accessToken: connect -> string;
value apprequest: ~title:string -> ~message:string -> ?recipient:string -> ?data:string -> ?successCallback:(list string -> unit) -> ?failCallback:(string -> unit) -> connect -> unit; (* list string in success callback -- user ids, which received request *)
(* value graphrequest: ~path:string -> ?params:(list (string * string)) -> ?successCallback:(Ojson.json -> unit) -> ?failCallback:(string -> unit) -> connect -> unit; *)
value graphrequest: ~path:string -> ?params:(list (string * string)) -> ?successCallback:(string -> unit) -> ?failCallback:(string -> unit) -> connect -> unit;
value disconnect: connect -> unit;
value sharePicUsingNativeApp: ~fname:string -> ~text:string -> unit -> bool; (* text skipped on android *)
value sharePic: ?success:(unit -> unit) -> ?fail:(string -> unit) -> ~fname:string -> ~text:string -> connect -> unit;