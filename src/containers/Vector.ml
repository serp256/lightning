value (<|) f v = f v;
value (|>) v f = f v;

type t 'a = 
  {
    data : mutable DynArray.t 'a;
    name : string;
  };

exception RangeError; 
exception Empty_vector;
exception Invalid_index of string ;


value count = ref 0;

value getName name = 
  match name with
  [ Some name -> name 
  | _ -> 
      (
        incr count;
        "Vector" ^ (string_of_int !count)
      )
  ];

value create ?name ?(initVals=[]) () =
  (
    let name = getName name in
    {data=DynArray.of_list initVals; name}
  );

value length vect = DynArray.length vect.data;

value clear vect = 
  DynArray.clear vect.data;

value push vect v = 
  DynArray.add vect.data v;

value push_ls vect values =
  List.iter (push vect) values;

value append v1 v2 =
	DynArray.append v1.data v2.data;

value shift vect = 
  match DynArray.empty vect.data with
  [ True -> failwith "Can't shift empty vector" 
  | False -> 
      let res = DynArray.get vect.data 0 in
        (
          DynArray.delete vect.data 0;
          res;
        )
  ];

value swap vect index1 index2 =
	let temp = DynArray.get vect.data index1 in 
		(
			DynArray.set vect.data index1 (DynArray.get vect.data index2);
			DynArray.set vect.data index2 temp;
		);

value insert vect index v =
  DynArray.insert vect.data index v;

value unshift vect v = 
  DynArray.insert vect.data 0 v; 

value iter f vect =
  DynArray.iter f vect.data;
  
value iteri f vect =
  DynArray.iteri f vect.data;

value mem v vect  = 
  try
    (
      ignore(DynArray.index_of (fun data -> data = v) vect.data);
      True
    )
  with
    [ Not_found -> False ];
 
value first vect = 
  match DynArray.empty vect.data with
  [ True -> failwith "Vector must be not empty"
  | _ -> DynArray.get vect.data 0
  ];
  
value last vect =
  match DynArray.empty vect.data with
  [ True -> failwith "Vector must be not empty"
  | _ -> DynArray.last vect.data
  ];

value to_list vect =
  DynArray.to_list vect.data;

value of_list ?name ls = 
  let name = getName name in
  {data = DynArray.of_list ls; name};

value find f vect = 
  DynArray.index_of f vect.data |> DynArray.get vect.data;

value find_map f vect = 
  let index = DynArray.index_of (fun item -> f item <> None) vect.data in
  match f (DynArray.get vect.data index) with
  [ Some res -> res 
  | _ -> assert False
  ];

value exists f vect  = 
  try
    (
      ignore(DynArray.index_of f vect.data);
      True
    )
  with
    [ Not_found -> False ];

value findi f vect  = 
  let res = ref None in 
  try
    (
      DynArray.iteri begin fun i data ->
        match f i data with
        [ True -> 
            (
              res.val := Some (i,data);
              raise Exit
            )
        | _ -> ()
        ]
      end vect.data;
      raise Not_found
    )
  with
    [ Exit -> OPTGET !res ];

value remove_if f vect  = 
  try
    DynArray.index_of f vect.data |> DynArray.delete vect.data; 
  with
    [ Not_found -> () ];

value remove vect v =
  try
    DynArray.index_of (fun data -> data = v)  vect.data |> DynArray.delete vect.data; 
  with
    [ Not_found -> () ];

value slice vect = 
  {data = DynArray.copy vect.data; name = vect.name ^ "_copy"}; 

value filter f vect  = 
  DynArray.filter f vect.data;
  
value get vect index =
  match DynArray.length vect.data with
  [ 0 -> raise Empty_vector
  | len -> if 0 <= index && index < len then DynArray.get vect.data index  else raise (Invalid_index (Printf.sprintf "name:%s;index:%d;len:%d;" vect.name index len))
  ];
  
value set vect index v =
  match DynArray.length vect.data with
  [ 0 -> raise Empty_vector
  | len -> if 0 <= index && index <= len then DynArray.set vect.data index v else raise (Invalid_index (Printf.sprintf "name:%s;index:%d;len:%d;" vect.name index len))
  ];

value indexOf vect search  =
  try
    Some (DynArray.index_of (fun data -> data = search) vect.data)
  with
    [ Not_found -> None ];
  
value indexOfFunc (vect:t 'a) (f:('a -> bool)) =
  try
    Some (DynArray.index_of f vect.data)
  with
    [ Not_found -> None ];
  
value deleteLast vect =
  DynArray.delete_last vect.data;
  
value fold_left (fn:'a -> 'b -> 'a) (res:'a) (vect:t 'b) :'a =
  DynArray.fold_left fn res vect.data ;
  
value fold_right fn vect res =
  DynArray.fold_right fn vect.data res; 
  
value filter_map ?name fn vect  =
  let name = 
    match name with
    [ Some name -> name
    | _ -> vect.name 
    ]
  in
  let data = DynArray.create () in
    (
      DynArray.iter begin fun v -> 
        match fn v with
        [ Some v -> DynArray.add data v
        | _ -> ()
        ]
      end vect.data;
      {data; name};
    );

value map ?name fn vect  =
  let name = 
    match name with
    [ Some name -> name
    | _ -> vect.name 
    ]
  in
  {data= DynArray.map fn vect.data; name}; 

value pop vect = 
  match DynArray.empty vect.data with
  [ True -> raise Empty_vector
  | _ ->
      let res = DynArray.last vect.data in
        (
          DynArray.delete_last vect.data;
          res;
        )
  ];
  
value sort f vect =
  vect.data := DynArray.to_list vect.data |>  List.fast_sort f |> DynArray.of_list;
