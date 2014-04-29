class c () =
	object(self)
		inherit DisplayObject.container as super;

		method! stage = Some self#asDisplayObjectContainer;

		method cacheAsImage = False;
		method setCacheAsImage _ = ();

		method color = assert False;
		method setColor _ = assert False;

		method filters = assert False;
		method setFilters _ = assert False;

		method rendertex () = RenderTexture.draw self#width self#height (fun _ -> self#render None);
		method !z = Some 0;

		initializer ignore(self#addEventListener DisplayObject.ev_ADDED_TO_STAGE (fun _ _ _ -> assert False));
	end;

type kind = [= `immediate | `delayed | `callback of (unit -> unit) ];

class renderer ?kind:(kind:kind = `immediate) obj =
	object(self)
		value obj:DisplayObject.c = obj;

		value mutable posBckp = Point.empty;
		value mutable parentBckp = None;
		value mutable indexBckp = 0;

		method backupPos () = posBckp := obj#pos;

		method backupParent () =
			(
				parentBckp := obj#parent;
				match parentBckp with
				[ Some p -> indexBckp := p#getChildIndex obj
				| _ -> ()
				]
			);

		method returnPos () = obj#setPosPoint posBckp;

		method returnParent () = 
			match parentBckp with
			[ Some p -> p#addChild ~index:indexBckp obj
			| _ -> ()
			];

		method render () =
			let stage = new c () in
			let bnds = obj#boundsInSpace (Some obj) in
				(
					self#backupPos ();
					self#backupParent ();

					obj#setPos (-.bnds.Rectangle.x) (-.bnds.Rectangle.y);
					stage#addChild obj;

					let delayed callback =
						let img = Image.create Texture.zero in
						let i = ref 0 in
							(
								ignore((Stage.instance ())#addEventListener DisplayObject.ev_ENTER_FRAME (fun _ _ lid ->
									if !i < 1
									then incr i
									else
										(
											(Stage.instance ())#removeEventListener DisplayObject.ev_ENTER_FRAME lid;
											img#setTexture (stage#rendertex ())#asTexture;

											self#returnPos ();
											self#returnParent ();

											match callback with
											[ Some cb -> cb ()
											| _ -> ()
											];
										)
								));

								img;
							)
					in
						match kind with
						[ `immediate ->
						 	let img = Image.create (stage#rendertex ())#asTexture in
								(
									self#returnPos ();
									self#returnParent ();
									img;
								)
						| `delayed -> delayed None
						| `callback cb -> delayed (Some cb)
						];
				);
	end;
