
module type S = sig
  module D : DisplayObjectT.M;

  class c:
    object
      inherit D.container;
      method filters: list Filters.t;
      method setFilters: list Filters.t -> unit;
      method cacheAsImage: bool;
      method setCacheAsImage: bool -> unit;
    end;

  value create: unit -> c;

end;

module Make(D:DisplayObjectT.M)(Image:Image.S with module D = D): S with module D = D;
