
type dataEmpty = [= `Empty ];

type t 'etype 'data 'target 'current_target =
  {
    etype:'etype ;
    stopImmediatePropagation:mutable bool;
    stopPropagation:mutable bool; 
    bubbles:bool;
(*     eventPhase: [= `AT_TARGET | `BUBBLING_PHASE ]; *)
    target: option 'target;
    currentTarget: option 'current_target;
    data:'data;
  } constraint 'eype = [> ] constraint 'data = [> dataEmpty ] constraint 'target = < .. > constraint 'current_target = < .. >;

value create etype ?(bubbles=False) ?(data=`Empty) () = 
  { 
    etype; stopImmediatePropagation = False; stopPropagation = False; bubbles; data;
    target = None; currentTarget = None
  };
