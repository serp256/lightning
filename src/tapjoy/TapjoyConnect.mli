(* дергаем тапжой, сообщаем о том, что мы запустили приложение. чем раньше дернем - тем лучше *)
value init : string -> string -> unit;

(* по умолчанию uid равен UDID (или IMEI на android). Если мы используем виртуальную валюту, то нужен нормальный ID *)
value setUserID : string -> unit;


value getUserID : unit -> string;

(* для Pay Per Action - сообщаем о том, что завершили action. Перед вызовом нужно выставить UserID *)
value actionComplete : string -> unit;


(* Показываем marketplace *)
value showOffers : unit -> unit;


(* Показываем marketplace. selector:bool говорит нам показывать ли пользователю переключатель валют или нет *)
value showOffersWithCurrency : string -> bool -> unit;





