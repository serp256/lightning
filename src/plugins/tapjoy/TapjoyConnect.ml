

IFPLATFORM(ios android) 

(* дергаем тапжой, сообщаем о том, что мы запустили приложение. чем раньше дернем - тем лучше *)
external init : string -> string -> unit = "ml_tapjoy_init";
(* Показываем marketplace *)
external showOffers : unit -> unit = "ml_tapjoy_show_offers";
(* Показываем marketplace. selector:bool говорит нам показывать ли пользователю переключатель валют или нет *)
external showOffersWithCurrency : string -> bool -> unit = "ml_tapjoy_show_offers_with_currency";
(* по умолчанию uid равен UDID (или IMEI на android). Если мы используем виртуальную валюту, то нужен нормальный ID *)
external setUserID: string -> unit = "ml_tapjoy_set_user_id";
(* external getUserID: unit -> string = "ml_tapjoy_get_user_id"; *)
(* для Pay Per Action - сообщаем о том, что завершили action. Перед вызовом нужно выставить UserID *)
external actionComplete : string -> unit = "ml_tapjoy_action_complete";

ELSE

value init appid skey = ();
value setUserID user_id = ();
value showOffers () = ();
value showOffersWithCurrency (currency:string) (selector:bool) = ();
ENDPLATFORM;
value getUserID () = "";
