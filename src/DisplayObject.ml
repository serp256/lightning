open Gl;
open LightCommon;

type eventType = [= `ADDED | `ADDED_TO_STAGE | `REMOVED | `REMOVED_FROM_STAGE ]; 
type eventData = Event.dataEmpty;

module type Param = sig
  type evType = private [> eventType ];
  type evData = private [> Event.dataEmpty ];
end;

module Make(P:Param) = struct

type hidden 'a = 'a;
type evType = P.evType;
type evData = P.evData;


(* приходит массив точек, к ним применяется трасформация и в результате получаем min и максимальные координаты *)
value transform_points points matrix = 
  let ar = [| max_float; ~-.max_float; max_float; ~-.max_float |] in
  (
    for i = 0 to (Array.length points) - 1 do
      let p = points.(i) in
      let (tx,ty) = Matrix.transformPoint matrix p in
      (
        if ar.(0) > tx then ar.(0) := tx else ();
        if ar.(1) < tx then ar.(1) := tx else ();
        if ar.(2) > ty then ar.(2) := ty else ();
        if ar.(3) < ty then ar.(3) := ty else ();
      )
    done;
    ar
  );

DEFINE RENDER_WITH_MASK(call_render) = 
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
    match transform_points maskPoints matrix with
    [ [| minX; maxX; minY; maxY |] ->
      let sheight = stage#height in
      (
        let minY = sheight -. maxY
        and maxY = sheight -. minY in
        (
          glEnable gl_scissor_test;
          glScissor (int_of_float minX) (int_of_float minY) (int_of_float (maxX -. minX)) (int_of_float (maxY -. minY));
          call_render;
          glDisable gl_scissor_test;
        )
      )
    | _ -> assert False
    ]
  | None -> failwith "render without stage"
  ];


class virtual _c [ 'parent ] = (*{{{*)
  object(self:'self)
    type 'displayObject = _c 'parent;
    inherit EventDispatcher.base [ P.evType,P.evData,'displayObject,'self];

    type 'parent = 
      < 
        asDisplayObject: _c _; removeChild': _c _ -> unit; dispatchEvent': !'ct. Event.t P.evType P.evData 'displayObject 'ct -> unit; 
        name: string; transformationMatrixToSpace: !'space. option (<asDisplayObject: _c _; ..> as 'space) -> Matrix.t; stage: option 'parent; .. 
      >;

    value intcache = Dictionary.create ();

    value mutable name = "";
    initializer  name := Printf.sprintf "instance%d" (Oo.id self);
    method name = name;
    method setName n = name := n;

    value mutable transfromPoint = (0.,0.);

    value mutable parent : option 'parent = None;
    method parent = parent;
    method setParent p = (parent := Some p; Dictionary.clear intcache);
    method clearParent () = (parent := None; Dictionary.clear intcache);

    (* Events *)
    type 'event = Event.t P.evType P.evData 'displayObject 'self;
    type 'listener = 'event -> unit;

    method dispatchEvent': !'ct. Event.t P.evType P.evData 'displayObject (< .. > as 'ct) -> unit = fun event -> (*{{{*)
      (
        try
          let l = List.assoc event.Event.etype listeners in
          let event = {(event) with Event.currentTarget = Some self} in
          ignore(List.for_all (fun (lid,l) -> (l event lid; event.Event.propagation = `StopImmediate)) l.EventDispatcher.lstnrs);
        with [ Not_found -> () ];
        match event.Event.bubbles && event.Event.propagation = `Propagate with
        [ True -> 
          match parent with
          [ Some p -> p#dispatchEvent' event
          | None -> ()
          ]
        | False -> ()
        ]
      );

    (* всегда ставить таргет в себя и соответственно current_target *)
    method dispatchEvent: !'ct. Event.t P.evType P.evData 'displayObject (< .. > as 'ct) -> unit = fun event -> 
      let event = {(event) with Event.target = Some self#asDisplayObject; currentTarget = None} in
      self#dispatchEvent' event;

(*     method hasEventListeners eventType = Listeners.has eventType listeners; *)
(*     method removeEventListener eventType listenerID = Listeners.remove eventType listenerID listeners; *)

    value mutable scaleX = 1.0;
    method scaleX = scaleX;
    method setScaleX ns = (scaleX := ns; Dictionary.clear intcache);

    value mutable scaleY = 1.0;
    method scaleY = scaleY;
    method setScaleY ns = (scaleY := ns; Dictionary.clear intcache);

    method setScale s = (scaleX := s; scaleY := s; Dictionary.clear intcache);

    value mutable visible = True;
    method visible = visible;
    method setVisible nv = visible := nv;

    value mutable touchable = True;
    method touchable = touchable;
    method setTouchable v = touchable := v;

    value mutable x = 0.0;
    method x = x;
    method setX x' = ( x := x'; Dictionary.clear intcache);

    value mutable y = 0.0;
    method y = y;
    method setY y' = (y := y'; Dictionary.clear intcache);

    method pos = (x,y);
    method setPos (x',y') = (x := x'; y := y';Dictionary.clear intcache);

    method virtual boundsInSpace: !'space. option (<asDisplayObject: 'displayObject; .. > as 'space) -> Rectangle.t;

    value mutable boundsCacheSelector = None;
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

    method width = self#bounds.Rectangle.width;

    method setWidth nw = 
    (
      (* this method calls 'self.scaleX' instead of changing mScaleX directly.
          that way, subclasses reacting on size changes need to override only the scaleX method. *)
      scaleX := 1.0;
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
      let actualHeight = self#height in
      if actualHeight <> 0.0
      then
        self#setScaleY (nh /. actualHeight) 
      else self#setScaleY 1.0
    );
    

    value mutable rotation = 0.0;
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
        Dictionary.clear intcache;
      );

    value mutable alpha = 1.0;
    method alpha = alpha;
    method setAlpha na = alpha := max 0.0 (min 1.0 na);


    value lastTouchTimestamp = 0.;
    method asDisplayObject = (self :> _c 'parent);
    method virtual dcast: [= `Object of 'displayObject | `Container of 'parent ];
    method transformGLMatrix () = 
    (
      if transfromPoint <> (0.,0.) || x <> 0.0 || y <> 0.0 then 
        let (x,y) = Point.addPoint (x,y) transfromPoint in
        glTranslatef x y 0. else ();
      if rotation <> 0.0 then glRotatef (rotation /. pi *. 180.0) 0. 0. 1.0 else ();
      if scaleX <> 0.0 || scaleY <> 0.0 then glScalef scaleX scaleY 1.0 else ();
    );

    method transformationMatrix = 
      let translate = Point.addPoint (x,y) transfromPoint in
      Matrix.create ~scale:(scaleX,scaleY) ~rotation ~translate (); (* Может быть стоит закэшировать нах. *)

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
    value mutable mask: option (bool * Rectangle.t * (array (float*float))) = None;
    method setMask ?(onSelf=False) rect = 
      let open Rectangle in 
      mask := Some (onSelf, rect, Rectangle.points rect); (* если будет система кэширования можно сразу преобразовать этот рект и закэшировать нах *)

    method virtual private render': option Rectangle.t -> unit;

    method render rect = 
      proftimer:render ("render %s" name)
      (
        match mask with
        [ None -> self#render' rect 
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
            [ None -> RENDER_WITH_MASK (self#render' (Some maskRect))
            | Some rect -> 
                match Rectangle.intersection maskRect rect with
                [ Some inRect -> RENDER_WITH_MASK (self#render' (Some inRect))
                | None -> ()
                ]
            ]
        ];
      );


    (*
    type 'event = Event.t 'event_type 'event_data 'displayObject 'self;
    value listeners: Hashtbl.t 'event_type 'listener = Hashtbl.create 0;
    method hasEventListeners eventType = Hashtbl.mem listeners eventType;
    method private dispatchEvent' event = 
      let listeners = 
        try
          let listeners = Hashtbl.find_all listeners event.Event.etype in
          Some listeners
        with [ Not_found -> None ]
      in
      match (event.Event.bubbles,listeners) with
      [ (False,None) -> ()
      | (_,lstnrs) -> 
          (
            match lstnrs with
            [ Some listeners -> 
(*               let event = {(event) with Event.currentTarget = Some self } in *)
              ignore(
                List.for_all begin fun l ->
                  (
                    l event;
                    event.Event.stopImmediatePropagation;
                  )
                end listeners 
              )
            | None -> ()
            ];
            (*
            match event.Event.bubbles && not event.Event.stopPropagation with
            [ True -> self#bubbleEvent event
            | False -> ()
            ]
            *)
          )
      ];
  
    method dispatchEvent (event:'event) = 
      let event = {(event) with Event.target = Some self#asDisplayObject} in
      self#dispatchEvent' event;
    *)



    method private hitTestPoint' localPoint isTouch = 
(*       let () = Printf.printf "hitTestPoint: %s, %s - %s\n" name (Point.to_string localPoint) (Rectangle.to_string (self#boundsInSpace (Some self#asDisplayObject))) in *)
      match Rectangle.containsPoint (self#boundsInSpace (Some self#asDisplayObject)) localPoint with
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

(*     method dispatchEventOnChildren event = self#dispatchEvent event; *)

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

  end;(*}}}*)

exception Invalid_index;
exception Child_not_found;

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
    method renderPrepare () = ();


    (*
    method! setParent parent =
      match (stage,parent#stage) with
      [ (Some _,None) -> Dllist.iter (fun c -> c#clearStage()) children
      | (None,Some s) -> Dllist.iter (fun c -> c#
      | None -> parent := Some parent
      ];

    method! clearParent () = 
    (
      match stage with
      [ Some _ -> 
        (
          stage := None;
          Dllist.iter (fun c -> c#clearStage ()) children;
        )
      | None -> ();
      ]
      parent := None;
    );
  *)


    method dispatchEventOnChildren: !'ct. Event.t P.evType P.evData 'displayObject (< .. > as 'ct) -> unit = fun event ->
      let rec loop obj = 
        let res = Enum.empty () in
        (
          if obj#hasEventListeners event.Event.etype then Enum.push res obj else ();
          match obj#dcast with
          [ `Container cont ->
            Enum.fold begin fun child res -> 
              Enum.append res (loop child)
            end res cont#children
          | _ -> res
          ]
        )
      in
      let listeners = loop self#asDisplayObject in
(*       let event = (event :> Event.t 'event_type 'event_data 'displayObject) in *)
      match Enum.is_empty listeners with
      [ True -> ()
      | False -> Enum.iter (fun (listener:'displayObject) -> listener#dispatchEvent event) listeners
      ];
    

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
          let event = Event.create `ADDED () in
          child#dispatchEvent event;
          match self#stage with
          [ Some _ -> 
            let event = Event.create `ADDED_TO_STAGE () in
            match child#dcast with
            [ `Container cont -> 
              let cont = (cont :> < dispatchEventOnChildren: !'a. Event.t P.evType P.evData 'displayObject (< .. > as 'a) -> unit >) in
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
        let event = Event.create `REMOVED () in
        child#dispatchEvent event;
        match self#stage with
        [ Some _ -> 
          let event = Event.create `REMOVED_FROM_STAGE () in
          match child#dcast with
          [ `Container cont -> cont#dispatchEventOnChildren event
          | `Object _ -> child#dispatchEvent event
          ]
        | None -> ()
        ];
      );

    method removeChild' child = 
      match children with
      [ None -> raise Child_not_found
      | Some children ->
          let n = try dllist_find children child with [ Not_found -> raise Child_not_found ] in
          self#removeChild'' n
      ];

    method removeChild: !'child. ((#_c container) as 'child) -> unit = fun child -> (* чекать сцука надо блядь *)
      let child = child#asDisplayObject in
      self#removeChild' child;

    method removeChildAtIndex index = 
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

    method removeChildren () = 
      match children with
      [ None -> ()
      | Some chldrn -> 
        let evs = 
          let event = Event.create `REMOVED () in 
          match self#stage with
          [ Some _ -> 
            let sevent = Event.create `REMOVED_FROM_STAGE () in
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
          Dllist.iter (fun (child:'displayObject) -> (evs child; child#clearParent())) chldrn;
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
          let (minX,maxX,minY,maxY) = 
            let open Rectangle in
            Dllist.fold_left begin fun (minX,maxX,minY,maxY) (child:'displayObject) ->
              let childBounds = child#boundsInSpace targetCoordinateSpace in
              (
                min minX childBounds.x,
                max maxX (childBounds.x +. childBounds.width),
                min minY childBounds.y,
                max maxY (childBounds.y +. childBounds.height)
              )
            end (max_float,~-.max_float,max_float,~-.max_float) children
          in
          Rectangle.create minX minY (maxX -. minX) (maxY -. minY)
      ];

   method bounds = self#boundsInSpace parent;

    method! private  hitTestPoint' localPoint isTouch = 
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


    method private render' rect = 
      match children with
      [ None -> ()
      | Some children -> 
        match rect with
        [ None -> 
          Dllist.iter begin fun child ->
            let childAlpha = child#alpha in
            if (childAlpha > 0.0 && child#visible) 
            then
            (
              glPushMatrix();
              child#transformGLMatrix ();
              child#setAlpha (childAlpha *. alpha);
              child#render None; 
              child#setAlpha childAlpha;
              glPopMatrix();
            )
            else ()
          end children
        | Some rect ->
            Dllist.iter begin fun (child:'displayObject) ->
              let childAlpha = child#alpha in
              if (childAlpha > 0.0 && child#visible) 
              then
                let bounds = child#bounds in
                match Rectangle.intersection rect bounds with
                [ Some intRect -> 
                  (
                    glPushMatrix();
                    child#transformGLMatrix ();
                    child#setAlpha (childAlpha *. alpha);
                    match child#dcast with
                    [ `Object _ -> child#render None (* FIXME: по идее нужно вызывать таки с ректом, но здесь оптимайзинг, убрать если надо! *)
                    | `Container c -> 
                      let childMatrix = self#transformationMatrixToSpace (Some child) in
                      c#render (Some (Matrix.transformRectangle childMatrix intRect))
                    ];
                    child#setAlpha childAlpha;
                    glPopMatrix();
                  )
                | None ->  debug:render "container '%s', not render: '%s'" name child#name
                ]
              else ()
            end children
        ]
      ];

  end;(*}}}*)



class virtual c =
  object(self)
    inherit _c [ container ];
    method dcast = `Object self#asDisplayObject;
    (*
    value mutable boundsCacheSelector = None;
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
  end;

end;
