
type eventType = [= DisplayObject.eventType | `TOUCH | `ENTER_FRAME ];
type eventData = [= DisplayObject.eventData | `Touches of list Touch.t | `PassedTime of float ];


module Make(D:DisplayObjectT.S with type evType = private [> eventType ] and type evData = private [> eventData ]) : StageT.S with module D = D;
