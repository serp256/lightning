
type rn_type = [= `RNBadge | `RNSound | `RNAlert ];


IFPLATFORM(pc)
value init ~rn_type ~sender_id ~success ~error = ();
ELSE
value convert_rn_types rntypes =
  List.fold_left begin fun mask -> fun 
    [ `RNBadge -> mask lor 1
    | `RNSound -> mask lor 2
    | `RNAlert -> mask lor 4
    ]
  end 0 rntypes;


external init: int -> string -> unit = "ml_rnInit";

value callbacks = ref None;

value init ~rn_type ~sender_id ~success ~error =
  match !callbacks with
  [ None ->
    (
      callbacks.val := Some (success,error);
      init (convert_rn_types rn_type) sender_id;
    )
  | Some _ -> callbacks.val := Some (success,error)
  ];


value on_success (regid:string) = 
  match !callbacks with
  [ Some (s,_) -> 
    (
      callbacks.val := None;
      ((s regid):unit);
    )
  | None -> assert False
  ];

value on_error (err:string) = 
  match !callbacks with
  [ Some (_,e) -> 
    (
      callbacks.val := None;
      ((e err):unit);
    )
  | None -> assert False
  ];

Callback.register "remote_notifications_success" on_success;
Callback.register "remote_notifications_error" on_error;
ENDPLATFORM;
