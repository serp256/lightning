
type eventType = [= `ADDED | `ADDED_TO_STAGE | `REMOVED | `REMOVED_FROM_STAGE | `ENTER_FRAME ]; 
type eventData = [= Ev.dataEmpty | `PassedTime of float ];

module type Param = sig
  type evType = private [> eventType ];
  type evData = private [> eventData ];
end;

module Make(P:Param): DisplayObjectT.S with type evType = P.evType and type evData = P.evData;
