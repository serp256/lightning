class c () =
	object(self)
		inherit Stage.base as super;

		value mutable rendertex:option RenderTexture.c = None;

		method texture () =
			(
				self#stageDispatchEnterFrame 0.;
				self#stageRunPrerender ();

				let bounds = self#boundsInSpace ~withMask:True (Some self) in
				let w = bounds.Rectangle.width in
				let h = bounds.Rectangle.height in
				let render _ =
					(
						self#setPos (-.(bounds.Rectangle.x)) (-.(bounds.Rectangle.y));
						self#render None;
					)
				in
					match rendertex with
					[ Some tex ->
						(
							ignore(tex#draw ~clear:(0, 0.) ~width:w ~height:h render);
							tex;
						)
					| _ ->
						let tex = RenderTexture.(draw ~kind:(Dedicated Texture.FilterLinear) w h render) in
							(
								rendertex := Some tex;
								tex;
							)
					];
			);
	end;