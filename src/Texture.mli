
open LightCommon;

type textureInfo;

(*
type textureFormat = 
  [ TextureFormatRGBA
  | TextureFormatRGB
  | TextureFormatAlpha
  | TextureFormatPvrtcRGB2
  | TextureFormatPvrtcRGBA2
  | TextureFormatPvrtcRGB4
  | TextureFormatPvrtcRGBA4
  | TextureFormat565
  | TextureFormat5551
  | TextureFormat4444
  ];
*)
exception Cant_load_texture of string;



type event = [= `RESIZE | `CHANGE ]; 

type filter = [ FilterNearest | FilterLinear ];
value setDefaultFilter: filter -> unit;

type kind = [ Simple of bool | Alpha | Pallete of textureInfo ];

value scale: ref float;

value int32_of_textureID: textureID -> int32;

type renderInfo =
  {
    rtextureID: textureID;
    rwidth: float;
    rheight: float;
    clipping: option Rectangle.t;
    kind: kind;
  };

class type renderer = 
  object
    method onTextureEvent: event -> c -> unit;
  end
and c =
  object
    method kind: kind;
    method renderInfo: renderInfo;
    method width: float;
    method height: float;
    method hasPremultipliedAlpha:bool;
    method scale: float;
(*     method scale: float; *)
    method textureID: textureID;
    method setFilter: filter -> unit;
    method base : option c;
    method clipping: option Rectangle.t;
    method rootClipping: option Rectangle.t;
(*     method update: string -> unit; *)
    method released: bool;
    method release: unit -> unit;
    method subTexture: Rectangle.t -> c;
    method addRenderer: renderer -> unit;
    method removeRenderer: renderer -> unit;
  end;


value zero: c;

value make : textureInfo -> c;

(* value create: textureFormat -> int -> int -> option (Bigarray.Array1.t int Bigarray.int8_unsigned_elt Bigarray.c_layout) -> c; *)
value load: ?with_suffix:bool -> ?filter:filter -> ?use_pvr:bool -> string -> c;


(*
type renderbuffer;

class type rendered = 
  object
    inherit c;
    method renderbuffer: renderbuffer;
    method activate: unit -> unit;
    method resize: float -> float -> unit;
    method draw: (unit -> unit) -> unit;
    method clear: int -> float -> unit;
    method deactivate: unit -> unit;
    method clone: unit -> rendered;
  end;

value defaultFilter:filter;
value glRGBA:int;
value glRGB:int;

value rendered: ?format:int -> ?filter:filter -> float -> float -> rendered; 
*)

value load_async: ?with_suffix:bool -> ?filter:filter -> ?use_pvr:bool -> string -> ?ecallback:(string -> unit) -> (c -> unit) -> unit;
value check_async: unit -> unit;
value loadExternal: string -> ~callback:(c -> unit) -> ~errorCallback:option (int -> string -> unit) -> unit;
