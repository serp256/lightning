
IFDEF IOS THEN

external storage_path: unit -> string = "ml_storage_path";

ELSE IFDEF ANDROID THEN

value storage_path () = failwith "Not implemented";

ELSE

value storage_path () = "Home";

ENDIF;
ENDIF;

exception Error of string;
exception Record_not_found;

IFNDEF ANDROID THEN

type db = [ Closed | Opened of Dbm.t ];

value load dbname = 
  let path = (Filename.concat (storage_path ()) dbname) in
  let db =  try Dbm.opendbm path [ Dbm.Dbm_rdwr ; Dbm.Dbm_create ] 0o600 with [ Dbm.Dbm_error s -> raise (Error s) ] in
  object(self)
    value patch = path;
    value mutable db = Opened db;

    method private db = 
      match db with
      [ Opened db -> db
      | Closed -> 
          try 
            let db' = Dbm.opendbm path [ Dbm.Dbm_rdwr ; Dbm.Dbm_create ] 0o600 in
            (
              db := Opened db';
              db'
            )
          with [ Dbm.Dbm_error s -> raise (Error s) ]
      ];

    method get k = 
      try 
        Dbm.find self#db k 
      with [ Not_found -> raise Record_not_found ];

    method get_opt k = 
      try Some (Dbm.find self#db k) with [ Not_found -> None ];

    method set k v =
      try
        Dbm.replace self#db k v
      with [ Dbm.Dbm_error s -> raise (Error s) ];

    method remove k =
      try
        Dbm.remove self#db k
      with 
      [ Dbm.Dbm_error "dbm_delete" -> raise Not_found 
      | Dbm.Dbm_error s -> raise (Error s)
      ];

    method iter f = Dbm.iter f self#db;

    method save () = 
      match db with
      [ Closed -> ()
      | Opened db' ->
        try 
          Dbm.close db';
          db := Closed;
        with [ Dbm.Dbm_error s -> raise (Error s) ]
      ];

  end;

ELSE

value load (_:string) = failwith "not implemented";
(*
  object
    method get _ = failwith "not implemented";
    method get_opt _ = failwith "not implemented";
    method set _ _ = failwith "not implemented";
    method remove _ = failwith "not implemented"
  end;
*)

ENDIF;

