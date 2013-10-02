
type data = exn;

value events = Hashtbl.create 11;

value makeData (type s) () =
  let module M = struct exception E of s; end in
  ((fun x -> M.E x), (fun [ M.E x -> Some x | _ -> None]));

module NewData(P:sig type t;end) = struct
  exception E of P.t;
  value pack x = E x;
  value unpack = fun [ E x -> Some x | _ -> None];
end;

value ((data_of_bool:(bool -> data)),bool_of_data) = makeData ();
value ((data_of_int:(int -> data)),int_of_data) = makeData ();
value ((data_of_float:(float -> data)),float_of_data) = makeData ();
value ((data_of_string:(string -> data)),string_of_data) = makeData ();

type id = int;

type t =
  {
    evid: id;
    propagation:mutable [= `Propagate | `Stop | `StopImmediate ];
    bubbles:bool;
    data: data;
  };

value id = ref 0;
value gen_id name = let res = !id in (incr id; Hashtbl.add events res name; res);
value string_of_id ev = try Hashtbl.find events ev with [ Not_found -> "UKNOWN" ];


value stopImmediatePropagation event = event.propagation := `StopImmediate;
value stopPropagation event = 
  match event.propagation with
  [ `Propagate -> event.propagation := `Stop
  | _ -> ()
  ];

exception EmptyData;

value nodata = EmptyData;

value create evid ?(bubbles=False) ?(data=EmptyData) () = { evid; propagation = `Propagate; bubbles; data};
