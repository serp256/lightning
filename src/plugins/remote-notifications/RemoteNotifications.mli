

type rn_type = [= `RNBadge | `RNSound | `RNAlert ];

value init: ~rn_type:list rn_type -> ~sender_id:string -> ~success:(string -> unit) -> ~error:(string -> unit) -> unit;
