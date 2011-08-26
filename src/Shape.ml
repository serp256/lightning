


module Make(D:DisplayObjectT.M) = struct


  class c =
    object
      inherit D.c;

      value graphics = Graphics.create ();
      method graphics = graphics;

      method boundsInSpace: !'space. (option (<asDisplayObject: D.c; .. > as 'space)) -> Rectangle.t = fun _ -> Rectangle.empty (); (*       let () = Printf.printf "bounds in space %s\n" name in *)

      method private render' _ = Graphics.render graphics;

    end;


  value create () = new c;

end;




