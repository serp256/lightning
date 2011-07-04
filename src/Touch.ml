
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

type n = 
  {
    n_tid: int32;
    n_timestamp: mutable float;
    n_globalX:float;
    n_globalY:float;
    n_previousGlobalX:mutable (option float);
    n_previousGlobalY:mutable (option float);
    n_tapCount:int;
    n_phase: mutable touchPhase;
  };


type t =
  { 
    tid: int32;
    timestamp:float;
    globalX:float;
    globalY:float;
    previousGlobalX: option float;
    previousGlobalY: option float;
    tapCount:int;
    phase: touchPhase;
  };


external t_of_n: n -> t = "%identity";
