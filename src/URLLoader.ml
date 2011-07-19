


type http_method = [= `GET | `POST ];
type data = [= `Buffer of Buffer.t | `String of string | `URLVariables of list (string*string) ];

type request = 
  {
    httpMethod: mutable httpMethod;
    headers: mutable list (string*string);
    data: option data;
    url: string;
  };

value get_header name headers = 
  let name = String.lowercase name in
  try
    let hv = MList.find_map (fun (hn,hv) -> match String.lowercase hn = name with [ True -> Some hv | False -> None ]) headers in
    Some hv
  with [ Not_found -> None ];


value string_of_httpMethod = fun
  [ `GET -> "GET"
  | `POST -> "POST"
  ];

value request ?(httpMethod=`GET) ?(headers=[]) ?data url = { httpMethod; headers; data; url}

type eventType = [= `PROGRESS | `COMPLETE | `IO_ERROR ];
type eventData = `NetData of string;

type response = 
  {
    code: int;
    headers: list (string*string);
  };


exception Incorrect_request;

IFDEF IOS THEN
value loaders = Hashtbl.create 1;
type ns_connection;
type loader_wrapper = 
  {
    onResponse: unit -> unit;
    onData: unit -> unit;
    onComplete: unit -> unit;
    onError: unit -> unit
  };

external url_connection: string -> string -> list (string*string) -> option string -> ns_connection = "ml_UrlConnection";

value start_load wrappers r = 
  let (url,data) = 
    match r.httpMethod with
    [ `POST -> 
      let data = 
        let data = 
          match r.data with
          [ `Buffer b -> Buffer.contents b 
          | `String s -> s
          | `URLVariables vars -> 
              (
                match get_header "content-type" r.headers with
                [ None -> r.headers := [ ("content-type","application/x-www-form-urlencoded; charset=utf-8") :: r.headers ]
                | _ -> ()
                ];
                UrlEncoding.mk_url_encoded_parameters variables
              )
          ]
        in
        (r.url,Some data)
    | `GET -> 
        let url = 
          match r.data with
          [ None -> r.url
          | Some (`URLVariables variables) -> 
              let params = UrlEncoding.mk_url_encoded_parameters variables in
              match r.url.[String.length r.url - 1] with
              [ '&' -> r.url ^ params
              | _ -> r.url ^ '?' ^ params
              ]
          | _ -> raise Incorrect_request
          ]
        in
        (url,None)
    ]
  in
  let ns_connection = url_connection url (string_of_httpMethod r.httpMethod) r.headers data in
  Hashtbl.add loaders ns_connection wrappers;

ELSE

value start_load wrappers r = failwith "Net not implemented on this platform yet";

ENDIF;

type state = [ Init | Loading | Ended ];

class loader ?request () = 
  object
    inherit EventDispatcher.simple [eventType, eventData, loader];
    value mutable state = Init;
    method private asEventTarget = (self :> loader);

    value mutable code = 0;
    value mutable headers = []
    value mutable bytesTotal = None;
    value mutable bytesLoaded = 0;

    method private onResponse () = debug "on response";
    method private onData () = debug "on data";
    method private onComplete () = debug "on complete"
    method private onError () = debug "on error";

    method load r =
      let wrapper = 
        {
          onResponse = self#onResponse
          onData = self#onData
          onComplete = self#onComplete
          onError = self#onError
        }
      in
      (
        start_load wrapper r;
        state := Loading;
      );

    initializer
      match request with
      [ Some r -> self#load r
      | None -> ()
      ];

  end;
