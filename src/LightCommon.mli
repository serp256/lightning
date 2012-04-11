value (|>): 'a -> ('a -> 'b) -> 'b;
value (<|): ('a -> 'b) -> 'a -> 'b;
value color_white: int;
value color_black: int;
type textureID; 
type framebufferID = int;

value powOfTwo: int -> int;
value nextPowerOfTwo: int -> int;

value pi:float;
value half_pi: float;
value two_pi:float;

value resource_path: string -> string;
value open_resource: string -> float -> in_channel;
value read_resource: string -> float -> string;
value read_json: string -> Ojson.t;

type remoteNotification = [= `RNBadge | `RNSound | `RNAlert ];

value request_remote_notifications: list remoteNotification ->  (string -> unit) -> (string -> unit) -> unit;

module MakeXmlParser(P:sig value path: string; end): sig
  value close: unit -> unit;
  value error: Pervasives.format4 'a unit string 'b -> 'a;
  value accept: Xmlm.signal -> unit;
  value next: unit -> Xmlm.signal;
  value floats: string -> float;
  value ints: string -> int;
  value get_attribute: string -> list Xmlm.attribute -> option string;
  value get_attributes: string -> list string -> list Xmlm.attribute -> list string;
  value parse_element: string -> list string -> option (list string * list Xmlm.attribute);
end;
