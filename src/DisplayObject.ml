open LightCommon;

type eventType = [= `ADDED | `ADDED_TO_STAGE | `REMOVED | `REMOVED_FROM_STAGE | `ENTER_FRAME ]; 
type eventData = [= Ev.dataEmpty | `PassedTime of float ];

module type Param = sig
  type evType = private [> eventType ];
  type evData = private [> eventData ];
end;

module Make(P:Param) = struct

type hidden 'a = 'a;
type evType = P.evType;
type evData = P.evData;

exception Invalid_index;
exception Child_not_found;

(* приходит массив точек, к ним применяется трасформация и в результате получаем min и максимальные координаты *)


DEFINE RENDER_WITH_MASK(call_render) = (*{{{*)
  match self#stage with
  [ Some stage ->
    let matrix = 
      match onSelf with
      [ True -> self#transformationMatrixToSpace None
      | False -> 
          match parent with
          [ Some parent -> parent#transformationMatrixToSpace None
          | None -> assert False 
          ]
      ]
    in
    match Matrix.transformPoints matrix maskPoints with
    [ [| minX; maxX; minY; maxY |] ->
      let sheight = stage#height in
      (
        let minY = sheight -. maxY
        and maxY = sheight -. minY in
        (
(*           glEnable gl_scissor_test; *)
(*           glScissor (int_of_float minX) (int_of_float minY) (int_of_float (maxX -. minX)) (int_of_float (maxY -. minY)); *)
          call_render;
(*           glDisable gl_scissor_test; *)
        )
      )
    | _ -> assert False
    ]
  | None -> failwith "render without stage"
  ];(*}}}*)

class type dispObj = 
  object
    method dispatchEvent: Ev.t P.evType P.evData -> unit;
    method name: string;
  end;

module SetD = Set.Make (struct type t = dispObj; value compare d1 d2 = compare d1 d2; end);

value onEnterFrameObjects = ref SetD.empty;

value dispatchEnterFrame seconds = 
  let enterFrameEvent = Ev.create `ENTER_FRAME ~data:(`PassedTime seconds) () in
  SetD.iter (fun obj -> let () = debug:enter_frame "dispatch enter frame on: %s" obj#name in obj#dispatchEvent enterFrameEvent) !onEnterFrameObjects;

DEFINE RESET_TRANSFORMATION_MATRIX = match transformationMatrix with [ Some _ -> transformationMatrix := None | _ -> () ];
DEFINE RESET_BOUNDS_CACHE =
(
    match boundsCache with
    [ Some _ -> boundsCache := None
    | None -> ()
    ];
    match parent with
    [ Some p -> p#boundsChanged ()
    | None -> ()
    ];
);

DEFINE RESET_CACHE(what) = (debug "%s changed [%s]" self#name what; RESET_TRANSFORMATION_MATRIX; RESET_BOUNDS_CACHE);

class virtual _c [ 'parent ] = (*{{{*)

  object(self:'self)
    type 'displayObject = _c 'parent;
    inherit EventDispatcher.base [ P.evType,P.evData,'displayObject,'self] as super;

    type 'parent = 
      < 
        asDisplayObject: _c _; removeChild': _c _ -> unit; dispatchEvent': Ev.t P.evType P.evData -> _c _ -> unit;
        name: string; transformationMatrixToSpace: !'space. option (<asDisplayObject: _c _; ..> as 'space) -> Matrix.t; stage: option 'parent; boundsChanged: unit -> unit; .. 
      >;

(*     value intcache = Dictionary.create (); *)

    value mutable name = "";
    method name = if name = ""  then Printf.sprintf "instance%d" (Oo.id self) else name;
    method setName n = name := n;

    value mutable pos  = {Point.x = 0.; y =0.};
    value mutable transformPoint = {Point.x=0.;y=0.};
    value mutable scaleX = 1.0;
    value mutable scaleY = 1.0;
    value mutable rotation = 0.0;
    value mutable transformationMatrix = None;
    value mutable boundsCache = None;
    value mutable parent : option 'parent = None;

    method transformationMatrix = 
      match transformationMatrix with
      [ None -> 
        let translate = match transformPoint with [ {Point.x=0.;y=0.} -> pos | _ -> Point.addPoint pos transformPoint ] in
        let m = Matrix.create ~scale:(scaleX,scaleY) ~rotation ~translate () in
        (
          transformationMatrix := Some m;
          m;
        )
      | Some m -> m
      ];


    method transformPointX = transformPoint.Point.x;
    method setTransformPointX nv = 
      if nv <> transformPoint.Point.x
      then
        (
          transformPoint := {Point.x = nv;y = transformPoint.Point.y};
          RESET_CACHE("setTransformPointX");
        )
      else ();

    method transformPointY = transformPoint.Point.y;
    method setTransformPointY nv =
      if nv <> transformPoint.Point.y
      then
        (
          transformPoint := {Point.x = transformPoint.Point.x;y=nv};
          RESET_CACHE("setTransformPointY");
        )
      else ();


    method transformPoint = transformPoint;
    method setTransformPoint p = 
      if p <> transformPoint
      then
      (
        transformPoint := p;
        RESET_CACHE("setTransformPoint");
      )
      else ();

    method parent = parent;
    method setParent p = (parent := Some p;);
    method clearParent () = (parent := None;);

    method virtual filters: list Filters.t;
    method virtual setFilters: list Filters.t -> unit;

    method private enterFrameListenerRemovedFromStage  _ _ lid =
      let _ = super#removeEventListener `REMOVED_FROM_STAGE lid in
      match self#hasEventListeners `ENTER_FRAME with
      [ True -> 
        (
          onEnterFrameObjects.val := SetD.remove (self :> dispObj) !onEnterFrameObjects;
          ignore(super#addEventListener `ADDED_TO_STAGE self#enterFrameListenerAddedToStage)
        )
      | False -> ()
      ];

    method private enterFrameListenerAddedToStage _ _ lid = 
      (
        match self#hasEventListeners `ENTER_FRAME with
        [ True -> self#listenEnterFrame ()
        | False -> () 
        ];
        super#removeEventListener `ADDED_TO_STAGE lid
      );

    method private listenEnterFrame () = 
      (
        onEnterFrameObjects.val := SetD.add (self :> dispObj) !onEnterFrameObjects;
        ignore(super#addEventListener `REMOVED_FROM_STAGE self#enterFrameListenerRemovedFromStage);
      );

    method! addEventListener (eventType:P.evType) (listener:'listener) = 
    (
      match eventType with
      [ `ENTER_FRAME -> 
        match self#hasEventListeners `ENTER_FRAME with
        [ False ->
          match self#stage with
          [ None -> ignore(super#addEventListener `ADDED_TO_STAGE self#enterFrameListenerAddedToStage)
          | Some _ -> self#listenEnterFrame ()
          ]
        | True -> ()
        ]
      | _ -> ()
      ];
      super#addEventListener eventType listener;
    );

    method! removeEventListener (eventType:P.evType) (lid:int) = 
    (
      super#removeEventListener eventType lid;
      match eventType with
      [ `ENTER_FRAME ->
          match self#hasEventListeners `ENTER_FRAME with
          [ False ->
            match self#stage with
            [ None -> ()
            | Some _ -> onEnterFrameObjects.val := SetD.remove (self :> dispObj) !onEnterFrameObjects 
            ]
          | True -> ()
          ]
      | _ -> ()
      ];
    );

    method dispatchEvent' event target =
    (
      try
        let l = List.assoc event.Ev.etype listeners in
        let evd = (target,self) in
        ignore(List.for_all (fun (lid,l) -> (l event evd lid; event.Ev.propagation <> `StopImmediate)) l.EventDispatcher.lstnrs);
      with [ Not_found -> () ];
      match event.Ev.bubbles && event.Ev.propagation = `Propagate with
      [ True -> 
        match parent with
        [ Some p -> p#dispatchEvent' event target
        | None -> ()
        ]
      | False -> ()
      ]
    );


    method dispatchEvent event = (*{{{*)
      self#dispatchEvent' event self#asDisplayObject;
    (*}}}*)

    method scaleX = scaleX;
    method setScaleX ns = (scaleX := ns; RESET_CACHE "setScaleX");

    method scaleY = scaleY;
    method setScaleY ns = (scaleY := ns; RESET_CACHE "setScaleY");

    method setScale s = (scaleX := s; scaleY := s; RESET_CACHE "setScale");

    value mutable visible = True;
    method visible = visible;
    method setVisible nv = visible := nv;

    value mutable touchable = True;
    method touchable = touchable;
    method setTouchable v = touchable := v;

    method x = pos.Point.x;
    method setX x' = ( pos := {(pos) with Point.x = x'}; RESET_CACHE "setX");

    method y = pos.Point.y;
    method setY y' = (pos  := {(pos) with Point.y = y'}; RESET_CACHE "setY");

    method pos = pos;
    method setPos x y = (pos := {Point.x=x;y=y}; RESET_CACHE "setPos");
    method setPosPoint p = (pos := p; RESET_CACHE "setPosPoint");

    method virtual boundsInSpace: !'space. option (<asDisplayObject: 'displayObject; .. > as 'space) -> Rectangle.t;

    (*
    method bounds = 
      match boundsCacheSelector with
      [ None -> 
        let bounds = self#boundsInSpace parent in
        let sel = Dictionary.define intcache bounds in
        (
          boundsCacheSelector := Some sel;
          bounds
        )
      | Some sel -> 
          match Dictionary.get intcache sel with
          [ Some bounds -> let () = debug:intcache "bounds from cache %s" name in bounds
          | None -> 
             let bounds = self#boundsInSpace parent in
             (
               Dictionary.set intcache sel bounds;
               bounds
             )
          ]
      ];
    *)

    method bounds = 
      match boundsCache with
      [ None -> 
          let bounds = self#boundsInSpace parent in
          (
            boundsCache := Some bounds;
            bounds
          )
      | Some bounds -> bounds
      ];

    method width = self#bounds.Rectangle.width;

    method setWidth nw = 
    (
      (* this method calls 'self.scaleX' instead of changing mScaleX directly.
          that way, subclasses reacting on size changes need to override only the scaleX method. *)
      scaleX := 1.0;
      boundsCache := None;
      let actualWidth = self#width in
      if actualWidth <> 0.0
      then
        self#setScaleX (nw /. actualWidth)
      else self#setScaleX 1.0;
    );
      
    method height = self#bounds.Rectangle.height;

    method setHeight nh = 
    (
      scaleY := 1.0;
      boundsCache := None;
      let actualHeight = self#height in
      if actualHeight <> 0.0
      then
        self#setScaleY (nh /. actualHeight) 
      else self#setScaleY 1.0
    );
    

    method rotation = rotation;
    method setRotation nr = 
      (* clamp between [-180 deg, +180 deg] *)
      let nr = 
        if nr < ~-.pi 
        then loop nr where rec loop nr = let nr = nr +. two_pi in if nr < ~-.pi then loop nr else nr
        else nr
      in
      let nr = 
        if nr > pi 
        then loop nr where rec loop nr = let nr = nr -. two_pi in if nr > pi then loop nr else nr
        else nr
      in
      (
        rotation := nr;
        RESET_CACHE "setRotation";
      );

    method setTransformationMatrix m =
    (
      let sx = Matrix.scaleX m in
      scaleX := sx;
      let sy = Matrix.scaleY m in
      scaleY := sy;
      let r = Matrix.rotation m in
      rotation := r;
      pos := {Point.x = m.Matrix.tx; y = m.Matrix.ty};
      transformationMatrix := Some m;
      RESET_BOUNDS_CACHE;
    );

    value mutable alpha = 1.0;
    method alpha = alpha;
    method setAlpha na = alpha := max 0.0 (min 1.0 na);


    method asDisplayObject = (self :> _c 'parent);
    method virtual dcast: [= `Object of 'displayObject | `Container of 'parent ];
    (*
    method transformGLMatrix () = 
    (
      if transformPoint <> (0.,0.) || x <> 0.0 || y <> 0.0 then 
        let (x,y) = Point.addPoint (x,y) transformPoint in
        glTranslatef x y 0. else ();
      if rotation <> 0.0 then glRotatef (rotation /. pi *. 180.0) 0. 0. 1.0 else ();
      if scaleX <> 0.0 || scaleY <> 0.0 then glScalef scaleX scaleY 1.0 else ();
    );
    *)


    method root = 
      loop self#asDisplayObject where
        rec loop currentObject =
          match currentObject#parent with
          [ None -> currentObject
          | Some p -> loop p#asDisplayObject
          ];

    method stage : option 'parent = 
      match parent with
      [ None -> None
      | Some p -> p#stage
      ];

    method transformationMatrixToSpace: !'space. option (<asDisplayObject: 'displayObject; ..> as 'space) -> Matrix.t = fun targetCoordinateSpace -> (*{{{*)
      match targetCoordinateSpace with
      [ None -> 
        let rec loop currentObject matrix = 
          let matrix = Matrix.concat matrix currentObject#transformationMatrix in
          match currentObject#parent with
          [ Some parent -> loop parent#asDisplayObject matrix
          | None -> matrix
          ]
        in
        loop self#asDisplayObject Matrix.identity
      | Some targetCoordinateSpace -> 
        let targetCoordinateSpace = targetCoordinateSpace#asDisplayObject in
        if targetCoordinateSpace = self#asDisplayObject
        then Matrix.identity
        else 
          match targetCoordinateSpace#parent with
          [ Some targetParent when targetParent#asDisplayObject = self#asDisplayObject -> (* optimization  - this is our child *)
              let targetMatrix = targetCoordinateSpace#transformationMatrix in
              Matrix.invert targetMatrix
          | _ ->
(*               let () = Printf.eprintf "self: [%s], parent: [%s], targetCoordinateSpace: [%s]\n%!" name (match parent with [ None -> "NONE" | Some s -> s#name ]) targetCoordinateSpace#name in *)
              match parent with
              [ Some parent when parent#asDisplayObject = targetCoordinateSpace -> self#transformationMatrix (* optimization  - this is our parent *) 
              | _ ->
                (* 1.: Find a common parent of self and the target coordinate space  *)
                let ancessors = 
                  loop self#asDisplayObject where
                    rec loop currentObject = 
                      let next = 
                        match currentObject#parent with
                        [ None -> []
                        | Some cp -> loop cp#asDisplayObject
                        ]
                      in
                      [ currentObject :: next ] 
                in
(*                 let () = Printf.eprintf "ancessors: [%s]\n%!" (String.concat ";" (List.map (fun o -> o#name) ancessors)) in *)
                let commonParent = 
                  loop targetCoordinateSpace where
                    rec loop currentObject = 
                      match List.mem currentObject ancessors with
                      [ True -> currentObject
                      | False -> 
                          match currentObject#parent with
                          [ None -> failwith "Object not connected to target"
                          | Some cp -> loop cp#asDisplayObject
                          ]
                      ]
                in
                let move_up obj = 
                    loop obj Matrix.identity where
                      rec loop currentObject matrix =
                        match currentObject = commonParent with
                        [ True -> matrix
                        | False ->
                            match currentObject#parent with
                            [ Some p -> loop p#asDisplayObject (Matrix.concat matrix currentObject#transformationMatrix)
                            | None -> assert False
                            ]
                        ]
                in
                (* 2.: Move up from self to common parent *)
                let selfMatrix = move_up self#asDisplayObject
                (* 3.: Move up from target to common parent *)
                and targetMatrix = move_up targetCoordinateSpace
                in
                 (* 4.: Combine the two matrices *)
                 Matrix.concat selfMatrix (Matrix.invert targetMatrix)
              ]
          ]
      ];(*}}}*)
   

    (* если придумать какое-то кэширование ? *)
    value mutable mask: option (bool * Rectangle.t * (array Point.t)) = None;
    method setMask ?(onSelf=False) rect = 
      let open Rectangle in 
      mask := Some (onSelf, rect, Rectangle.points rect); (* FIXME: можно сразу преобразовать этот рект и закэшировать нах *)

    method virtual private render': ?alpha:float -> ~transform:bool -> option Rectangle.t -> unit;

    method render ?alpha:(parentAlpha) ?(transform=True) rect = 
      proftimer:render ("render %s" name)
      (
        if visible && alpha > 0. 
        then
          match mask with
          [ None -> self#render' ?alpha:parentAlpha ~transform rect 
          | Some (onSelf,maskRect,maskPoints) ->
              let maskRect = 
                match onSelf with
                [ True -> maskRect
                | False -> 
                    let m = self#transformationMatrix in 
                    Matrix.transformRectangle (Matrix.invert m) maskRect
                ]
              in
              match rect with
              [ None -> RENDER_WITH_MASK (self#render' ?alpha:parentAlpha ~transform (Some maskRect))
              | Some rect -> 
                  match Rectangle.intersection maskRect rect with
                  [ Some inRect -> RENDER_WITH_MASK (self#render' ?alpha:parentAlpha ~transform (Some inRect))
                  | None -> ()
                  ]
              ]
          ]
        else ();
      );

    method private hitTestPoint' localPoint isTouch = 
(*       let () = Printf.printf "hitTestPoint: %s, %s - %s\n" name (Point.to_string localPoint) (Rectangle.to_string (self#boundsInSpace (Some self#asDisplayObject))) in *)
      match Rectangle.containsPoint (self#boundsInSpace (Some self)) localPoint with
      [ True -> Some self#asDisplayObject
      | False -> None
      ];

    method hitTestPoint localPoint isTouch = 
      (* on a touch test, invisible or untouchable objects cause the test to fail *)
      match (isTouch && (not visible || not touchable)) with
      [ True -> None
      | False -> 
        match mask with
        [ None -> self#hitTestPoint' localPoint isTouch
        | Some (onSelf,maskRect,maskPoints) ->
            let maskRect = 
              match onSelf with
              [ True -> maskRect
              | False -> 
                  let m = self#transformationMatrix in 
                  Matrix.transformRectangle (Matrix.invert m) maskRect
              ]
            in
            match Rectangle.containsPoint maskRect localPoint with
            [ True -> self#hitTestPoint' localPoint isTouch
            | False -> None
            ]
        ]
      ];

    method removeFromParent () = 
      match parent with
      [ Some parent -> parent#removeChild' self#asDisplayObject
      | None -> ()
      ];

    method localToGlobal localPoint = 
      (* move up until parent is nil *)
      let matrix = 
        loop self#asDisplayObject Matrix.identity where
          rec loop currentObject matrix =
            let matrix = Matrix.concat matrix currentObject#transformationMatrix in
            match currentObject#parent with
            [ None -> matrix
            | Some p -> loop p#asDisplayObject matrix
            ]
      in
      Matrix.transformPoint matrix localPoint;


    method globalToLocal globalPoint = 
      (* move up until parent is nil, then invert matrix *)
      let matrix = 
        loop self#asDisplayObject Matrix.identity where
          rec loop currentObject matrix = 
            let matrix = Matrix.concat matrix currentObject#transformationMatrix in
            match currentObject#parent with
            [ None -> matrix
            | Some p -> loop p#asDisplayObject matrix
            ]
      in
      Matrix.transformPoint (Matrix.invert matrix) globalPoint;

    method boundsChanged () = RESET_BOUNDS_CACHE;


  end;(*}}}*)





(* Dll additional functions {{{*)
value dllist_find node el = 
  match Dllist.get node = el with
  [ True -> node
  | False ->
    let rec loop n =
      if n != node 
      then
        match Dllist.get n = el with
        [ True -> n
        | False -> loop (Dllist.next n)
        ]
      else raise Not_found
    in
    loop (Dllist.next node)
  ];
  
value dllist_existsf f node = 
  match f (Dllist.get node) with
  [ True -> True
  | False ->
      let rec loop n =
        if n != node 
        then
          match f (Dllist.get n) with
          [ True -> True
          | False -> loop (Dllist.next n)
          ]
        else
          False
      in
      loop (Dllist.next node)
  ];

value dllist_find_map f node = 
  match f (Dllist.get node) with 
  [ Some r -> r
  | None ->
      let rec loop n =
        if n != node 
        then
          match f (Dllist.get n) with
          [ Some r -> r
          | None -> loop (Dllist.next n)
          ]
        else raise Not_found
    in
    loop (Dllist.next node)
  ];


value dllist_find_map_back f node = 
  let node = Dllist.prev node in
  match f (Dllist.get node) with
  [ Some r -> r
  | None ->
      let rec loop n =
        if n != node
        then 
          match f (Dllist.get n) with
          [ Some r -> r
          | None -> loop (Dllist.prev n)
          ]
        else raise Not_found
      in
      loop (Dllist.prev node)
  ];
  
(*}}}*)


class virtual container = (*{{{*)
  object(self:'self)
    inherit _c [ container ] as super;
    type 'displayObject = _c container;
    (* пока на листах, потом видно будет *)
    value mutable children : option (Dllist.node_t 'displayObject) = None;
    value mutable numChildren = 0;
    method children = match children with [ None -> Enum.empty () | Some children -> Dllist.enum children];
    method numChildren = numChildren;
    method asDisplayObjectContainer = (self :> container);
    method dcast = `Container self#asDisplayObjectContainer;

    (* Сделать enum устойчивым к модификациям и переписать на полное использование енумов или щас ? *)
    method dispatchEventOnChildren event = 
    (
      self#dispatchEvent event;
      Enum.iter begin fun (child:'displayObject) -> (* здесь хуйня с таргетом надо разобраца *)
        match child#dcast with
        [ `Container cont -> cont#dispatchEventOnChildren event
(*           (cont :> < dispatchEventOnChildren: !'a. Ev.t eventType eventData 'displayObject (< .. > as 'a) -> unit >)#dispatchEventOnChildren event *)
        | `Object obj -> obj#dispatchEvent event
        ]
      end self#children;
    );

    method virtual cacheAsImage: bool;
    method virtual setCacheAsImage: bool -> unit;

    method addChild: !'child. ?index:int -> ((#_c container) as 'child) -> unit = fun  ?index child ->
      let child = child#asDisplayObject in
      (
          debug:container "%s: addChild '%s'" name child#name;
          match children with
          [ None -> 
            match index with
            [ Some idx when idx > 0 -> raise Invalid_index
            | _ -> ( child#removeFromParent(); children := Some (Dllist.create child))
            ]
          | Some chldrn -> 
              match index with
              [ None -> (* добавить в канец *) (child#removeFromParent(); Dllist.add (Dllist.prev chldrn) child )
              | Some idx when idx > 0 && idx < numChildren -> (child#removeFromParent(); Dllist.add (Dllist.skip chldrn (idx-1)) child)
              | Some idx when idx = 0 -> (child#removeFromParent(); children := Some (Dllist.prepend chldrn child))
              | Some idx when idx = numChildren -> (child#removeFromParent(); Dllist.add (Dllist.prev chldrn) child)
              | _ -> raise Invalid_index
              ]
          ];
          numChildren := numChildren + 1;
          child#setParent self#asDisplayObjectContainer;
          self#boundsChanged();
          let event = Ev.create `ADDED () in
          child#dispatchEvent event;
          match self#stage with
          [ Some _ -> 
            let event = Ev.create `ADDED_TO_STAGE () in
            match child#dcast with
            [ `Container cont -> 
(*               let cont = (cont :> < dispatchEventOnChildren: !'a. Ev.t eventType eventData 'displayObject (< .. > as 'a) -> unit >) in *)
              cont#dispatchEventOnChildren event
            | `Object _ -> child#dispatchEvent event
            ]
          | None -> ()
          ]
      );

    method getChildAt index = 
      match children with
      [ None -> raise Invalid_index
      | Some children -> 
          match index >= 0 && index < numChildren with
          [ True -> Dllist.get (Dllist.skip children index)
          | False -> raise Invalid_index
          ]
      ];

    method getLastChild =
      match children with
      [ None -> raise Invalid_index
      | Some children -> Dllist.get (Dllist.prev children)
      ];

    (* FIXME: защиту от зацикливаний бы поставить нах *)
    method private removeChild'' (child_node:Dllist.node_t 'displayObject) =
      let child = Dllist.get child_node in
      (
        child#clearParent();
        match children with
        [ Some chldrn ->
          if chldrn == child_node
          then
            match Dllist.next child_node == chldrn with
            [ True -> children := None
            | False -> children := Some (Dllist.drop child_node)
            ]
          else 
            Dllist.remove child_node
        | None -> assert False
        ];
        numChildren := numChildren - 1;
        self#boundsChanged();
        let event = Ev.create `REMOVED () in
        child#dispatchEvent event;
        match self#stage with
        [ Some _ -> 
          let event = Ev.create `REMOVED_FROM_STAGE () in
          match child#dcast with
          [ `Container cont -> cont#dispatchEventOnChildren event
          | `Object _ -> child#dispatchEvent event
          ]
        | None -> ()
        ];
        child;
      );

    method removeChild' child = 
      match children with
      [ None -> raise Child_not_found
      | Some children ->
          let n = try dllist_find children child with [ Not_found -> raise Child_not_found ] in
          ignore(self#removeChild'' n)
      ];

    method removeChild: !'child. ((#_c container) as 'child) -> unit = fun child -> (* чекать сцука надо блядь *)
      let child = child#asDisplayObject in
      self#removeChild' child;

    method removeChildAtIndex index : 'displayObject = 
      match children with
      [ None -> raise Invalid_index
      | Some children -> 
        match index >= 0 && index < numChildren with
        [ True -> 
          let n = Dllist.skip children index in
          self#removeChild'' n
        | False -> raise Invalid_index 
        ]
      ];

    method clearChildren () = 
      match children with
      [ None -> ()
      | Some chldrn -> 
        let evs = 
          let event = Ev.create `REMOVED () in 
          match self#stage with
          [ Some _ -> 
            let sevent = Ev.create `REMOVED_FROM_STAGE () in
            fun (child:'displayObject) -> 
              (
                child#dispatchEvent event;
                match child#dcast with
                [ `Container cont -> cont#dispatchEventOnChildren sevent
                | `Object _ -> child#dispatchEvent sevent
                ]
              )
          | None -> fun child -> child#dispatchEvent event
          ]
        in
        (
          children := None;
          numChildren := 0;
          Dllist.iter (fun (child:'displayObject) -> (child#clearParent();evs child)) chldrn;
          self#boundsChanged();
        )
      ];

    method containsChild' child = 
      match children with
      [ None -> False
      | Some children -> 
        dllist_existsf begin fun chld ->
          match chld = child with
          [ True -> True
          | False ->
              match chld#dcast with
              [ `Container container -> container#containsChild' child
              | _ -> False 
              ]
          ]
        end children
      ];

    method containsChild: !'child. ((#_c container) as 'child) -> bool = fun child ->
      let child = child#asDisplayObject in
      self#containsChild' child;

    method boundsInSpace targetCoordinateSpace =
      match children with
      [ None -> Rectangle.create 0. 0. 0. 0.
      | Some children when children == (Dllist.next children) (* 1 child *) -> (Dllist.get children)#boundsInSpace targetCoordinateSpace
      | Some children -> 
          let ar = [| max_float; ~-.max_float; max_float; ~-.max_float |] in
          (
            let open Rectangle in
(*             let transformationMatrix = self#transformationMatrixToSpace targetCoordinateSpace in *)
            let matrix = self#transformationMatrixToSpace targetCoordinateSpace in 
            Dllist.iter begin fun (child:'displayObject) ->
(*               let childBounds = child#boundsInSpace targetCoordinateSpace in *)
              let childBounds = Matrix.transformRectangle matrix child#bounds in
              (
                if childBounds.x < ar.(0) then ar.(0) := childBounds.x else ();
                let rightX = childBounds.x +. childBounds.width in
                if rightX > ar.(1) then ar.(1) := rightX else ();
                if childBounds.y < ar.(2) then ar.(2) := childBounds.y else ();
                let downY = childBounds.y +. childBounds.height in
                if downY > ar.(3) then ar.(3) := downY else ();
              )
            end children;
            Rectangle.create ar.(0) ar.(2) (ar.(1) -. ar.(0)) (ar.(3) -. ar.(2))
          )
      ];


    method! private hitTestPoint' localPoint isTouch = 
      match children with
      [ None -> None
      | Some children -> 
        try
          let res = 
            dllist_find_map_back begin fun child ->
              let transformationMatrix = self#transformationMatrixToSpace (Some child) in
              let transformedPoint = Matrix.transformPoint transformationMatrix localPoint in
              child#hitTestPoint transformedPoint isTouch
            end children
          in
          Some res
        with [ Not_found -> None ]
      ];


    method private render' ?alpha:(alpha') ~transform rect = 
      match children with
      [ None -> ()
      | Some children -> 
          let alpha = 
            if alpha <> 1.
            then 
              let a = match alpha' with [ None -> alpha | Some a -> a *. alpha ] in
              Some a
            else alpha'
          in
          (
            if transform then Render.push_matrix self#transformationMatrix else ();
            match rect with
            [ None -> Dllist.iter (fun (child:'displayObject) -> child#render ?alpha None) children
            | Some rect -> 
              Dllist.iter begin fun (child:'displayObject) ->
                let childAlpha = child#alpha in
                if (childAlpha > 0.0 && child#visible) 
                then
                  let bounds = child#bounds in
                  match Rectangle.intersection rect bounds with
                  [ Some intRect -> 
                      match child#dcast with
                      [ `Object _ -> child#render ?alpha None (* FIXME: по идее нужно вызывать таки с ректом, но здесь оптимайзинг, убрать если надо! *)
                      | `Container (c:container) -> 
                          let childMatrix = self#transformationMatrixToSpace (Some child) in
                          c#render ?alpha ?transform:(Some True) (Some (Matrix.transformRectangle childMatrix intRect))
                      ]
                  | None ->  debug:render "container '%s', not render: '%s'" name child#name
                  ]
                else ()
              end children
            ];
            if transform then Render.restore_matrix () else ();
          )
      ];

  end;(*}}}*)



class virtual c =
  object(self)
    inherit _c [ container ];
    method dcast = `Object (self :> c);
  end;


end;
