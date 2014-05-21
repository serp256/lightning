open LightCommon;

value ev_ADDED = Ev.gen_id "ADDED";
value ev_ADDED_TO_STAGE = Ev.gen_id "ADDED_TO_STAGE";
value ev_REMOVED = Ev.gen_id "REMOVED";
value ev_REMOVED_FROM_STAGE = Ev.gen_id "REMOVED_FROM_STAGE";
value ev_ENTER_FRAME = Ev.gen_id "ENTER_FRAME";

type hidden 'a = 'a;

exception Invalid_index of (int*int);
Printexc.register_printer (fun [ Invalid_index (c,n) -> Some (Printf.sprintf "DisplayObject.Invalid_index %d %d" c n) | _ -> None ]);
exception Child_not_found;


(* приходит массив точек, к ним применяется трасформация и в результате получаем min и максимальные координаты *)

external glEnableScissor: int -> int -> int -> int -> unit = "ml_gl_scissor_enable";
external glDisableScissor: unit -> unit = "ml_gl_scissor_disable";

type rect_mask = { x0 : float ; y0 : float ; x1 : float ; y1 : float };
value maskStack = Stack.create ();

value scissor = ref None;
value setScissor x y = scissor.val := Some (x, y);
value resetScissor () = scissor.val := None;

Callback.register "setScissor" setScissor;
Callback.register "resetScissor" resetScissor;

DEFINE SCISSOR =
  match !scissor with
  [ Some (x, y) -> { x0 = os.x0 +. x; y0 = os.y0 +. y; x1 = os.x1 -. os.x0; y1 = os.y1 -. os.y0 }
  | _ ->
    let minY = sheight -. os.y1
    and maxY = sheight -. os.y0 in
      {(os) with x1 = os.x1 -. os.x0 ; y0 = minY ; y1 = maxY -. minY }
  ];

DEFINE RENDER_WITH_MASK(call_render) = (*{{{*)
  match stage with
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
    let () = debug:mask "transform points for mask" in
    match Matrix.transformPoints matrix maskPoints with
    [ [| minX; maxX; minY; maxY |] ->
      let sheight = stage#height in
      (
				let os = { x0 = minX ; y0 = minY ; x1 =  maxX ; y1 =  maxY } in
				let os = 
					try 
					 	let a = Stack.top maskStack in
							{ x0 = max os.x0 a.x0 ; y0 = max os.y0 a.y0 ; x1 = min os.x1 a.x1 ; y1 = min os.y1 a.y1 }
					with
						[ Stack.Empty -> os ]
					in
					(
						debug:mask "push %f %f %f %f " os.x0 os.y0 os.x1 os.y1;
						Stack.push os maskStack;
						let os = SCISSOR in
						let np = ref False in
						(
						 if (os.x1 > 0.0 && os.y1 > 0.0) then (
							 if (Stack.length maskStack > 1) then glDisableScissor () else ();
               debug:mask "push %f %f %f %f " os.x0 os.y0 os.x1 os.y1;
                glEnableScissor (int_of_float os.x0) (int_of_float os.y0) (int_of_float os.x1) (int_of_float os.y1);
								call_render;
								glDisableScissor ();
								if (Stack.length maskStack > 1) then 
									(
										np.val := True;
										ignore ( Stack.pop maskStack );
										let os = Stack.top maskStack in
                    let os = SCISSOR in
(* 										let minY = sheight -. os.y1
										and maxY = sheight -. os.y0 in
										let os = {(os) with x1 = os.x1 -. os.x0 ; y0 = minY ; y1 = maxY -. minY } in *)
										(
											glEnableScissor (int_of_float os.x0) (int_of_float os.y0) (int_of_float os.x1) (int_of_float os.y1);
										);
									)
								else ();
							) else ();

							if !np then () else 
							ignore ( Stack.pop maskStack );
							debug:mask "pull";
						);
					);
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
  SetD.iter (fun obj -> proftimer:prof "dispatch enter frame on: %s = %F" obj#name with obj#dispatchEvent enterFrameEvent) !onEnterFrameObjects;


class type prerenderObj =
  object
    method prerender: bool -> unit;
    method z: option int;
    method name: string;
  end;

value prerender_locked = ref None;
value prerender_objects = RefList.empty ();
value add_prerender o = 
  let () = debug:prerender "add_prerender: %s" o#name in
  match !prerender_locked with
  [ Some waits -> RefList.push waits o
  | None -> RefList.push prerender_objects o
  ];
  
value prerender () =
  proftimer(0.015):prof "prerender %f" with
    match RefList.is_empty prerender_objects with
    [ True -> ()
    | False ->
      (
        debug:prerender "start prerender";
        let locked_prerenders = RefList.empty () in
        (
          debug:perfomance "PRERENDER CNT: %d" (RefList.length prerender_objects);
          prerender_locked.val := Some locked_prerenders;
          let cmp ((z1:int),_) (z2,_) = compare z1 z2 in
          let sorted_objects = RefList.empty () in
          (
            proftimer:pprerender "SORT OBJECTS %F" with
            (RefList.iter (fun o -> 
              match o#z with
              [ Some z -> RefList.add_sort ~cmp sorted_objects (z,o)
              | None -> o#prerender False
              ]
            ) prerender_objects);
            proftimer:pprerender "EXECUTE %F" with (RefList.iter (fun (_,o) -> o#prerender True) sorted_objects);
          );
          RefList.copy prerender_objects locked_prerenders;
          prerender_locked.val := None;
        );
        debug:prerender "end prerender";
      )
    ];

value prerender () = proftimer:steam "prerender: %f" with (prerender ());


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

value object_count = ref 0;

class virtual _c [ 'parent ] = (*{{{*)

  object(self:'self)
    type 'displayObject = _c 'parent;
    inherit EventDispatcher.base [ 'displayObject,'self] as super;

    type 'displayObject = _c 'parent;
    type 'parent = 
      < 
        asDisplayObject: _c _; removeChild': _c _ -> unit; getChildIndex': _c _ -> int; z: option int; dispatchEvent': Ev.t -> _c _ -> unit; dispatchEventGlobal: Ev.t -> unit;
        name: string; transformationMatrixToSpace: !'space. option (<asDisplayObject: _c _; ..> as 'space) -> Matrix.t; stage: option 'parent; boundsChanged: unit -> unit;
        forceStageRender: ?reason:string -> unit -> unit;
        .. 
      >;

    value mutable parent : option 'parent = None;
    value mutable stage = None;

		initializer
		(
			 Gc.finalise (fun _ -> (
			 		decr object_count;
					) ) self;
			 incr object_count;

       ignore(self#addEventListener ev_ADDED_TO_STAGE (fun _ _ lid -> let () = debug:rmfromstage "add to stage %d lid %d" (Oo.id self) lid in stage := match parent with [ Some p -> p#stage | _ -> assert False ]));
       ignore(self#addEventListener ev_REMOVED_FROM_STAGE (fun _ _ _ -> let () = debug:rmfromstage "remove from stage %d" (Oo.id self) in stage := None));

(* 			 if !object_count mod 100 = 0 then *)
(* 				( *)
					 debug:leak "DO [%d] COUNT [%d] " (Oo.id self) !object_count ;
(* 				) *)
(* 			 else (); *)
		);

    value mutable name = None;
    method private defaultName = Printf.sprintf "instance%d" (Oo.id self);
    method name = match name with [ None -> self#defaultName | Some n -> n];
    method setName n = name := Some n;

    value mutable pos  = {Point.x = 0.; y =0.};
    value mutable transformPoint = {Point.x=0.;y=0.};
    value mutable scaleX = 1.0;
    value mutable scaleY = 1.0;
    value mutable rotation = 0.0;
    value mutable transformationMatrix = None;
    value mutable boundsCache = None;

		method classes  = ([]:list exn);

    method virtual color: color;
    method virtual setColor: color -> unit;

    method transformationMatrix = 
      match transformationMatrix with
      [ None -> 
(*         let translate = match transformPoint with [ {Point.x=0.;y=0.} -> pos | _ -> Point.addPoint pos transformPoint ] in *)
        let m = Matrix.create ~scale:(scaleX,scaleY) ~rotation ~translate:pos () in
        let m = 
          match transformPoint with 
          [ {Point.x = 0.; y = 0.} -> m 
          | p -> 
              let m' = Matrix.create ~translate:p () in
              Matrix.concat m' m
          ] 
        in
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
      debug:prerender "addToPrerenders: %s" self#name;
      match Queue.is_empty prerenders with
      [ False -> add_prerender (self :> prerenderObj)
      | True -> ()
      ];
      self#removeEventListener ev_ADDED_TO_STAGE lid;
      prerender_wait_listener := None;
    );

    method private addPrerender (pr:unit -> unit) =
    (
      debug:prerender "addPrerender for %s" self#name;
      match Queue.is_empty prerenders with
      [ True -> 
        match stage with
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


		method virtual dispatchEventGlobal: Ev.t -> unit;
    method setParent p = 
    (
(*       debug:prerender "set parent for %s" self#name; *)
      parent := Some p;
			let event = Ev.create ev_ADDED () in
			self#dispatchEvent event;
			match p#stage with
			[ Some _ -> 
				let event = Ev.create ev_ADDED_TO_STAGE () in
				  self#dispatchEventGlobal event
			| None -> ()
			]
    );

    method clearParent () = 
			match parent with
			[ Some p ->
				let on_stage = match stage with [ Some _ -> True | _ -> False ] in
				(
          stage := None;
          parent := None;
          let event = Ev.create ev_REMOVED () in
          self#dispatchEvent event;
          match on_stage with
          [ True ->
          	let event = Ev.create ev_REMOVED_FROM_STAGE () in
              (
                stage := None;
                self#dispatchEventGlobal event;
              )
          | False -> ()
          ];
				)
			| None -> ()
			];

    method z =
      match parent with
      [ Some parent -> 
        match parent#z with
        [ Some z -> Some (z + (parent#getChildIndex' (self :> _c 'parent)) + 1)
        | None -> None
        ]
      | None -> None
      ];

    method virtual filters: list Filters.t;
    method virtual setFilters: list Filters.t -> unit;

    method private enterFrameListenerRemovedFromStage  _ _ lid =
      let () = debug:rmfromstage "enterFrameListenerRemovedFromStage call" in
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
          match stage with
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
            match stage with
            [ None -> ()
            | Some _ -> onEnterFrameObjects.val := SetD.remove (self :> dispObj) !onEnterFrameObjects 
            ]
          | True -> ()
          ]
      else ()
    );

    method dispatchEvent' event target =
    (
      let evd = (target,self) in
      MList.apply_assoc 
        (fun l ->
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
    method setVisible nv =
      if visible <> nv
      then
        (
          self#forceStageRender ~reason:"set visible" ();
          visible := nv;
        )
      else ();

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

    method virtual boundsInSpace: !'space. ?withMask:bool -> option (<asDisplayObject: 'displayObject; .. > as 'space) -> Rectangle.t;

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
      let nr = clamp_rotation nr in
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
    method setAlpha na =
      if na <> alpha
      then
        (
          self#forceStageRender ~reason:"set alpha" ();
          alpha := max 0.0 (min 1.0 na);
        )
      else ();

    method asDisplayObject = (self :> _c 'parent);
    method virtual dcast: [= `Object of 'displayObject | `Container of 'parent ];

    method root = 
      loop (self :> _c 'parent) where
        rec loop currentObject =
          match currentObject#parent with
          [ None -> currentObject
          | Some p -> loop p#asDisplayObject
          ];

    method stage = stage;

    method forceStageRender ?reason () =
      match stage with
      [ Some s -> s#forceStageRender ?reason ()
      | _ -> ()
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

    method mask = match mask with [ Some (onSelf, rect, _) -> Some (onSelf, rect) | _ -> None ];
    method resetMask () = mask := None;
    method setMask ?(onSelf=False) rect =
      (
        self#forceStageRender ~reason:"set mask" ();
        let open Rectangle in 
        mask := Some (onSelf, rect, Rectangle.points rect); (* FIXME: можно сразу преобразовать этот рект и закэшировать нах *)        
      );


    method virtual private render': ?alpha:float -> ~transform:bool -> option Rectangle.t -> unit;

    method render ?alpha:(parentAlpha) ?(transform=True) rect =
      let () = debug "display object render" in
      let () = debug:tmp "render [%s]" self#name in
      proftimer:render ("render [%s] %f" self#name) with
      (
        if visible && alpha > 0. 
        then
          let () = debug "visible && alpha" in
          match mask with
          [ None -> self#render' ?alpha:parentAlpha ~transform rect 
          | Some (onSelf,maskRect,maskPoints) ->
            let () = debug:rendermask "some mask" in
              let maskRect = 
                match onSelf with
                [ True -> maskRect
                | False -> 
                    let m = self#transformationMatrix in 
                    Matrix.transformRectangle (Matrix.invert m) maskRect
                ]
              in
              let () = debug:rendermask "mask rect %s, rect = None: %B" (Rectangle.to_string maskRect) (rect = None) in
              match rect with
              [ None -> RENDER_WITH_MASK (self#render' ?alpha:parentAlpha ~transform (Some maskRect))
              | Some rect -> 
                  match Rectangle.intersection maskRect rect with
                  [ Some inRect ->
                    let () = debug:rendermask "Rectangle.intersection maskRect rect %s" (Rectangle.to_string inRect) in
                      RENDER_WITH_MASK (self#render' ?alpha:parentAlpha ~transform (Some inRect))
                  | None -> ()
                  ]
              ]
          ]
        else ();
      );

    method private virtual hitTestPoint': Point.t -> bool -> option (_c 'parent);

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


    method virtual stageResized: unit -> unit;

    method private maskInSpace: !'space. option (<asDisplayObject: 'displayObject; ..> as 'space) -> Rectangle.t = fun space ->
      let () = debug:boundswithmask "%s maskInSpace call" name in
      match mask with
      [ Some (onself, rect, _) ->
        let () = debug:boundswithmask "some mask %B %s" onself (Rectangle.to_string rect) in
        if onself
        then
          match space with
          [ Some s when s#asDisplayObject = self#asDisplayObject -> rect
          | _ -> Matrix.transformRectangle (self#transformationMatrixToSpace space) rect
          ]
        else
          match self#parent with
          [ Some p ->
            match space with
            [ Some s when s#asDisplayObject = p#asDisplayObject -> rect
            | _ -> Matrix.transformRectangle (p#transformationMatrixToSpace space) rect
            ]
          | _ -> Rectangle.empty
          ]
      | _ -> let () = debug:boundswithmask "no mask" in Rectangle.empty
      ];

    method private boundsWithMask': !'space. Rectangle.t -> option (<asDisplayObject: 'displayObject; ..> as 'space) -> bool -> Rectangle.t = fun bounds space withMask ->
      let () = debug:boundswithmask "%s bounds %s withMask %B" name (Rectangle.to_string bounds) withMask in
      if withMask
      then
        let mask = self#maskInSpace space in
          if Rectangle.isEmpty mask
          then let () = debug:boundswithmask "empty mask" in bounds
          else
            let () = debug:boundswithmask "mask in space %s" (Rectangle.to_string mask) in
              match Rectangle.intersection mask bounds with
              [ Some r -> r
              | _ -> Rectangle.empty
              ]
      else bounds;
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
    method dispatchEventGlobal event = 
    (
      self#dispatchEvent event;
      Enum.iter begin fun (child:'displayObject) -> (* здесь хуйня с таргетом надо разобраца *)
				child#dispatchEventGlobal event
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
          [ Some idx when idx > 0 -> raise (Invalid_index (idx,0))
          | _ -> children := Some (Dllist.create child)
          ]
        | Some chldrn -> 
            match index with
            [ None -> (* добавить в канец *) Dllist.add (Dllist.prev chldrn) child 
            | Some idx when idx > 0 && idx < numChildren -> Dllist.add (Dllist.skip chldrn (idx-1)) child
            | Some idx when idx = 0 -> children := Some (Dllist.prepend chldrn child)
            | Some idx when idx = numChildren -> Dllist.add (Dllist.prev chldrn) child
            | Some idx -> raise (Invalid_index (idx,numChildren))
            ]
        ];
        numChildren := numChildren + 1;
        child#setParent self#asDisplayObjectContainer;
        self#boundsChanged();
      );

    method getChildAt index = 
      match children with
      [ None -> raise (Invalid_index (index,0))
      | Some children -> 
          match index >= 0 && index < numChildren with
          [ True -> Dllist.get (Dllist.skip children index)
          | False -> raise (Invalid_index (index,numChildren))
          ]
      ];

    method getLastChild =
      match children with
      [ None -> raise (Invalid_index (1,0))
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
          if index >= numChildren || index < 0 then raise (Invalid_index (index,numChildren))
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
        child#clearParent();
        self#boundsChanged();
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
      [ None -> raise (Invalid_index (index,0))
      | Some children -> 
        match index >= 0 && index < numChildren with
        [ True -> 
          let n = Dllist.skip children index in
          self#removeChild'' n
        | False -> raise (Invalid_index (index,numChildren))
        ]
      ];

    method clearChildren () = 
      let () = debug:children "[%s] clear children" self#name in
      match children with
      [ None -> ()
      | Some chldrn -> 
				(*
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
				*)
        (
          children := None;
          numChildren := 0;
(*           Dllist.iter (fun (child:'displayObject) -> (child#clearParent();evs child)) chldrn; *)
          Dllist.iter (fun (child:'displayObject) -> child#clearParent()) chldrn;
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

    method boundsInSpace ?(withMask = False) targetCoordinateSpace =
        match children with
        [ None -> Rectangle.empty
        | Some children when children == (Dllist.next children) (* 1 child *) -> let () = debug:boundswithmask "1" in self#boundsWithMask' ((Dllist.get children)#boundsInSpace ~withMask targetCoordinateSpace) targetCoordinateSpace withMask
        | Some children ->
          let () = debug:boundswithmask "2" in 
            let ar = [| max_float; ~-.max_float; max_float; ~-.max_float |] in
            (
              let open Rectangle in
  (*             let transformationMatrix = self#transformationMatrixToSpace targetCoordinateSpace in *)
              let matrix = self#transformationMatrixToSpace targetCoordinateSpace in 
              Dllist.iter begin fun (child:'displayObject) ->
  (*               let childBounds = child#boundsInSpace targetCoordinateSpace in *)
                let childBounds = Matrix.transformRectangle matrix (if withMask then child#boundsInSpace ~withMask:True (Some self) else child#bounds) in
                (
                  if childBounds.x < ar.(0) then ar.(0) := childBounds.x else ();
                  let rightX = childBounds.x +. childBounds.width in
                  if rightX > ar.(1) then ar.(1) := rightX else ();
                  if childBounds.y < ar.(2) then ar.(2) := childBounds.y else ();
                  let downY = childBounds.y +. childBounds.height in
                  if downY > ar.(3) then ar.(3) := downY else ();
                )
              end children;

              self#boundsWithMask' (Rectangle.create ar.(0) ar.(2) (ar.(1) -. ar.(0)) (ar.(3) -. ar.(2))) targetCoordinateSpace withMask;
            )
        ];


    method private hitTestPoint' localPoint isTouch = 
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
      let () = debug:render "rendering container" in
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

    method stageResized () =
      match children with
      [ Some children -> Dllist.iter (fun (child:'displayObject) -> child#stageResized ()) children
      | _ -> ()
      ];
      
  end;(*}}}*)



class virtual c =
  object(self)
    inherit _c [ container ];
    method dcast = `Object (self :> c);
    method dispatchEventGlobal event = self#dispatchEvent event;
    method private hitTestPoint' localPoint isTouch = 
(*       let () = Printf.printf "hitTestPoint: %s, %s - %s\n" name (Point.to_string localPoint) (Rectangle.to_string (self#boundsInSpace (Some self#asDisplayObject))) in *)
      match Rectangle.containsPoint (self#boundsInSpace (Some self)) localPoint with
      [ True -> Some (self :> _c 'parent)
      | False -> None
      ];

    method stageResized () = ();
  end;

