
module type S = sig
  module D : DisplayObjectT.M;

  class c:
    object
      inherit D.container;
    end;

  value create: unit -> c;

end;

module Make(D:DisplayObjectT.M): S with module D = D;
