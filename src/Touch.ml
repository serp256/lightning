
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

type et 'event_type 'event_data = 
  {
    touch: t;
    target: option (DisplayObject.c 'event_type 'event_data)
  } constraint 'event_type = [> `TOUCH ] constraint 'event_data = [> `Touch of (t * (list (et 'event_type 'event_data))) ];


value touchesWithTarget touches ?phase target = 
  let target = target#asDisplayObject in
  let checkTarget t = 
    match t.target with
    [ Some trg -> 
      match trg = target with
      [ True ->
        match phase with
        [ None -> Some t.touch
        | Some phase when phase = t.touch.phase -> Some t.touch
        | _ -> None
        ]
      | False ->
          match target#dcast with
          [ `Container cont -> 
            match cont#containsChild trg with
            [ True -> Some t.touch
            | False -> None
            ]
          | _ -> None
          ]
      ]
    | None -> None
    ]
  in
  match phase with
  [ None -> ExtList.List.filter_map checkTarget touches
  | Some phase -> 
      ExtList.List.filter_map (fun t -> match t.touch.phase = phase with [ True -> checkTarget t | False -> None ]) touches
  ];
