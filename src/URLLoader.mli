
type http_method = [= `GET | `POST ];
type data = [= `Buffer of Buffer.t | `String of string | `URLVariables of list (string*string) ];
type request = 
  {
    httpMethod: mutable http_method;
    headers: mutable list (string*string);
    data: option data;
    url: string;
  };
value get_header: string -> list (string*string) -> option string;
value request: ?httpMethod:http_method -> ?headers:list (string*string) -> ?data:data -> string -> request;
type state = [= `Loading | `Complete ];

value ev_PROGRESS: Ev.id; 
value ev_COMPLETE: Ev.id;
value ev_IO_ERROR: Ev.id;

value ioerror_of_data: Ev.data -> option (int * string);

IFDEF PC THEN
external run: unit -> unit = "net_run";
ENDIF;

class loader: [ ?request:request] -> [ unit ] ->
  object
    inherit EventDispatcher.simple [loader];
    method private asEventTarget: loader;
    method state: state;
    method httpCode: int;
    method contentType: string;
    method bytesTotal: Int64.t;
    method bytesLoaded: Int64.t;
    method data: string;
    method load: request -> unit;
    method cancel: unit -> unit;
  end;


IFDEF ANDROID THEN
external download: ~url:string -> ~path:string -> ?ecallback:(int -> string -> unit) -> (unit -> unit) -> unit = "ml_DownloadFile";
ELSE
value download: ~url:string -> ~path:string -> ?ecallback:(int -> string -> unit) -> (unit -> unit)  -> unit;
END;
