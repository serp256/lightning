module Transaction : 
  sig
    type t;
    value get_id : t -> string;
    value get_receipt : t -> string;
    value get_signature : t -> string;
  end;


value init : ?pubkey:string -> (string -> Transaction.t -> bool -> unit) -> (string -> string -> bool -> unit) -> unit;
value purchase : string -> unit;
value commit_transaction : Transaction.t -> unit;
value commit_transaction_by_id : string -> unit;
value restoreTransactions: unit -> unit;