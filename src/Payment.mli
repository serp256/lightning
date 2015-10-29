module Product:
  sig
    type t;
    type info = {
      currency: string;
      amount: float;
    };
    value price: string -> option string;
    value details: string -> option info;
  end;

module Transaction :
  sig
    type t;
    value get_id : t -> string;
    value get_receipt : t -> string;
    value get_signature : t -> string;
  end;

type marketType = [= `Google | `Amazon | `Yandex | `Samsung | `SamsungDev ];

value init: ?marketType:marketType -> ?skus:(list string) -> (string -> Transaction.t -> bool -> unit) -> (string -> string -> bool -> unit) -> unit;
value purchase: string -> unit;
value commit_transaction: Transaction.t -> unit;
value commit_transaction_by_id: string -> unit;
value restorePurchases: unit -> unit;
value restoreCompletedPurchases: unit -> unit;
