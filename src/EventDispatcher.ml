open Ev;

exception Listener_not_found;

type lst 'eventType 'eventData 'target 'currentTarget = 
  {
    counter: mutable int;
    lstnrs: mutable list (int * (Ev.t 'eventType 'eventData -> ('target * 'currentTarget ) -> int -> unit));
  };


class base [ 'eventType,'eventData,'target,'currentTarget ] = (*{{{*)
  object
    value mutable listeners: list ('eventType * (lst 'eventType 'eventData 'target 'currentTarget)) = [];
    method addEventListener (eventType:'eventType) listener =
      let res = ref 0 in
      (
        listeners := 
          MList.update_assoc eventType begin fun 
            [ None -> {counter = 1; lstnrs = [ (0,listener) ]}
            | Some l ->
                (
                  l.lstnrs := [ (l.counter,listener) :: l.lstnrs ];
                  res.val := l.counter;
                  l.counter := l.counter + 1;
                  l
                )
            ]
          end listeners;
        !res;
      );

    method removeEventListener eventType listenerID = 
      try
        let l = List.assoc eventType listeners in
        (
          l.lstnrs := try MList.remove_assoc_exn listenerID l.lstnrs with [ Not_found -> raise Listener_not_found ];
          match l.lstnrs with
          [ [] -> listeners := List.remove_assoc eventType listeners 
          | _ -> ()
          ]
        )
      with [ Not_found  -> raise Listener_not_found ];

    method hasEventListeners eventType = List.mem_assoc eventType listeners;

  end;(*}}}*)



class virtual simple [ 'eventType , 'eventData , 'target ]  =
  object(self)
    inherit base ['eventType,'eventData,'target,'target];
    type 'event = Ev.t 'eventType 'eventData;

    method virtual private asEventTarget: 'target;

    (* всегда ставить таргет в себя и соответственно current_target *)
    method dispatchEvent (event:'event) = 
      let t = self#asEventTarget in 
      let evd = (t,t) in
      try
        let l = List.assoc event.Ev.etype listeners in
        ignore(List.for_all (fun (lid,l) -> (l event evd lid; event.Ev.propagation = `StopImmediate)) l.lstnrs);
      with [ Not_found -> () ];

  end;
