
module type S = sig
  module D : DisplayObjectT.M;

  class c:
    object
      inherit D.container;
    end;

  value create: unit -> c;

end;

module Make(D:DisplayObjectT.M) = struct

  module D = D;
  class c =
    object(self)
      inherit D.container; 
    end;

  value create () = new c;
end;

