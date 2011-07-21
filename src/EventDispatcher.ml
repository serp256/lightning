open Ev;

exception Listener_not_found;

type listener 'eventType 'eventData 'target 'currentTarget = Ev.t 'eventType 'eventData 'target 'currentTarget -> unit;
type listeners 'eventType 'eventData 'target 'currentTarget = list (int * (listener 'eventType 'eventData 'target 'currentTarget));
type lst 'eventType 'eventData 'target 'currentTarget = 
  {
    counter: mutable int;
(*     lstnrs: mutable list (int * (listener 'eventType 'eventData 'target 'currentTarget)); *)
    lstnrs: mutable list (int * (Ev.t 'eventType 'eventData 'target 'currentTarget -> int -> unit));
  };

value fire event lst = 
  try
    let l = List.assoc event.Ev.etype lst in
    ignore(List.for_all (fun (lid,l) -> (l event lid; event.Ev.propagation = `StopImmediate)) l.lstnrs);
    True
  with [ Not_found -> False ];


class base [ 'eventType,'eventData,'target,'currentTarget ] = (*{{{*)
  object
    value mutable listeners: list ('eventType * (lst 'eventType 'eventData 'target 'currentTarget)) = [];
(*     type 'listener = Event.t 'eventType 'eventData 'target 'currentTarget -> unit; *)
    method addEventListener (eventType:'eventType) listener =
      let res = ref 0 in
      (
        listeners := 
          MList.update_assoc eventType begin fun 
            [ None -> {counter = 1; lstnrs = [ (0,listener) ]}
            | Some l ->
                (
                  l.lstnrs := [ (l.counter,listener) :: l.lstnrs ];
                  l.counter := l.counter + 1;
                  res.val := l.counter;
                  l
                )
            ]
          end listeners;
        !res;
      );

    (*
    method private fireEvent event =
      try
        let l = List.assoc event.Event.etype listeners in
        let event = {(event) with Event.currentTarget = Some currentTarget } in
        ignore(List.for_all (fun (_,l) -> (l event; event.Event.propagation = `StopImmediate)) l.lstnrs);
        True
      with [ Not_found -> False ];
    *)

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


(*
class type virtual c [ 'eventType,'eventData,'target,'currentTarget ] = 
  object
    type 'event = Event.t 'eventType 'eventData 'target 'currentTarget;
    type 'target = #c 'eventType 'eventData 'target 'currentTarget;
    type 'listener = 'event -> unit;
    method virtual private asEventTarget: 'target;
    method addEventListener: 'eventType -> 'listener -> unit;
    method dispatchEvent: 'event -> unit;
    method removeEventListener: 'eventType -> int -> unit;
    method hasEventListeners: 'eventType -> bool;
  end;
*)


class virtual simple [ 'eventType , 'eventData , 'target ]  =
  object(self)
    inherit base ['eventType,'eventData,'target,'target];
    type 'event = Ev.t 'eventType 'eventData 'target 'target;

(*     method private dispatchEvent' event = fire event listeners; *)
  
    method virtual private asEventTarget: 'target;

    (* всегда ставить таргет в себя и соответственно current_target *)
    method dispatchEvent (event:'event) = 
      let t = self#asEventTarget in 
      let event = {(event) with target = Some t; currentTarget = Some t } in
      try
        let l = List.assoc event.Ev.etype listeners in
        ignore(List.for_all (fun (lid,l) -> (l event lid; event.Ev.propagation = `StopImmediate)) l.lstnrs);
      with [ Not_found -> () ];

  end;


(*
class virtual simple [ 'eventType , 'eventData , 'target ] =
  object(self:'self)
    inherit base ['eventType,'eventData,'target,'target];
    type 'event = Event.t 'event_type 'event_data 'target 'target;
    type 'listener = 'event -> unit;
    value listeners: Listeners.t 'eventType 'eventData 'target 'target = Listeners.empty ();
    method addEventListener eventType listener = Listeners.add eventType listener listeners;

    (* не трогает target *)
    method virtual private asEventTarget: 'target;
    method private dispatchEvent' event = Listeners.fire event self listeners;
      (*
      match Listeners.get listeners event.etype with
      [ None -> ()
      | Some listeners ->
          let event = {(event) with currentTarget = Some self#asEventTarget} in
          Listeners.fire event listeners
(*
            match event.bubbles && not event.stopPropagation with
            [ True -> self#bubbleEvent event
            | False -> ()
            ]
*)
      ];
      *)
  

    (* всегда ставить таргет в себя и соответственно current_target *)
    method dispatchEvent (event:'event) = 
      let t = self#asEventTarget in 
      let event = {(event) with target = Some t; currentTarget = Some t } in
      Listeners.fire event self listeners;

(*     method hasEventListeners eventType = Hashtbl.mem listeners eventType; *)
    method hasEventListeners eventType = Listeners.has eventType listeners;

  end;
*)
