value init: ?consumerKey:string -> ?consumerSecret:string -> unit -> unit; (* on ios and pc should not be called or called without params, on android both option params should have some values *)
value tweet: ?success:(unit -> unit) -> ?fail:(string -> unit) -> ~text:string -> unit -> unit;
value tweetPic: unit -> unit;