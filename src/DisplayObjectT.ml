
type eventType = [= `ADDED | `ADDED_TO_STAGE | `REMOVED | `REMOVED_FROM_STAGE ]; 
type eventData = Event.dataEmpty;

module type M = sig

type hidden 'a;
type evType = private [> eventType ];
type evData = private [> eventData ];

class virtual _c [ 'parent ]:
  object('self)
    type 'parent = < asDisplayObject: _c _; removeChild': _c _ -> unit; dispatchEvent': !'ct. Event.t evType evData _ 'ct -> unit; name: string; .. >;
(*     inherit EventDispatcher.c [ 'event_type, 'event_data , _c _ _ _, _]; *)

    type 'displayObject = _c 'parent;
    type 'event = Event.t evType evData 'displayObject 'self;
    type 'listener = 'event -> unit;
    method addEventListener: evType -> 'listener -> int;
    method dispatchEvent: 'event -> unit;
    method dispatchEvent': !'ct. Event.t evType evData 'displayObject 'ct -> unit;
    method hasEventListeners: evType -> bool;

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
    method hitTestPoint: Point.t -> bool -> option (_c _ );
    method bounds: Rectangle.t;
    method transformationMatrix: Matrix.t;
    method transformationMatrixToSpace: option (_c _) -> Matrix.t;
    method virtual boundsInSpace: option (_c _) -> Rectangle.t;
    method globalToLocal: Point.t -> Point.t;
    method localToGlobal: Point.t -> Point.t;
    method setMask: Rectangle.t -> unit;
    method virtual private render': unit -> unit;
    method render: unit -> unit;
    method asDisplayObject: _c _;
    method virtual dcast: [= `Object of _c _ | `Container of 'parent ];
    method root: _c _;
    (* need to be hidden *)
    method clearParent: hidden unit -> unit;
    method isStage: bool;
    method setParent: hidden 'parent -> unit;
    method stage: option (_c _);
  end;


class virtual container:
  object
    inherit _c [ container ];
    type 'displayObject = _c container;

    method dcast: [= `Object of 'displayObject | `Container of container ];

    method asDisplayObjectContainer: container;
    method children: Enum.t 'displayObject;
    method addChild: !'child. ?index:int -> (#_c container as 'child) -> unit;
    method containsChild: !'child. (#_c container as 'child) -> bool;
    method getChildAt: int -> 'displayObject;
    method getLastChild: 'displayObject;
    method numChildren: int;
    method removeChild: !'child. (#_c container as 'child) -> unit;
    method removeChildAtIndex: int -> unit;
    (* need to be hidden *)
    method removeChild': 'displayObject -> unit;
    method containsChild': 'displayObject -> bool;
    method dispatchEventOnChildren: Event.t evType evData 'displayObject 'displayObject -> unit;
    method boundsInSpace: option 'displayObject -> Rectangle.t;
    method private render': unit -> unit;
  end;


class virtual c:
  object
    inherit _c  [ container ];
    method dcast: [= `Object of c | `Container of container ];
  end;
end;
