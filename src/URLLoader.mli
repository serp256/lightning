
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
type state = [ Init | Loading | Complete ];

type eventType = [= `PROGRESS | `COMPLETE | `IO_ERROR ];
type eventData = [= Ev.dataEmpty | `HTTPBytes of int | `IOError of (int * string)];

IFDEF SDL THEN
value process_events: unit -> unit;
ENDIF;

class loader: [ ?request:request] -> [ unit ] ->
  object
    inherit EventDispatcher.simple [eventType, eventData, loader];
    method private asEventTarget: loader;
    method state: state;
    method httpCode: int;
    method contentType: string;
    method bytesTotal: Int64.t;
    method bytesLoaded: Int64.t;
    method data: string;
    method load: request -> unit;
  end;
