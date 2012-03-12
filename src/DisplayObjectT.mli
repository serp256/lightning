
type eventType = [= `ADDED | `ADDED_TO_STAGE | `REMOVED | `REMOVED_FROM_STAGE | `ENTER_FRAME ]; 
type eventData = [= Ev.dataEmpty | `PassedTime of float ];

module type S = sig

type hidden 'a;
type evType = private [> eventType ];
type evData = private [> eventData ];

exception Invalid_index;
exception Child_not_found;

value dispatchEnterFrame: float -> unit;
value prerender: unit -> unit;
class virtual _c [ 'parent ] : (*  _c' [evType,evData,'parent];  =  *)

  object('self)
    type 'displayObject = _c 'parent;
    type 'parent = 
      < 
        asDisplayObject: _c _; removeChild': _c _ -> unit; getChildIndex': _c _ -> int; z: option int; dispatchEvent': Ev.t evType evData -> _c _ -> unit; 
        name: string; transformationMatrixToSpace: !'space. option (<asDisplayObject: _c _; ..> as 'space) -> Matrix.t; stage: option 'parent; height: float; boundsChanged: unit -> unit; .. >;
(*     inherit EventDispatcher.c [ 'event_type, 'event_data , _c _ _ _, _]; *)

    type 'event = Ev.t evType evData;
    type 'listener = 'event -> ('displayObject * 'self) -> int -> unit;
    method addEventListener: evType -> 'listener -> int;
    method removeEventListener: evType -> int -> unit;
    method dispatchEvent': 'event -> _c _ -> unit;
    method dispatchEvent: 'event -> unit;
    method hasEventListeners: evType -> bool;

    value name: string;
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
    value alpha:float;
    method alpha: float;
    method setAlpha: float -> unit;
    method rotation: float;
    method setRotation: float -> unit;
    method setAlpha: float -> unit;
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
    method private hitTestPoint': Point.t -> bool -> option (_c _);
    method hitTestPoint: Point.t -> bool -> option (_c _) ;
    method virtual bounds: Rectangle.t;
    method transformationMatrix: Matrix.t;
    method setTransformationMatrix: Matrix.t -> unit;
    method transformationMatrixToSpace: !'space. option (<asDisplayObject: 'displayObject; ..> as 'space) -> Matrix.t;
    method virtual boundsInSpace: !'space. option (<asDisplayObject: 'displayObject; ..> as 'space) -> Rectangle.t;
    method globalToLocal: Point.t -> Point.t;
    method localToGlobal: Point.t -> Point.t;
    method setMask: ?onSelf:bool -> Rectangle.t -> unit;
    method virtual private render': ?alpha:float -> ~transform:bool -> option Rectangle.t -> unit;
    method private addPrerender: (unit -> unit) -> unit;
    method prerender: bool -> unit;
    method render: ?alpha:float -> ?transform:bool -> option Rectangle.t -> unit;
    method asDisplayObject: _c _;
    method virtual dcast: [= `Object of _c _ | `Container of 'parent ];
    method root: _c _;
    method stage: option 'parent;
    method boundsChanged: unit -> unit; 

    (* need to be hidden *)
    method clearParent: hidden unit -> unit;
    method setParent: hidden 'parent -> unit;
  end;



class virtual container:
  object
    inherit _c [ container ];
    type 'displayObject = _c container;

    method dcast: [= `Object of 'displayObject | `Container of container ];

    method bounds: Rectangle.t;
    method asDisplayObjectContainer: container;
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
    method dispatchEventOnChildren: Ev.t evType evData -> unit;
    method boundsInSpace: !'space. option (<asDisplayObject: 'displayObject; ..> as 'space) -> Rectangle.t;
    method private render': ?alpha:float -> ~transform:bool -> option Rectangle.t -> unit;
    method private hitTestPoint': Point.t -> bool -> option ('displayObject);
  end;


class virtual c:
  object
    inherit _c  [ container ];
    method dcast: [= `Object of c | `Container of container ];
    method bounds: Rectangle.t;
  end;
end;
