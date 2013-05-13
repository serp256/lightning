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
type marketType = [= `Google of (option string) | `Amazon ];


IFDEF IOS THEN
external ml_init : (string -> Transaction.t -> bool -> unit) -> (string -> string -> bool -> unit) -> unit = "ml_payment_init";
external ml_commit_transaction : Transaction.t -> unit = "ml_payment_commit_transaction";
external ml_purchase : string -> unit = "ml_payment_purchase";
value restorePurchases () = ();
external restoreCompletedPurchases: unit -> unit = "ml_payment_restore_completed_transactions";
ELSE

IFDEF ANDROID THEN

external ml_init : marketType -> unit = "ml_paymentsInit";
external ml_purchase : string -> unit = "ml_paymentsPurchase";
external _ml_commit_transaction : string -> unit = "ml_paymentsCommitTransaction";
external ml_restorePurchases: unit -> unit = "ml_restorePurchases";

value ml_commit_transaction t = _ml_commit_transaction (Transaction.get_id t);
value restoreCompletedPurchases () = ();
value restorePurchases = ml_restorePurchases;

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

value restorePurchases () = ();
value restoreCompletedPurchases () = ();

ENDIF;
ENDIF;

(* 
  инитим.
  Передаем два колбэка. 
  Первый - success, принимает product_id и флаг, показывающий, что транзацкция была восстановлена
  Второй - error, принимает product_id, строку ошибки и флаг, показывающий, что юзер отменил транзакцию.
*)

value init ?(marketType = `Google None) success_cb error_cb = (
  IFDEF ANDROID THEN
  (
    Callback.register "camlPaymentsSuccess" success_cb;
    Callback.register "camlPaymentsFail" error_cb;
    ml_init marketType
  )
  ELSE
    ml_init success_cb error_cb
  ENDIF;

  initialized.val := True;
);


(*
  совершаем покупку 
*)

value purchase product_id = 
  match !initialized with 
  [ False -> failwith "Payment not initialized. Call init first"
  | True  -> ml_purchase product_id
  ];


value commit_transaction tr = 
  match !initialized with 
  [ False -> failwith "Payment not initialized. Call init first"
  | True  ->
    IFDEF AMAZON THEN
      ()
    ELSE
      ml_commit_transaction tr
    ENDIF
  ];  

IFDEF ANDROID THEN
value commit_transaction_by_id = _ml_commit_transaction;
ELSE
value commit_transaction_by_id _ = failwith "cannot commit transaction by id";
ENDIF;
