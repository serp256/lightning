(* TODO: доделать передачу receipt *)
value initialized = ref False;

IFDEF IOS THEN

external ml_init : (string -> bool -> unit) -> (string -> string -> bool -> unit) -> unit = "ml_payment_init";
external ml_purchase : string -> unit = "ml_payment_purchase";

ELSE

type callbacks = 
  {
    on_success: (string -> bool -> unit);
    on_error: (string -> string -> bool -> unit);
  };

value callbacks = ref None;

value ml_init success error = callbacks.val := Some {on_success = success; on_error = error};

value ml_purchase (id:string) = ();

ENDIF;

(* 
  инитим.
  Передаем два колбэка. 
  Первый - success, принимает product_id и флаг, показывающий, что транзацкция была восстановлена
  Второй - error, принимает product_id, строку ошибки и флаг, показывающий, что юзер отменил транзакцию.
*)
value init success_cb error_cb = (
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
