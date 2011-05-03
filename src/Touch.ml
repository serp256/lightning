
type touchPhase = 
  [ TouchPhaseBegan  (* The finger just touched the screen *)
  | TouchPhaseMoved  (* The finger moves around *)
  | TouchPhaseStationary (* The finger has not moved since the last frame *)
  | TouchPhaseEnded       (*  The finger was lifted from the screen   *)
  | TouchPhaseCancelled   (* The touch was aborted by the system (e.g. because of a alert Box popping up) *)
  ];

value string_of_touchPhase = fun
  [ TouchPhaseBegan -> "began"
  | TouchPhaseMoved -> "moved"
  | TouchPhaseStationary -> "stationary"
  | TouchPhaseEnded -> "ended"
  | TouchPhaseCancelled -> "cancelled"
  ];

type t =
  { 
    timestamp:float;
    globalX:float;
    globalY:float;
    previousGlobalX:float;
    previousGlobalY:float;
    tapCount:int;
    phase: touchPhase;
  };
