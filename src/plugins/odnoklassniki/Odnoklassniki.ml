external init: string -> string -> string -> unit = "ok_init"; 
external authorize: ?fail:(unit -> unit) -> ~success:(unit -> unit) -> unit -> unit = "ok_authorize"; 
