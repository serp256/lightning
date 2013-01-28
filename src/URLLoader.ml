


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
    let hv = MList.find_map_raise (fun (hn,hv) -> match String.lowercase hn = name with [ True -> Some hv | False -> None ]) headers in
    Some hv
  with [ Not_found -> None ];


value string_of_httpMethod = fun
  [ `GET -> "GET"
  | `POST -> "POST"
  ];

value request ?(httpMethod=`GET) ?(headers=[]) ?data url = { httpMethod; headers; data; url};

value ev_PROGRESS = Ev.gen_id "PROGRESS";
value ev_COMPLETE =  Ev.gen_id "COMPLETE";
value ev_IO_ERROR = Ev.gen_id "IO_ERORR";

value (data_of_ioerror,ioerror_of_data) = Ev.makeData();


exception Incorrect_request;

value prepare_request r = 
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
  ];

type loader_wrapper = 
  {
    onResponse: int -> int64 -> string -> unit;
    onData: string -> unit;
    onComplete: unit -> unit;
    onError: int -> string -> unit
  };


type connection;
value loaders = Hashtbl.create 1;

external url_connection: string -> http_method -> list (string*string) -> option string -> connection = "ml_URLConnection";

value get_loader ns_connection = 
  try
    Hashtbl.find loaders ns_connection
  with [ Not_found -> failwith("HTTPConneciton not found") ];

value url_response connection httpCode contentLength contentType =
  let () = debug "url response" in
  let w = get_loader connection in
  w.onResponse httpCode contentLength contentType;

Callback.register "url_response" url_response;

value url_data connection data = 
  let () = debug "url data" in
  let w = get_loader connection in
  w.onData data;

Callback.register "url_data" url_data;

value url_complete connection = 
  let () = debug "url complete" in
  let w = get_loader connection in
  (
    Hashtbl.remove loaders connection;
    w.onComplete ();
  );

Callback.register "url_complete" url_complete;

value url_failed connection code msg = 
  let () = debug "url failed" in
  let w = get_loader connection in
  (
    Hashtbl.remove loaders connection;
    w.onError code msg;
  );

Callback.register "url_failed" url_failed;

value start_load wrappers r = 
  let (url,data) = prepare_request r in
  let () = debug "HEADERS: [%s]" (String.concat ";" (List.map (fun (n,v) -> n ^ ":" ^ v) r.headers)) in
  let ns_connection = url_connection url r.httpMethod r.headers data in
  (
    Hashtbl.add loaders ns_connection wrappers;
    ns_connection;
  );



external cancel_ns_connection: connection -> unit = "ml_URLConnection_cancel";
value cancel_load connection =
(
  cancel_ns_connection connection;
  Hashtbl.remove loaders connection;
);

(*}}}
IFDEF ANDROID THEN

type connection;
value loaders = Hashtbl.create 1;

external url_connection: string -> string -> list (string*string) -> option string -> connection = "ml_android_connection";

value get_loader ns_connection = 
  try
    Hashtbl.find loaders ns_connection
  with [ Not_found -> failwith("HTTPConneciton not found") ];

value url_response ns_connection httpCode contentType totalBytes =
  let () = debug "url response" in
  let w = get_loader ns_connection in
  w.onResponse httpCode contentType totalBytes;

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
  let (url,data) = prepare_request r in
  let ns_connection = url_connection url (string_of_httpMethod r.httpMethod) r.headers data in
  (
    Hashtbl.add loaders ns_connection wrappers;
    ns_connection;
  );

(* external cancel_ns_connection: connection -> unit = "ml_URLConnection_cancel"; *)
value cancel_load connection =
(
(*   cancel_ns_connection connection; *)
  Hashtbl.remove loaders connection;
);


(*}}}*)

ELSE
IFDEF SDL THEN (*{{{*)

type connection = int;
value curl_initialized = ref False;

module type CurlLoader = sig
  value push_request: loader_wrapper -> request -> int;
  value cancel_request: int -> unit;
  value check_response: unit -> unit;
end;

module CurlLoader(P:sig end) = struct

  match !curl_initialized with
  [ False -> (Curl.global_init Curl.CURLINIT_GLOBALNOTHING; curl_initialized.val := True)
  | True -> ()
  ];

  value condition = Condition.create ();

  value requests_queue = ThreadSafeQueue.create ();

  value waiting_loaders = Hashtbl.create 1;
  value request_id = ref 0;
  value push_request loader request = 
    (
      incr request_id;
      Hashtbl.add waiting_loaders !request_id loader;
      let (url,data) = prepare_request request in
      ThreadSafeQueue.enqueue requests_queue (!request_id,url,request.httpMethod,request.headers,data);
      Condition.signal condition;
      !request_id;
    );

  value cancel_request reqid = Hashtbl.remove waiting_loaders reqid;

  value response_queue = ThreadSafeQueue.create ();

  value rec check_response () = 
    match ThreadSafeQueue.dequeue response_queue with
    [ Some (request_id,result) ->
      (
        let loader = try Some (Hashtbl.find waiting_loaders request_id) with [
          Not_found -> None ] in
        match loader with
        [ Some loader ->
          match result with
          [ `Result (code,contentType,contentLength,data) ->
            (
              loader.onResponse code contentType contentLength;
              loader.onData data;
              loader.onComplete ();
            )
          | `Failure code errmsg -> loader.onError code errmsg
          ]
        | None -> ()
        ];
        check_response ();
      )
    | None -> ()
    ];

  value mutex = Mutex.create ();
  value run () = 
    let () = Mutex.lock mutex in
    let buffer = Buffer.create 1024 in
    let dataf = (fun str -> (Buffer.add_string buffer str; String.length str)) in
    loop () where
      rec loop () = 
        let () = debug "try check requests" in
        match ThreadSafeQueue.dequeue requests_queue with
        [ Some (request_id,url,hmth,headers,body) ->
          (
            let () = debug "new curl request on url: %s" url in
            let ccon = Curl.init () in
            try
              Curl.set_url ccon url;
              match headers with
              [ [] -> ()
              | _ -> 
                  let headers = List.map (fun (n,v) -> Printf.sprintf "%s:%s" n v) headers in
                  Curl.set_httpheader ccon headers
              ];
              match hmth with
              [ `POST -> Curl.set_post ccon True
              | _ -> ()
              ];
              match body with
              [ Some b -> 
                (
                  Curl.set_postfields ccon b;
                  Curl.set_postfieldsize ccon (String.length b);
                )
              | None -> ()
              ];
              Curl.set_writefunction ccon dataf;
              Curl.perform ccon;
              debug "curl performed";
              let httpCode = Curl.get_httpcode ccon
              and contentType = Curl.get_contenttype ccon
              and contentLength = Int64.of_float (Curl.get_contentlengthdownload ccon)
              in
              ThreadSafeQueue.enqueue response_queue (request_id,`Result (httpCode,contentType,contentLength,Buffer.contents buffer));
              Buffer.clear buffer;
              Curl.cleanup ccon;
            with [ Curl.CurlException _ code str -> ThreadSafeQueue.enqueue response_queue (request_id,(`Failure code str))];
            loop ()
          )
        | None ->
          (
            Condition.wait condition mutex;
            loop ()
          )
        ];
  value thread = Thread.create run ();

end;


value curl_loader = ref None;
value process_events () =
  match !curl_loader with
  [ Some m ->
    let module Loader = (value m:CurlLoader) in
    Loader.check_response ()
  | None -> ()
  ];

value start_load wrapper r = 
  let m =
    match !curl_loader with
    [ Some m -> m
    | None -> 
        let module Loader = CurlLoader (struct end) in
        let m = (module Loader:CurlLoader) in
        (
          curl_loader.val := Some m;
          m
        )
        
    ]
  in
  let module Loader = (value m:CurlLoader) in
  Loader.push_request wrapper r;

value cancel_load req = 
  let m = 
    match !curl_loader with
    [ Some m -> m
    | None -> assert False
    ]
  in
  let module Loader = (value m:CurlLoader) in
  Loader.cancel_request req;

ENDIF;
ENDIF;
ENDIF;
}}}*)

IFDEF PC THEN
external run: unit -> unit = "net_run";
ENDIF;

exception Loading_in_progress;

type state = [= `Loading | `Complete ];
type istate = [ Loading of connection | Complete ];

class loader ?request () = 
  object(self)
    inherit EventDispatcher.simple [loader];
    value mutable state = Complete;
    method state : state = match state with [ Complete -> `Complete | Loading _ -> `Loading ];
    method private asEventTarget = (self :> loader);

    value mutable httpCode = 0;
    method httpCode = httpCode;
    value mutable contentType = "";
    method contentType = contentType;
    value mutable bytesTotal = 0L;
    method bytesTotal = bytesTotal;
    value mutable bytesLoaded = 0L;
    method bytesLoaded = bytesLoaded;
    value data = Buffer.create 10;
    method data = Buffer.contents data;

    method private onResponse c b ct =  
    (
      debug "onResponse: %d:%Ld:%s" c b ct;
      httpCode := c; 
      bytesTotal := b;
      contentType := ct;
      bytesLoaded := 0L;
    );

    method private onData d = 
      let () = debug "onData" in
      let bytes = String.length d in
      (
        bytesLoaded := Int64.add bytesLoaded (Int64.of_int bytes);
        Buffer.add_string data d;
        let event = Ev.create ev_PROGRESS ~data:(Ev.data_of_int bytes) () in
        self#dispatchEvent event;
      );

    method private onError code msg = 
    (
      debug "onError";
      state := Complete;
      let event = Ev.create ev_IO_ERROR ~data:(data_of_ioerror (code,msg)) ()  in
      self#dispatchEvent event
    );

    method private onComplete () = 
    (
      debug "on complete";
      state := Complete;
      let event = Ev.create ev_COMPLETE () in
      self#dispatchEvent event
    );

    method load r =
      match state with
      [ Complete ->
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
          contentType := "";
          bytesTotal := 0L;
          bytesLoaded := 0L;
          Buffer.clear data;
          state := Loading (start_load wrapper r);
        )
      | Loading _ -> raise Loading_in_progress
      ];

    method cancel () =
      match state with
      [ Loading conn -> 
        (
          cancel_load conn;
          state := Complete;
        )
      | _ -> ()
      ];

    initializer
      match request with
      [ Some r -> self#load r
      | None -> ()
      ];

  end;



IFDEF ANDROID THEN
external download: ~url:string -> ~path:string -> ?ecallback:(int -> string -> unit) -> (unit -> unit) -> unit = "ml_DownloadFile";
ELSE
value downlaod (url:sring) (path:string) ?(ecallback:(int -> string -> unit))  (callback:(unit -> unit))  = assert False;
END;
