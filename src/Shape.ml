open LightCommon;

(* type point = 
  {
    x:float;
    y:float;
    color:int;
    alpha:float;
  };
value point0 = {x=0.;y=0.;color=0;alpha=0.}; *)
type point =
  {
    x: float;
    y: float;
  };

value point0 = {x=0.;y=0.};
value point x y = { x; y };

type draw_method = [= `Points | `Lines | `Line_loop | `Line_strip | `Triangles | `Triangle_strip | `Triangle_fan ];
value int_of_draw_method = fun
  [ `Points -> 0
  | `Lines -> 1
  | `Line_loop -> 2
  | `Line_strip -> 3
  | `Triangles -> 4
  | `Triangle_strip -> 5
  | `Triangle_fan -> 6
  ];

type layer =
  {
    drawMethod: int;
    color: int;
    alpha: float;
    lineWidth: float;
  };

value layer ?(drawMethod = `Points) ?(color = 0xffffff) ?(alpha = 1.) ?(lineWidth = 1.) () = { drawMethod = int_of_draw_method drawMethod; color; alpha; lineWidth };

type shape_data;
external ml_shape_create: array point -> list layer -> shape_data = "ml_shape_create";
external ml_shape_render: Matrix.t -> Render.prg -> ?alpha:float -> shape_data -> unit = "ml_shape_render";
external ml_shape_set_points: shape_data -> array point -> unit = "ml_shape_set_points";

class c ?(layers = [ layer () ]) ?bounds points =
  let bounds = 
    match bounds with
    [ Some b -> b
    | None -> 
      (* найти самые крайние точки *)
      let ar = [| max_float; ~-.max_float; max_float; ~-.max_float |] in
      (
        for i = 0 to Array.length points - 1 do
          let p = points.(i) in
          (
            if ar.(0) > p.x then ar.(0) := p.x else ();
            if ar.(1) < p.x then ar.(1) := p.x else ();
            if ar.(2) > p.y then ar.(2) := p.y else ();
            if ar.(3) < p.y then ar.(3) := p.y else ();
          )
        done;
        Rectangle.create ar.(0) ar.(2) (ar.(1) -. ar.(0)) (ar.(3) -. ar.(2));
      )
    ]
  in
  object(self)
    inherit DisplayObject.c;
    value shaderProgram = GLPrograms.Shape.create ();
    value gl_data  = ml_shape_create points layers;

    value bounds = bounds;

    (* TODO: filters *)
    method filters = [];
    method setFilters _ = assert False;

    (* TODO: colors *)
    method color = `NoColor;
    method setColor _ = assert False;

    method boundsInSpace: !'space. (option (<asDisplayObject: DisplayObject.c; .. > as 'space)) -> Rectangle.t = fun targetCoordinateSpace ->  
      match targetCoordinateSpace with
      [ Some ts when ts#asDisplayObject = self#asDisplayObject -> bounds
      | _ -> 
        let transformationMatrix = self#transformationMatrixToSpace targetCoordinateSpace in
        Matrix.transformRectangle transformationMatrix bounds
      ];

    method private render' ?alpha ~transform _ =
      let alpha =
        match alpha with
        [ Some palpha -> palpha *. self#alpha
        | _ -> self#alpha
        ]
      in
        ml_shape_render (if transform then self#transformationMatrix else Matrix.identity) shaderProgram ~alpha gl_data;

    method setPoints points = ml_shape_set_points gl_data points;
  end;


value create = new c;

value circle color alpha radius =
  let segs = 360 in
  let offset = radius in
  let verticies = Array.make (segs + 1) point0 in
  (
    let coef = two_pi /. (float segs) in
    for i = 0 to segs do
      let rads = (float i) *. coef in
      let j = radius *. (cos rads) +. offset
      and k = radius *. (sin rads) +. offset
      in
      verticies.(i) := {x=j;y=k}
    done;
    let diametr = radius *. 2. in
    new c ~layers:[ layer ~drawMethod:`Triangle_fan ~alpha ~color () ] ~bounds:(Rectangle.create 0. 0. diametr diametr) verticies;
  );

