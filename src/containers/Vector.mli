type t 'a ;

exception RangeError; 
exception Empty_vector;
exception Invalid_index of string;

value create: ?name:string -> ?initVals:list 'a -> unit -> t 'a; 

value length: t 'a -> int;
value clear : t 'a -> unit;
value push : t 'a -> 'a -> unit;
value push_ls: t 'a -> list 'a -> unit;
value append : t 'a -> t 'a -> unit;

value shift : t 'a -> 'a;
value unshift : t 'a -> 'a -> unit;

value iter : ('a -> unit) -> t 'a -> unit;
value iteri : (int -> 'a -> unit) -> t 'a -> unit;
value mem : 'a -> t 'a -> bool;
value first: t 'a  -> 'a;
value last: t 'a  -> 'a;
value to_list: t 'a -> list 'a;
value of_list : ?name:string -> list 'a -> t 'a;
value find : ('a -> bool) -> t 'a -> 'a;
value find_map : ('a -> option 'b) -> t 'a -> 'b;
value exists : ('a -> bool) -> t 'a -> bool;
value findi : (int -> 'a -> bool) -> t 'a -> (int * 'a);
value remove_if : ('a -> bool) -> t 'a -> unit;
value remove : t 'a -> 'a -> unit;  
value slice : t 'a -> t 'a;
value filter : ('a -> bool) -> t 'a -> unit;
value filter_map : ?name:string -> ('a -> option 'b) -> t 'a -> t 'b;
value get : t 'a -> int -> 'a;
value set : t 'a -> int -> 'a -> unit;
value indexOf: t 'a -> 'a -> option int;
value indexOfFunc: t 'a -> ('a -> bool) -> option int;
value deleteLast : t 'a -> unit;
value fold_left : ('b -> 'a -> 'b) -> 'b -> t 'a -> 'b;  
value fold_right :('a -> 'b -> 'b) -> t 'a -> 'b -> 'b;  
value map : ?name:string -> ('a -> 'b) -> t 'a -> t 'b;
value pop : t 'a -> 'a;
value sort: ('a -> 'a -> int) -> t 'a -> unit; 
value swap: t 'a -> int -> int -> unit; 
value insert: t 'a -> int -> 'a -> unit;
value delete : t 'a -> int -> unit;
value pop_if : ('a -> bool) -> t 'a -> 'a;
