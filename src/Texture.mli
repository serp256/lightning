
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


type event = [= `RESIZE | `CHANGE ]; 

type filter = [ FilterNearest | FilterLinear ];

type kind = [ Simple | Pallete of textureInfo ];

class type renderer = 
  object
    method onTextureEvent: event -> c -> unit;
  end
and c =
  object
    method kind: kind;
    method width: float;
    method height: float;
    method hasPremultipliedAlpha:bool;
(*     method scale: float; *)
    method textureID: textureID;
    method setFilter: filter -> unit;
    method base : option c;
    method clipping: option Rectangle.t;
    method rootClipping: option Rectangle.t;
(*     method update: string -> unit; *)
    method release: unit -> unit;
    method subTexture: Rectangle.t -> c;
    method addRenderer: renderer -> unit;
    method removeRenderer: renderer -> unit;
  end;


value zero: c;

value make : textureInfo -> c;

(* value create: textureFormat -> int -> int -> option (Bigarray.Array1.t int Bigarray.int8_unsigned_elt Bigarray.c_layout) -> c; *)
value load: string -> c;

class type rendered =
  object
    inherit c;
    method realWidth: int;
    method realHeight: int;
    method setPremultipliedAlpha: bool -> unit;
    method framebufferID: LightCommon.framebufferID;
    method resize: float -> float -> unit;
    method draw: (unit -> unit) -> unit;
    method clear: int -> float -> unit;
  end;

value glRGBA:int;
value glRGB:int;

value rendered: ?format:int -> ?color:int -> ?alpha:float -> float -> float -> rendered; (*object inherit c; method renderObject: !'a. (#renderObject as 'a) -> unit; end;*)



value load_async: string -> (c -> unit) -> unit;
value check_async: unit -> unit;


value loadExternal: string -> ~callback:(c -> unit) -> ~errorCallback:option (int -> string -> unit) -> unit;
