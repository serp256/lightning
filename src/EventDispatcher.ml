open Ev;

exception Listener_not_found of (Ev.id * string * int);

type lst 'target 'currentTarget = 
  {
    counter: mutable int;
    lstnrs: mutable list (int * (Ev.t -> ('target * 'currentTarget ) -> int -> unit));
  };


class base [ 'target,'currentTarget ] = (*{{{*)
  object
    value mutable listeners: list (Ev.id * (lst 'target 'currentTarget)) = [];
    method addEventListener eventType listener =
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
          l.lstnrs := try MList.remove_assoc_exn listenerID l.lstnrs with [ Not_found -> raise (Listener_not_found (eventType,Ev.string_of_id eventType, listenerID)) ];
          match l.lstnrs with
          [ [] -> listeners := List.remove_assoc eventType listeners 
          | _ -> ()
          ]
        )
      with [ Not_found  -> raise (Listener_not_found (eventType,Ev.string_of_id eventType, listenerID)) ];

    method hasEventListeners eventType = List.mem_assoc eventType listeners;

  end;(*}}}*)


class virtual simple [ 'target ]  =
  object(self)
    inherit base [ 'target,'target];

    method virtual private asEventTarget: 'target;

    (* всегда ставить таргет в себя и соответственно current_target *)
    method dispatchEvent event = 
      let t = self#asEventTarget in 
      let evd = (t,t) in
      match try Some (List.assoc event.Ev.evid listeners) with [ Not_found -> None ] with
      [ Some l -> ignore(List.for_all (fun (lid,l) -> (l event evd lid; event.Ev.propagation = `StopImmediate)) l.lstnrs)
      | None -> ()
      ];

  end;
