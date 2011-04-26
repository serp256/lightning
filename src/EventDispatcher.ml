open Event;

class type c [ 'event_type,'event_data,'target,'currentTarget ] = 
  object
    type 'event = Event.t 'event_type 'event_data 'target 'currentTarget;
    type 'listener = 'event -> unit;
    method addEventListener: 'event_type -> 'listener -> unit;
    method dispatchEvent: 'event -> unit;
    method hasEventListeners: 'event_type -> bool;
  end;


class virtual simple [ 'event_type , 'event_data , 'target ] =
  object(self:'self)
    type 'target = #simple 'event_type 'event_data _;
    type 'event = Event.t 'event_type 'event_data 'target 'target;
    type 'listener = 'event -> unit;
    value listeners: Hashtbl.t 'event_type 'listener = Hashtbl.create 0;
    method addEventListener eventType listener = Hashtbl.add listeners eventType listener;

    (* не трогает target *)
    method virtual private asEventTarget: 'target;
    method private dispatchEvent' event =
      let listeners = 
        try
          let listeners = Hashtbl.find_all listeners event.etype in
          Some listeners
        with [ Not_found -> None ]
      in
      match (event.bubbles,listeners) with
      [ (False,None) -> ()
      | (_,lstnrs) -> 
          (
            match lstnrs with
            [ Some listeners -> 
              let event = {(event) with currentTarget = Some self#asEventTarget} in
              ignore(
                List.for_all begin fun l ->
                  (
                    l event;
                    event.stopImmediatePropagation;
                  )
                end listeners 
              )
            | None -> ()
            ];
(*
            match event.bubbles && not event.stopPropagation with
            [ True -> self#bubbleEvent event
            | False -> ()
            ]
*)
          )
      ];
  

    (* всегда ставить таргет в себя и соответственно current_target *)
    method dispatchEvent (event:'event) = 
      let event = {(event) with target = Some self#asEventTarget} in
      self#dispatchEvent' event;

    method hasEventListeners eventType = Hashtbl.mem listeners eventType;

  end;
