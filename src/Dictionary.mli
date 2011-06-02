exception Selector_not_found;
exception Undefined;
type t;
type prop 'a;
value create : unit -> t;
value clear: t -> unit;
value create_selector: unit -> prop 'a;

value define: t -> 'a -> prop 'a; 
value set: t -> prop 'a -> 'a -> unit;
value unset: t -> prop 'a -> unit;
value get: t -> prop 'a -> option 'a;
value get_exn: t -> prop 'a -> 'a;
value (%):  t -> prop 'a -> 'a;
(* props *)

