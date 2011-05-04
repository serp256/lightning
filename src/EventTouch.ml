
open Touch;

module Make(D:DisplayObjectT.M) = struct 
  
  type t = {
      touch: Touch.t;
      target: option D.c;
    };

  type e = (Touch.t * list t);


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

end;
