


module Make(D:DisplayObjectT.M) = struct


  class c =
    object(self)
      inherit D.c;

      value graphics = Graphics.create ();
      method graphics = graphics;

      method boundsInSpace: !'space. (option (<asDisplayObject: D.c; .. > as 'space)) -> Rectangle.t = fun targetCoordinateSpace ->
        match Graphics.bounds graphics with
        [ None -> Rectangle.empty
        | Some bounds -> 
          match targetCoordinateSpace with
          [ Some ts when ts#asDisplayObject = self#asDisplayObject -> bounds
          | _ ->
            let transformationMatrix = self#transformationMatrixToSpace targetCoordinateSpace in
            Matrix.transformRectangle transformationMatrix bounds
          ]
        ];

      method private render' _ = Graphics.render graphics;

    end;


  value create () = new c;

end;
