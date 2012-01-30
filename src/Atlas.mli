

module type S = sig

  module D : DisplayObjectT.M;

  class c: [ Texture.c ] -> 
    object
      inherit D.c;
      method texture: Texture.c;
      method filters: list Filters.t;
      method setFilters: list Filters.t -> unit;
      method private render': ?alpha:float -> ~transform:bool -> option Rectangle.t -> unit;
      method boundsInSpace: !'space. option (<asDisplayObject: D.c; .. > as 'space) -> Rectangle.t;
      method addChild: ?index:int -> AtlasNode.t -> unit;
      method children: Enum.t AtlasNode.t;
      method clearChildren: unit -> unit;
      method getChildAt: int -> AtlasNode.t;
      method numChildren: int;
      method updateChild: int -> AtlasNode.t -> unit;
      method removeChild: int -> unit;
    end;


  value create: Texture.c -> c;

end;

module Make(D:DisplayObjectT.M) : S with module D = D;
