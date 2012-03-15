
type id;

type data;

value makeData: unit -> (('a -> data) * (data -> option 'a));


value data_of_bool: bool -> data;
value bool_of_data: data -> option bool;

value data_of_int:int -> data;
value int_of_data: data -> option int;

value data_of_float: float -> data;
value float_of_data: data -> option float;

value data_of_string: string -> data;
value string_of_data: data -> option string;

value nodata : data;

type t =
  {
    evid: id;
    propagation:mutable [= `Propagate | `Stop | `StopImmediate ];
    bubbles:bool;
    data: data;
  };

value gen_id: unit -> id;

value stopImmediatePropagation: t -> unit;
value stopPropagation: t -> unit;

value create: id -> ?bubbles:bool -> ?data:data -> unit -> t;
