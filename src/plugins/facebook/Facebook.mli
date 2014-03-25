type connect;
type httpMethod = [= `get | `post ];

value init: ~appId:string -> unit -> unit;

value connect: ?permissions:(list string) -> ~successCallback:(connect -> unit) -> ~failCallback:(string -> unit) -> unit -> unit;
value loggedIn: unit -> option connect;

value accessToken: connect -> string;
value apprequest: ~title:string -> ~message:string -> ?recipient:string -> ?data:string -> ?successCallback:(list string -> unit) -> ?failCallback:(string -> unit) -> connect -> unit; (* list string in success callback -- user ids, which received request *)
value graphrequest: ~path:string -> ?params:(list (string * string)) -> ?successCallback:(string -> unit) -> ?failCallback:(string -> unit) -> ?httpMethod:httpMethod -> connect -> unit;
value disconnect: connect -> unit;

value sharePic: ?success:(unit -> unit) -> ?fail:(string -> unit) -> ~fname:string -> ~text:string -> connect -> unit;
value share: ?text:string -> ?link:string -> ?picUrl:string -> ?success:(unit -> unit) -> ?fail:(string -> unit) -> unit -> unit; (* This functions uses share dialog, integrated into Facebook app (Facebook app must be installed). No need to call "connect", "init" function call with app id is enough. *)


(*value sharePicUsingNativeApp: ~fname:string -> ~text:string -> unit -> bool; (* this method works only on android, share on ios using next method; text parameter skipped now due to facebook policy *)*)