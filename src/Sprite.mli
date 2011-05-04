
module Make(D:DisplayObjectT.M): sig

  class c:
    object
      inherit D.container;
    end;

  value create: unit -> c;
end;
