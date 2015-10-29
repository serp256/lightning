module Transaction = struct

IFDEF ANDROID THEN
  type t;

  external get_id: t -> string = "openiab_token";
  external get_receipt: t -> string = "openiab_orig_json";
  external get_signature: t -> string = "openiab_signature";
ELSE
  IFDEF IOS THEN
    type t;

    external get_id : t -> string = "ml_payment_get_transaction_id";
    external get_receipt : t -> string = "ml_payment_get_transaction_receipt";
    value get_signature (tr:t) = "";
  ELSE
    type t = unit;

    value get_id (tr:t) = "";
    value get_receipt (tr:t) = "";
    value get_signature (tr:t) = "";
  ENDIF;
ENDIF;

end;

module Product =
  struct
    type info = {
      currency: string;
      amount: float;
    };
    IFDEF PC THEN
      type t;

      value price sku = None;
      value details sku = None;
    ELSE
      IFDEF IOS THEN
        type t;
      ELSE
        type t = string;
      ENDIF;


      value prods = Hashtbl.create 10;
      value register sku prod = Hashtbl.add prods sku prod;
      value get sku = try Some (Hashtbl.find prods sku) with [ Not_found -> None ];

      value details = Hashtbl.create 10;
      value registerDetails sku i = Hashtbl.add details sku i;

      IFDEF IOS THEN
        external price: t -> string = "ml_product_price";
        value price sku = match get sku with [ Some p -> Some (price p) | _ -> None ];

        external details: t -> info = "ml_product_details";
        value details sku = match get sku with [ Some p -> Some (details p) | _ -> None ];
        value createDetails currency amount = {currency; amount};
      ELSE
        value price = get;
        value details sku = try Some (Hashtbl.find details sku) with [ Not_found -> None ];
        value createDetails currency amount=  {currency; amount};
      ENDIF;
    ENDIF;
  end;


(* TODO: доделать передачу receipt *)
value initialized = ref False;
type marketType = [= `Google | `Amazon | `Yandex | `Samsung | `SamsungDev ];


IFDEF IOS THEN
external ml_init : ?skus:list string -> (string -> Transaction.t -> bool -> unit) -> (string -> string -> bool -> unit)-> unit = "ml_payment_init";
external ml_commit_transaction : Transaction.t -> unit = "ml_payment_commit_transaction";
external ml_purchase_deprecated : string -> unit = "ml_payment_purchase_deprecated";
external ml_purchase : Product.t -> unit = "ml_payment_purchase";
value ml_purchase sku = match Product.get sku with [ Some p -> ml_purchase p | _ -> ml_purchase_deprecated sku ];
value restorePurchases () = ();
external restoreCompletedPurchases: unit -> unit = "ml_payment_restore_completed_transactions";


Callback.register "register_product" Product.register;
Callback.register "create_product_details" Product.createDetails;
ELSE

IFDEF ANDROID THEN

external ml_init : ?skus:list string -> marketType -> unit = "openiab_init";
external ml_purchase : string -> unit = "openiab_purchase";
external ml_commit_transaction : Transaction.t -> unit = "openiab_comsume";
external ml_restorePurchases: unit -> unit = "openiab_inventory";


value restoreCompletedPurchases () = ();
value restorePurchases = ml_restorePurchases;

Callback.register "register_product" Product.register;
Callback.register "register_product_details" Product.registerDetails;
Callback.register "create_product_details" Product.createDetails;
ELSE

type callbacks =
  {
    on_success: (string -> Transaction.t -> bool -> unit);
    on_error: (string -> string -> bool -> unit);
  };

value callbacks = ref None;

value ml_init ?skus success error = callbacks.val := Some {on_success = success; on_error = error};

value ml_purchase (id:string) =
  match !callbacks with
  [ Some { on_success = c; _ } -> c id () False
  | _ -> ()
  ];

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

value init ?(marketType = `Google) ?skus success_cb error_cb = (
  IFDEF ANDROID THEN
  (
    Callback.register "camlPaymentsSuccess" success_cb;
    Callback.register "camlPaymentsFail" error_cb;
    ml_init ?skus marketType
  )
  ELSE
    ml_init ?skus success_cb error_cb
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
  | True  -> ml_commit_transaction tr
  ];

IFDEF ANDROID THEN
value commit_transaction_by_id _ = assert False;
ELSE
value commit_transaction_by_id _ = failwith "cannot commit transaction by id";
ENDIF;
