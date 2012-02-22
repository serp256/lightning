module Transaction : 
  sig
    type t;
    value get_id : t -> string;
    value get_receipt : t -> string;
  end;


value init : (string -> Transaction.t -> bool -> unit) -> (string -> string -> bool -> unit) -> unit;

value purchase : string -> unit;

value commit_transaction : Transaction.t -> unit;