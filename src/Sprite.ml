
module Make(D:DisplayObjectT.M) = struct

  class c =
    object(self)
      inherit D.container; 
    end;

  value create () = new c;
end;

