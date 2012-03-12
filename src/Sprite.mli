
module type S = sig
  module D : DisplayObjectT.S;

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

module Make(Image:Image.S): S with module D = Image.D;
