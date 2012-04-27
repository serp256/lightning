
open LightCommon;

class _c: [ Texture.c ] -> 
  object
    inherit DisplayObject.c;
    method color: color;
    method setColor: color -> unit;
    method texture: Texture.c;
    method filters: list Filters.t;
    method setFilters: list Filters.t -> unit;
    method private render': ?alpha:float -> ~transform:bool -> option Rectangle.t -> unit;
    method boundsInSpace: !'space. option (<asDisplayObject: DisplayObject.c; .. > as 'space) -> Rectangle.t;
    method addChild: ?index:int -> AtlasNode.t -> unit;
    method children: Enum.t AtlasNode.t;
    method clearChildren: unit -> unit;
    method getChildAt: int -> AtlasNode.t;
    method numChildren: int;
    method updateChild: int -> AtlasNode.t -> unit;
    method removeChild: int -> unit;
    method setChildIndex: int -> int -> unit;
  end;

class c: [ Texture.c ] -> 
  object
    inherit _c;
    method ccast: [= `Atlas of c ];
  end;

value create: Texture.c -> c;
