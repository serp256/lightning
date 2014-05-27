
open ExtList;
open LightCommon;

value ev_ADDED: Ev.id;
value ev_ADDED_TO_STAGE: Ev.id;
value ev_REMOVED: Ev.id;
value ev_REMOVED_FROM_STAGE: Ev.id;
value ev_ENTER_FRAME: Ev.id;


(* type hidden 'a; *)
exception Invalid_index of (int*int);
exception Child_not_found;

value dispatchEnterFrame: float -> unit;
value prerender: unit -> unit;

class virtual _c [ 'parent ] : 

  object('self)
    type 'displayObject = _c 'parent;
    type 'parent = 
      < 
        asDisplayObject: _c _; removeChild': _c _ -> unit; getChildIndex': _c _ -> int; z: option int; dispatchEvent': Ev.t -> _c _ -> unit; dispatchEventGlobal: Ev.t -> unit;
        name: string; transformationMatrixToSpace: !'space. option (<asDisplayObject: _c _; ..> as 'space) -> Matrix.t; stage: option 'parent; height: float; boundsChanged: unit -> unit;
        forceStageRender: ?reason:string -> unit -> unit;
        ..
      >;

    type 'listener = Ev.t -> ('displayObject * 'self) -> int -> unit;
    method addEventListener: Ev.id -> 'listener -> int;
    method removeEventListener: Ev.id -> int -> unit;
    method dispatchEvent': Ev.t -> _c _ -> unit;
    method dispatchEvent: Ev.t -> unit;
		method virtual dispatchEventGlobal: Ev.t -> unit;
    method hasEventListeners: Ev.id -> bool;


    method private defaultName: string;
    method name: string;
    method setName: string -> unit;
    value transformPoint: Point.t;
    method transformPointX: float;
    method setTransformPointX: float -> unit;
    method transformPointY: float;
    method setTransformPointY: float -> unit;
    method transformPoint: Point.t;
    method setTransformPoint: Point.t -> unit;
    method x: float;
    method setX: float -> unit;
    method y: float;
    method setY: float -> unit;
    value pos: Point.t;
    method pos: Point.t;
    method setPos: float -> float -> unit;
    method setPosPoint: Point.t -> unit;
    method width: float;
    method setWidth: float -> unit;
    method height: float;
    method setHeight: float -> unit;
    value scaleX:float;
    method scaleX: float;
    method setScaleX: float -> unit;
    value scaleY:float;
    method scaleY: float;
    method setScaleY: float -> unit;
    method setScale: float -> unit;
    method virtual color: color;
    method virtual setColor: color -> unit;
    value alpha:float;
    method alpha: float;
    method setAlpha: float -> unit;
    method rotation: float;
    method setRotation: float -> unit;
    value visible: bool;
    method visible: bool;
    method setVisible: bool -> unit;
    value touchable: bool;
    method touchable: bool;
    method setTouchable: bool -> unit;
    value parent: option 'parent;
    method parent: option 'parent;
    method z: option int;
    method removeFromParent: unit -> unit;
    method virtual filters: list Filters.t;
    method virtual setFilters: list Filters.t -> unit;
    method virtual private hitTestPoint': Point.t -> bool -> option (_c _);
    method hitTestPoint: Point.t -> bool -> option (_c _) ;
    method virtual bounds: Rectangle.t;
    method transformationMatrix: Matrix.t;
    method setTransformationMatrix: Matrix.t -> unit;
    method transformationMatrixToSpace: !'space. option (<asDisplayObject: 'displayObject; ..> as 'space) -> Matrix.t;
    method private maskInSpace: !'space. option (<asDisplayObject: 'displayObject; ..> as 'space) -> Rectangle.t;
    method private boundsWithMask': !'space. Rectangle.t -> option (<asDisplayObject: 'displayObject; ..> as 'space) -> bool -> Rectangle.t;
    method virtual boundsInSpace: !'space. ?withMask:bool -> option (<asDisplayObject: 'displayObject; ..> as 'space) -> Rectangle.t;
    method globalToLocal: Point.t -> Point.t;
    method localToGlobal: Point.t -> Point.t;
    method mask: option (bool * Rectangle.t);
    method resetMask: unit -> unit;
    method setMask: ?onSelf:bool -> Rectangle.t -> unit;
    method virtual private render': ?alpha:float -> ~transform:bool -> option Rectangle.t -> unit;
    method private addPrerender: (unit -> unit) -> unit;
    method prerender: bool -> unit;
    method render: ?alpha:float -> ?transform:bool -> option Rectangle.t -> unit;
    method asDisplayObject: _c _;
    method virtual dcast: [= `Object of _c _ | `Container of 'parent ];
    method root: _c _;    
    method bounds: Rectangle.t;
    method boundsChanged: unit -> unit; 

    (* need to be hidden *)
    method clearParent: (* hidden *) unit -> unit;
    method setParent: (* hidden *) 'parent -> unit;
		method classes: list exn;

    method virtual stageResized: unit -> unit;

    value mutable stage: option 'parent;
    method stage: option 'parent;
    method forceStageRender: ?reason:string -> unit -> unit;
  end;



class virtual container:
  object
    inherit _c [ container ];
    type 'displayObject = _c container;

    method dcast: [= `Object of 'displayObject | `Container of container ];

    method asDisplayObjectContainer: container;
		method dispatchEventGlobal: Ev.t -> unit;
    method children: Enum.t 'displayObject;
    method addChild: !'child. ?index:int -> (#_c container as 'child) -> unit;
    method containsChild: !'child. (#_c container as 'child) -> bool;
    method getChildAt: int -> 'displayObject;
    method setChildIndex: !'child. (#_c container as 'child) -> int -> unit;
    method getLastChild: 'displayObject;
    method getChildIndex': 'displayObject -> int; 
    method getChildIndex: !'child. (#_c container as 'child) -> int;
    method numChildren: int;
    method removeChild: !'child. (#_c container as 'child) -> unit;
    method removeChildAtIndex: int -> 'displayObject;
    method virtual cacheAsImage: bool;
    method virtual setCacheAsImage: bool -> unit;
    (* need to be hidden *)
    method removeChild': 'displayObject -> unit;
    method containsChild': 'displayObject -> bool;
    method clearChildren: unit -> unit;
(*     method dispatchEventOnChildren: Ev.t -> unit; *)
    method boundsInSpace: !'space. ?withMask:bool -> option (<asDisplayObject: 'displayObject; ..> as 'space) -> Rectangle.t;
    method private render': ?alpha:float -> ~transform:bool -> option Rectangle.t -> unit;
    method private hitTestPoint': Point.t -> bool -> option ('displayObject);
		method classes: list exn;
    method stageResized: unit -> unit;
  end;


class virtual c:
  object
    inherit _c  [ container ];
    method dcast: [= `Object of c | `Container of container ];
    method private hitTestPoint': Point.t -> bool -> option ('displayObject);
	method dispatchEventGlobal: Ev.t -> unit;
    method stageResized: unit -> unit;
  end;
