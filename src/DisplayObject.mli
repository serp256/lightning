

type eventType = [= `ADDED | `ADDED_TO_STAGE | `REMOVED | `REMOVED_FROM_STAGE ];

type hidden 'a;

class virtual _c [ 'event_type, 'event_data, 'parent ] : 
  object('self)
    type 'event_type = [> eventType ];
    type 'parent = < asDisplayObject: _c _ _ _; removeChild': _c _ _ _ -> unit; dispatchEvent': Event.t 'event_type 'event_data _ _ -> unit; name: string; .. >;
(*     inherit EventDispatcher.c [ 'event_type, 'event_data , _c _ _ _, _]; *)

    type 'displayObject = _c 'event_type 'event_data 'parent;
    type 'event = Event.t 'event_type 'event_data 'displayObject 'self;
    type 'listener = 'event -> unit;
    method addEventListener: 'event_type -> 'listener -> unit;
    method dispatchEvent: 'event -> unit;
    method dispatchEvent': 'event -> unit;
    method hasEventListeners: 'event_type -> bool;

    value name: string;
    method name: string;
    method setName: string -> unit;
    value x:float;
    method x: float;
    method setX: float -> unit;
    value y:float;
    method y: float;
    method setY: float -> unit;
    method setPos: Point.t -> unit;
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
    method removeFromParent: unit -> unit;
    method hitTestPoint: Point.t -> bool -> option (_c _ _ _ );
    method bounds: Rectangle.t;
    method transformationMatrix: Matrix.t;
    method transformationMatrixToSpace: option (_c _ _ _) -> Matrix.t;
    method virtual boundsInSpace: option (_c _ _ _) -> Rectangle.t;
    method globalToLocal: Point.t -> Point.t;
    method localToGlobal: Point.t -> Point.t;
    method virtual render: unit -> unit;
    method asDisplayObject: _c _ _ _;
    method virtual dcast: [= `Object of _c _ _ _ | `Container of 'parent ];
    method root: _c _ _ _;
    (* need to be hidden *)
    method clearParent: hidden unit -> unit;
    method isStage: bool;
    method setParent: hidden 'parent -> unit;
    method stage: option (_c _ _ _);
  end;


class virtual container [ 'event_type, 'event_data ]:
  object
    inherit _c [ 'event_type, 'event_data, (container 'event_type 'event_data)];
    type 'displayObjectContainer = container 'event_type 'event_data;
    type 'displayObject = _c 'event_type 'event_data 'displayObjectContainer;

    method dcast: [= `Object of 'displayObject | `Container of 'displayObjectContainer ];

    method asDisplayObjectContainer: 'displayObjectContainer;
    method children: Enum.t 'displayObject;
    method addChild: !'child. ?index:int -> (#_c 'event_type 'event_data (container 'event_type 'event_data) as 'child) -> unit;
    method containsChild: !'child. (#_c 'event_type 'event_data (container 'event_type 'event_data) as 'child) -> bool;
    method getChildAt: int -> 'displayObject;
    method getLastChild: 'displayObject;
    method numChildren: int;
    method removeChild: !'child. (#_c 'event_type 'event_data (container 'event_type 'event_data) as 'child) -> unit;
    method removeChildAtIndex: int -> unit;
    (* need to be hidden *)
    method removeChild': 'displayObject -> unit;
    method containsChild': 'displayObject -> bool;
    method dispatchEventOnChildren: Event.t 'event_type 'event_data 'displayObject 'displayObject -> unit;
    method boundsInSpace: option 'displayObject -> Rectangle.t;
    method render: unit -> unit;
  end;


class virtual c [ 'event_type, 'event_data ]:
  object
    inherit _c  [ 'event_type, 'event_data, (container 'event_type 'event_data) ];
    method dcast: [= `Object of c _ _ | `Container of container _ _ ];
  end;

