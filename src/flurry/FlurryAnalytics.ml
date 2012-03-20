type gender = [ Male | Female ];

IFDEF IOS THEN

external ml_flurry_start_session : string -> unit = "ml_flurry_start_session";

external ml_flurry_log_event : string -> bool -> option (list (string*string)) -> unit = "ml_flurry_log_event";

external ml_flurry_end_timed_event : string -> option (list (string*string)) -> unit = "ml_flurry_end_timed_event";

external ml_flurry_set_user_id : string -> unit = "ml_flurry_set_user_id";

external ml_flurry_set_user_age : int -> unit = "ml_flurry_set_user_age";

external ml_set_user_gender : gender -> unit = "ml_set_user_gender";

ELSE 

value ml_flurry_start_session appkey = ();

value ml_flurry_log_event eventName timed params = ();

value ml_flurry_end_timed_event eventName params = ();

value ml_flurry_set_user_id uid = ();

value ml_flurry_set_user_age age = ();

value ml_set_user_gender gender = ();

ENDIF;

value startSession appkey = ml_flurry_start_session appkey;

value logEvent ?(timed=False) ?(params=None) eventName = ml_flurry_log_event eventName timed params;

value endTimedEvent ?(params=None) eventName = ml_flurry_end_timed_event eventName params;

value setUserID uid = ml_flurry_set_user_id uid;

value setAge age = ml_flurry_set_user_age age;

value setGender gender = ml_set_user_gender gender;
