exception Selector_not_found;
type t;
type prop 'a;
value create : unit -> t;
value newProp: unit -> prop 'a;

value define: t -> 'a -> prop 'a; 
value call: t -> prop 'a -> 'a;
value (%):  t -> prop 'a -> 'a;

(* props *)
value newProp : unit -> prop 'a;
value setProp: t -> prop 'a -> 'a -> unit;
value getProp: t -> prop 'a -> option 'a;

