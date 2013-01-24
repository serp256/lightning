module Transaction = struct
  
IFDEF ANDROID THEN
  type t = {
    id:string;
    receipt:string;
    signature:string;
  };

  value get_id tr = tr.id;
  value get_receipt tr = tr.receipt;
  value get_signature tr = tr.signature;
ELSE
  type t;
  
  IFDEF IOS THEN
    external get_id : t -> string = "ml_payment_get_transaction_id";
    external get_receipt : t -> string = "ml_payment_get_transaction_receipt"; 
    value get_signature (tr:t) = "";
  ELSE
    value get_id (tr:t) = "";
    value get_receipt (tr:t) = "";
    value get_signature (tr:t) = "";
  ENDIF;    
ENDIF;
  
end;


(* TODO: доделать передачу receipt *)
value initialized = ref False;

external ml_purchase : string -> unit = "ml_payment_purchase";

IFDEF IOS THEN
external ml_init : (string -> Transaction.t -> bool -> unit) -> (string -> string -> bool -> unit) -> unit = "ml_payment_init";
external ml_commit_transaction : Transaction.t -> unit = "ml_payment_commit_transaction";
ELSE

IFDEF ANDROID THEN
external ml_init : ?pubkey:string -> (string -> Transaction.t -> bool -> unit) -> (string -> string -> bool -> unit) -> unit = "ml_payment_init";
external _ml_commit_transaction : string -> unit = "ml_payment_commit_transaction";
external restoreTransactions: unit -> unit = "ml_restoreTransactions";
value ml_commit_transaction t = _ml_commit_transaction (Transaction.get_id t);
ELSE

type callbacks = 
  {
    on_success: (string -> Transaction.t -> bool -> unit);
    on_error: (string -> string -> bool -> unit);
  };

value callbacks = ref None;

value ml_init success error = callbacks.val := Some {on_success = success; on_error = error};

value ml_purchase (id:string) = ();

value ml_commit_transaction (tr:Transaction.t) = ();

value restoreTransactions () = ();

ENDIF;
ENDIF;

(* 
  инитим.
  Передаем два колбэка. 
  Первый - success, принимает product_id и флаг, показывающий, что транзацкция была восстановлена
  Второй - error, принимает product_id, строку ошибки и флаг, показывающий, что юзер отменил транзакцию.
*)
value init ?pubkey success_cb error_cb = (
  ifplatform(android)
    ml_init ?pubkey success_cb error_cb
  else
    ml_init success_cb error_cb;
  initialized.val := True;
);


(*
  совершаем покупку 
*)

value purchase product_id = 
  match !initialized with 
  [ False -> failwith "Payment not initialized. Call init first"
  | True  ->  ml_purchase product_id
  ];


value commit_transaction tr = 
  match !initialized with 
  [ False -> failwith "Payment not initialized. Call init first"
  | True  ->  ml_commit_transaction tr
  ];  

IFDEF ANDROID THEN
value commit_transaction_by_id = _ml_commit_transaction;
ELSE
value commit_transaction_by_id _ = failwith "cannot commit transaction by id";
ENDIF;