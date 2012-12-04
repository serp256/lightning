open LightCommon;

exception Texture_not_found of string;
type t;
value load: string -> t;
value loadxml: string -> t;
value texture: t -> int -> Texture.c;

value description: t -> string -> (int * Rectangle.t * (int * int));
value subTexture: t -> string -> Texture.c;
value atlasNode: t -> string -> ?pos:Point.t -> ?scaleX:float -> ?scaleY:float -> ?color:color -> ?flipX:bool -> ?flipY:bool -> ?alpha:float -> unit -> AtlasNode.t;

value subTexturePos: t -> string -> (int * int);
value loadRegionsByPrefix: t -> string -> list (string * Texture.c * (int * int));
