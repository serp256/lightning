


type http_method = [= `GET | `POST ];
type data = [= `Buffer of Buffer.t | `String of string | `URLVariables of list (string*string) ];

type request = 
  {
    httpMethod: mutable http_method;
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

value request ?(httpMethod=`GET) ?(headers=[]) ?data url = { httpMethod; headers; data; url};

type eventType = [= `PROGRESS | `COMPLETE | `IO_ERROR ];
type eventData = [= Event.dataEmpty | `HTTPBytes of int | `IOError of (int * string)];


exception Incorrect_request;

IFDEF IOS THEN
type ns_connection;
type loader_wrapper = 
  {
    onResponse: int -> int64 -> list (string*string) -> unit;
    onData: string -> unit;
    onComplete: unit -> unit;
    onError: int -> string -> unit
  };
value loaders = Hashtbl.create 1;

external url_connection: string -> string -> list (string*string) -> option string -> ns_connection = "ml_URLConnection";

value get_loader ns_connection = 
  try
    Hashtbl.find loaders ns_connection
  with [ Not_found -> failwith("HTTPConneciton not found") ];

value url_response ns_connection httpCode totalBytes headers =
  let () = debug "url response" in
  let w = get_loader ns_connection in
  w.onResponse httpCode totalBytes headers;

Callback.register "url_response" url_response;

value url_data ns_connection data = 
  let () = debug "url data" in
  let w = get_loader ns_connection in
  w.onData data;

Callback.register "url_data" url_data;

value url_complete ns_connection = 
  let () = debug "url complete" in
  let w = get_loader ns_connection in
  (
    Hashtbl.remove loaders ns_connection;
    w.onComplete ();
  );

Callback.register "url_complete" url_complete;

value url_failed ns_connection code msg = 
  let () = debug "url failed" in
  let w = get_loader ns_connection in
  (
    Hashtbl.remove loaders ns_connection;
    w.onError code msg;
  );

Callback.register "url_failed" url_failed;

value start_load wrappers r = 
  let (url,data) = 
    match r.httpMethod with
    [ `POST -> 
        let data = 
          match r.data with
          [ Some d ->
            let data = 
              match d with
              [ `Buffer b -> Buffer.contents b 
              | `String s -> s
              | `URLVariables vars -> 
                (
                  match get_header "content-type" r.headers with
                  [ None -> r.headers := [ ("content-type","application/x-www-form-urlencoded; charset=utf-8") :: r.headers ]
                  | _ -> ()
                  ];
                  UrlEncoding.mk_url_encoded_parameters vars
                )
              ]
            in
            Some data
          | None -> None
          ]
        in
        (r.url,data)
    | `GET -> 
        let url = 
          match r.data with
          [ None -> r.url
          | Some (`URLVariables variables) -> 
              let params = UrlEncoding.mk_url_encoded_parameters variables in
              match r.url.[String.length r.url - 1] with
              [ '&' -> r.url ^ params
              | _ -> r.url ^ "?" ^ params
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

type state = [ Init | Loading | Complete ];

class loader ?request () = 
  object(self)
    inherit EventDispatcher.simple [eventType, eventData, loader];
    value mutable state = Init;
    method private asEventTarget = (self :> loader);

    value mutable httpCode = 0;
    method httpCode = httpCode;
    value mutable httpHeaders = [];
    method httpHeaders = httpHeaders;
    value mutable bytesTotal = 0L;
    method bytesTotal = bytesTotal;
    value mutable bytesLoaded = 0L;
    method bytesLoaded = bytesLoaded;
    value data = Buffer.create 10;
    method data = Buffer.contents data;

    method private onResponse c b h = 
    (
      debug "onResponse";
      httpCode := c; 
      bytesTotal := b;
      bytesLoaded := 0L;
      httpHeaders := h;
    );

    method private onData d = 
      let () = debug "onData" in
      let bytes = String.length d in
      (
        bytesLoaded := Int64.add bytesLoaded (Int64.of_int bytes);
        Buffer.add_string data d;
        let event = Event.create `PROGRESS ~data:(`HTTPBytes bytes) () in
        self#dispatchEvent event;
      );

    method private onError code msg = 
    (
      debug "onError";
      state := Complete;
      let event = Event.create `IO_ERROR ~data:(`IOError (code,msg)) ()  in
      self#dispatchEvent event
    );

    method onComplete () = 
    (
      debug "on complete";
      state := Complete;
      let event = Event.create `COMPLETE () in
      self#dispatchEvent event
    );

    method load r =
      let wrapper = 
        {
          onResponse = self#onResponse;
          onData = self#onData;
          onComplete = self#onComplete;
          onError = self#onError
        }
      in
      (
        httpCode := 0;
        httpHeaders := [];
        bytesTotal := 0L;
        bytesLoaded := 0L;
        Buffer.clear data;
        start_load wrapper r;
        state := Loading;
      );

    initializer
      match request with
      [ Some r -> self#load r
      | None -> ()
      ];

  end;
