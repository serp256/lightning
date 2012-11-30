
type point = 
  {
    x:float;
    y:float;
    color:int;
    alpha:float;
  };


type draw_method = [= `Line | `Line_loop | `Triangles | `Triangle_strip | `Triangle_fan ];

type shape_data;
external ml_shape_create: array point -> draw_method -> shape_data = "ml_shape_create";
external ml_shape_draw: shape_data -> unit = "ml_shape_draw";

class c ?(draw_method=`Line) points =
  object(self)
    inherit DisplayObject.c;
    value gl_data  = ml_shape_create points draw_method;

    method private render' _ = ml_shape_draw gl_data;

    (*
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
    *)

(*     method private render' _ = Graphics.render graphics; *)

  end;


value create = new c;

