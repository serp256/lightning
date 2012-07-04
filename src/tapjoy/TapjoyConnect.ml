IFDEF IOS THEN

external ml_tapjoy_init : string -> string -> unit = "ml_tapjoy_init";

external ml_tapjoy_set_user_id : string -> unit = "ml_tapjoy_set_user_id";

external ml_tapjoy_get_user_id : unit -> string = "ml_tapjoy_get_user_id";

external ml_tapjoy_action_complete : string -> unit = "ml_tapjoy_action_complete";

external ml_tapjoy_show_offers : unit -> unit = "ml_tapjoy_show_offers";

external ml_tapjoy_show_offers_with_currency : string -> bool -> unit = "ml_tapjoy_show_offers_with_currency";

external getOpenUDID: unit -> option string = "ml_TJCOpenUDIDvalue";

ELSE 

value ml_tapjoy_init appid skey = ();

value ml_tapjoy_set_user_id user_id = ();

value ml_tapjoy_get_user_id () = "";

value ml_tapjoy_action_complete action = ();

value ml_tapjoy_show_offers () = ();

value ml_tapjoy_show_offers_with_currency currency selector = ();

value getOpenUDID () = None;

ENDIF;

(* дергаем тапжой, сообщаем о том, что мы запустили приложение. чем раньше дернем - тем лучше *)
value init appid skey = ml_tapjoy_init appid skey;



(* по умолчанию uid равен UDID (или IMEI на android). Если мы используем виртуальную валюту, то нужен нормальный ID *)
value setUserID uid = ml_tapjoy_set_user_id uid;



value getUserID () = ml_tapjoy_get_user_id ();



(* для Pay Per Action - сообщаем о том, что завершили action. Перед вызовом нужно выставить UserID *)
value actionComplete action = ml_tapjoy_action_complete action;



(* Показываем marketplace *)
value showOffers () = ml_tapjoy_show_offers ();



(* Показываем marketplace. selector:bool говорит нам показывать ли пользователю переключатель валют или нет *)
value showOffersWithCurrency currency selector = ml_tapjoy_show_offers_with_currency currency selector;




