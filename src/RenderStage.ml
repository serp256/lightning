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

		method image () =
			let tex = RenderTexture.draw self#width self#height (fun _ -> self#render None) in
				new Image.c tex#asTexture;

		initializer ignore(self#addEventListener DisplayObject.ev_ADDED_TO_STAGE (fun _ _ _ -> assert False));
	end;

value render (d:DisplayObject.c) =
	let prnt = d#parent in
	let bnds = d#boundsInSpace (Some d) in
	let pos = d#pos in
	let rs:c = new c () in
		(
			d#setPos (-.bnds.Rectangle.x) (-.bnds.Rectangle.y);
			debug "--------------------------------";
			rs#addChild d;

			let img = rs#image () in
				(
					debug "+++++++++++++++++++++++++++++++";
					d#setPosPoint pos;
					match prnt with
					[ Some p -> p#addChild d
					| _ -> ()
					];

					img;
				);
		);