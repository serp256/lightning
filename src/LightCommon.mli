value (|>): 'a -> ('a -> 'b) -> 'b;
value (<|): ('a -> 'b) -> 'a -> 'b;
value color_white: int;
value color_black: int;


type qColor = 
  {
    qcTopLeft: int;
    qcTopRight: int;
    qcBottomLeft: int;
    qcBottomRight: int;
  };

value qColor: ~topLeft:int -> ~topRight:int -> ~bottomLeft:int ->
  ~bottomRight:int -> qColor;

type color = [= `NoColor | `Color of int | `QColors of qColor ];



exception File_not_exists of string;

type textureID; 
type framebufferID = int;

value powOfTwo: int -> int;
value nextPowerOfTwo: int -> int;

value pi:float;
value half_pi: float;
value two_pi:float;
value clamp_rotation: float -> float;

value resources_suffix: unit -> option string;
value set_resources_suffix: string -> unit;

value path_with_suffix: string -> string;
(* value resource_path: ?with_suffix:bool -> string -> string; *)
value open_resource: ?with_suffix:bool -> string -> in_channel;
value read_resource: ?with_suffix:bool -> string -> string;
value read_json: ?with_suffix:bool -> string -> Ojson.json;

type deviceType = [ Phone | Pad ];
value deviceType: unit -> deviceType;

type ios_device = [ IPhoneOld | IPhone3GS | IPhone4 | IPhone5 | IPhoneNew | IPad1 | IPad2 | IPad3 | IPadNew | IUnknown ];
type androidScreen = [ UnknownScreen | Small | Normal | Large | Xlarge ];
type androidDensity = [ UnknownDensity | Ldpi | Mdpi | Hdpi | Xhdpi | Tvdpi ];
type device = [ Android of (androidScreen * androidDensity) | IOS of ios_device ];
value device: unit -> device;

(* value androidScreen: unit -> option (androidScreen * androidDensity); *)
value androidScreenToString: androidScreen -> string;
value androidDensityToString: androidDensity -> string;

IFDEF PC THEN
value internalDeviceType: ref deviceType;
ENDIF;

value getLocale: unit -> string;
value getVersion: unit -> string;

IFDEF PC THEN
value storagePath: unit -> string; 
ELSE
external storagePath: unit -> string = "ml_getStoragePath";
ENDIF;

module MakeXmlParser(P:sig value path: string; value with_suffix:bool; end): sig
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
