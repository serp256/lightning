
module Make(D:DisplayObjectT.M) = struct
  module D = D;


  type node = 
    { 
      rect: Rectangle.t;
      flipX: mutable bool;
      flipY: mutable bool;
      scaleX: mutable float;
      scaleY: mutable float;
    };

  class c _texture =
    object
      inherit D.c as super;

      (* ну вообще не принципиально нихуя чайлды это просто ректы нахуй *)

    end;

end;
