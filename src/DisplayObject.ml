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

class virtual _c [ 'parent ] = (*{{{*)
  object(self:'self)
    type 'displayObject = _c 'parent;
    type 'parent = < asDisplayObject: _c _; removeChild': _c _ -> unit; dispatchEvent': Event.t P.evType P.evData _ _ -> unit; name: string; .. >;
    value mutable scaleX = 1.0;

    value mutable parent : option 'parent = None;
    method parent = parent;
    method setParent p = parent := Some p;
    method clearParent () = parent := None;

    (* Events *)
    type 'event = Event.t P.evType P.evData 'displayObject 'self;
    type 'listener = 'event -> unit;
    value listeners: Hashtbl.t P.evType 'listener = Hashtbl.create 0;
    method addEventListener evType listener = Hashtbl.add listeners evType listener;
    method dispatchEvent' event =
      let open Event in 
      let listeners = 
        try
          let listeners = Hashtbl.find_all listeners event.etype in
          Some listeners
        with [ Not_found -> None ]
      in
      match (event.bubbles,listeners) with
      [ (False,None) -> ()
      | (_,lstnrs) -> 
          (
            match lstnrs with
            [ Some listeners -> 
              let event = {(event) with currentTarget = Some self} in
              ignore(
                List.for_all begin fun l ->
                  (
                    l event;
                    event.stopImmediatePropagation;
                  )
                end listeners 
              )
            | None -> ()
            ];
            match event.bubbles && not event.stopPropagation with
            [ True -> 
              match parent with
              [ Some p -> 
                let event = {(event) with currentTarget = None } in
                p#dispatchEvent' event
              | None -> ()
              ]
            | False -> ()
            ]
          )
      ];
  
    (* всегда ставить таргет в себя и соответственно current_target *)
    method dispatchEvent (event:'event) = 
      let event = {(event) with Event.target = Some self#asDisplayObject} in
      self#dispatchEvent' event;

    method hasEventListeners eventType = Hashtbl.mem listeners eventType;



    method scaleX = scaleX;
    method setScaleX ns = scaleX := ns;

    value mutable scaleY = 1.0;
    method scaleY = scaleY;
    method setScaleY ns = scaleY := ns;

    method setScale s = (self#setScaleX s; self#setScaleY s);

    value mutable visible = True;
    method visible = visible;
    method setVisible nv = visible := nv;

    value mutable touchable = True;
    method touchable = touchable;
    method setTouchable v = touchable := v;

    value mutable x = 0.0;
    method x = x;
    method setX x' = x := x';

    value mutable y = 0.0;
    method y = y;
    method setY y' = y := y';

    method setPos (x',y') = (x := x'; y := y');


(*     method virtual boundsInSpace: !'target. option ((#_c 'et 'ed 'p) as 'target) -> Rectangle.t; *)

    method virtual boundsInSpace: option (_c 'parent) -> Rectangle.t;

(*     method bounds = self#boundsInSpace (parent :> option (_c 'event_type 'event_data 'parent)); *)

    method bounds = 
      (* бага типовыводилки здеся *)
      match parent with
      [ None -> self#boundsInSpace None
      | Some parent -> self#boundsInSpace (Some parent#asDisplayObject)
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
      rotation := nr;

    value mutable alpha = 1.0;
    method alpha = alpha;
    method setAlpha na = alpha := max 0.0 (min 1.0 na);

    value mutable name = "";
    initializer  name := Printf.sprintf "instance%d" (Oo.id self);
    method name = name;
    method setName n = name := n;

    value lastTouchTimestamp = 0.;
    method asDisplayObject = (self :> _c 'parent);
    method virtual dcast: [= `Object of 'displayObject | `Container of 'parent ];
    method isStage = False;
    method transformationMatrix = 
      let matrix = Matrix.create () in
      (
        if scaleX <> 1.0 || scaleY <> 1.0 then Matrix.scaleByXY matrix scaleX scaleY else ();
        if rotation <> 0.0 then Matrix.rotate matrix rotation else ();
        if x <> 0.0 || y <> 0.0 then Matrix.translateByXY matrix x y else ();
        matrix
      );

    method root = 
      loop self#asDisplayObject where
        rec loop currentObject =
          match currentObject#parent with
          [ None -> currentObject
          | Some p -> loop p#asDisplayObject
          ];

    method stage = 
      let root = self#root in
      match root#isStage with
      [ True -> Some root
      | False -> None
      ];


    method transformationMatrixToSpace: option 'displayObject -> Matrix.t = fun targetCoordinateSpace -> (*{{{*)
      match targetCoordinateSpace with
      [ None -> 
        let matrix = Matrix.create () in
        let rec loop currentObject = 
          (
            Matrix.concat matrix currentObject#transformationMatrix;
            match currentObject#parent with
            [ Some parent -> loop parent#asDisplayObject
            | None -> ()
            ]
          )
        in
        (
          loop self#asDisplayObject;
          matrix
        )
      | Some targetCoordinateSpace -> 
        if targetCoordinateSpace#asDisplayObject = self#asDisplayObject
        then Matrix.create ()
        else 
          match targetCoordinateSpace#parent with
          [ Some targetParent when targetParent#asDisplayObject = self#asDisplayObject -> (* optimization *)
              let targetMatrix = targetCoordinateSpace#transformationMatrix in
              (
                Matrix.invert targetMatrix;
                targetMatrix
              )
          | _ ->
(*               let () = Printf.eprintf "self: [%s], parent: [%s], targetCoordinateSpace: [%s]\n%!" name (match parent with [ None -> "NONE" | Some s -> s#name ]) targetCoordinateSpace#name in *)
              match parent with
              [ Some parent when parent#asDisplayObject = targetCoordinateSpace -> self#transformationMatrix (* optimization *) 
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
                  let matrix = Matrix.create () in
                  (
                    loop obj where
                      rec loop currentObject =
                        match currentObject = commonParent with
                        [ True -> ()
                        | False ->
                          (
                            Matrix.concat matrix currentObject#transformationMatrix;
                            match currentObject#parent with
                            [ Some p -> loop p#asDisplayObject
                            | None -> assert False
                            ]
                          )
                        ];
                      matrix;
                    )
                in
                (* 2.: Move up from self to common parent *)
                let selfMatrix = move_up self#asDisplayObject
                (* 3.: Move up from target to common parent *)
                and targetMatrix = move_up targetCoordinateSpace
                in
                (
                   (* 4.: Combine the two matrices *)
                   Matrix.invert targetMatrix;
                   Matrix.concat selfMatrix targetMatrix;
                   selfMatrix;
                )
              ]
          ]
      ];(*}}}*)
   
    method virtual render: unit -> unit;


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


    method hitTestPoint localPoint isTouch = 
(*       let () = Printf.printf "hitTestPoint: %s, %s - %s\n" name (Point.to_string localPoint) (Rectangle.to_string (self#boundsInSpace (Some self#asDisplayObject))) in *)
      (* on a touch test, invisible or untouchable objects cause the test to fail *)
      match (isTouch && (not visible || not touchable)) with
      [ True -> None
      | False ->
        match Rectangle.containsPoint (self#boundsInSpace (Some self#asDisplayObject)) localPoint with
        [ True -> Some self#asDisplayObject
        | False -> None
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
      let matrix = Matrix.create () in
      (
        loop self#asDisplayObject where
          rec loop currentObject =
            (
              Matrix.concat matrix currentObject#transformationMatrix;
              match currentObject#parent with
              [ None -> ()
              | Some p -> loop p#asDisplayObject
              ]
            );
        Matrix.transformPoint matrix localPoint;
      );


    method globalToLocal globalPoint = 
      (* move up until parent is nil, then invert matrix *)
      let matrix = Matrix.create () in
      (
        loop self#asDisplayObject where
          rec loop currentObject = 
            (
              Matrix.concat matrix currentObject#transformationMatrix;
              match currentObject#parent with
              [ None -> ()
              | Some p -> loop p#asDisplayObject
              ]
            );
         Matrix.invert matrix;
         Matrix.transformPoint matrix globalPoint;
      );

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

    method dispatchEventOnChildren event =
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
      | False -> Enum.iter (fun listener -> listener#dispatchEvent event) listeners
      ];
    

    method addChild: !'child. ?index:int -> ((#_c container) as 'child) -> unit = fun  ?index child ->
      let child = child#asDisplayObject in
      (
          match children with
          [ None -> 
            match index with
            [ Some idx when idx > 0 -> raise Invalid_index
            | _ -> ( child#removeFromParent(); children := Some (Dllist.create child))
            ]
          | Some chldrn -> 
              match index with
              [ None -> (* добавить с канец *) (child#removeFromParent(); Dllist.add (Dllist.prev chldrn) child )
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

    (* FIXME: защиту от зацикливаний бы поставить нах *)
    method private removeChild'' child_node =
      let child = Dllist.get child_node in
      (
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
            Dllist.fold_left begin fun (minX,maxX,minY,maxY) child ->
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

    method! hitTestPoint localPoint isTouch = 
      match isTouch && (not visible || not touchable) with
      [ True -> None
      | False -> (* бля это правда важно с конца сцука нахуй *)
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
          ]
      ];
    
    method render () = (* А здесь нужно наоборот сцука *)
      match children with
      [ None -> ()
      | Some children -> 
        Dllist.iter begin fun child ->
          let childAlpha = child#alpha in
          if (childAlpha > 0.0 && child#visible) 
          then
          (
            glPushMatrix();
            RenderSupport.transformMatrixForObject child;
            child#setAlpha (childAlpha *. alpha);
            child#render ();
            child#setAlpha childAlpha;
            glPopMatrix();
          )
          else ()
        end children
      ];
  end;(*}}}*)



class virtual c =
  object(self)
    inherit _c [ container ];
    method dcast = `Object self#asDisplayObject;
  end;

end;
