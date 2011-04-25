open Event;


class virtual c [ 'event_type , 'event_data , 'target ] =
  object(self:'self)
    type 'target = #c 'event_type 'event_data _;
    type 'event = Event.t 'event_type 'event_data 'target 'self;
    type 'listener = 'event -> unit;
    value listeners: Hashtbl.t 'event_type 'listener = Hashtbl.create 0;
    method private virtual upcast: 'target;
    method addEventListener eventType listener = Hashtbl.add listeners eventType listener;

    (* не трогает target *)
    method virtual private bubbleEvent: 'event -> unit;
    method dispatchEvent' event =
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
              let event = {(event) with currentTarget = Some self } in
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
            match event.bubbles && not event.stopPropagation with
            [ True -> self#bubbleEvent event
            | False -> ()
            ]
          )
      ];
  

    (* всегда ставить таргет в себя и соответственно current_target *)
    method dispatchEvent (event:'event) = 
      let event = {(event) with target = Some self#upcast} in
      self#dispatchEvent' event;

    method hasEventListeners eventType = Hashtbl.mem listeners eventType;

  end;

