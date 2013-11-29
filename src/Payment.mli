module Product:
  sig
    type t;

    value get: string -> option t;
    value price: t -> float;
    value currency: t -> string;
  end;

module Transaction : 
  sig
    type t;
    value get_id : t -> string;
    value get_receipt : t -> string;
    value get_signature : t -> string;
  end;

type marketType = [= `Google of (option string) | `Amazon ];

value init: ?marketType:marketType -> ?skus:(list string) -> (string -> Transaction.t -> bool -> unit) -> (string -> string -> bool -> unit) -> unit;
value purchase: string -> unit;
value commit_transaction: Transaction.t -> unit;
value commit_transaction_by_id: string -> unit;
value restorePurchases: unit -> unit;
value restoreCompletedPurchases: unit -> unit;
