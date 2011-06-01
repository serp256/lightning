exception Selector_not_found;
type t;
type prop 'a;
value create : unit -> t;
value newProp: unit -> prop 'a;

value define: t -> 'a -> prop 'a; 
value set: t -> prop 'a -> 'a -> unit;
value get: t -> prop 'a -> option 'a;
value get_exn: t -> prop 'a -> 'a;
value (%):  t -> prop 'a -> 'a;

(* props *)

