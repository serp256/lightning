
type t;
value create: 
  Texture.c ->  Rectangle.t -> ?name:string -> ?pos:Point.t -> ?scaleX:float -> ?scaleY:float -> 
    ?rotation:float -> ?flipX:bool -> ?flipY:bool -> ?color:LightCommon.color ->  ?alpha:float -> unit -> t;


value pos: t -> Point.t;
value x: t -> float;
value y: t -> float;
value width: t -> float;
value height: t -> float;

value setX: float -> t -> t;
value setY: float -> t -> t;
value setPos: float -> float -> t -> t;
value setPosPoint: Point.t -> t -> t;

value flipX: t -> bool;
value setFlipX: bool -> t -> t;

value flipY: t -> bool;
value setFlipY: bool -> t -> t;

value color: t -> LightCommon.color;
value setColor: LightCommon.color -> t -> t;

value alpha: t -> float;
value setAlpha: float -> t -> t;

value name: t -> option string;
value setName: option string -> t -> t;

value update: ?pos:Point.t -> ?scale:float -> ?rotation:float -> ?flipX:bool -> ?flipY:bool -> ?color:LightCommon.color ->  ?alpha:float -> t -> t;

value texture: t -> Texture.c;

value matrix: t -> Matrix.t;

value sync: t -> unit;
value bounds: t -> Rectangle.t;
