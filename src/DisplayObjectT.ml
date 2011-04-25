
type eventType = [= `ADDED | `ADDED_TO_STAGE | `REMOVED | `REMOVED_FROM_STAGE ];

class type virtual base [ 'event_type, 'event_data, 'parent, 'super ] =
  object
    type 'event_type = [> eventType ];
    type 'parent = < asDisplayObject: base _ _ _ _; removeChild': base _ _ _ _ -> unit; .. >;
    inherit EventDispatcher.c [ 'event_type, 'event_data ];
    method name: string;
    method setName: string -> unit;
    method x: float;
    method setX: float -> unit;
    method y: float;
    method setY: float -> unit;
    method setPos: Point.t -> unit;
    method width: float;
    method setWidth: float -> unit;
    method height: float;
    method setHeight: float -> unit;
    method scaleX: float;
    method setScaleX: float -> unit;
    method scaleY: float;
    method setScaleY: float -> unit;
    method setScale: float -> unit;
    method alpha: float;
    method setAlpha: float -> unit;
    method rotation: float;
    method setRotation: float -> unit;
    method setAlpha: float -> unit;
    method visible: bool;
    method setVisible: bool -> unit;
    method touchable: bool;
    method setTouchable: bool -> unit;
    method parent: option 'parent;
    method removeFromParent: unit -> unit;
    method hitTestPoint: Point.t -> bool -> option (base _ _ _ _);
    method bounds: Rectangle.t;
    method transformationMatrix: Matrix.t;
    method transformationMatrixToSpace: option (base _ _ _ _) -> Matrix.t;
    method virtual boundsInSpace: option (base _ _ _ _) -> Rectangle.t;
    method globalToLocal: Point.t -> Point.t;
    method localToGlobal: Point.t -> Point.t;
    method virtual render: unit -> unit;
    method asDisplayObject: base _ _ _ _;
    method virtual supers: list 'super;
    method virtual dcast: [= `Object of base _ _ _ _ | `Container of 'parent ];
    method root: base _ _ _ _;
    (* need to be hidden *)
    method clearParent: unit -> unit;
    method isStage: bool;
    method setParent: 'parent -> unit;
    method stage: option (base _ _ _ _);
    (*
    *)
  end;


class type virtual container [ 'event_type, 'event_data, 'super ] = 
  object
    inherit base [ 'event_type, 'event_data, (container 'event_type 'event_data 'super), 'super];
    type 'displayObjectContainer = container 'event_type 'event_data 'super;
    type 'displayObject = base 'event_type 'event_data 'displayObjectContainer 'super;
    type 'super = [> `Object of 'displayObject | `Container of 'displayObjectContainer ];

    method asDisplayObjectContainer: 'displayObjectContainer;
    method children: Enum.t 'displayObject;
    method addChild: !'child. ?index:int -> (#base 'event_type 'event_data (container 'event_type 'event_data 'super) 'super as 'child) -> unit;
    method containsChild: !'child. (#base 'event_type 'event_data (container 'event_type 'event_data 'super) 'super as 'child) -> bool;
    method getChildAt: int -> 'displayObject;
    method getLastChild: 'displayObject;
    method numChildren: int;
    method removeChild: !'child. (#base 'event_type 'event_data (container 'event_type 'event_data 'super) 'super as 'child) -> unit;
    method removeChildAtIndex: int -> unit;
    method dispatchEventOnChildren: Event.t 'event_type 'event_data 'displayObject -> unit;
    method removeChild': 'displayObject -> unit;

   method containsChild': 'displayObject -> bool;

  end;
