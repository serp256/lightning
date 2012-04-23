(*
notify  Пользователь разрешил отправлять ему уведомления.
friends     Доступ к друзьям.
photos  Доступ к фотографиям.
audio   Доступ к аудиозаписям.
video   Доступ к видеозаписям.
docs    Доступ к документам.
notes   Доступ заметкам пользователя.
pages   Доступ к wiki-страницам.
wall    Доступ к обычным и расширенным методам работы со стеной.
groups  Доступ к группам пользователя.
messages    (для Standalone-приложений) Доступ к расширенным методам работы с сообщениями.
notifications   Доступ к оповещениям об ответах пользователю.
stats   Доступ к статистике групп и приложений пользователя, администратором которых он является.
ads     Доступ к расширенным методам работы с рекламным API.
offline     Доступ к API в любое время со стороннего сервера.

Пример: scope=friends,video,offline
*)

open SNTypes;

type permission = [ Notify | Friends | Photos | Audio | Video | Docs | Notes | Pages | Wall | Groups | Messages | Notifications | Stats | Ads | Offline ];

type permissions = list permission;


module type Param = sig
  value appid: string;
  value permissions:permissions;
end;


module Make(P:Param) : sig
(* value init : string -> permissions -> unit; *)
  
  value call_method : ?delegate:delegate -> string -> list (string*string) -> unit;

  value get_access_token : unit -> string;

  value get_user_id : unit -> string;
end;











