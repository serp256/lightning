open LightCommon;

value ev_ADDED = Ev.gen_id "ADDED";
value ev_ADDED_TO_STAGE = Ev.gen_id "ADDED_TO_STAGE";
value ev_REMOVED = Ev.gen_id "REMOVED";
value ev_REMOVED_FROM_STAGE = Ev.gen_id "REMOVED_FROM_STAGE";
value ev_ENTER_FRAME = Ev.gen_id "ENTER_FRAME";

type hidden 'a = 'a;

exception Invalid_index;
exception Child_not_found;

(* приходит массив точек, к ним применяется трасформация и в результате получаем min и максимальные координаты *)

external glEnableScissor: int -> int -> int -> int -> unit = "ml_gl_scissor_enable";
external glDisableScissor: unit -> unit = "ml_gl_scissor_disable";

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
          glEnableScissor (int_of_float minX) (int_of_float minY) (int_of_float (maxX -. minX)) (int_of_float (maxY -. minY)); 
(*           glEnable gl_scissor_test; *)
(*           glScissor (int_of_float minX) (int_of_float minY) (int_of_float (maxX -. minX)) (int_of_float (maxY -. minY)); *)
          call_render;
(*           glDisable gl_scissor_test; *)
          glDisableScissor ();
        )
      )
    | _ -> assert False
    ]
  | None -> failwith "render without stage"
  ];(*}}}*)

class type dispObj = 
  object
    method dispatchEvent: Ev.t -> unit;
    method name: string;
  end;

module SetD = Set.Make (struct type t = dispObj; value compare d1 d2 = compare d1 d2; end);

value onEnterFrameObjects = ref SetD.empty;

value dispatchEnterFrame seconds = 
  let enterFrameEvent = Ev.create ev_ENTER_FRAME ~data:(Ev.data_of_float seconds) () in
  SetD.iter (fun obj -> let () = debug:enter_frame "dispatch enter frame on: %s" obj#name in obj#dispatchEvent enterFrameEvent) !onEnterFrameObjects;


class type prerenderObj =
  object
    method prerender: bool -> unit;
    method z: option int;
    method name: string;
  end;

value prerender_locked = ref False;
value prerender_objects = RefList.empty ();
value add_prerender o = 
  let () = debug:prerender "add_prerender: %s" o#name in
  match !prerender_locked with
  [ True -> failwith "Prerender locked"
  | False -> RefList.push prerender_objects o
  ];
  
value prerender () =
  match RefList.is_empty prerender_objects with
  [ True -> ()
  | False ->
    (
      debug:prerender "start prerender";
      prerender_locked.val := True;
      let cmp ((z1:int),_) (z2,_) = compare z1 z2 in
      let sorted_objects = RefList.empty () in
      (
        RefList.iter (fun o -> 
          match o#z with
          [ Some z -> 
            let () = debug:prerender "object [%s] with z %d added to prerender" o#name z in
            RefList.add_sort ~cmp sorted_objects (z,o)
          | None -> o#prerender False
          ]
        ) prerender_objects;
        RefList.iter (fun (_,o) -> o#prerender True) sorted_objects;
        RefList.clear prerender_objects;
      );
      prerender_locked.val := False;
    )
  ];


Callback.register "prerender" prerender;

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
    inherit EventDispatcher.base [ 'displayObject,'self] as super;

    type 'parent = 
      < 
        asDisplayObject: _c _; removeChild': _c _ -> unit; getChildIndex': _c _ -> int; z: option int; dispatchEvent': Ev.t -> _c _ -> unit;
        name: string; transformationMatrixToSpace: !'space. option (<asDisplayObject: _c _; ..> as 'space) -> Matrix.t; stage: option 'parent; boundsChanged: unit -> unit; .. 
      >;

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

    value mutable prerender_wait_listener = None;
    value prerenders : Queue.t (unit -> unit) = Queue.create ();
    method private addToPrerenders _ _ lid = 
    (
      match Queue.is_empty prerenders with
      [ False -> add_prerender (self :> prerenderObj)
      | True -> ()
      ];
      self#removeEventListener ev_ADDED_TO_STAGE lid;
      prerender_wait_listener := None;
    );

    method private addPrerender pr =
    (
      debug:prerender "addPrerender for %s" self#name;
      match Queue.is_empty prerenders with
      [ True -> 
        match self#stage with
        [ Some _ -> add_prerender (self :> prerenderObj)
        | None -> prerender_wait_listener := Some (self#addEventListener ev_ADDED_TO_STAGE self#addToPrerenders)
        ]
      | False -> ()
      ];
      Queue.push pr prerenders;
    );

    method prerender exe = 
      let () = debug:prerender "prerender %s - %b" self#name exe in
      match exe with
      [ True -> 
        (
          while not (Queue.is_empty prerenders) do
            (Queue.pop prerenders) ();
          done;
          match prerender_wait_listener with
          [ Some lid -> 
            (
              self#removeEventListener ev_ADDED_TO_STAGE lid;
              prerender_wait_listener := None;
            )
          | None -> ()
          ]
        )
      | False -> 
          match prerender_wait_listener with
          [ None -> prerender_wait_listener := Some (self#addEventListener ev_ADDED_TO_STAGE self#addToPrerenders)
          | Some _ -> ()
          ]
      ];

    method parent = parent;
    method setParent p = 
    (
      debug:prerender "set parent for %s" self#name;
      parent := Some p;
    );

    method clearParent () = (parent := None;);
    method z =
      match parent with
      [ Some parent -> 
        let () = debug "i have parent" in
        match parent#z with
        [ Some z -> Some (z + (parent#getChildIndex' (self :> _c 'parent)) + 1)
        | None -> None
        ]
      | None -> None
      ];

    method virtual filters: list Filters.t;
    method virtual setFilters: list Filters.t -> unit;

    method private enterFrameListenerRemovedFromStage  _ _ lid =
      let _ = super#removeEventListener ev_REMOVED_FROM_STAGE lid in
      match self#hasEventListeners ev_ENTER_FRAME with
      [ True -> 
        (
          onEnterFrameObjects.val := SetD.remove (self :> dispObj) !onEnterFrameObjects;
          ignore(super#addEventListener ev_ADDED_TO_STAGE self#enterFrameListenerAddedToStage)
        )
      | False -> ()
      ];

    method private enterFrameListenerAddedToStage _ _ lid = 
      (
        match self#hasEventListeners ev_ENTER_FRAME with
        [ True -> self#listenEnterFrame ()
        | False -> () 
        ];
        super#removeEventListener ev_ADDED_TO_STAGE lid
      );

    method private listenEnterFrame () = 
      (
        onEnterFrameObjects.val := SetD.add (self :> dispObj) !onEnterFrameObjects;
        ignore(super#addEventListener ev_REMOVED_FROM_STAGE self#enterFrameListenerRemovedFromStage);
      );

    method! addEventListener eventType (listener:'listener) = 
    (
      if eventType = ev_ENTER_FRAME
      then
        match self#hasEventListeners ev_ENTER_FRAME with
        [ False ->
          match self#stage with
          [ None -> ignore(super#addEventListener ev_ADDED_TO_STAGE self#enterFrameListenerAddedToStage)
          | Some _ -> self#listenEnterFrame ()
          ]
        | True -> ()
        ]
      else ();
      super#addEventListener eventType listener;
    );

    method! removeEventListener eventType (lid:int) = 
    (
      super#removeEventListener eventType lid;
      if eventType = ev_ENTER_FRAME
      then
          match self#hasEventListeners ev_ENTER_FRAME with
          [ False ->
            match self#stage with
            [ None -> ()
            | Some _ -> onEnterFrameObjects.val := SetD.remove (self :> dispObj) !onEnterFrameObjects 
            ]
          | True -> ()
          ]
      else ()
    );

    method dispatchEvent' event target =
    (
      MList.apply_assoc 
        (fun l ->
          let evd = (target,self) in
          ignore(List.for_all (fun (lid,l) -> (l event evd lid; event.Ev.propagation <> `StopImmediate)) l.EventDispatcher.lstnrs)
        )
        event.Ev.evid listeners;
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
      RESET_CACHE("setWidth");
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
      RESET_CACHE("setHeight");
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

    method root = 
      loop (self :> _c 'parent) where
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
        loop (self :> _c 'parent) Matrix.identity
      | Some targetCoordinateSpace -> 
        let targetCoordinateSpace = targetCoordinateSpace#asDisplayObject in
        if targetCoordinateSpace = (self :> _c 'parent)
        then Matrix.identity
        else 
          match targetCoordinateSpace#parent with
          [ Some targetParent when targetParent#asDisplayObject = (self :> _c 'parent) -> (* optimization  - this is our child *)
              let targetMatrix = targetCoordinateSpace#transformationMatrix in
              Matrix.invert targetMatrix
          | _ ->
(*               let () = Printf.eprintf "self: [%s], parent: [%s], targetCoordinateSpace: [%s]\n%!" name (match parent with [ None -> "NONE" | Some s -> s#name ]) targetCoordinateSpace#name in *)
              match parent with
              [ Some parent when parent#asDisplayObject = targetCoordinateSpace -> self#transformationMatrix (* optimization  - this is our parent *) 
              | _ ->
                (* 1.: Find a common parent of self and the target coordinate space  *)
                let ancessors = 
                  loop (self :> _c 'parent) where
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
                let selfMatrix = move_up (self :> _c 'parent)
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
      let () = debug:tmp "render [%s]" self#name in
      proftimer:render ("render [%s] %f" self#name)
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
      [ True -> Some (self :> _c 'parent)
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
      [ Some parent -> parent#removeChild' (self :> _c 'parent)
      | None -> ()
      ];

    method localToGlobal localPoint = 
      (* move up until parent is nil *)
      let matrix = 
        loop (self :> _c 'parent) Matrix.identity where
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
        loop (self :> _c 'parent) Matrix.identity where
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
  
value dllist_find_index node el = 
  match Dllist.get node = el with
  [ True -> 0
  | False ->
    let rec loop n i =
      if n != node 
      then
        match Dllist.get n = el with
        [ True -> i
        | False -> loop (Dllist.next n) (i+1)
        ]
      else raise Not_found
    in
    loop (Dllist.next node) 1
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
          debug:children "[%s] addChild '%s'" self#name child#name;
          child#removeFromParent(); 
          match children with
          [ None -> 
            match index with
            [ Some idx when idx > 0 -> raise Invalid_index
            | _ -> children := Some (Dllist.create child)
            ]
          | Some chldrn -> 
              match index with
              [ None -> (* добавить в канец *) Dllist.add (Dllist.prev chldrn) child 
              | Some idx when idx > 0 && idx < numChildren -> Dllist.add (Dllist.skip chldrn (idx-1)) child
              | Some idx when idx = 0 -> children := Some (Dllist.prepend chldrn child)
              | Some idx when idx = numChildren -> Dllist.add (Dllist.prev chldrn) child
              | _ -> raise Invalid_index
              ]
          ];
          numChildren := numChildren + 1;
          child#setParent self#asDisplayObjectContainer;
          self#boundsChanged();
          let event = Ev.create ev_ADDED () in
          child#dispatchEvent event;
          match self#stage with
          [ Some _ -> 
            let event = Ev.create ev_ADDED_TO_STAGE () in
            match child#dcast with
            [ `Container cont -> cont#dispatchEventOnChildren event
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

    method getChildIndex' child =
      match children with
      [ None -> raise Child_not_found
      | Some children ->
          try 
            dllist_find_index children child
          with 
            [ Not_found -> raise Child_not_found ] 
      ];


    method getChildIndex: !'child. ((#_c container) as 'child) -> int = fun child -> self#getChildIndex' child#asDisplayObject;


    method setChildIndex: !'child. ((#_c container) as 'child) -> int -> unit = fun child index -> 
      match children with
      [ None -> raise Child_not_found
      | Some chldrn ->
          if index >= numChildren || index < 0 then raise Invalid_index
          else
            let () = debug:children "[%s] setChildIndex %s" self#name child#name in 
            let child = child#asDisplayObject in
            match Dllist.get chldrn = child with
            [ True -> 
              if index > 0
              then
                let next_node = Dllist.next chldrn in
                match next_node == chldrn with
                [ True -> () (* ничего делать не надо *)
                | False -> 
                    let () = Dllist.remove chldrn in
                    let prev = Dllist.skip next_node (index - 1) in
                    let next = Dllist.next prev in
                    (
                      Dllist.splice prev chldrn;
                      Dllist.splice chldrn next;
                      children := Some next_node;
                    )
                ]
              else ()
            | False -> 
                let node = find_node (Dllist.next chldrn) where
                  rec find_node n =
                    if n != chldrn
                    then 
                      match Dllist.get n = child with
                      [ True -> n
                      | False -> find_node (Dllist.next n)
                      ]
                    else raise Child_not_found
                in
                (
                  Dllist.remove node;
                  if index = 0
                  then
                  (
                    Dllist.splice (Dllist.prev chldrn) node;
                    Dllist.splice node chldrn;
                    children := Some node
                  )
                  else
                    if index = numChildren - 1
                    then
                    (
                      Dllist.splice (Dllist.prev chldrn) node;
                      Dllist.splice node chldrn;
                    )
                    else
                      let prev = Dllist.skip chldrn (index - 1) in
                      let next = Dllist.next prev in
                      (
                        Dllist.splice prev node;
                        Dllist.splice node next;
                      )
                )
            ]
      ];

    (* FIXME: защиту от зацикливаний бы поставить нах *)
    method private removeChild'' (child_node:Dllist.node_t 'displayObject) =
      let child = Dllist.get child_node in
      (
        let () = debug:children "[%s] removeChild %s" self#name child#name in
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
        let event = Ev.create ev_REMOVED () in
        child#dispatchEvent event;
        match self#stage with
        [ Some _ -> 
          let event = Ev.create ev_REMOVED_FROM_STAGE () in
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
          let () = debug:children "[%s] removeChild' %s" self#name child#name in
          let n = try dllist_find children child with [ Not_found -> raise Child_not_found ] in
          ignore(self#removeChild'' n)
      ];

    method removeChild: !'child. ((#_c container) as 'child) -> unit = fun child -> (* чекать сцука надо блядь *)
      let child = child#asDisplayObject in
      match children with
      [ None -> raise Child_not_found
      | Some children ->
          let () = debug:children "[%s] removeChild' %s" self#name child#name in
          let n = try dllist_find children child with [ Not_found -> raise Child_not_found ] in
          ignore(self#removeChild'' n)
      ];

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
      let () = debug:children "[%s] clear children" self#name in
      match children with
      [ None -> ()
      | Some chldrn -> 
        let evs = 
          let event = Ev.create ev_REMOVED () in 
          match self#stage with
          [ Some _ -> 
            let sevent = Ev.create ev_REMOVED_FROM_STAGE () in
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
      [ None -> Rectangle.empty
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

