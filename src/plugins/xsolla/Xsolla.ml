
IFPLATFORM(android)
  external _purchase: ~sandbox: bool -> ~suc_cal:(unit -> unit) ->  ~err_cal:(string -> unit) -> ~redirectUrl:string -> string -> unit = "ml_xsolla_purchase";
  value purchase ?(sandbox=False) ~suc_cal ~err_cal ~redirectUrl token = _purchase ~sandbox ~suc_cal ~err_cal ~redirectUrl token;
ELSE
  value purchase ?sandbox ~suc_cal ~err_cal ~redirectUrl _ = ();
ENDPLATFORM;
