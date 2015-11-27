value init: ~appKey: string -> ~secretKey: string -> ?version: string -> ?enableDebug: bool -> ?currencies:(list string) -> ?itemTypes:(list string) -> ?dimensions:(list string) -> unit -> unit;
value businessEvent: ~cartType: string -> ~itemType: string -> ~itemId: string -> ~currency: string -> ~amount: int -> ~receipt: string -> ?signature: string -> unit -> unit;

type resourceEventType = [= `sink| `source];
value resourceEvent: ~flowType: resourceEventType -> ~currency: string -> ~amount: float -> ~itemType: string -> ~itemId: string -> unit -> unit;

type progressionEventType = [=`start | `complete | `fail];
value progressionEvent: ~status: progressionEventType -> ~progression1: string -> ?progression2: string -> ?progression3: string -> ?score: int -> unit -> unit;

value designEvent: ~eventId: string -> ?fvalue: float -> unit -> unit;

type errorEventType = [= `edebug| `info | `warning | `error | `critical];
value errorEvent: ~errorType: errorEventType -> ?message:string -> unit -> unit;
