
IFPLATFORM(android)

external _init: string -> string -> option string -> bool -> option (list string)-> option (list string) -> option (list string) -> unit = "ml_ga_init_byte" "ml_ga_init";
value init ~appKey ~secretKey ?version ?(enableDebug=False) ?currencies ?itemTypes ?dimensions () = _init appKey secretKey version enableDebug currencies itemTypes dimensions;

external _businessEvent: string -> string -> string -> string -> int -> string -> string -> unit = "ml_ga_business_event_byte" "ml_ga_business_event";
value businessEvent ~cartType ~itemType ~itemId ~currency ~amount ~receipt ~signature () = _businessEvent cartType itemType itemId currency amount receipt signature;

type resourceEventType = [= `sink| `source];
external _resourceEvent: resourceEventType -> string -> float -> string -> string -> unit = "ml_ga_resource_event";
value resourceEvent ~flowType ~currency ~amount ~itemType ~itemId () = _resourceEvent flowType currency amount itemType itemId;

type progressionEventType = [=`start | `complete | `fail];
external _progressionEvent: progressionEventType -> string -> option string -> option string -> option int -> unit = "ml_ga_progression_event";
value progressionEvent ~status ~progression1 ?progression2  ?progression3  ?score () = _progressionEvent status progression1 progression2 progression3 score;

external _designEvent: string -> option float -> unit  = "ml_ga_design_event";
value designEvent ~eventId ?fvalue () = _designEvent eventId fvalue;

type errorEventType = [=`edebug | `info | `warning | `error | `critical];
external _errorEvent: errorEventType -> option string -> unit  = "ml_ga_error_event";
value errorEvent ~errorType ?message () = _errorEvent errorType message;

ELSE

value init ~appKey ~secretKey ?version ?(enableDebug=False) ?currencies ?itemTypes ?dimensions () = fun _ _ _ _ _ _ _ _ -> ();
value businessEvent ~cartType ~itemType ~itemId ~currency ~amount ~receipt ~signature () = fun _ _ _ _ _ _ _ _ -> ();
value resourceEvent ~flowType ~currency ~amount ~itemType ~itemId () = fun _ _ _ _ _ _ -> ();
value progressionEvent ~status ~progression1 ?progression2  ?progression3  ?score () = fun _ _ _ _ _ _ -> ();

value designEvent ~eventId ?fvalue () = fun _ _ _ -> ();
value errorEvent ~errorType ?message () = fun _ _ _ -> ();

ENDPLATFORM;

