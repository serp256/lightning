
type dataEmpty = [= `Empty ];

type t 'etype 'data 'target 'currentTarget =
  {
    etype:'etype ;
    propagation:mutable [= `Propagate | `Stop | `StopImmediate ];
    bubbles:bool;
(*     eventPhase: [= `AT_TARGET | `BUBBLING_PHASE ]; *)
    target: option 'target;
    currentTarget: option 'currentTarget;
    data:'data;
  } constraint 'etype = [> ] constraint 'data = [> dataEmpty ] constraint 'target = < .. > constraint 'currentTarget = < .. >;



value stopImmediatePropagation event = event.propagation := `StopImmediate;
value stopPropagaion event = 
  match event.propagation with
  [ `Propagate -> event.propagation := `Stop
  | _ -> ()
  ];

value create etype ?(bubbles=False) ?(data=`Empty) () = { etype; propagation = `Propagate; bubbles; data; target = None; currentTarget = None };
