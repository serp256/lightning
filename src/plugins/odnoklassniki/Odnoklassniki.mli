value init: string -> string -> string -> unit;
value authorize: ?fail:(unit -> unit) -> ~success:(unit -> unit) -> unit -> unit;
